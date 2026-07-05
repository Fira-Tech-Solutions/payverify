# BirrGuard — Landing Page

A responsive marketing site for BirrGuard, a payment-verification app for Ethiopian
merchants (QR / receipt-OCR / transaction-ID checks against CBE, TeleBirr, Awash, Dashen,
Bank of Abyssinia, Amole, M-Pesa ET, and HelloCash).

Built with React 18 + Vite + Tailwind CSS. Charts via Recharts.

## Run it locally

```bash
npm install
npm run dev
```

Open the URL Vite prints (usually `http://localhost:5173`).

## Build for production

```bash
npm run build
npm run preview   # optional, serves the production build locally
```

The static site is output to `dist/` — upload that folder to any static host
(Netlify, Vercel, GitHub Pages, S3, cPanel, etc).

## Project structure

```
src/
  components/
    Navbar.jsx        sticky nav with mobile menu
    Hero.jsx           headline + animated "verification stamp" phone mockup
    TrustBar.jsx        supported banks & wallets
    Problem.jsx         the fake-screenshot scam framing
    HowItWorks.jsx       3-step verification flow (QR / receipt / transaction ID)
    Analytics.jsx        stats + weekly verification chart (recharts)
    Pricing.jsx           Starter / Business / Enterprise tiers
    Download.jsx          APK download CTA + QR placeholder
    Faq.jsx                accordion FAQ
    Footer.jsx
  data.js                 all copy/content lives here — edit this file to update
                          pricing, FAQs, steps, or the payment-method list
  App.jsx                 assembles the page
  index.css               Tailwind base + a couple of small utilities
tailwind.config.js        color, font, and animation tokens (the design system)
```

## Things you'll likely want to swap before shipping

- **`#download` links** in `Download.jsx` point to `#` — replace with your real
  APK URL and QR code image once the file is hosted.
- **Numbers in `Analytics.jsx`** and **`data.js` stats** are illustrative sample
  data — wire them to your real backend/analytics endpoint when ready.
- **Contact details** in `Footer.jsx` (email, phone, address) are placeholders.
- **Google Play badge** in `Download.jsx` currently reads "in review" — update
  once (or if) the app is published there.

## Design notes

Colors and type live entirely in `tailwind.config.js` (`ink`, `paper`, `birr`,
`gold`, `rust`) so the palette can be retuned in one place. The signature visual
is the animated verification stamp in the hero phone mockup — it loops every
~4 seconds to show the core product moment (scan → match → stamp).
