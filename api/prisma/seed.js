'use strict';

require('dotenv').config();
const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function seed() {
  console.log('Seeding database...');

  // ── Subscription plans ────────────────────────────────────────────────────
  const plans = [
    {
      tier: 'STARTER',
      nameEn: 'Starter',
      monthlyPrice: 199,
      yearlyPrice: 1990,
      maxCashiers: 3,
      maxLocations: 1,
      features: ['QR Scan', 'Receipt OCR', 'Manual Entry', 'Real-time Verification', 'History (30 days)', 'Offline Mode'],
    },
    {
      tier: 'BUSINESS',
      nameEn: 'Business',
      monthlyPrice: 499,
      yearlyPrice: 4990,
      maxCashiers: -1,
      maxLocations: 3,
      features: ['Everything in Starter', 'Analytics Dashboard', 'CSV Export', 'Worker Performance', 'History (unlimited)', 'Priority Support'],
    },
    {
      tier: 'ENTERPRISE',
      nameEn: 'Enterprise',
      monthlyPrice: 1200,
      yearlyPrice: 12000,
      maxCashiers: -1,
      maxLocations: -1,
      features: ['Everything in Business', 'API Access', 'Dedicated Onboarding', 'Custom SMS Name', 'Multi-location', 'SLA Guarantee'],
    },
  ];

  for (const plan of plans) {
    await prisma.subscriptionPlan.upsert({
      where: { tier: plan.tier },
      create: plan,
      update: plan,
    });
  }
  console.log('  Subscription plans seeded');

  // ── Test business + owner ─────────────────────────────────────────────────
  const passwordHash = await bcrypt.hash('admin123', 12);
  const cashierHash = await bcrypt.hash('cashier123', 12);

  const now = new Date();
  const trialEnds = new Date(now);
  trialEnds.setDate(trialEnds.getDate() + 14);

  const business = await prisma.business.upsert({
    where: { id: 'test-biz-001' },
    create: {
      id: 'test-biz-001',
      ownerName: 'Fira Demo',
      businessName: 'Fira Coffee Shop',
      phoneNumber: '+251911111111',
      subscriptionStatus: 'ACTIVE',
      subscriptionTier: 'STARTER',
      trialEndsAt: trialEnds,
      subscriptionEndsAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    },
    update: {
      subscriptionStatus: 'ACTIVE',
    },
  });
  console.log('  Business seeded:', business.businessName);

  // ── Owner user ────────────────────────────────────────────────────────────
  const owner = await prisma.user.upsert({
    where: { phone: '+251911111111' },
    create: {
      businessId: business.id,
      name: 'Fira Demo',
      phone: '+251911111111',
      passwordHash,
      role: 'OWNER',
    },
    update: { name: 'Fira Demo' },
  });
  console.log('  Owner seeded:', owner.phone);

  // ── Cashier user ──────────────────────────────────────────────────────────
  const cashier = await prisma.user.upsert({
    where: { phone: '+251922222222' },
    create: {
      businessId: business.id,
      name: 'Cashier Abebe',
      phone: '+251922222222',
      passwordHash: cashierHash,
      role: 'CASHIER',
    },
    update: { name: 'Cashier Abebe' },
  });
  console.log('  Cashier seeded:', cashier.phone);

  // ── Manager user ──────────────────────────────────────────────────────────
  const managerHash = await bcrypt.hash('manager123', 12);
  const manager = await prisma.user.upsert({
    where: { phone: '+251933333333' },
    create: {
      businessId: business.id,
      name: 'Manager Bontu',
      phone: '+251933333333',
      passwordHash: managerHash,
      role: 'MANAGER',
    },
    update: { name: 'Manager Bontu' },
  });
  console.log('  Manager seeded:', manager.phone);

  // ── Invite codes ──────────────────────────────────────────────────────────
  const codeExpiry = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  const codes = ['PV0001', 'PV0002', 'PV0003'];
  for (const code of codes) {
    await prisma.inviteCode.upsert({
      where: { code },
      create: {
        businessId: business.id,
        code,
        expiresAt: codeExpiry,
      },
      update: { expiresAt: codeExpiry },
    });
  }
  console.log('  Invite codes seeded:', codes.join(', '));

  // ── Sample transactions ───────────────────────────────────────────────────
  const methods = ['TELEBIRR', 'CBE', 'AWASH', 'DASHEN', 'AMOLE', 'HELLOCASH', 'ABYSSINIA'];
  const names = ['Abebe Kebede', 'Bontu Tesfaye', 'Chala Wonda', 'Desta Mulugeta', 'Eleni Abera'];
  const txns = [];

  for (let i = 0; i < 15; i++) {
    const amount = Math.floor(Math.random() * 5000 + 100);
    const txId = `TXN${String(Date.now()).slice(-4)}${String(i).padStart(4, '0')}`;
    const status = i < 3 ? 'PENDING' : i < 10 ? 'VERIFIED' : 'MISMATCH';
    const created = new Date(Date.now() - (15 - i) * 60 * 60 * 1000);

    txns.push({
      businessId: business.id,
      workerId: i % 2 === 0 ? owner.id : cashier.id,
      transactionId: txId,
      amount,
      senderName: names[i % names.length],
      senderPhone: `+2519${String(Math.floor(Math.random() * 10000000)).padStart(7, '0')}`,
      paymentMethod: methods[i % methods.length],
      status,
      rawSms: `ETB ${amount}.00 paid to Fira Coffee Shop. Ref: ${txId}`,
      createdAt: created,
    });
  }

  // Insert transactions (skip duplicates)
  for (const tx of txns) {
    await prisma.transaction.upsert({
      where: { transactionId: tx.transactionId },
      create: tx,
      update: { status: tx.status },
    });
  }
  console.log('  Sample transactions seeded:', txns.length);

  // ── Subscription payment history ──────────────────────────────────────────
  await prisma.subscriptionPayment.create({
    data: {
      businessId: business.id,
      transactionId: 'SUB-INITIAL-001',
      amount: 199,
      tier: 'STARTER',
      periodMonths: 1,
      paidAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
      verifiedAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
    },
  });
  console.log('  Subscription payment seeded');

  console.log('\nSeed complete!');
  console.log('  Login credentials:');
  console.log('  Owner   : +251911111111 / admin123');
  console.log('  Cashier : +251922222222 / cashier123');
  console.log('  Manager : +251933333333 / manager123');
}

seed()
  .catch((e) => { console.error('Seed failed:', e); process.exit(1); })
  .finally(() => prisma.$disconnect());
