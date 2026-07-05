'use strict';

require('dotenv').config();
const express    = require('express');
const http       = require('http');
const cors       = require('cors');
const helmet     = require('helmet');
const rateLimit  = require('express-rate-limit');
const { setupWebSocket }  = require('./services/websocket');
const { startCronJobs }   = require('./services/cron');

const authRoutes         = require('./routes/auth');
const verifyRoutes       = require('./routes/verify');
const transactionRoutes  = require('./routes/transactions');
const workerRoutes       = require('./routes/workers');
const analyticsRoutes    = require('./routes/analytics');
const smsWebhookRoutes   = require('./routes/sms-webhook');
const subscriptionRoutes = require('./routes/subscription');
const adminRoutes        = require('./routes/admin');
const telebirrRoutes     = require('./routes/telebirr');

const app    = express();
const server = http.createServer(app);

app.set('trust proxy', 1);
app.use(helmet());
app.use(cors({
  origin:         process.env.ALLOWED_ORIGINS?.split(',') ?? '*',
  methods:        ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-device-secret', 'x-at-secret'],
}));

app.use(rateLimit({ windowMs: 60 * 1000, max: 120, message: { error: 'Too many requests' } }));

const verifyLimit = rateLimit({ windowMs: 60 * 1000, max: 60, message: { error: 'Verification rate limit exceeded' } });

app.use(express.json({ limit: '512kb' }));
app.use(express.urlencoded({ extended: true }));

app.get('/health', (_, res) => res.json({ status: 'ok', ts: new Date().toISOString(), env: process.env.NODE_ENV }));

app.use('/v1/auth',          authRoutes);
app.use('/v1/verify',        verifyLimit, verifyRoutes);
app.use('/v1/transactions',  transactionRoutes);
app.use('/v1/workers',       workerRoutes);
app.use('/v1/analytics',     analyticsRoutes);
app.use('/v1/subscription',  subscriptionRoutes);
app.use('/v1/admin',         adminRoutes);
app.use('/v1/telebirr',      telebirrRoutes);
app.use('/v1/sms',           smsWebhookRoutes);

app.use((req, res) => res.status(404).json({ error: `Route not found: ${req.method} ${req.path}` }));

app.use((err, req, res, next) => {
  if (err.name === 'ZodError') {
    const details = err.errors.map(e => `${e.path.join('.')}: ${e.message}`);
    // Friendly message for auth routes
    if (req.path.includes('/auth/')) {
      const fieldErrors = details.join('. ');
      return res.status(400).json({ error: fieldErrors || 'Please check your input and try again.' });
    }
    return res.status(400).json({ error: 'Validation error', details });
  }
  if (err.code === 'P2002')
    return res.status(409).json({ error: 'Record already exists' });
  if (['JsonWebTokenError', 'TokenExpiredError'].includes(err.name))
    return res.status(401).json({ error: 'Invalid or expired token' });
  console.error('[ERROR]', err);
  res.status(500).json({ error: 'Internal server error' });
});

setupWebSocket(server);

if (process.env.NODE_ENV !== 'test') startCronJobs();

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`\n🛡  PayVerify Backend`);
  console.log(`   Port : ${PORT}`);
  console.log(`   Env  : ${process.env.NODE_ENV}\n`);
});

module.exports = { app, server };
