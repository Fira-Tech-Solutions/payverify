'use strict';

const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { authenticate, requireOwner } = require('../middleware/auth');
const { activateSubscription, PLAN_DETAILS } = require('../services/subscription-service');

const router = express.Router();
const prisma = new PrismaClient();

// ── Admin auth middleware ──────────────────────────────────────────────────────
function authenticateAdmin(req, res, next) {
  const secret = req.headers['x-admin-secret'];
  if (!secret || secret !== process.env.ADMIN_SECRET) {
    return res.status(401).json({ error: 'Invalid admin secret' });
  }
  next();
}

router.use(authenticateAdmin);

// ── GET /v1/admin/businesses ──────────────────────────────────────────────────
router.get('/businesses', async (req, res, next) => {
  try {
    const { status, search, page = 1, limit = 50 } = req.query;
    const where = {};
    if (status) where.subscriptionStatus = status;
    if (search) {
      where.OR = [
        { businessName: { contains: search, mode: 'insensitive' } },
        { ownerName:    { contains: search, mode: 'insensitive' } },
        { phoneNumber:  { contains: search } },
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [businesses, total] = await Promise.all([
      prisma.business.findMany({
        where,
        include: {
          _count: { select: { users: true, transactions: true, subscriptionPayments: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit),
      }),
      prisma.business.count({ where }),
    ]);

    res.json({
      businesses: businesses.map(b => ({
        id:                 b.id,
        ownerName:          b.ownerName,
        businessName:       b.businessName,
        phoneNumber:        b.phoneNumber,
        subscriptionStatus: b.subscriptionStatus,
        subscriptionTier:   b.subscriptionTier,
        trialEndsAt:        b.trialEndsAt?.toISOString(),
        subscriptionEndsAt: b.subscriptionEndsAt?.toISOString(),
        createdAt:          b.createdAt.toISOString(),
        workerCount:        b._count.users,
        transactionCount:   b._count.transactions,
        paymentCount:       b._count.subscriptionPayments,
      })),
      total,
      page: parseInt(page),
      limit: parseInt(limit),
    });
  } catch (err) { next(err); }
});

// ── POST /v1/admin/subscription ───────────────────────────────────────────────
// Manually activate or extend a business subscription
router.post('/subscription', async (req, res, next) => {
  try {
    const { businessId, tier, months, amount } = req.body;

    if (!businessId || !tier || !months) {
      return res.status(400).json({ error: 'businessId, tier, and months are required' });
    }

    if (!['STARTER', 'BUSINESS', 'ENTERPRISE'].includes(tier)) {
      return res.status(400).json({ error: 'Invalid tier' });
    }

    if (typeof months !== 'number' || months < 1 || months > 36) {
      return res.status(400).json({ error: 'Months must be 1-36' });
    }

    const biz = await prisma.business.findUnique({ where: { id: businessId } });
    if (!biz) {
      return res.status(404).json({ error: 'Business not found' });
    }

    const paymentAmount = amount || PLAN_DETAILS[tier].monthlyPrice * months;
    const txnId = `ADMIN-${Date.now()}-${businessId.slice(-6).toUpperCase()}`;

    const result = await activateSubscription(businessId, tier, months, txnId, paymentAmount);

    res.json({
      message:        'Subscription activated',
      businessId,
      tier,
      months,
      subscriptionEndsAt: result.newEndsAt.toISOString(),
    });
  } catch (err) { next(err); }
});

// ── GET /v1/admin/revenue ─────────────────────────────────────────────────────
router.get('/revenue', async (req, res, next) => {
  try {
    const now = new Date();
    const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);

    const [thisMonthRevenue, lastMonthRevenue, totalRevenue, activeBusinesses, totalBusinesses] = await Promise.all([
      prisma.subscriptionPayment.aggregate({
        where: { verifiedAt: { gte: thisMonth } },
        _sum: { amount: true },
        _count: true,
      }),
      prisma.subscriptionPayment.aggregate({
        where: { verifiedAt: { gte: lastMonth, lt: thisMonth } },
        _sum: { amount: true },
        _count: true,
      }),
      prisma.subscriptionPayment.aggregate({
        where: { verifiedAt: { not: null } },
        _sum: { amount: true },
        _count: true,
      }),
      prisma.business.count({ where: { subscriptionStatus: 'ACTIVE' } }),
      prisma.business.count(),
    ]);

    const mrr = Number(thisMonthRevenue._sum.amount || 0);
    const lastMrr = Number(lastMonthRevenue._sum.amount || 0);
    const mrrGrowth = lastMrr > 0 ? ((mrr - lastMrr) / lastMrr * 100).toFixed(1) : '0.0';

    res.json({
      mrr,
      mrrGrowth: parseFloat(mrrGrowth),
      totalRevenue:     Number(totalRevenue._sum.amount || 0),
      totalPayments:    totalRevenue._count,
      activeBusinesses,
      totalBusinesses,
      thisMonthPayments: thisMonthRevenue._count,
    });
  } catch (err) { next(err); }
});

module.exports = router;
