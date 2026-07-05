export const paymentMethods = [
  { name: 'CBE', type: 'Bank' },
  { name: 'TeleBirr', type: 'Wallet' },
  { name: 'Awash Bank', type: 'Bank' },
  { name: 'Dashen Bank', type: 'Bank' },
  { name: 'Bank of Abyssinia', type: 'Bank' },
  { name: 'Amole', type: 'Wallet' },
  { name: 'M-Pesa ET', type: 'Wallet' },
  { name: 'HelloCash', type: 'Wallet' },
]

export const steps = [
  {
    label: 'Scan',
    title: 'Point the camera at the QR code',
    body: 'The till camera reads the payment QR the instant it prints or appears on the customer\u2019s screen \u2014 no typing, no waiting for an SMS.',
  },
  {
    label: 'Read',
    title: 'Or photograph the receipt',
    body: 'No QR? BirrGuard\u2019s offline OCR pulls the transaction ID, amount, and sender straight off a printed slip or a screenshot.',
  },
  {
    label: 'Confirm',
    title: 'Get a stamp, not a guess',
    body: 'BirrGuard checks the amount and sender against the bank or wallet directly and stamps the result on screen: matched, mismatched, or not found.',
  },
]

export const tiers = [
  {
    name: 'Starter',
    price: '199',
    period: '/ month',
    audience: 'One shop, one till',
    features: [
      '1 owner account + 3 cashier logins',
      'All 8 supported payment methods',
      'Full verification history',
      'Daily summary SMS',
    ],
    highlight: false,
  },
  {
    name: 'Business',
    price: '499',
    period: '/ month',
    audience: 'Growing shops, small chains',
    features: [
      'Unlimited cashier logins',
      'Analytics dashboard + CSV export',
      'Up to 3 branches, one account',
      'Priority support line',
    ],
    highlight: true,
  },
  {
    name: 'Enterprise',
    price: '1,200',
    period: '/ month',
    audience: 'Supermarkets, pharmacies, fuel stations',
    features: [
      'Everything in Business',
      'Custom SMS sender name',
      'POS integration via API',
      'Monthly business review call',
    ],
    highlight: false,
  },
]

export const faqs = [
  {
    q: 'Does BirrGuard work without internet?',
    a: 'Receipt scanning and OCR run on the device, so a cashier can capture and queue a check with no signal. The final bank confirmation completes the moment connectivity returns.',
  },
  {
    q: 'What happens when a subscription lapses?',
    a: 'A 3\u20135 day grace period keeps the till working. After that, only new verifications pause \u2014 cashiers see a plain message to ask the owner to renew, and nothing locks mid-sale.',
  },
  {
    q: 'Can I try it before paying?',
    a: 'Every plan opens with a 14-day trial, full features, no card required. Onboarding one shop at a time in Adama and Addis Ababa first, so setup help is hands-on.',
  },
  {
    q: 'How do I renew?',
    a: 'Send the fee to BirrGuard\u2019s TeleBirr, CBE, or Awash number with your shop\u2019s reference code. The app listens for the confirmation SMS and renews automatically \u2014 no forms.',
  },
]
