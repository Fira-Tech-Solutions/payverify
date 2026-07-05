'use strict';

const { PrismaClient } = require('@prisma/client');
const { broadcastToBusiness } = require('./websocket');

const prisma = new PrismaClient();

/**
 * Scheduled tasks.
 * Call startCronJobs() from index.js.
 * Uses setInterval — no external dependency needed.
 * For production, consider node-cron or a proper queue (BullMQ).
 */

function startCronJobs() {
  // ── Expire old PENDING transactions every hour ──────────────────
  setInterval(expirePendingTransactions, 60 * 60 * 1000);

  // ── Clean up used/expired invite codes daily ────────────────────
  setInterval(cleanInviteCodes, 24 * 60 * 60 * 1000);

  // ── Subscription state machine every hour ───────────────────────
  setInterval(checkSubscriptions, 60 * 60 * 1000);

  console.log('[CRON] Jobs scheduled');
}

async function expirePendingTransactions() {
  try {
    const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const { count } = await prisma.transaction.updateMany({
      where: {
        status:    'PENDING',
        createdAt: { lt: cutoff },
      },
      data: { status: 'EXPIRED' },
    });
    if (count > 0) {
      console.log(`[CRON] Expired ${count} old PENDING transactions`);
    }
  } catch (err) {
    console.error('[CRON] expirePendingTransactions failed:', err.message);
  }
}

async function cleanInviteCodes() {
  try {
    const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const { count } = await prisma.inviteCode.deleteMany({
      where: {
        OR: [
          { expiresAt: { lt: cutoff } },
          { usedAt: { lt: cutoff } },
        ],
      },
    });
    if (count > 0) {
      console.log(`[CRON] Cleaned ${count} old invite codes`);
    }
  } catch (err) {
    console.error('[CRON] cleanInviteCodes failed:', err.message);
  }
}

async function checkSubscriptions() {
  const now = new Date();
  try {
    // Move ACTIVE → GRACE when subscriptionEndsAt passes
    const expiredActive = await prisma.business.updateMany({
      where: {
        subscriptionStatus: 'ACTIVE',
        subscriptionEndsAt: { lt: now },
      },
      data: { subscriptionStatus: 'GRACE' },
    });
    if (expiredActive.count > 0) {
      console.log(`[CRON] Moved ${expiredActive.count} businesses to GRACE`);
    }

    // Move GRACE → EXPIRED when graceEndsAt passes
    const expiredGrace = await prisma.business.updateMany({
      where: {
        subscriptionStatus: 'GRACE',
        graceEndsAt: { lt: now },
      },
      data: { subscriptionStatus: 'EXPIRED' },
    });
    if (expiredGrace.count > 0) {
      console.log(`[CRON] Moved ${expiredGrace.count} businesses to EXPIRED`);
    }

    // TRIAL expiring in 3 days — push notification
    const threeDays = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
    const oneDay = new Date(now.getTime() + 1 * 24 * 60 * 60 * 1000);

    const expiringSoon = await prisma.business.findMany({
      where: {
        subscriptionStatus: 'TRIAL',
        trialEndsAt: { gt: now, lt: threeDays },
      },
    });

    for (const biz of expiringSoon) {
      const daysLeft = Math.ceil((biz.trialEndsAt - now) / (1000 * 60 * 60 * 24));
      try {
        broadcastToBusiness(biz.id, {
          type: 'subscription_expiring',
          daysLeft,
        });
      } catch (_) {}
    }
  } catch (err) {
    console.error('[CRON] checkSubscriptions failed:', err.message);
  }
}

module.exports = { startCronJobs };
