'use strict';

const express = require('express');
const { z }   = require('zod');
const { v4: uuidv4 } = require('uuid');
const { PrismaClient }  = require('@prisma/client');
const { authenticateSmsWebhook } = require('../middleware/auth');
const { parseSms }               = require('../services/sms-parser');
const { broadcastNewTransaction } = require('../services/websocket');

const router = express.Router();
const prisma = new PrismaClient();

// ── Africa's Talking incoming SMS webhook ─────────────────────────────────────
// Africa's Talking POSTs to this endpoint when an SMS arrives on your number.
// Configure in AT dashboard: https://account.africastalking.com/apps/sandbox/messaging
//
// POST /v1/sms/incoming
// Body (form-encoded): from, to, text, id, date, linkId
//
router.post('/incoming', authenticateSmsWebhook, async (req, res, next) => {
  try {
    const { from, text, to } = req.body;

    if (!text || !from) {
      return res.status(400).json({ error: 'Missing SMS fields' });
    }

    console.log(`[SMS] Incoming from ${from}: ${text.substring(0, 80)}…`);

    // Find which business owns this phone number (the "to" number)
    const business = await prisma.business.findFirst({
      where: { phoneNumber: to },
    });

    if (!business) {
      console.warn(`[SMS] No business found for number: ${to}`);
      return res.status(200).json({ received: true, stored: false });
    }

    await ingestSms(text, from, business.id);

    res.status(200).json({ received: true });
  } catch (err) { next(err); }
});

// ── Android SMS Forwarder webhook ─────────────────────────────────────────────
// The merchant's Android device (with bank SIM) runs a lightweight app
// that forwards incoming SMS to this endpoint.
//
// POST /v1/sms/forward
// Body (JSON): { businessId, from, body, secret }
//
const forwardSchema = z.object({
  businessId: z.string().uuid(),
  from:       z.string(),
  body:       z.string().min(10),
});

router.post('/forward', async (req, res, next) => {
  try {
    // Validate device secret
    const deviceSecret = req.headers['x-device-secret'] || req.body.secret;
    if (deviceSecret !== process.env.SMS_WEBHOOK_SECRET) {
      return res.status(401).json({ error: 'Invalid device secret' });
    }

    const { businessId, from, body } = forwardSchema.parse(req.body);

    // Verify the business exists
    const business = await prisma.business.findUnique({
      where: { id: businessId },
    });

    if (!business) {
      return res.status(404).json({ error: 'Business not found' });
    }

    const stored = await ingestSms(body, from, businessId);

    res.json({ received: true, stored: !!stored, transactionId: stored?.transactionId });
  } catch (err) { next(err); }
});

// ── Shared ingestion logic ────────────────────────────────────────────────────

async function ingestSms(smsBody, senderAddress, businessId) {
  const parsed = parseSms(smsBody, senderAddress);

  if (!parsed) {
    console.log(`[SMS] Not a recognised bank SMS from ${senderAddress}`);
    return null;
  }

  if (parsed.amount <= 0) {
    console.warn(`[SMS] Parsed amount is 0 — skipping: ${parsed.transactionId}`);
    return null;
  }

  try {
    // upsert: if same transactionId arrives twice, don't duplicate (idempotency)
    const tx = await prisma.transaction.upsert({
      where: { transactionId: parsed.transactionId },
      update: {}, // do nothing if already exists
      create: {
        id:            uuidv4(),
        businessId,
        transactionId: parsed.transactionId,
        amount:        parsed.amount,
        senderName:    parsed.senderName,
        senderPhone:   parsed.senderPhone,
        paymentMethod: parsed.paymentMethod,
        status:        'PENDING',
        rawSms:        smsBody,
      },
    });

    // Push to all connected cashiers in this business in real time
    broadcastNewTransaction(businessId, {
      id:            tx.id,
      transactionId: tx.transactionId,
      amount:        Number(tx.amount),
      senderName:    tx.senderName,
      senderPhone:   tx.senderPhone,
      paymentMethod: tx.paymentMethod,
      status:        tx.status,
      timestamp:     tx.createdAt.toISOString(),
      businessId:    tx.businessId,
    });

    console.log(`[SMS] ✓ Stored: ${tx.transactionId} ETB ${tx.amount} (${tx.paymentMethod})`);
    return tx;
  } catch (err) {
    // transactionId unique constraint violation = duplicate, safe to ignore
    if (err.code === 'P2002') {
      console.log(`[SMS] Duplicate tx ignored: ${parsed.transactionId}`);
      return null;
    }
    throw err;
  }
}

module.exports = router;
