import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { downloadOptions } from '../data'

const storeIcons = {
  apk: (
    <svg className="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
    </svg>
  ),
  galaxy: (
    <svg className="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
    </svg>
  ),
  huawei: (
    <svg className="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 21a9.004 9.004 0 008.716-6.747M12 21a9.004 9.004 0 01-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 017.843 4.582M12 3a8.997 8.997 0 00-7.843 4.582m15.686 0A11.953 11.953 0 0112 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0121 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0112 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 013 12c0-1.605.42-3.113 1.157-4.418" />
    </svg>
  ),
  apkpure: (
    <svg className="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M20.25 6.375c0 2.278-3.694 4.125-8.25 4.125S3.75 8.653 3.75 6.375m16.5 0c0-2.278-3.694-4.125-8.25-4.125S3.75 4.097 3.75 6.375m16.5 0v11.25c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125V6.375" />
    </svg>
  ),
  appstore: (
    <svg className="h-7 w-7" viewBox="0 0 24 24" fill="currentColor">
      <path d="M14.94 5.19A4.38 4.38 0 0016 2a4.44 4.44 0 00-3 1.52 4.17 4.17 0 00-1 3.09 3.69 3.69 0 003-1.42zM17.67 13.82c-1.24-1.14-1.67-2.32-1.61-3.54a4.56 4.56 0 011.42-.93 4.47 4.47 0 00-3.7-2c-1.57-.16-3.08.92-3.87.92s-2-.9-3.36-.87A4.77 4.77 0 002 13.16c0 1.23.45 2.56 1 4 .39 1 1.75 3.45 3.17 3.4s1.57-1.09 3.22-1.09 1.94 1.09 3.22 1.06 2.51-2.35 2.9-3.35a4.54 4.54 0 01-1.84-7.36z" />
    </svg>
  ),
  testflight: (
    <svg className="h-7 w-7" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z" />
    </svg>
  ),
}

function detectPlatform() {
  if (typeof navigator === 'undefined') return 'android'
  const ua = navigator.userAgent
  if (/iPad|iPhone|iPod/.test(ua)) return 'ios'
  return 'android'
}

