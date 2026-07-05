const express  = require('express');
const bcrypt   = require('bcryptjs');
const jwt      = require('jsonwebtoken');
const { z }    = require('zod');
const { PrismaClient } = require('@prisma/client');
const { getTrialEndsAt } = require('../services/subscription-service');
const { authenticate, requireOwner } = require('../middleware/auth');

const router = express.Router();
const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'change-this-in-production';
const SALT_ROUNDS = 12;

// ── Validators ────────────────────────────────────────────────────────────────

const loginSchema = z.object({
  phone:    z.string().min(10),
  password: z.string().min(6),
});

const registerSchema = z.object({
  name:         z.string().min(2),
  phone:        z.string().min(10),
  password:     z.string().min(6),
  businessName: z.string().min(2),
});

const joinSchema = z.object({
  inviteCode: z.string().length(6),
  name:       z.string().min(2),
  phone:      z.string().min(10),
  password:   z.string().min(6),
});

function makeToken(user) {
  return jwt.sign(
    { userId: user.id, businessId: user.businessId, role: user.role },
    JWT_SECRET,
    { expiresIn: '30d' },
  );
}

function userResponse(user, business, token) {
  return {
    token,
    user: {
      id:           user.id,
      name:         user.name,
      phone:        user.phone,
      role:         user.role,
      businessId:   user.businessId,
      businessName: business.businessName,
    },
  };
}

// ── POST /v1/auth/login ───────────────────────────────────────────────────────
router.post('/login', async (req, res, next) => {
  try {
    const { phone, password } = loginSchema.parse(req.body);

    const user = await prisma.user.findUnique({
      where: { phone },
      include: { business: true },
    });

    if (!user || !user.isActive) {
      return res.status(401).json({ error: 'Invalid phone or password' });
    }

    const match = await bcrypt.compare(password, user.passwordHash);
    if (!match) {
      return res.status(401).json({ error: 'Invalid phone or password' });
    }

    if (user.business.subscriptionStatus === 'EXPIRED') {
      return res.status(403).json({ error: 'Business subscription expired. Contact your employer.' });
    }

    const token = makeToken(user);
    res.json(userResponse(user, user.business, token));
  } catch (err) { next(err); }
});

// ── POST /v1/auth/register (owner creates new business) ──────────────────────
router.post('/register', async (req, res, next) => {
  try {
    const { name, phone, password, businessName } = registerSchema.parse(req.body);

    const existing = await prisma.user.findUnique({ where: { phone } });
    if (existing) {
      return res.status(409).json({ error: 'Phone number already registered' });
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const result = await prisma.$transaction(async (tx) => {
      // Create business first (need id for user)
      const business = await tx.business.create({
        data: {
          ownerName: name,
          businessName,
          phoneNumber: phone,
          subscriptionStatus: 'TRIAL',
          subscriptionTier: 'STARTER',
          trialEndsAt: getTrialEndsAt(),
        },
      });

      const user = await tx.user.create({
        data: {
          businessId: business.id,
          name,
          phone,
          passwordHash,
          role: 'OWNER',
        },
      });

      return { user, business };
    });

    const token = makeToken(result.user);
    res.status(201).json(userResponse(result.user, result.business, token));
  } catch (err) { next(err); }
});

// ── POST /v1/auth/join (cashier joins with invite code) ──────────────────────
router.post('/join', async (req, res, next) => {
  try {
    const { inviteCode, name, phone, password } = joinSchema.parse(req.body);

    // Validate invite code
    const invite = await prisma.inviteCode.findUnique({
      where: { code: inviteCode.toUpperCase() },
      include: { business: true },
    });

    if (!invite) {
      return res.status(404).json({ error: 'Invalid invite code' });
    }
    if (invite.usedAt) {
      return res.status(410).json({ error: 'Invite code already used' });
    }
    if (invite.expiresAt < new Date()) {
      return res.status(410).json({ error: 'Invite code expired. Ask your employer for a new one.' });
    }

    const existing = await prisma.user.findUnique({ where: { phone } });
    if (existing) {
      return res.status(409).json({ error: 'Phone number already registered' });
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const result = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          businessId:   invite.businessId,
          name,
          phone,
          passwordHash,
          role:         'CASHIER',
        },
      });

      // Mark code as used
      await tx.inviteCode.update({
        where: { id: invite.id },
        data: { usedAt: new Date() },
      });

      return { user, business: invite.business };
    });

    const token = makeToken(result.user);
    res.status(201).json(userResponse(result.user, result.business, token));
  } catch (err) { next(err); }
});

// ── PATCH /v1/auth/business-name ───────────────────────────────────────────
router.patch('/business-name', authenticate, requireOwner, async (req, res, next) => {
  try {
    const schema = z.object({ businessName: z.string().min(2).max(100) });
    const { businessName } = schema.parse(req.body);

    const business = await prisma.business.update({
      where: { id: req.user.businessId },
      data: { businessName },
    });

    res.json({ businessName: business.businessName });
  } catch (err) { next(err); }
});

module.exports = router;
