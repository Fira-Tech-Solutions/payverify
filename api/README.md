# PayVerify Backend

Node.js + Express + PostgreSQL + WebSocket backend for the PayVerify Ethiopia app.

---

## Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Set up environment
cp .env.example .env
# Edit .env — set DATABASE_URL, JWT_SECRET, SMS_WEBHOOK_SECRET

# 3. Set up PostgreSQL database
createdb payverify   # or use your cloud DB

# 4. Run migrations
npx prisma migrate dev --name init
npx prisma generate

# 5. Start dev server
npm run dev
# Server runs on http://localhost:3000
```

---

## Project Structure

```
src/
├── index.js                  # Express app + WebSocket + cron setup
├── middleware/
│   └── auth.js               # JWT auth, role guards, webhook secret
├── routes/
│   ├── auth.js               # Login / Register / Join-with-code
│   ├── verify.js             # Core payment verification endpoint
│   ├── transactions.js       # List, filter, expire transactions
│   ├── workers.js            # Invite codes, worker management
│   ├── analytics.js          # Dashboard stats, trends, CSV export
│   ├── subscription.js       # Subscription management + payment verification
│   ├── admin.js              # Admin endpoints (plan override, force trial)
│   └── sms-webhook.js        # Africa's Talking + Android forwarder
├── services/
│   ├── websocket.js          # WS server, business rooms, push helpers
│   ├── sms-parser.js         # Regex parsers for all Ethiopian banks
│   ├── subscription-service.js  # Subscription activation, state machine
│   └── cron.js               # Scheduled jobs (expire txns + subscription state machine)
├── utils/
│   ├── invite-code.js        # 6-char invite code generator
│   └── subscription-reference.js  # PV-XXXXXX-XXX reference code generation
prisma/
└── schema.prisma             # PostgreSQL schema
```

---

## API Reference

### Auth

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/v1/auth/login` | None | Phone + password → JWT |
| POST | `/v1/auth/register` | None | Create owner account + business |
| POST | `/v1/auth/join` | None | Cashier joins with invite code |

**Login request:**
```json
{ "phone": "0912345678", "password": "secret123" }
```

**Login response:**
```json
{
  "token": "eyJ...",
  "user": {
    "id": "uuid", "name": "Abebe", "phone": "0912345678",
    "role": "CASHIER", "businessId": "uuid", "businessName": "Abebe Store"
  }
}
```

---

### Verify

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/v1/verify` | Bearer | Verify a payment reference |

**Request:**
```json
{ "referenceCode": "TLB20260628884201" }
```

**Response (success):**
```json
{
  "verified": true,
  "transaction": {
    "transactionId": "TLB20260628884201",
    "amount": 1250.00,
    "senderName": "Abebe Bekele",
    "senderPhone": "0912345678",
    "paymentMethod": "TeleBirr",
    "status": "VERIFIED",
    "timestamp": "2026-06-28T11:32:00.000Z",
    "workerName": "Cashier Sara"
  }
}
```

**Response (not found):**
```json
{
  "verified": false,
  "transaction": { "transactionId": "TLB...", "status": "MISMATCH", "amount": 0 }
}
```

---

### Transactions

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/v1/transactions` | Bearer | List transactions (role-filtered) |
| GET | `/v1/transactions/:id` | Bearer | Get single transaction |
| POST | `/v1/transactions/expire` | Manager | Expire old pending transactions |

**Query params:** `?limit=50&offset=0&status=VERIFIED&method=TeleBirr&from=2026-06-01&to=2026-06-30`

---

### Workers

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/v1/workers/invite` | Manager | Generate 6-char invite code |
| GET | `/v1/workers/invite/active` | Manager | Get current active invite code |
| GET | `/v1/workers` | Manager | List all workers |
| DELETE | `/v1/workers/:id` | Manager | Remove a worker |
| PUT | `/v1/workers/:id/role` | Manager | Change worker role |

---

### Analytics (Owner/Manager only)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/v1/analytics/dashboard` | Manager | Summary stats |
| GET | `/v1/analytics/trends` | Manager | Daily totals (last N days) |
| GET | `/v1/analytics/export` | Manager | CSV export |

**Dashboard query:** `?period=today|week|month`

