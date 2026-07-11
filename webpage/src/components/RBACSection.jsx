import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { rbacScenarios } from '../data'

const ownerIcon = (
  <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
  </svg>
)

const cashierIcon = (
  <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
  </svg>
)

const checkIcon = (
  <svg className="h-4 w-4 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
  </svg>
)

const lockIcon = (
  <svg className="h-4 w-4 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
  </svg>
)

export default function RBACSection() {
  const [activeView, setActiveView] = useState('owner')

  const current = rbacScenarios[activeView]
  const other = activeView === 'owner' ? rbacScenarios.cashier : rbacScenarios.owner

  return (
    <section id="rbac" className="relative py-20 sm:py-28 overflow-x-hidden">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-20"
        >
          <p className="text-xs font-semibold uppercase tracking-wider text-[var(--color-forest)]">
            Multi-Tenant Security
          </p>
          <h2 className="mt-3 font-display text-3xl font-bold text-white sm:text-4xl lg:text-5xl">
            Built for Teams, Not Just Tills
          </h2>
          <p className="mx-auto mt-5 max-w-2xl text-base leading-relaxed text-white/90">
            Owners see everything. Cashiers see only what they need. Secure 24-hour invitation codes for onboarding — no shared passwords.
          </p>
        </motion.div>

        {/* Toggle */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mx-auto mb-16 flex w-fit rounded-2xl p-1.5"
          style={{ backgroundColor: 'var(--color-bg)', border: '1px solid var(--color-border)' }}
        >
          {['owner', 'cashier'].map((view) => (
            <button
              key={view}
              onClick={() => setActiveView(view)}
              className={`group relative flex items-center gap-2.5 rounded-xl px-8 py-4 text-sm font-semibold transition-all duration-300 active:scale-95 focus-ring ${
                activeView === view
                  ? 'text-white z-10'
                  : 'text-white/70 hover:text-white'
              }`}
              style={activeView === view
                ? { backgroundColor: 'var(--color-forest)', boxShadow: '0 4px 20px rgba(39,107,71,0.4)' }
                : {}
              }
            >
              <span className="relative z-10 flex items-center gap-2.5">
                {view === 'owner' ? ownerIcon : cashierIcon}
                <span className="capitalize">{view === 'owner' ? 'Owner View' : 'Cashier View'}</span>
              </span>
            </button>
          ))}
        </motion.div>

        {/* Comparison display */}
        <div className="grid gap-8 lg:grid-cols-2">
          {/* Active view */}
          <motion.div
            key={activeView}
            initial={{ opacity: 0, x: activeView === 'owner' ? -20 : 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.4 }}
            className="relative rounded-2xl border-2 border-[var(--color-forest)] bg-white/5 backdrop-blur-md p-8"
            style={{ boxShadow: '0 8px 40px rgba(39,107,71,0.2)' }}
          >
            {/* Accent glow */}
            <div className="absolute -inset-0.5 rounded-2xl bg-gradient-to-r from-[var(--color-forest)]/20 to-transparent opacity-50 blur-xl"></div>
            
            <div className="relative mb-8 flex items-center gap-4">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl text-white shadow-lg" style={{ backgroundColor: 'var(--color-forest)' }}>
                {activeView === 'owner' ? ownerIcon : cashierIcon}
              </div>
              <div>
                <p className="text-xs font-medium text-white/60">Current View</p>
                <p className="text-xl font-bold text-white">{current.label}</p>
              </div>
            </div>

            <div className="space-y-4">
              {current.features.map((feature, i) => (
                <motion.div
                  key={feature}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.08 }}
                  className="group flex items-start gap-4 rounded-xl border border-white/10 bg-white/5 p-5 transition-all duration-300 hover:border-white/20 hover:bg-white/10 active:scale-[0.98]"
                >
                  <span className="mt-0.5 flex-shrink-0 text-[var(--color-forest)]">{checkIcon}</span>
                  <span className="text-sm font-medium text-white/90">{feature}</span>
                </motion.div>
              ))}
            </div>
          </motion.div>

          {/* Other view (locked) */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            className="relative rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-8 opacity-70"
          >
            {/* Lock overlay */}
            <div className="absolute inset-0 z-10 flex items-center justify-center rounded-2xl bg-black/40 backdrop-blur-sm">
              <div className="flex flex-col items-center gap-3 rounded-xl border border-white/10 bg-white/10 px-6 py-5 backdrop-blur-md">
                <span className="text-[var(--color-text-muted)]">{lockIcon}</span>
                <span className="text-xs font-semibold tracking-wide text-white/60">Restricted Access</span>
              </div>
            </div>

            <div className="relative mb-8 flex items-center gap-4">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl border border-white/10 bg-white/5 text-[var(--color-text-muted)]">
                {other.icon === 'owner' ? ownerIcon : cashierIcon}
              </div>
              <div>
                <p className="text-xs font-medium text-white/60">Not Visible</p>
                <p className="text-xl font-bold text-white/70">{other.label}</p>
              </div>
            </div>

            <div className="space-y-4">
              {other.features.map((feature) => (
                <div
                  key={feature}
                  className="flex items-start gap-4 rounded-xl border border-white/5 bg-white/5 p-5"
                >
                  <span className="mt-0.5 flex-shrink-0 text-white/40">{lockIcon}</span>
                  <span className="text-sm font-medium text-white/50">{feature}</span>
                </div>
              ))}
            </div>
          </motion.div>
        </div>

        {/* Invitation code callout */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="relative mt-20 rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-10 shadow-xl"
        >
          {/* Decorative elements */}
          <div className="absolute -top-6 -right-6 h-32 w-32 rounded-full bg-[var(--color-gold)]/20 blur-3xl"></div>
          <div className="absolute -bottom-6 -left-6 h-24 w-24 rounded-full bg-[var(--color-forest)]/20 blur-2xl"></div>
          
          <div className="relative flex flex-col items-center text-center">
            <div className="mb-6 flex h-16 w-16 items-center justify-center rounded-2xl border border-white/10 bg-white/10 shadow-lg" style={{ backgroundColor: 'rgba(232,184,46,0.15)', color: 'var(--color-gold)' }}>
              <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 5.25a3 3 0 013 3m3 0a6 6 0 01-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1 .43-1.563A6 6 0 1121.75 8.25z" />
              </svg>
            </div>
            <h3 className="text-2xl font-bold text-white">
              Secure 24-Hour Invitation Codes
            </h3>
            <p className="mx-auto mt-4 max-w-lg text-base leading-relaxed text-white/80">
              Owners generate time-limited codes to onboard new cashiers. No shared credentials, no permanent access.
              Codes expire automatically and can be revoked instantly.
            </p>
          </div>
        </motion.div>
      </div>
    </section>
  )
}
