'use strict';

const express = require('express');
const rateLimit = require('express-rate-limit');
const { PrismaClient } = require('@prisma/client');
const { authenticate, requireOwner } = require('../middleware/auth');
const { createOrder, handleNotify, getPlanAmount } = require('../services/telebirr');

const router = express.Router();
const prisma = new PrismaClient();

const webhookLimit = rateLimit({ windowMs: 60 * 1000, max: 60, message: { error: 'Too many webhook calls' } });

// ── POST /v1/telebirr/create-order ────────────────────────────────────────────
router.post('/create-order', authenticate, requireOwner, async (req, res, next) => {
  try {
    const { tier, periodMonths } = req.body;

    if (!tier || !['STARTER', 'BUSINESS', 'ENTERPRISE'].includes(tier)) {
      return res.status(400).json({ error: 'Invalid tier' });
    }
    if (!periodMonths || ![1, 12].includes(periodMonths)) {
      return res.status(400).json({ error: 'Invalid period. Must be 1 or 12' });
    }

    const amount = getPlanAmount(tier, periodMonths);
    if (!amount) {
      return res.status(400).json({ error: 'Could not calculate amount' });
    }

    const result = await createOrder({
      businessId: req.user.businessId,
      tier,
      periodMonths,
      amount,
    });

    res.json({
      outTradeNo: result.outTradeNo,
      rawRequest: result.rawRequest,
      toPayUrl: result.toPayUrl,
      amount,
      tier,
      periodMonths,
    });
  } catch (err) { next(err); }
});

// ── POST /v1/telebirr/notify ─────────────────────────────────────────────────
// TeleBirr webhook — NO auth, always returns 200
router.post('/notify', webhookLimit, async (req, res) => {
  try {
    const result = await handleNotify(req.body);
    res.status(200).json(result);
  } catch (err) {
    console.error('[TELEBIRR] Notify handler error:', err);
    res.status(200).json({ return_code: 'FAIL', return_msg: 'Internal error' });
  }
});

// ── GET /v1/telebirr/order/:outTradeNo ────────────────────────────────────────
// Poll order status (Flutter fallback)
router.get('/order/:outTradeNo', authenticate, async (req, res, next) => {
  try {
    const order = await prisma.subscriptionOrder.findUnique({
      where: { outTradeNo: req.params.outTradeNo },
      select: {
        outTradeNo: true,
        tier: true,
        periodMonths: true,
        amount: true,
        status: true,
        toPayUrl: true,
        paidAt: true,
        createdAt: true,
      },
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    res.json({
      outTradeNo: order.outTradeNo,
      tier: order.tier,
      periodMonths: order.periodMonths,
      amount: Number(order.amount),
      status: order.status,
      toPayUrl: order.toPayUrl,
      paidAt: order.paidAt?.toISOString(),
      createdAt: order.createdAt.toISOString(),
    });
  } catch (err) { next(err); }
});

module.exports = router;
