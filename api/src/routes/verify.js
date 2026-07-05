'use strict';

const express = require('express');
const { z }   = require('zod');
const { PrismaClient } = require('@prisma/client');
const { authenticate } = require('../middleware/auth');
const { broadcastStatusUpdate } = require('../services/websocket');

const router = express.Router();
const prisma = new PrismaClient();

const verifySchema = z.object({
  referenceCode: z.string().min(4).max(40),
  businessId:    z.string().uuid().optional(), // fallback if not in token
  workerId:      z.string().uuid().optional(),
});

/**
 * POST /v1/verify
 *
 * Core verification flow:
 * 1. Cashier submits a reference code (from QR scan / manual entry / OCR)
 * 2. We look for a PENDING transaction with that ID in this business's ledger
 * 3. If found → mark VERIFIED, return details, broadcast update to all clients
 * 4. If not found → return MISMATCH
 * 5. Idempotency: VERIFIED transactions cannot be re-verified (anti-fraud)
 */
router.post('/', authenticate, async (req, res, next) => {
  try {
    const { referenceCode } = verifySchema.parse(req.body);
    const businessId = req.user.businessId;
    const workerId   = req.user.id;

    // Normalise: strip spaces, uppercase
    const normalised = referenceCode.trim().toUpperCase();

    // Look up by transactionId scoped to this business ONLY
    // Cashiers cannot query across businesses — enforced at DB level
    const tx = await prisma.transaction.findFirst({
      where: {
        businessId,
        transactionId: { equals: normalised, mode: 'insensitive' },
      },
    });

    // ── Not found ─────────────────────────────────────────────────
    if (!tx) {
      // Log the failed attempt for fraud monitoring
      console.warn(`[VERIFY] MISMATCH — ref: ${normalised} business: ${businessId} worker: ${workerId}`);
      return res.status(200).json({
        verified: false,
        transaction: {
          transactionId: normalised,
          status:        'MISMATCH',
          paymentMethod: 'Unknown',
          amount:        0,
          senderName:    '',
          senderPhone:   '',
          timestamp:     new Date().toISOString(),
          businessId,
          workerName:    req.user.name,
        },
      });
    }

    // ── Already verified (anti-reuse / idempotency) ───────────────
    if (tx.status === 'VERIFIED') {
      return res.status(200).json({
        verified: false,
        alreadyUsed: true,
        transaction: formatTx(tx),
        message: 'This payment was already verified. Cannot reuse.',
      });
    }

    // ── Expired ───────────────────────────────────────────────────
    if (tx.status === 'EXPIRED') {
      return res.status(200).json({
        verified: false,
        transaction: formatTx(tx),
        message: 'This transaction has expired.',
      });
    }

    // ── Verify it ─────────────────────────────────────────────────
    const updated = await prisma.transaction.update({
      where: { id: tx.id },
      data: {
        status:   'VERIFIED',
        workerId,
        updatedAt: new Date(),
      },
    });

    // Push real-time update to all clients in this business room
    broadcastStatusUpdate(businessId, updated.transactionId, 'VERIFIED');

    console.log(`[VERIFY] ✓ ${updated.transactionId} ETB ${updated.amount} — worker: ${req.user.name}`);

    return res.json({
      verified: true,
      transaction: {
        ...formatTx(updated),
        workerName: req.user.name,
      },
    });
  } catch (err) { next(err); }
});

function formatTx(tx) {
  return {
    id:            tx.id,
    transactionId: tx.transactionId,
    amount:        Number(tx.amount),
    senderName:    tx.senderName,
    senderPhone:   tx.senderPhone,
    paymentMethod: tx.paymentMethod,
    status:        tx.status,
    timestamp:     tx.createdAt.toISOString(),
    businessId:    tx.businessId,
  };
}

module.exports = router;
