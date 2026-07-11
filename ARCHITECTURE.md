# PayVerify Architecture Diagram

## System Overview

PayVerify is a payment verification SaaS for Ethiopian merchants that prevents fake payment screenshot scams by verifying transactions against real bank data.

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              PAYVERIFY ECOSYSTEM                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌──────────────┐         ┌──────────────┐         ┌──────────────┐               │
│  │   CUSTOMER   │         │   MERCHANT   │         │   BANKS      │               │
│  │              │         │              │         │              │               │
│  │ • Makes      │────────▶│ • Receives   │◀────────│ • Send SMS   │               │
│  │   payment    │         │   payment    │         │   confirm   │               │
│  │ • Shows      │         │ • Verifies   │         │              │               │
│  │   screenshot │         │   via app    │         │              │               │
│  └──────────────┘         └──────┬───────┘         └──────────────┘               │
│                                   │                                                   │
│                                   │                                                   │
│                          ┌────────▼────────┐                                          │
│                          │  FLUTTER APP    │                                          │
│                          │  (Merchant App) │                                          │
│                          │                 │                                          │
│                          │ • QR Scanner    │                                          │
│                          │ • OCR Receipt   │                                          │
│                          │ • Manual Entry  │                                          │
│                          │ • SMS Listener  │                                          │
│                          │ • WebSocket     │                                          │
│                          │ • Offline Mode  │                                          │
│                          └────────┬────────┘                                          │
│                                   │                                                   │
│                                   │ REST API + WebSocket                               │
│                                   │                                                   │
│                          ┌────────▼──────────────────────────────────────────┐      │
│                          │           NODE.JS BACKEND API                       │      │
│                          │          (Express + Prisma)                        │      │
│                          │                                                    │      │
│                          │  ┌──────────────────────────────────────────┐     │      │
│                          │  │         REST API Endpoints                │     │      │
│                          │  │  • /v1/auth (login, register, join)      │     │      │
│                          │  │  • /v1/verify (payment verification)     │     │      │
│                          │  │  • /v1/transactions (CRUD, filter)       │     │      │
│                          │  │  • /v1/workers (invite, manage)           │     │      │
│                          │  │  • /v1/analytics (dashboard, trends)     │     │      │
│                          │  │  • /v1/subscription (status, payment)     │     │      │
│                          │  │  • /v1/admin (business management)        │     │      │
│                          │  └──────────────────────────────────────────┘     │      │
│                          │                                                    │      │
│                          │  ┌──────────────────────────────────────────┐     │      │
│                          │  │         WebSocket Server                 │     │      │
│                          │  │  • Real-time payment notifications       │     │      │
│                          │  │  • Transaction status updates            │     │      │
│                          │  │  • Business-specific rooms               │     │      │
│                          │  └──────────────────────────────────────────┘     │      │
│                          │                                                    │      │
│                          │  ┌──────────────────────────────────────────┐     │      │
│                          │  │         SMS Webhook Endpoints            │     │      │
│                          │  │  • /v1/sms/incoming (Africa's Talking)  │     │      │
│                          │  │  • /v1/sms/forward (Android forwarder)   │     │      │
│                          │  └──────────────────────────────────────────┘     │      │
│                          │                                                    │      │
│                          │  ┌──────────────────────────────────────────┐     │      │
│                          │  │         Background Services               │     │      │
│                          │  │  • SMS Parser (6 Ethiopian banks)       │     │      │
│                          │  │  • Cron Jobs (expire txns, sub state)   │     │      │
│                          │  │  • Subscription Service                  │     │      │
│                          │  │  • TeleBirr Integration                  │     │      │
│                          │  └──────────────────────────────────────────┘     │      │
│                          └────────┬──────────────────────────────────────────┘      │
│                                   │                                                   │
│                                   │ Prisma ORM                                         │
│                                   │                                                   │
│                          ┌────────▼────────┐                                          │
│                          │   POSTGRESQL    │                                          │
│                          │     DATABASE    │                                          │
│                          │                 │                                          │
│                          │ • Business      │                                          │
│                          │ • User          │                                          │
│                          │ • Transaction   │                                          │
│                          │ • InviteCode    │                                          │
│                          │ • Subscription  │                                          │
│                          │ • Payment       │                                          │
│                          └─────────────────┘                                          │
│                                                                                     │
│  ┌──────────────┐         ┌──────────────┐         ┌──────────────┐               │
│  │   ANDROID    │         │  AFRICA'S     │         │   REACT      │               │
│  │   SMS        │────────▶│   TALKING     │────────▶│   LANDING    │               │
│  │   FORWARDER  │         │   SMS API     │         │   PAGE       │               │
│  └──────────────┘         └──────────────┘         └──────────────┘               │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Flutter Mobile App (`/apk`)
**Tech Stack:** Flutter 3.x, Riverpod, GoRouter, Dio, Hive, WebSocket

**Key Features:**
- **QR Scanner** - Scan payment reference codes using mobile_scanner
- **OCR Receipt** - Extract transaction data from receipt images using ML Kit
- **Manual Entry** - Type reference codes manually
- **SMS Listener** - Auto-capture bank SMS messages (6 Ethiopian banks)
- **WebSocket Client** - Real-time payment notifications
- **Offline Mode** - Hive local database with sync when connected
- **Subscription Management** - In-app TeleBirr payments
- **Role-Based Access** - Owner, Manager, Cashier permissions
- **PIN/Biometric Lock** - App security with local_auth

**Architecture:**
```
lib/
├── main.dart                 # App entry, routing, lifecycle
├── models/                   # Data models (Transaction, User, etc.)
├── providers/                # Riverpod state management
├── services/                 # Business logic
│   ├── api/                  # REST API client
│   ├── auth/                 # Authentication & PIN
│   ├── realtime/             # WebSocket client
│   ├── sms/                  # SMS parsing & listener
│   ├── sync/                 # Offline sync manager
│   └── local_db/             # Hive local storage
├── features/                 # UI screens by feature
│   ├── auth/                 # Login, register, PIN setup
│   ├── verify/               # Payment verification UI
│   ├── history/              # Transaction history
│   ├── workers/              # Team management
│   ├── analytics/            # Dashboard & trends
│   ├── subscription/         # Plans, payment, history
│   └── settings/             # App settings
└── theme/                    # App theming
```

### 2. Node.js Backend API (`/api`)
**Tech Stack:** Node.js, Express, Prisma, PostgreSQL, WebSocket, JWT

**Key Services:**
- **REST API** - 9 route modules for all operations
- **WebSocket Server** - Real-time push to connected clients
- **SMS Parser** - Regex patterns for 6 Ethiopian banks
- **Cron Jobs** - Scheduled tasks for cleanup and state management
- **Subscription Service** - Plan activation and state machine
- **TeleBirr Integration** - H5 payment flow

**Architecture:**
```
src/
├── index.js                  # Express app setup, middleware, routes
├── middleware/               # Auth, rate limiting, validation
├── routes/                   # API endpoints
│   ├── auth.js               # Login, register, join with code
│   ├── verify.js             # Payment verification
│   ├── transactions.js       # CRUD, filtering, expiration
│   ├── workers.js            # Invite codes, team management
│   ├── analytics.js          # Dashboard stats, trends, export
│   ├── subscription.js       # Status, plans, payment verification
│   ├── admin.js              # Business management, overrides
│   ├── telebirr.js           # TeleBirr H5 integration
│   └── sms-webhook.js        # SMS incoming endpoints
├── services/                 # Business logic
│   ├── websocket.js          # WS server, room management
│   ├── sms-parser.js         # Bank-specific regex parsers
│   ├── subscription-service.js  # Subscription state machine
│   ├── cron.js               # Scheduled jobs
│   └── telebirr.js           # TeleBirr API integration
└── utils/                    # Helpers (invite codes, references)
```

### 3. PostgreSQL Database (`/db`)
**Schema (Prisma):**
- **Business** - Merchant accounts, subscription status
- **User** - Staff accounts with roles (OWNER/MANAGER/CASHIER)
- **Transaction** - Payment records with verification status
- **InviteCode** - 6-character codes for cashier onboarding
- **SubscriptionPayment** - Payment history for subscriptions
- **SubscriptionPlan** - Available tiers (STARTER/BUSINESS/ENTERPRISE)
- **SubscriptionOrder** - TeleBirr payment orders

**Enums:**
- SubscriptionStatus: TRIAL, ACTIVE, GRACE, EXPIRED
- SubscriptionTier: STARTER, BUSINESS, ENTERPRISE
- UserRole: OWNER, MANAGER, CASHIER
- TxStatus: PENDING, VERIFIED, MISMATCH, EXPIRED
- PaymentMethod: TELEBIRR, CBE, AWASH, DASHEN, ABYSSINIA, AMOLE, HELLOCASH

### 4. React Landing Page (`/webpage`)
**Tech Stack:** React 18, Vite, Tailwind CSS, Framer Motion

**Components:**
- **Navbar** - Navigation with mobile menu
- **Hero** - Animated verification stamp mockup
- **TrustBar** - Supported banks display
- **Problem** - Fake screenshot scam explanation
- **HowItWorks** - 3-step verification flow
- **Analytics** - Stats and charts
- **Pricing** - Subscription tiers
- **Download** - APK download CTA
- **FAQ** - Accordion FAQ
- **Footer** - Contact info

## Data Flow

### Payment Verification Flow:
```
1. Customer → Bank: Makes payment (TeleBirr, CBE, etc.)
2. Bank → Merchant Phone: Sends SMS confirmation
3. SMS → Android Forwarder/Africa's Talking: Captures SMS
4. SMS → Backend Webhook: POST /v1/sms/incoming or /v1/sms/forward
5. Backend → SMS Parser: Extracts transaction details
6. Backend → PostgreSQL: Stores transaction (PENDING status)
7. Backend → WebSocket: Pushes notification to merchant's Flutter app
8. Merchant → Flutter App: Scans QR/OCR/Manual entry
9. Flutter App → Backend: POST /v1/verify with reference code
10. Backend → PostgreSQL: Matches reference, updates status (VERIFIED/MISMATCH)
11. Backend → WebSocket: Broadcasts status update
12. Flutter App: Shows verification result
```

### Subscription Payment Flow:
```
1. Merchant → Flutter App: Selects plan (STARTER/BUSINESS/ENTERPRISE)
2. Flutter App → Backend: POST /v1/subscription/plans
3. Backend → TeleBirr API: Creates H5 payment order
4. Backend → Flutter App: Returns toPayUrl and outTradeNo
5. Flutter App → WebView: Opens TeleBirr H5 payment page
6. Customer → TeleBirr: Completes payment
7. TeleBirr → Backend: Webhook notification
8. Backend → PostgreSQL: Updates order status, activates subscription
9. Backend → WebSocket: Notifies Flutter app
10. Flutter App: Shows success screen
```

### SMS Ingestion Flow:
```
Two parallel paths:

Path A (Africa's Talking):
1. Bank SMS → Africa's Talking API
2. Africa's Talking → Backend Webhook: POST /v1/sms/incoming
3. Backend → SMS Parser: Extracts transaction data

Path B (Android Forwarder):
1. Bank SMS → Android SMS Forwarder App
2. Forwarder → Backend Webhook: POST /v1/sms/forward
3. Backend → SMS Parser: Extracts transaction data

Both paths converge at SMS Parser, which uses bank-specific regex patterns:
- TeleBirr: TLB + 10 digits
- CBE: CBE + 10 digits
- Awash: AWB + 10 digits
- Dashen: DSH + 10 digits
- Amole: AML + 10 digits
- HelloCash: HLC + 10 digits
```

## Security Features

1. **JWT Authentication** - Token-based auth for all API endpoints
2. **Role-Based Access Control** - OWNER/MANAGER/CASHIER permissions
3. **Rate Limiting** - 120 req/min general, 60 req/min for verification
4. **Webhook Secrets** - x-at-secret, x-device-secret for SMS endpoints
5. **Admin Secret** - x-admin-secret for admin operations
6. **PIN/Biometric Lock** - App-level security in Flutter app
7. **Secure Storage** - flutter_secure_storage for tokens
8. **Helmet.js** - Security headers for Express
9. **CORS** - Configurable allowed origins

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    PRODUCTION                           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐         ┌──────────────┐             │
│  │   Nginx      │────────▶│   Node.js    │             │
│  │   (SSL)      │  Proxy  │   (PM2)      │             │
│  └──────────────┘         └──────┬───────┘             │
│                                  │                       │
│                                  │                       │
│                         ┌────────▼────────┐             │
│                         │   PostgreSQL    │             │
│                         │   (Docker)      │             │
│                         └─────────────────┘             │
│                                                         │
│  ┌──────────────┐         ┌──────────────┐             │
│  │   Flutter    │         │   React       │             │
│  │   APK        │         │   Static      │             │
│  │   (Play      │         │   (Netlify/   │             │
│  │    Store)    │         │    Vercel)    │             │
│  └──────────────┘         └──────────────┘             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Technology Stack Summary

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Mobile App** | Flutter 3.x | Cross-platform mobile app |
| | Riverpod | State management |
| | GoRouter | Navigation |
| | Dio | HTTP client |
| | Hive | Local database |
| | WebSocket | Real-time updates |
| | MobileScanner | QR scanning |
| | ML Kit | OCR for receipts |
| | flutter_secure_storage | Secure token storage |
| | local_auth | PIN/biometric lock |
| **Backend API** | Node.js 20 | Runtime |
| | Express 4.x | Web framework |
| | Prisma 5.x | ORM |
| | PostgreSQL 15 | Database |
| | WebSocket | Real-time server |
| | JWT | Authentication |
| | Zod | Validation |
| | Helmet.js | Security headers |
| | rate-limit | DDoS protection |
| **Database** | PostgreSQL 15 | Relational database |
| | Docker | Containerization |
| **Landing Page** | React 18 | UI framework |
| | Vite 5.x | Build tool |
| | Tailwind CSS 3.x | Styling |
| | Framer Motion | Animations |
| **Infrastructure** | Nginx | Reverse proxy |
| | PM2 | Process manager |
| | Docker | Containerization |
| | Africa's Talking | SMS API |
| | TeleBirr | Payment gateway |

## Supported Banks

| Bank | SMS Sender | Reference Pattern |
|------|------------|-------------------|
| TeleBirr | TeleBirr | TLB + 10 digits |
| Commercial Bank of Ethiopia (CBE) | 841 | CBE + 10 digits |
| Awash Bank | AwashBank | AWB + 10 digits |
| Dashen Bank | DashenBank | DSH + 10 digits |
| Bank of Abyssinia | Abyssinia | ABY + 10 digits |
| Amole | Amole | AML + 10 digits |
| HelloCash | HelloCash | HLC + 10 digits |

## Subscription Tiers

| Tier | Monthly | Yearly | Max Cashiers | Max Locations |
|------|---------|--------|--------------|----------------|
| STARTER | ETB 199 | ETB 1,990 | 3 | 1 |
| BUSINESS | ETB 499 | ETB 4,990 | 10 | 3 |
| ENTERPRISE | ETB 1,200 | ETB 12,000 | Unlimited | Unlimited |

## Key Integration Points

1. **SMS Ingestion** - Africa's Talking API + Android SMS Forwarder
2. **Payment Gateway** - TeleBirr H5 integration for subscriptions
3. **Real-time Updates** - WebSocket server with business-specific rooms
4. **Offline Sync** - Hive local database with sync manager
5. **Admin Operations** - Secret-based admin API for business management
