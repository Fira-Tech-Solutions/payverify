'use strict';

const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { authenticate, requireOwner } = require('../middleware/auth');
const { checkSubscriptionStatus, getPlans, getSubscriptionHistory } = require('../services/subscription-service');

const router = express.Router();
const prisma = new PrismaClient();

router.use(authenticate);

// ── GET /v1/subscription ──────────────────────────────────────────────────────
// Current subscription status for the business
router.get('/', async (req, res, next) => {
  try {
    const biz = req.business;
    const now = new Date();

    let daysRemaining = null;
    if (biz.subscriptionEndsAt) {
      daysRemaining = Math.max(0, Math.ceil((biz.subscriptionEndsAt - now) / (1000 * 60 * 60 * 24)));
    } else if (biz.subscriptionStatus === 'TRIAL') {
      daysRemaining = Math.max(0, Math.ceil((biz.trialEndsAt - now) / (1000 * 60 * 60 * 24)));
    }

    let graceDaysRemaining = null;
    if (biz.subscriptionStatus === 'GRACE' && biz.graceEndsAt) {
      graceDaysRemaining = Math.max(0, Math.ceil((biz.graceEndsAt - now) / (1000 * 60 * 60 * 24)));
    }

    // Get verification count this period
    const verificationCount = await prisma.transaction.count({
      where: {
        businessId: biz.id,
        status: 'VERIFIED',
      },
    });

    // Get worker count
    const workerCount = await prisma.user.count({
      where: {
        businessId: biz.id,
        isActive: true,
        role: { not: 'OWNER' },
      },
    });

    res.json({
      status:           biz.subscriptionStatus,
      tier:             biz.subscriptionTier,
      trialEndsAt:      biz.trialEndsAt?.toISOString(),
      subscriptionEndsAt: biz.subscriptionEndsAt?.toISOString(),
      graceEndsAt:      biz.graceEndsAt?.toISOString(),
      daysRemaining,
      graceDaysRemaining,
      verificationCount,
      workerCount,
    });
  } catch (err) { next(err); }
});

// ── GET /v1/subscription/plans ────────────────────────────────────────────────
router.get('/plans', async (_req, res, next) => {
  try {
    const plans = await getPlans();
    res.json({ plans });
  } catch (err) { next(err); }
});

// ── GET /v1/subscription/history ──────────────────────────────────────────────
router.get('/history', async (req, res, next) => {
  try {
    const payments = await getSubscriptionHistory(req.user.businessId);
    res.json({
      payments: payments.map(p => ({
        id:            p.id,
        transactionId: p.transactionId,
        amount:        Number(p.amount),
        tier:          p.tier,
        periodMonths:  p.periodMonths,
        paidAt:        p.paidAt.toISOString(),
        verifiedAt:    p.verifiedAt?.toISOString(),
        createdAt:     p.createdAt.toISOString(),
      })),
    });
  } catch (err) { next(err); }
});

// ── POST /v1/subscription/verify-payment ─────────────────────────────────────
// Manually trigger payment verification (polling after user clicks "I've paid")
router.post('/verify-payment', async (req, res, next) => {
  try {
    const status = await checkSubscriptionStatus(req.user.businessId);
    res.json({ subscription: status });
  } catch (err) { next(err); }
});

module.exports = router;
