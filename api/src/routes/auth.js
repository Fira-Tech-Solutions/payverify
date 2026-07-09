const express  = require('express');
const bcrypt   = require('bcryptjs');
const jwt      = require('jsonwebtoken');
const { z }    = require('zod');
const { PrismaClient } = require('@prisma/client');
const { getTrialEndsAt } = require('../services/subscription-service');
const { mockFaydaRegistryLookup } = require('../services/faydaService');
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

// ── POST /v1/auth/register-initial (Fayda ID step 1) ────────────────────────
router.post('/register-initial', async (req, res, next) => {
  try {
    const schema = z.object({
      businessName: z.string().min(2),
      faydaId:      z.string().min(3),
    });
    const { businessName, faydaId } = schema.parse(req.body);

    // Check if Fayda ID already registered
    const existing = await prisma.user.findUnique({ where: { faydaId } });
    if (existing) {
      return res.status(400).json({ error: 'This Fayda ID is already registered' });
    }

    // Fetch identity from Fayda registry
    let identity;
    try {
      identity = await mockFaydaRegistryLookup(faydaId);
    } catch (e) {
      return res.status(400).json({ error: 'Could not verify Fayda ID. Please check and try again.' });
    }

    // Create business + pending user in a transaction
    const result = await prisma.$transaction(async (tx) => {
      const business = await tx.business.create({
        data: {
          businessName,
          subscriptionStatus: 'TRIAL',
          subscriptionTier: 'STARTER',
          trialEndsAt: getTrialEndsAt(),
        },
      });

      const user = await tx.user.create({
        data: {
          businessId: business.id,
          faydaId,
          name: identity.name,
          phone: identity.phone,
          role: 'OWNER',
        },
      });

      return { user, business };
    });

    res.status(201).json({
      userId: result.user.id,
      fetchedName: identity.name,
      fetchedPhone: identity.phone,
    });
  } catch (err) { next(err); }
});

// ── POST /v1/auth/complete-signup (Fayda ID step 2) ─────────────────────────
router.post('/complete-signup', async (req, res, next) => {
  try {
    const schema = z.object({
      userId:   z.string().uuid(),
      password: z.string().min(6),
    });
    const { userId, password } = schema.parse(req.body);

    // Find the pending user
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { business: true },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.passwordHash) {
      return res.status(400).json({ error: 'Account already completed' });
    }

    // Hash password and finalize the account
    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });

    const token = makeToken(updatedUser);
    res.status(200).json(userResponse(updatedUser, user.business, token));
  } catch (err) { next(err); }
});

// ── GET /v1/auth/fayda-login-init ─────────────────────────────────────────
// Redirects the user's browser/webview to the Fayda OIDC authorize endpoint.
// The state parameter carries the business name through the OAuth flow.
router.get('/fayda-login-init', (req, res, next) => {
  try {
    const bizName = req.query.bizName;
    if (!bizName || bizName.trim().length < 2) {
      return res.status(400).json({ error: 'Business name is required' });
    }

    const baseUrl = process.env.API_BASE_URL || `http://${req.hostname}:${process.env.PORT || 3000}`;
    const redirectUri = `${baseUrl}/v1/auth/fayda-callback`;

    const params = new URLSearchParams({
      response_type: 'code',
      client_id:     process.env.FAYDA_CLIENT_ID || 'payverify-sandbox',
      redirect_uri:  redirectUri,
      scope:         'openid profile phone',
      state:         Buffer.from(JSON.stringify({ bizName: bizName.trim() })).toString('base64'),
    });

    const faydaAuthUrl = `https://esignet.fayda.gov.et/oauth/v2/authorize?${params.toString()}`;
    res.redirect(faydaAuthUrl);
  } catch (err) { next(err); }
});

// ── GET /v1/auth/fayda-callback ───────────────────────────────────────────
// OIDC callback. Exchanges the authorization code for identity, creates
// Business + User records, then redirects to fayda-success with the data.
router.get('/fayda-callback', async (req, res, next) => {
  try {
    const { code, state } = req.query;

    if (!code || !state) {
      return res.status(400).json({ error: 'Missing authorization code or state' });
    }

    const baseUrl = process.env.API_BASE_URL || `http://${req.hostname}:${process.env.PORT || 3000}`;

    // Decode state to get business name
    let bizName;
    try {
      const decoded = JSON.parse(Buffer.from(state, 'base64').toString());
      bizName = decoded.bizName;
    } catch {
      return res.status(400).json({ error: 'Invalid state parameter' });
    }

    // Mock Fayda token exchange — in production, call Fayda's token endpoint
    // For sandbox, we simulate a successful OIDC response
    const mockProfile = {
      sub:  '483920194832',
      name: 'Abebe Kebede Tessema',
      phone: '+251911234567',
    };

    // Check if Fayda ID already registered
    const existing = await prisma.user.findUnique({ where: { faydaId: mockProfile.sub } });
    if (existing) {
      return res.redirect(
        `${baseUrl}/v1/auth/fayda-success?userId=${existing.id}&name=${encodeURIComponent(existing.name || '')}&phone=${encodeURIComponent(existing.phone || '')}`
      );
    }

    // Create business + user in a transaction
    const result = await prisma.$transaction(async (tx) => {
      const business = await tx.business.create({
        data: {
          businessName: bizName,
          subscriptionStatus: 'TRIAL',
          subscriptionTier: 'STARTER',
          trialEndsAt: getTrialEndsAt(),
        },
      });

      const user = await tx.user.create({
        data: {
          businessId: business.id,
          faydaId: mockProfile.sub,
          name: mockProfile.name,
          phone: mockProfile.phone,
          role: 'OWNER',
        },
      });

      return { user, business };
    });

    res.redirect(
      `${baseUrl}/v1/auth/fayda-success?userId=${result.user.id}&name=${encodeURIComponent(mockProfile.name)}&phone=${encodeURIComponent(mockProfile.phone)}`
    );
  } catch (err) { next(err); }
});

// ── GET /v1/auth/fayda-success ────────────────────────────────────────────
// Terminal page shown briefly in the webview before the Flutter app intercepts
// the deep link and closes the modal.
router.get('/fayda-success', (req, res) => {
  const { userId, name, phone } = req.query;
  res.send(`
    <!DOCTYPE html>
    <html>
    <head><title>Verification Successful</title></head>
    <body style="display:flex;justify-content:center;align-items:center;height:100vh;margin:0;font-family:system-ui;background:#f0fdf4">
      <div style="text-align:center">
        <div style="font-size:48px;margin-bottom:16px">&#10003;</div>
        <h2 style="color:#166534;margin:0 0 8px">Verification Successful</h2>
        <p style="color:#16a34a;margin:0">Returning to your application...</p>
      </div>
    </body>
    </html>
  `);
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
