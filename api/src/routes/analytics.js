'use strict';

const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { authenticate, requireManager } = require('../middleware/auth');

const router = express.Router();
const prisma = new PrismaClient();

router.use(authenticate, requireManager);

// ── GET /v1/analytics/dashboard ───────────────────────────────────────────────
// Returns summary stats for the owner dashboard
// ?period=today|week|month
router.get('/dashboard', async (req, res, next) => {
  try {
    const { period = 'today' } = req.query;
    const businessId = req.user.businessId;
    const { from, to } = periodRange(period);

    const where = {
      businessId,
      createdAt: { gte: from, lte: to },
    };

    // Run all queries in parallel
    const [
      totalCount,
      verifiedCount,
      mismatchCount,
      pendingCount,
      amountAgg,
      byMethod,
      byWorker,
      hourlyBreakdown,
    ] = await Promise.all([

      prisma.transaction.count({ where }),

      prisma.transaction.count({ where: { ...where, status: 'VERIFIED' } }),

      prisma.transaction.count({ where: { ...where, status: 'MISMATCH' } }),

      prisma.transaction.count({ where: { ...where, status: 'PENDING' } }),

      // Total verified amount
      prisma.transaction.aggregate({
        where: { ...where, status: 'VERIFIED' },
        _sum: { amount: true },
      }),

      // Breakdown by payment method
      prisma.transaction.groupBy({
        by: ['paymentMethod'],
        where: { ...where, status: 'VERIFIED' },
        _count: { id: true },
        _sum:   { amount: true },
        orderBy: { _sum: { amount: 'desc' } },
      }),

      // Top workers by verification count
      prisma.transaction.groupBy({
        by: ['workerId'],
        where: { ...where, status: 'VERIFIED', workerId: { not: null } },
        _count: { id: true },
        _sum:   { amount: true },
        orderBy: { _count: { id: 'desc' } },
        take: 5,
      }),

      // Hourly activity (today only)
      period === 'today'
        ? prisma.$queryRaw`
            SELECT
              EXTRACT(HOUR FROM "createdAt") AS hour,
              COUNT(*) FILTER (WHERE status = 'VERIFIED') AS verified,
              COALESCE(SUM(amount) FILTER (WHERE status = 'VERIFIED'), 0) AS amount
            FROM transactions
            WHERE "businessId" = ${businessId}
              AND "createdAt" >= ${from}
              AND "createdAt" <= ${to}
            GROUP BY hour
            ORDER BY hour
          `
        : Promise.resolve([]),
    ]);

    // Resolve worker names
    const workerIds = byWorker.map(w => w.workerId).filter(Boolean);
    const workerMap = {};
    if (workerIds.length > 0) {
      const users = await prisma.user.findMany({
        where: { id: { in: workerIds } },
        select: { id: true, name: true },
      });
      users.forEach(u => { workerMap[u.id] = u.name; });
    }

    res.json({
      period,
      from: from.toISOString(),
      to:   to.toISOString(),
      summary: {
        totalCount,
        verifiedCount,
        mismatchCount,
        pendingCount,
        totalAmount:    Number(amountAgg._sum.amount ?? 0),
        successRate:    totalCount > 0
          ? Math.round((verifiedCount / totalCount) * 100)
          : 0,
      },
      byMethod: byMethod.map(m => ({
        method:  m.paymentMethod,
        count:   m._count.id,
        amount:  Number(m._sum.amount ?? 0),
      })),
      topWorkers: byWorker.map(w => ({
        workerId:   w.workerId,
        workerName: workerMap[w.workerId] ?? 'Unknown',
        count:      w._count.id,
        amount:     Number(w._sum.amount ?? 0),
      })),
      hourly: hourlyBreakdown.map(h => ({
        hour:     Number(h.hour),
        verified: Number(h.verified),
        amount:   Number(h.amount),
      })),
    });
  } catch (err) { next(err); }
});

// ── GET /v1/analytics/trends ──────────────────────────────────────────────────
// Daily totals for the last 30 days — used for charts
router.get('/trends', async (req, res, next) => {
  try {
    const businessId = req.user.businessId;
    const days       = Math.min(parseInt(req.query.days ?? '30'), 90);
    const from       = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    const rows = await prisma.$queryRaw`
      SELECT
        DATE("createdAt") AS date,
        COUNT(*) FILTER (WHERE status = 'VERIFIED') AS verified,
        COUNT(*) FILTER (WHERE status = 'MISMATCH') AS mismatch,
        COALESCE(SUM(amount) FILTER (WHERE status = 'VERIFIED'), 0) AS amount
      FROM transactions
      WHERE "businessId" = ${businessId}
        AND "createdAt" >= ${from}
      GROUP BY DATE("createdAt")
      ORDER BY date
    `;

    res.json({
      days,
      trends: rows.map(r => ({
        date:     r.date,
        verified: Number(r.verified),
        mismatch: Number(r.mismatch),
        amount:   Number(r.amount),
      })),
    });
  } catch (err) { next(err); }
});

// ── GET /v1/analytics/export ──────────────────────────────────────────────────
// CSV export of transactions for a date range
router.get('/export', async (req, res, next) => {
  try {
    const { from, to } = req.query;
    if (!from || !to) {
      return res.status(400).json({ error: 'from and to dates required' });
    }

    const transactions = await prisma.transaction.findMany({
      where: {
        businessId: req.user.businessId,
        createdAt: {
          gte: new Date(from),
          lte: new Date(to),
        },
      },
      include: { worker: { select: { name: true } } },
      orderBy: { createdAt: 'desc' },
    });

    const csv = [
      'Date,Time,TransactionID,Amount,Method,Sender,Phone,Status,VerifiedBy',
      ...transactions.map(tx => [
        tx.createdAt.toISOString().split('T')[0],
        tx.createdAt.toTimeString().split(' ')[0],
        tx.transactionId,
        Number(tx.amount).toFixed(2),
        tx.paymentMethod,
        `"${tx.senderName}"`,
        tx.senderPhone,
        tx.status,
        `"${tx.worker?.name ?? ''}"`,
      ].join(',')),
    ].join('\n');

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition',
      `attachment; filename="payverify-${from}-${to}.csv"`);
    res.send(csv);
  } catch (err) { next(err); }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function periodRange(period) {
  const now  = new Date();
  const from = new Date();

  switch (period) {
    case 'today':
      from.setHours(0, 0, 0, 0);
      break;
    case 'week':
      from.setDate(now.getDate() - 7);
      from.setHours(0, 0, 0, 0);
      break;
    case 'month':
      from.setDate(1);
      from.setHours(0, 0, 0, 0);
      break;
    default:
      from.setHours(0, 0, 0, 0);
  }

  return { from, to: now };
}

module.exports = router;
