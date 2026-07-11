import { motion } from 'framer-motion'

const fadeUp = {
  hidden: { opacity: 0, y: 30 },
  visible: (i = 0) => ({
    opacity: 1,
    y: 0,
    transition: { delay: i * 0.12, duration: 0.6, ease: [0.25, 0.46, 0.45, 0.94] },
  }),
}

function PhoneMockup() {
  return (
    <div className="relative mx-auto w-[260px] sm:w-[280px] lg:w-[320px]" style={{ perspective: '1000px' }}>
      {/* Glow behind phone */}
      <div className="absolute -inset-8 rounded-[3rem] opacity-40 blur-3xl" style={{ background: 'radial-gradient(circle, var(--color-forest) 0%, transparent 70%)' }} />

      <motion.div
        initial={{ rotateY: -15, rotateX: 5, opacity: 0 }}
        animate={{ rotateY: -5, rotateX: 2, opacity: 1 }}
        transition={{ duration: 1, ease: [0.25, 0.46, 0.45, 0.94], delay: 0.4 }}
        className="relative"
        style={{ transformStyle: 'preserve-3d' }}
      >
        {/* Phone frame */}
        <div className="relative rounded-[2.5rem] p-2 shadow-2xl" style={{ backgroundColor: 'var(--color-border)' }}>
          <div className="relative overflow-hidden rounded-[2rem] bg-[var(--color-surface)]" style={{ border: '1px solid var(--color-border)' }}>
            {/* Notch */}
            <div className="absolute top-0 left-1/2 -translate-x-1/2 z-10 h-7 w-32 rounded-b-2xl" style={{ backgroundColor: 'var(--color-border)' }} />

            {/* Screen content */}
            <div className="relative min-h-[480px] sm:min-h-[540px] overflow-hidden" style={{ backgroundColor: 'var(--color-bg-secondary)' }}>
              {/* Status bar */}
              <div className="flex items-center justify-between px-6 pt-8 pb-3">
                <span className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>9:41</span>
                <div className="flex gap-1">
                  <div className="h-3 w-3 rounded-full" style={{ backgroundColor: 'var(--color-forest)' }} />
                  <div className="h-3 w-3 rounded-full" style={{ backgroundColor: 'var(--color-gold)' }} />
                </div>
              </div>

              {/* App header */}
              <div className="px-5 pb-4">
                <div className="flex items-center gap-3">
                  <img
                    src="/images/app_icons/payverify_icon_192x192.png"
                    alt="PayVerify"
                    className="h-10 w-10 rounded-xl shadow-md"
                  />
                  <div>
                    <p className="text-sm font-bold" style={{ color: 'var(--color-text)' }}>PayVerify</p>
                    <p className="text-[10px]" style={{ color: 'var(--color-text-muted)' }}>Cashier Terminal</p>
                  </div>
                </div>
              </div>

              {/* Verify card */}
              <div className="mx-4 rounded-2xl p-4" style={{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border)' }}>
                <p className="mb-3 text-xs font-semibold uppercase tracking-wider" style={{ color: 'var(--color-text-muted)' }}>Verify Transaction</p>

                {/* QR button */}
                <div className="mb-3 flex items-center justify-center gap-2 rounded-xl py-3 text-white text-sm font-semibold" style={{ backgroundColor: 'var(--color-forest)' }}>
                  <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
                  </svg>
                  Scan QR Code
                </div>

                {/* Receipt result */}
                <div className="rounded-xl p-3" style={{ backgroundColor: 'var(--color-bg)', border: '1px solid var(--color-border)' }}>
                  <div className="mb-2 flex items-center justify-between">
                    <span className="text-[10px] font-medium" style={{ color: 'var(--color-text-muted)' }}>TeleBirr</span>
                    <span className="rounded-full px-2 py-0.5 text-[9px] font-bold text-white" style={{ backgroundColor: 'var(--color-forest)' }}>VERIFIED</span>
                  </div>
                  <p className="font-mono text-xs font-semibold" style={{ color: 'var(--color-text)' }}>TXN: CBW4L9X2K7</p>
                  <p className="mt-1 text-lg font-bold" style={{ color: 'var(--color-gold)' }}>ETB 640.00</p>
                  <div className="mt-2 flex gap-2">
                    <span className="rounded-md px-2 py-0.5 text-[9px] font-medium" style={{ backgroundColor: 'rgba(39,107,71,0.15)', color: 'var(--color-forest)' }}>Sender Match</span>
                    <span className="rounded-md px-2 py-0.5 text-[9px] font-medium" style={{ backgroundColor: 'rgba(232,184,46,0.15)', color: 'var(--color-gold)' }}>Amount OK</span>
                  </div>
                </div>
              </div>

              {/* Scanline animation */}
              <div className="pointer-events-none absolute inset-x-4 top-0 overflow-hidden rounded-2xl">
                <div className="animate-scanline h-0.5 w-full opacity-60" style={{ background: 'linear-gradient(90deg, transparent, var(--color-gold), transparent)' }} />
              </div>

              {/* Bottom nav */}
              <div className="absolute bottom-0 left-0 right-0 flex items-center justify-around border-t px-4 py-3" style={{ borderColor: 'var(--color-border)', backgroundColor: 'var(--color-surface)' }}>
                {['Verify', 'History', 'Settings'].map((item, i) => (
                  <div key={item} className="flex flex-col items-center gap-1">
                    <div className={`h-5 w-5 rounded-full ${i === 0 ? '' : 'opacity-30'}`} style={{ backgroundColor: i === 0 ? 'var(--color-forest)' : 'var(--color-text-muted)' }} />
                    <span className={`text-[9px] font-medium ${i === 0 ? '' : 'opacity-40'}`} style={{ color: i === 0 ? 'var(--color-forest)' : 'var(--color-text-muted)' }}>{item}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Floating badge */}
        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 1.2, duration: 0.5 }}
          className="absolute -right-6 top-24 glass rounded-xl px-3 py-2 shadow-lg sm:block hidden"
        >
          <p className="text-[10px] font-medium" style={{ color: 'var(--color-text-muted)' }}>Avg. check time</p>
          <p className="text-lg font-bold font-mono" style={{ color: 'var(--color-gold)' }}>0.8s</p>
        </motion.div>
      </motion.div>
    </div>
  )
}

export default function Hero() {
  return (
    <section id="hero" className="relative min-h-[auto] sm:min-h-screen flex items-center overflow-x-hidden pt-20 pb-12 sm:pt-16 sm:pb-20 lg:pt-0 lg:pb-0">
      {/* Background gradient */}
      <div className="absolute inset-0" style={{
        background: 'linear-gradient(135deg, var(--color-bg) 0%, var(--color-bg-secondary) 50%, var(--color-bg) 100%)'
      }} />

      {/* Decorative orbs */}
      <div className="absolute top-20 right-10 h-72 w-72 rounded-full opacity-20 blur-[100px]" style={{ backgroundColor: 'var(--color-forest)' }} />
      <div className="absolute bottom-20 left-10 h-56 w-56 rounded-full opacity-15 blur-[80px]" style={{ backgroundColor: 'var(--color-gold)' }} />

      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        {/* Mobile-first: phone on top, text below. Desktop: side by side */}
        <div className="flex flex-col-reverse items-center gap-12 lg:grid lg:grid-cols-2 lg:gap-16 lg:items-center">
          {/* Left: Text */}
          <div className="text-center lg:text-left">
            <motion.div
              variants={fadeUp}
              initial="hidden"
              animate="visible"
              custom={0}
              className="mb-4 inline-flex items-center gap-2.5 rounded-full border border-[var(--color-forest)]/30 bg-[var(--color-forest)]/10 px-5 py-2.5 text-xs font-semibold tracking-wider backdrop-blur-md"
            >
              <span className="h-2 w-2 rounded-full animate-pulse" style={{ backgroundColor: 'var(--color-forest)' }} />
              Built for Ethiopian Merchants
            </motion.div>

            <motion.h1
              variants={fadeUp}
              initial="hidden"
              animate="visible"
              custom={1}
              className="font-display text-4xl font-extrabold leading-[1.1] tracking-tight text-white sm:text-5xl lg:text-6xl xl:text-7xl"
            >
              End Payment Fraud{' '}
              <span className="text-[var(--color-forest)]">at the Counter</span>
            </motion.h1>

            <motion.p
              variants={fadeUp}
              initial="hidden"
              animate="visible"
              custom={2}
              className="mt-6 max-w-lg text-base leading-relaxed text-white/90 sm:text-lg mx-auto lg:mx-0"
            >
              Verify every TeleBirr, CBE, and bank transaction in under a second.
              QR scan, receipt OCR, or manual check — fake screenshots never make it past your till.
            </motion.p>

            <motion.div
              variants={fadeUp}
              initial="hidden"
              animate="visible"
              custom={3}
              className="mt-10 flex flex-col sm:flex-row gap-4 justify-center lg:justify-start"
            >
              <a
                href="#download"
                className="group relative inline-flex items-center justify-center gap-2.5 rounded-xl border border-[var(--color-forest)]/30 bg-[var(--color-forest)] px-8 py-4 text-base font-semibold text-white backdrop-blur-md transition-all duration-300 hover:scale-[1.02] hover:border-[var(--color-forest)]/50 active:scale-[0.98] focus-ring"
              >
                <div className="absolute inset-0 rounded-xl bg-gradient-to-r from-transparent via-white/20 to-transparent opacity-0 transition-opacity group-hover:opacity-100"></div>
                <svg className="relative h-5 w-5 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
                </svg>
                <span className="relative">Download the App</span>
              </a>
              <a
                href="#gallery"
                className="group relative inline-flex items-center justify-center gap-2 rounded-xl border border-white/20 bg-white/5 px-8 py-4 text-base font-semibold text-white backdrop-blur-md transition-all duration-300 hover:scale-[1.02] hover:bg-white/10 active:scale-[0.98] focus-ring"
              >
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6.827 6.175A2.31 2.31 0 015.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 00-1.134-.175 2.31 2.31 0 01-1.64-1.055l-.822-1.316a2.192 2.192 0 00-1.736-1.039 48.774 48.774 0 00-5.232 0 2.192 2.192 0 00-1.736 1.039l-.821 1.316z" />
                  <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 12.75a4.5 4.5 0 11-9 0 4.5 4.5 0 019 0z" />
                </svg>
                <span>See Screenshots</span>
              </a>
            </motion.div>

            <motion.div
              variants={fadeUp}
              initial="hidden"
              animate="visible"
              custom={4}
              className="mt-10 flex flex-wrap gap-3 justify-center lg:justify-start"
            >
              {[
                { icon: '📱', text: 'Android 8.0+' },
                { icon: '📡', text: 'Works Offline' },
                { icon: '🌍', text: 'Amharic & English' },
              ].map((chip) => (
                <span
                  key={chip.text}
                  className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-4 py-2.5 text-xs font-medium backdrop-blur-md transition-all hover:border-white/20 hover:bg-white/10"
                >
                  <span className="text-lg">{chip.icon}</span>
                  <span className="text-white/90">{chip.text}</span>
                </span>
              ))}
            </motion.div>
          </div>

          {/* Right: Phone mockup */}
          <motion.div
            initial={{ opacity: 0, x: 40 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8, ease: [0.25, 0.46, 0.45, 0.94], delay: 0.3 }}
            className="flex justify-center lg:justify-end"
          >
            <PhoneMockup />
          </motion.div>
        </div>
      </div>
    </section>
  )
}
