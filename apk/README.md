# PayVerify Ethiopia — Flutter App

Mobile payment verification SaaS for Ethiopian market businesses.

---

## Quick Start

```bash
flutter pub get
flutter run
```

---

## Features

- **QR / OCR / Manual** reference code verification
- **SMS listener** auto-captures payment messages from 6 banks
- **WebSocket** real-time push (new payment → instant alert)
- **Offline mode** with automatic sync when connected
- **Dashboard** with analytics, trends, CSV/JSON export
- **Subscription management** with in-app renewal flow
- **Team management** — invite cashiers via code
- **Role-based access** — Owner, Manager, Cashier

---

## Project Structure

```
lib/
├── main.dart
├── models/
│   ├── transaction.dart
│   ├── user.dart
│   ├── worker.dart
│   └── subscription.dart
├── providers/
│   ├── providers.dart
│   └── subscription_provider.dart
├── services/
│   ├── api/api_client.dart
│   ├── auth/auth_service.dart
│   ├── realtime/realtime_service.dart
│   ├── sms/sms_parser.dart
│   ├── sms/sms_listener_service.dart
│   ├── sync/offline_sync_manager.dart
│   └── local_db/local_db.dart
├── features/
│   ├── splash/screens/splash_screen.dart
│   ├── auth/screens/login_screen.dart
│   ├── app_shell.dart
│   ├── verify/
│   │   ├── screens/verify_screen.dart
│   │   └── widgets/subscription_banner.dart
│   ├── history/screens/history_screen.dart
│   ├── workers/screens/workers_screen.dart
│   ├── analytics/screens/analytics_screen.dart
│   ├── dashboard/screens/
│   │   ├── trends_screen.dart
│   │   └── export_screen.dart
│   ├── subscription/screens/
│   │   ├── subscription_screen.dart
│   │   ├── plans_screen.dart
│   │   ├── renew_screen.dart
│   │   └── payment_history_screen.dart
│   └── settings/screens/settings_screen.dart
└── theme/
    └── app_theme.dart
```

---

## API Endpoints (Backend)

| Endpoint | Description |
|----------|-------------|
| `POST /v1/auth/login` | Phone + password → JWT |
| `POST /v1/auth/register` | Create owner + business |
| `POST /v1/auth/join` | Join with invite code |
| `POST /v1/verify` | Verify payment reference |
| `GET /v1/transactions` | List transactions |
| `GET /v1/analytics/dashboard` | Dashboard stats |
| `GET /v1/subscription/status` | Subscription status |
| `POST /v1/subscription/verify-payment` | Verify subscription payment |

---

## Environment

Set API base URL in `lib/services/api/api_client.dart`:

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:3000/v1';
```

WebSocket URL in `lib/services/realtime/realtime_service.dart`:

```dart
static const String _wsUrl = 'ws://YOUR_SERVER_IP:3000/ws';
```

---

## Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## Supported Payment Methods

| Bank | Reference Pattern |
|------|-------------------|
| TeleBirr | `TLB` + 10 digits |
| CBE | `CBE` + 10 digits |
| Awash | `AWB` + 10 digits |
| Dashen | `DSH` + 10 digits |
| Amole | `AML` + 10 digits |
| HelloCash | `HLC` + 10 digits |

---

## Tech Stack

- **Flutter 3.x** — Material Design
- **Riverpod** — State management
- **GoRouter** — Navigation
- **Dio** — HTTP client
- **Hive** — Local cache
- **WebSocket** — Real-time push
- **MobileScanner** — QR scanning
- **ML Kit** — On-device OCR
