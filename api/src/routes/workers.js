'use strict';

const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { authenticate, requireManager } = require('../middleware/auth');

const router = express.Router();
const prisma = new PrismaClient();

router.use(authenticate);

// ── POST /v1/workers/invite ───────────────────────────────────────────────────
// Owner/Manager generates a 6-char invite code (expires 24h)
router.post('/invite', requireManager, async (req, res, next) => {
  try {
    // Expire any old unused codes for this business first
    await prisma.inviteCode.updateMany({
      where: {
        businessId: req.user.businessId,
        usedAt:     null,
        expiresAt:  { lt: new Date() },
      },
      data: { expiresAt: new Date() }, // mark as expired
    });

    const code      = generateCode();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24h

    await prisma.inviteCode.create({
      data: {
        businessId: req.user.businessId,
        code,
        expiresAt,
      },
    });

    res.json({ code, expiresAt });
  } catch (err) { next(err); }
});

// ── GET /v1/workers ───────────────────────────────────────────────────────────
// List all workers in the business (manager+ only)
router.get('/', requireManager, async (req, res, next) => {
  try {
    const workers = await prisma.user.findMany({
      where: {
        businessId: req.user.businessId,
        isActive:   true,
        role:       { not: 'OWNER' }, // don't list the owner as a worker
      },
      select: {
        id:        true,
        name:      true,
        phone:     true,
        role:      true,
        createdAt: true,
        _count: {
          select: { transactions: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({
      workers: workers.map(w => ({
        id:               w.id,
        name:             w.name,
        phone:            w.phone,
        role:             w.role,
        joinedAt:         w.createdAt.toISOString(),
        verificationCount: w._count.transactions,
      })),
    });
  } catch (err) { next(err); }
});

// ── DELETE /v1/workers/:id ────────────────────────────────────────────────────
// Deactivate a worker (soft delete)
router.delete('/:id', requireManager, async (req, res, next) => {
  try {
    const worker = await prisma.user.findFirst({
      where: {
        id:         req.params.id,
        businessId: req.user.businessId,
        role:       { not: 'OWNER' }, // can't remove the owner
      },
    });

    if (!worker) {
      return res.status(404).json({ error: 'Worker not found' });
    }

    await prisma.user.update({
      where: { id: worker.id },
      data:  { isActive: false },
    });

    res.json({ removed: true, workerId: worker.id });
  } catch (err) { next(err); }
});

// ── PUT /v1/workers/:id/role ──────────────────────────────────────────────────
// Promote a cashier to manager (owner only)
router.put('/:id/role', requireManager, async (req, res, next) => {
  try {
    const { role } = req.body;
    if (!['CASHIER', 'MANAGER'].includes(role)) {
      return res.status(400).json({ error: 'Role must be CASHIER or MANAGER' });
    }

    // Only owners can promote to manager
    if (role === 'MANAGER' && req.user.role !== 'OWNER') {
      return res.status(403).json({ error: 'Only owners can promote to manager' });
    }

    const worker = await prisma.user.findFirst({
      where: {
        id:         req.params.id,
        businessId: req.user.businessId,
        role:       { not: 'OWNER' },
      },
    });

    if (!worker) {
      return res.status(404).json({ error: 'Worker not found' });
    }

    const updated = await prisma.user.update({
      where: { id: worker.id },
      data:  { role },
    });

    res.json({ updated: true, worker: { id: updated.id, name: updated.name, role: updated.role } });
  } catch (err) { next(err); }
});

// ── GET /v1/workers/invite/active ─────────────────────────────────────────────
// Get the currently active (unused, not expired) invite code if any
router.get('/invite/active', requireManager, async (req, res, next) => {
  try {
    const active = await prisma.inviteCode.findFirst({
      where: {
        businessId: req.user.businessId,
        usedAt:     null,
        expiresAt:  { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!active) {
      return res.json({ code: null });
    }

    res.json({ code: active.code, expiresAt: active.expiresAt });
  } catch (err) { next(err); }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function generateCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I confusion
  return Array.from({ length: 6 }, () =>
    chars[Math.floor(Math.random() * chars.length)]
  ).join('');
}

module.exports = router;