export default function DownloadSection() {
  const [platform, setPlatform] = useState('android')

  useEffect(() => {
    setPlatform(detectPlatform())
  }, [])

  const items = downloadOptions.filter((o) => o.platform === platform)
  const primary = items.find((o) => o.primary)
  const others = items.filter((o) => !o.primary)

  return (
    <section id="download" className="relative py-20 sm:py-28 overflow-x-hidden">
      <div className="absolute inset-0" style={{
        background: 'linear-gradient(180deg, var(--color-bg) 0%, var(--color-bg-secondary) 50%, var(--color-bg) 100%)'
      }} />

      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-12"
        >
          <p className="text-xs font-semibold uppercase tracking-wider text-[var(--color-forest)]">
            Get the App
          </p>
          <h2 className="mt-3 font-display text-3xl font-bold text-white sm:text-4xl lg:text-5xl">
            Download PayVerify
          </h2>
          <p className="mx-auto mt-5 max-w-xl text-base leading-relaxed text-white/90">
            Available for Android and iOS. Pick your platform below.
          </p>
        </motion.div>

        {/* Platform tabs */}
        <div className="mx-auto mb-12 flex max-w-xs rounded-2xl p-1.5" style={{ backgroundColor: 'var(--color-bg)', border: '1px solid var(--color-border)' }}>
          {['android', 'ios'].map((p) => (
            <button
              key={p}
              onClick={() => setPlatform(p)}
              className={`relative flex-1 rounded-xl py-3 text-sm font-semibold transition-all duration-300 active:scale-95 ${
                platform === p
                  ? 'text-white z-10'
                  : 'text-white/70 hover:text-white'
              }`}
              style={platform === p
                ? { backgroundColor: 'var(--color-forest)', boxShadow: '0 4px 20px rgba(39,107,71,0.3)' }
                : {}
              }
            >
              <span className="relative z-10">{
                platform === p && p === 'android' ? '🧬 Android' :
                platform === p && p === 'ios' ? '🍎 iPhone' :
                p === 'android' ? 'Android' : 'iPhone'
              }</span>
            </button>
          ))}
        </div>

        {/* Primary download */}
        {primary && (
          <motion.div
            key={primary.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="mx-auto mb-8 max-w-2xl overflow-hidden rounded-3xl"
            style={{
              backgroundColor: 'var(--color-surface)',
              border: '2px solid var(--color-forest)',
              boxShadow: 'var(--shadow-glow)',
            }}
          >
            <div className="flex flex-col sm:flex-row items-center gap-6 p-6 sm:p-8">
              <div className="flex-shrink-0">
                <img
                  src="/images/app_icons/payverify_icon_192x192.png"
                  alt="PayVerify"
                  className="h-20 w-20 rounded-2xl shadow-lg"
                />
              </div>

              <div className="flex-1 text-center sm:text-left">
                <div className="flex items-center gap-2 justify-center sm:justify-start">
                  <h3 className="text-xl font-bold" style={{ color: 'var(--color-text)' }}>{primary.name}</h3>
                  <span className="rounded-full px-2.5 py-0.5 text-[10px] font-bold text-white" style={{ backgroundColor: 'var(--color-forest)' }}>
                    {primary.badge}
                  </span>
                </div>
                <p className="mt-1 text-sm" style={{ color: 'var(--color-text-secondary)' }}>{primary.description}</p>
                {platform === 'android' && (
                  <p className="mt-1 text-xs" style={{ color: 'var(--color-text-muted)' }}>
                    SHA-256: <span className="font-mono">a1b2c3d4...</span>
                  </p>
                )}
              </div>

              <a
                href={primary.url}
                target="_blank"
                rel="noopener noreferrer"
                className="flex-shrink-0 inline-flex items-center gap-2.5 rounded-2xl px-8 py-4 text-base font-semibold text-white shadow-lg transition-all hover:scale-[1.02] hover:shadow-xl active:scale-[0.98] focus-ring"
                style={{ backgroundColor: 'var(--color-forest)', boxShadow: '0 4px 24px rgba(39,107,71,0.35)' }}
              >
                {storeIcons[primary.icon]}
                {platform === 'android' ? 'Download APK' : 'Download on App Store'}
              </a>
            </div>

            <div className="flex items-center gap-2 border-t px-6 sm:px-8 py-3" style={{ borderColor: 'var(--color-border)', backgroundColor: 'var(--color-bg)' }}>
              <svg className="h-4 w-4 flex-shrink-0" style={{ color: 'var(--color-forest)' }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
              </svg>
              <span className="text-xs" style={{ color: 'var(--color-text-muted)' }}>
                {platform === 'android' ? 'Hosted on Cloudflare R2. Fast, secure, global CDN delivery.' : 'Download directly from the official App Store.'}
              </span>
            </div>
          </motion.div>
        )}

        {/* Other stores grid */}
        <motion.div
          key={`grid-${platform}`}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="grid gap-4 sm:grid-cols-3"
        >
          {others.map((option) => (
            <motion.a
              key={option.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              href={option.url}
              target="_blank"
              rel="noopener noreferrer"
              className="group flex items-center gap-4 rounded-2xl p-5 transition-all hover:scale-[1.01]"
              style={{
                backgroundColor: 'var(--color-surface)',
                border: '1px solid var(--color-border)',
              }}
            >
              <div
                className="flex h-14 w-14 flex-shrink-0 items-center justify-center rounded-xl transition-transform group-hover:scale-110"
                style={{ backgroundColor: 'var(--color-bg)', color: 'var(--color-text-muted)' }}
              >
                {storeIcons[option.icon]}
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <p className="text-sm font-bold truncate" style={{ color: 'var(--color-text)' }}>{option.name}</p>
                  <span className="flex-shrink-0 rounded-full px-2 py-0.5 text-[9px] font-semibold" style={{ backgroundColor: 'var(--color-bg)', color: 'var(--color-text-muted)', border: '1px solid var(--color-border)' }}>
                    {option.badge}
                  </span>
                </div>
                <p className="text-xs" style={{ color: 'var(--color-text-muted)' }}>{option.subtitle}</p>
              </div>
              <svg className="h-4 w-4 flex-shrink-0 opacity-0 transition-all group-hover:opacity-100 group-hover:translate-x-1" style={{ color: 'var(--color-text-muted)' }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
              </svg>
            </motion.a>
          ))}
        </motion.div>

        {/* Version info */}
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          className="mt-8 text-center"
        >
          <p className="text-xs" style={{ color: 'var(--color-text-muted)' }}>
            {platform === 'android'
              ? 'Current version: v1.0.0 · Size: ~21 MB · Requires Android 8.0+'
              : 'Current version: v1.0.0 · Requires iOS 14.0+'}
          </p>
        </motion.div>
      </div>
    </section>
  )
}
