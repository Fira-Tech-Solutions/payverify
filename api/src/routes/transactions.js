'use strict';

const express = require('express');
const { z }   = require('zod');
const { PrismaClient } = require('@prisma/client');
const { authenticate, requireManager } = require('../middleware/auth');

const router = express.Router();
const prisma = new PrismaClient();

// All transaction routes require auth
router.use(authenticate);

// ── GET /v1/transactions ──────────────────────────────────────────────────────
// Cashiers: returns only their own verified transactions (no revenue totals)
// Managers/Owners: returns full business ledger with filters
router.get('/', async (req, res, next) => {
  try {
    const { limit = 50, offset = 0, status, method, from, to } = req.query;
    const businessId = req.user.businessId;
    const isCashier  = req.user.role === 'CASHIER';

    const where = {
      businessId,
      // Cashiers can only see transactions they personally verified
      ...(isCashier ? { workerId: req.user.id } : {}),
      ...(status ? { status } : {}),
      ...(method ? { paymentMethod: method } : {}),
      ...(from || to ? {
        createdAt: {
          ...(from ? { gte: new Date(from) } : {}),
          ...(to   ? { lte: new Date(to)   } : {}),
        },
      } : {}),
    };

    const [transactions, total] = await Promise.all([
      prisma.transaction.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take:    Math.min(parseInt(limit), 200),
        skip:    parseInt(offset),
        select: {
          id:            true,
          transactionId: true,
          amount:        true,
          senderName:    true,
          senderPhone:   true,
          paymentMethod: true,
          status:        true,
          createdAt:     true,
          businessId:    true,
          worker: { select: { name: true } },
          // Never expose rawSms to cashiers
          ...(isCashier ? {} : { rawSms: true }),
        },
      }),
      prisma.transaction.count({ where }),
    ]);

    res.json({
      transactions: transactions.map(tx => ({
        ...tx,
        amount:     Number(tx.amount),
        timestamp:  tx.createdAt.toISOString(),
        workerName: tx.worker?.name ?? null,
      })),
      total,
      limit:  parseInt(limit),
      offset: parseInt(offset),
    });
  } catch (err) { next(err); }
});

// ── GET /v1/transactions/:id ──────────────────────────────────────────────────
router.get('/:id', async (req, res, next) => {
  try {
    const tx = await prisma.transaction.findFirst({
      where: {
        id:         req.params.id,
        businessId: req.user.businessId, // always scope to business
      },
    });

    if (!tx) return res.status(404).json({ error: 'Transaction not found' });
    res.json({ ...tx, amount: Number(tx.amount) });
  } catch (err) { next(err); }
});

// ── POST /v1/transactions/expire ─────────────────────────────────────────────
// Expires PENDING transactions older than 24 hours (run as a cron or manually)
router.post('/expire', requireManager, async (req, res, next) => {
  try {
    const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const { count } = await prisma.transaction.updateMany({
      where: {
        businessId: req.user.businessId,
        status:     'PENDING',
        createdAt:  { lt: cutoff },
      },
      data: { status: 'EXPIRED' },
    });

    console.log(`[EXPIRE] Expired ${count} old PENDING transactions`);
    res.json({ expired: count });
  } catch (err) { next(err); }
});

module.exports = router;
