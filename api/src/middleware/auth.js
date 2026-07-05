const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'change-this-in-production';

// ── Attach user to req ────────────────────────────────────────────────────────
async function authenticate(req, res, next) {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid token' });
    }

    const token = header.slice(7);
    const payload = jwt.verify(token, JWT_SECRET);

    // Verify user still exists and is active
    const user = await prisma.user.findUnique({
      where: { id: payload.userId },
      include: { business: true },
    });

    if (!user || !user.isActive) {
      return res.status(401).json({ error: 'Account not found or deactivated' });
    }

    if (user.business.subscriptionStatus === 'EXPIRED') {
      return res.status(403).json({ error: 'Subscription expired' });
    }

    req.user     = user;
    req.business = user.business;
    next();
  } catch (err) {
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }
    next(err);
  }
}

// ── Role guards ───────────────────────────────────────────────────────────────
function requireOwner(req, res, next) {
  if (req.user.role !== 'OWNER') {
    return res.status(403).json({ error: 'Owner access required' });
  }
  next();
}

function requireManager(req, res, next) {
  if (!['OWNER', 'MANAGER'].includes(req.user.role)) {
    return res.status(403).json({ error: 'Manager access required' });
  }
  next();
}

// ── Africa's Talking SMS webhook secret ──────────────────────────────────────
function authenticateSmsWebhook(req, res, next) {
  const secret = req.headers['x-at-secret'] || req.query.secret;
  if (secret !== process.env.SMS_WEBHOOK_SECRET) {
    return res.status(401).json({ error: 'Invalid webhook secret' });
  }
  next();
}

module.exports = { authenticate, requireOwner, requireManager, authenticateSmsWebhook };
