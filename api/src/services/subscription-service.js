'use strict';

const { PrismaClient } = require('@prisma/client');
const { parseReferenceCode, resolveTierAndMonths } = require('../utils/subscription-reference');
const { broadcastToBusiness } = require('./websocket');

const prisma = new PrismaClient();

const GRACE_DAYS = 5;
const TRIAL_DAYS = 14;

const PLAN_DETAILS = {
  STARTER: {
    tier: 'STARTER',
    nameEn: 'Starter',
    monthlyPrice: 199,
    yearlyPrice: 1990,
    maxCashiers: 3,
    maxLocations: 1,
    features: ['QR Scan', 'Receipt OCR', 'Manual Entry', 'Real-time Verification', 'History (30 days)', 'Offline Mode'],
  },
  BUSINESS: {
    tier: 'BUSINESS',
    nameEn: 'Business',
    monthlyPrice: 499,
    yearlyPrice: 4990,
    maxCashiers: -1,
    maxLocations: 3,
    features: ['Everything in Starter', 'Analytics Dashboard', 'CSV Export', 'Worker Performance', 'History (unlimited)', 'Priority Support'],
  },
  ENTERPRISE: {
    tier: 'ENTERPRISE',
    nameEn: 'Enterprise',
    monthlyPrice: 1200,
    yearlyPrice: 12000,
    maxCashiers: -1,
    maxLocations: -1,
    features: ['Everything in Business', 'API Access', 'Dedicated Onboarding', 'Custom SMS Name', 'Multi-location', 'SLA Guarantee'],
  },
};

function getTrialEndsAt() {
  return new Date(Date.now() + TRIAL_DAYS * 24 * 60 * 60 * 1000);
}

function addMonths(date, months) {
  const result = new Date(date);
  result.setMonth(result.getMonth() + months);
  return result;
}

async function activateSubscription(businessId, tier, months, transactionId, amount) {
  const now = new Date();

  const result = await prisma.$transaction(async (tx) => {
    // Determine start date: if currently ACTIVE or GRACE, extend from expiry; otherwise from now
    const biz = await tx.business.findUnique({ where: { id: businessId } });
    let startDate = now;
    if (biz.subscriptionStatus === 'ACTIVE' && biz.subscriptionEndsAt) {
      startDate = biz.subscriptionEndsAt > now ? biz.subscriptionEndsAt : now;
    } else if (biz.subscriptionStatus === 'GRACE' && biz.subscriptionEndsAt) {
      startDate = biz.subscriptionEndsAt;
    }

    const newEndsAt = addMonths(startDate, months);
    const newGraceEndsAt = addMonths(newEndsAt, 0);
    newGraceEndsAt.setDate(newGraceEndsAt.getDate() + GRACE_DAYS);

    await tx.business.update({
      where: { id: businessId },
      data: {
        subscriptionStatus: 'ACTIVE',
        subscriptionTier: tier,
        subscriptionEndsAt: newEndsAt,
        graceEndsAt: null,
      },
    });

    const payment = await tx.subscriptionPayment.create({
      data: {
        businessId,
        transactionId,
        amount,
        tier,
        periodMonths: months,
        paidAt: now,
        verifiedAt: now,
      },
    });

    return { payment, newEndsAt };
  });

  // Broadcast subscription activation to the business owner
  try {
    broadcastToBusiness(businessId, {
      type: 'subscription_activated',
      tier,
      endsAt: result.newEndsAt.toISOString(),
    });
  } catch (_) { /* websocket might not be connected */ }

  return result;
}

async function processSubscriptionSms(smsBody, senderAddress) {
  // Check for subscription reference pattern
  const ref = parseReferenceCode(smsBody);
  if (!ref) return null;

  // Find business by matching the suffix of their ID
  const businesses = await prisma.business.findMany({
    where: { subscriptionStatus: { not: 'EXPIRED' } },
  });

  const biz = businesses.find(b => {
    const suffix = b.id.replace(/-/g, '').slice(-6).toUpperCase();
    return suffix === ref.businessSuffix;
  });

  if (!biz) {
    console.log(`[SUB] Reference ${ref.businessSuffix} matched no business`);
    return null;
  }

  // Extract amount from SMS
  const amountMatch = smsBody.match(/ETB\s*([\d,]+\.?\d*)/i);
  if (!amountMatch) return null;

  const amount = parseFloat(amountMatch[1].replace(/,/g, ''));
  const resolved = resolveTierAndMonths(amount);

  if (!resolved || resolved.tier !== ref.tier) {
    console.log(`[SUB] Amount ${amount} does not match tier ${ref.tier}`);
    return { status: 'PENDING', businessId: biz.id, reason: 'amount_mismatch' };
  }

  // Check for duplicate payment
  const existingPayment = await prisma.subscriptionPayment.findUnique({
    where: { transactionId: smsBody.match(/[A-Z0-9]{8,}/)?.[0] || 'NONE' },
  });
  if (existingPayment) return { status: 'DUPLICATE' };

  // Use the detected transaction ID from the SMS
  const txnIdMatch = smsBody.match(/(?:Ref[:\s]+|TxnID[:\s]+|Tx[:\s]+)([A-Z0-9]{8,})/i);
  const txnId = txnIdMatch ? txnIdMatch[1] : `SUB-${Date.now()}`;

  return await activateSubscription(biz.id, ref.tier, resolved.months, txnId, amount);
}

async function checkSubscriptionStatus(businessId) {
  const biz = await prisma.business.findUnique({ where: { id: businessId } });
  if (!biz) return null;

  const now = new Date();

  // Auto-transition states
  if (biz.subscriptionStatus === 'TRIAL' && biz.trialEndsAt < now) {
    await prisma.business.update({
      where: { id: businessId },
      data: { subscriptionStatus: 'EXPIRED' },
    });
    return { status: 'EXPIRED', tier: biz.subscriptionTier };
  }

  if (biz.subscriptionStatus === 'ACTIVE' && biz.subscriptionEndsAt && biz.subscriptionEndsAt < now) {
    const graceEnd = new Date(biz.subscriptionEndsAt);
    graceEnd.setDate(graceEnd.getDate() + GRACE_DAYS);

    if (now < graceEnd) {
      await prisma.business.update({
        where: { id: businessId },
        data: { subscriptionStatus: 'GRACE', graceEndsAt: graceEnd },
      });
      return { status: 'GRACE', tier: biz.subscriptionTier, graceEndsAt: graceEnd };
    } else {
      await prisma.business.update({
        where: { id: businessId },
        data: { subscriptionStatus: 'EXPIRED' },
      });
      return { status: 'EXPIRED', tier: biz.subscriptionTier };
    }
  }

  if (biz.subscriptionStatus === 'GRACE' && biz.graceEndsAt && biz.graceEndsAt < now) {
    await prisma.business.update({
      where: { id: businessId },
      data: { subscriptionStatus: 'EXPIRED' },
    });
    return { status: 'EXPIRED', tier: biz.subscriptionTier };
  }

  return { status: biz.subscriptionStatus, tier: biz.subscriptionTier, endsAt: biz.subscriptionEndsAt };
}

async function getPlans() {
  return Object.values(PLAN_DETAILS);
}

async function getSubscriptionHistory(businessId) {
  return prisma.subscriptionPayment.findMany({
    where: { businessId },
    orderBy: { createdAt: 'desc' },
  });
}

module.exports = {
  activateSubscription,
  processSubscriptionSms,
  checkSubscriptionStatus,
  getPlans,
  getSubscriptionHistory,
  getTrialEndsAt,
  addMonths,
  PLAN_DETAILS,
};