**Dashboard response:**
```json
{
  "summary": {
    "totalCount": 45, "verifiedCount": 43, "mismatchCount": 2,
    "totalAmount": 87500.00, "successRate": 96
  },
  "byMethod": [
    { "method": "TeleBirr", "count": 30, "amount": 55000 },
    { "method": "CBE",      "count": 13, "amount": 32500 }
  ],
  "topWorkers": [
    { "workerName": "Sara T.", "count": 22, "amount": 42000 }
  ],
  "hourly": [
    { "hour": 9, "verified": 5, "amount": 8000 },
    { "hour": 10, "verified": 12, "amount": 21500 }
  ]
}
```

---

### Subscription

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/v1/subscription/status` | Bearer | Get subscription status + countdown |
| GET | `/v1/subscription/plans` | Bearer | List available plans |
| GET | `/v1/subscription/history` | Bearer | Payment history (with pagination) |
| POST | `/v1/subscription/verify-payment` | Bearer | Verify payment reference code (PV-XXXXXX-XXX) |

**Status response:**
```json
{
  "businessId": "uuid",
  "status": "ACTIVE",
  "tier": "BUSINESS",
  "daysRemaining": 22,
  "autoRenew": true,
  "trialEndsAt": "2026-07-12T00:00:00.000Z"
}
```

**Reference code format:** `PV-{last 6 of businessId}-{STR|BIZ|ENT}`
- Starter:  ETB 199/mo | ETB 1990/yr
- Business: ETB 499/mo | ETB 4990/yr
- Enterprise: ETB 1200/mo | ETB 12000/yr

---

### Admin

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/v1/admin/businesses` | `x-admin-secret` | List all businesses |
| POST | `/v1/admin/subscription/override` | `x-admin-secret` | Override subscription plan + duration |
| POST | `/v1/admin/subscription/trial` | `x-admin-secret` | Start/extend trial for a business |
| POST | `/v1/admin/subscription/deactivate` | `x-admin-secret` | Deactivate subscription |

---

### SMS Webhooks

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/v1/sms/incoming` | `x-at-secret` header | Africa's Talking incoming SMS |
| POST | `/v1/sms/forward` | `x-device-secret` header | Android SMS forwarder |

**Android forwarder POST body:**
```json
{
  "businessId": "uuid",
  "from": "841",
  "body": "Cr ETB1,500.00 ... Ref No:CBE2026062812345",
  "secret": "your_sms_webhook_secret"
}
```

---

## WebSocket

Connect: `wss://api.payverify.et/ws?token=JWT&businessId=UUID`

**Messages from server:**
```json
// New payment arrived (show to cashier instantly)
{ "type": "new_transaction", "transaction": { ... } }

// A payment was just verified
{ "type": "status_update", "transactionId": "TLB...", "status": "VERIFIED" }

// Keep-alive
{ "type": "pong" }
```

**Messages from client:**
```json
{ "type": "ping" }
```

---

## Deployment (Ubuntu VPS)

```bash
# Install Node 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib
sudo -u postgres createdb payverify
sudo -u postgres createuser payverify_user --pwprompt

# Clone and set up
git clone your-repo && cd payverify-backend
npm install --production
cp .env.example .env  # fill in production values

# Run migrations
npx prisma migrate deploy

# Start with PM2
npm install -g pm2
pm2 start src/index.js --name payverify-backend
pm2 save
pm2 startup

# Nginx reverse proxy (for HTTPS + WebSocket)
# /etc/nginx/sites-available/payverify:
# location / { proxy_pass http://localhost:3000; proxy_http_version 1.1;
#   proxy_set_header Upgrade $http_upgrade;
#   proxy_set_header Connection "upgrade"; }
```

---

## SMS Parser — Supported Formats

| Bank | Sender | Reference Example |
|------|--------|-------------------|
| TeleBirr | `TeleBirr` | `TLB20260628884201` |
| CBE | `841` | `CBE2026062812345` |
| Awash | `AwashBank` | `AWB20260628556677` |
| Dashen | `DashenBank` | `DSH20260628112233` |
| Amole | `Amole` | `AML20260628998877` |
| HelloCash | `HelloCash` | `HLC20260628445566` |

Add new formats in `src/services/sms-parser.js`.
