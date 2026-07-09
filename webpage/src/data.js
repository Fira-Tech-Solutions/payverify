export const paymentMethods = [
  { name: 'CBE', type: 'Bank', color: '#1A6B3C', icon: '/images/bank_icons/cbe.png' },
  { name: 'TeleBirr', type: 'Wallet', color: '#E8B82E', icon: '/images/bank_icons/tellebirr.jpg' },
  { name: 'Awash Bank', type: 'Bank', color: '#0066B3', icon: '/images/bank_icons/awash-bank-logo.png' },
  { name: 'Dashen Bank', type: 'Bank', color: '#E31E24', icon: '/images/bank_icons/Dashen_Bank.png' },
  { name: 'Bank of Abyssinia', type: 'Bank', color: '#0054A6', icon: '/images/bank_icons/cbe_birr.jpeg' },
  { name: 'Amole', type: 'Wallet', color: '#FF6B00', icon: '/images/bank_icons/Amole-Logo.png' },
  { name: 'HelloCash', type: 'Wallet', color: '#9C27B0', icon: '/images/bank_icons/hello-cash.jpeg' },
]

export const downloadOptions = [
  // Android
  {
    id: 'direct-apk',
    name: 'Download APK',
    subtitle: 'Direct download',
    description: 'Get the latest Android version directly. v1.0.0',
    url: 'https://pub-<YOUR_R2_SUBDOMAIN>.r2.dev/payverify-v1.0.0.apk',
    icon: 'apk',
    primary: true,
    badge: 'Latest',
    platform: 'android',
  },
  {
    id: 'galaxy-store',
    name: 'Galaxy Store',
    subtitle: 'Samsung devices',
    description: 'Optimized for Samsung Galaxy phones',
    url: 'https://galaxy.store/payverify',
    icon: 'galaxy',
    primary: false,
    badge: 'Coming Soon',
    platform: 'android',
  },
  {
    id: 'huawei-appgallery',
    name: 'AppGallery',
    subtitle: 'Huawei devices',
    description: 'Available on Huawei AppGallery',
    url: 'https://appgallery.huawei.com/app/C100',
    icon: 'huawei',
    primary: false,
    badge: 'Coming Soon',
    platform: 'android',
  },
  {
    id: 'apkpure',
    name: 'APKPure',
    subtitle: 'All Android',
    description: 'Universal download for any Android device',
    url: 'https://apkpure.com/payverify',
    icon: 'apkpure',
    primary: false,
    badge: 'Coming Soon',
    platform: 'android',
  },
  // iOS
  {
    id: 'app-store',
    name: 'App Store',
    subtitle: 'iPhone & iPad',
    description: 'Download from the official Apple App Store',
    url: 'https://apps.apple.com/app/payverify/id0000000000',
    icon: 'appstore',
    primary: true,
    badge: 'Latest',
    platform: 'ios',
  },
  {
    id: 'testflight',
    name: 'TestFlight',
    subtitle: 'Beta access',
    description: 'Join the iOS beta program for early access',
    url: 'https://testflight.apple.com/join/xxxxxxxx',
    icon: 'testflight',
    primary: false,
    badge: 'Beta',
    platform: 'ios',
  },
]

export const appScreenshots = [
  {
    id: 'verify',
    title: 'Verify Transaction',
    description: 'Scan QR codes or upload receipts for instant verification',
    placeholder: true,
  },
  {
    id: 'dashboard',
    title: 'Owner Dashboard',
    description: 'Real-time analytics, revenue tracking, and fraud alerts',
    placeholder: true,
  },
  {
    id: 'history',
    title: 'Transaction History',
    description: 'Complete log of all verified and flagged transactions',
    placeholder: true,
  },
  {
    id: 'scanner',
    title: 'QR Scanner',
    description: 'Camera-based scanner with gold corner brackets',
    placeholder: true,
  },
  {
    id: 'workers',
    title: 'Worker Management',
    description: 'Onboard cashiers with secure 24-hour invitation codes',
    placeholder: true,
  },
]

export const features = [
  {
    id: 'qr-scan',
    title: 'QR Code Scanning',
    description: 'Point, scan, verify. The till camera reads payment QRs the instant they appear — no typing, no waiting.',
    icon: 'qr',
    color: '#7C6FF7',
    span: 'col-span-1 md:col-span-2',
  },
  {
    id: 'receipt-ocr',
    title: 'Receipt OCR',
    description: 'No QR? Our offline OCR engine pulls transaction IDs, amounts, and senders straight off printed slips.',
    icon: 'receipt',
    color: '#4A9EFF',
    span: 'col-span-1',
  },
  {
    id: 'telebirr-cbe',
    title: 'TeleBirr & CBE Integration',
    description: 'Direct verification against bank and wallet APIs. Real-time confirmation, not guesswork.',
    icon: 'bank',
    color: '#276B47',
    span: 'col-span-1',
  },
  {
    id: 'offline-queue',
    title: 'Offline Queueing',
    description: 'No signal? Captures queue locally and verifies the moment connectivity returns. Zero lost checks.',
    icon: 'offline',
    color: '#E8B82E',
    span: 'col-span-1 md:col-span-2',
  },
]

export const rbacScenarios = {
  owner: {
    label: 'Owner Dashboard',
    icon: 'owner',
    features: [
      'Total revenue & transaction volume',
      'Fraud attempt tracking & alerts',
      'Worker performance analytics',
      'Branch-by-branch comparison',
      'Exportable CSV reports',
      'Subscription & billing management',
    ],
  },
  cashier: {
    label: 'Cashier Terminal',
    icon: 'cashier',
    features: [
      'Quick verify button (QR / receipt)',
      'Transaction history for this terminal',
      'Instant pass/fail stamp result',
      'Offline queue status',
      'No access to business analytics',
      'No access to other workers data',
    ],
  },
}

export const stats = [
  { label: 'Transactions Verified Today', value: 12847, suffix: '', apiEndpoint: '/api/stats/transactions-today' },
  { label: 'Active Merchant Terminals', value: 312, suffix: '', apiEndpoint: '/api/stats/active-terminals' },
  { label: 'Average Verification Speed', value: 0.8, suffix: 's', apiEndpoint: '/api/stats/avg-speed', decimals: 1 },
]

export const team = {
  company: 'Fira Tech Solutions',
  location: 'Adama, Ethiopia',
  email: 'support@payverify.app',
  phone: '+251 91 123 4567',
  telegram: '@PayVerifySupport',
  github: 'https://github.com/Fira-Tech-Solutions/payverify',
}

export const footerLinks = {
  product: [
    { label: 'How It Works', href: '#features' },
    { label: 'App Gallery', href: '#gallery' },
    { label: 'Download', href: '#download' },
    { label: 'API Documentation', href: '#' },
  ],
  legal: [
    { label: 'Privacy Policy', href: '#' },
    { label: 'Terms of Service', href: '#' },
    { label: 'Cookie Policy', href: '#' },
  ],
  support: [
    { label: 'Help Center', href: '#' },
    { label: 'Contact Us', href: `mailto:${team.email}` },
    { label: 'Telegram Support', href: `https://t.me/${team.telegram.replace('@', '')}` },
    { label: 'Report a Bug', href: `${team.github}/issues` },
    { label: 'System Status', href: '#' },
  ],
}
