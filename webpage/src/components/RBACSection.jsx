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
    <section id="rbac" className="relative py-20 sm:py-28">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <p className="text-xs font-semibold uppercase tracking-widest" style={{ color: 'var(--color-forest)' }}>
            Multi-Tenant Security
          </p>
          <h2 className="mt-3 font-display text-3xl font-bold sm:text-4xl lg:text-5xl" style={{ color: 'var(--color-text)' }}>
            Built for Teams, Not Just Tills
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-lg" style={{ color: 'var(--color-text-secondary)' }}>
            Owners see everything. Cashiers see only what they need. Secure 24-hour invitation codes for onboarding — no shared passwords.
          </p>
        </motion.div>

        {/* Toggle */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mx-auto mb-12 flex w-fit rounded-2xl p-1"
          style={{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border)' }}
        >
          {['owner', 'cashier'].map((view) => (
            <button
              key={view}
              onClick={() => setActiveView(view)}
              className={`relative flex items-center gap-2 rounded-xl px-6 py-3 text-sm font-semibold transition-all focus-ring ${
                activeView === view ? 'text-white' : ''
              }`}
              style={activeView === view ? { backgroundColor: 'var(--color-forest)' } : { color: 'var(--color-text-secondary)' }}
            >
              {view === 'owner' ? ownerIcon : cashierIcon}
              <span className="capitalize">{view === 'owner' ? 'Owner View' : 'Cashier View'}</span>
            </button>
          ))}
        </motion.div>

        {/* Comparison display */}
        <div className="grid gap-6 lg:grid-cols-2">
          {/* Active view */}
          <motion.div
            key={activeView}
            initial={{ opacity: 0, x: activeView === 'owner' ? -20 : 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.4 }}
            className="rounded-2xl p-6 sm:p-8"
            style={{
              backgroundColor: 'var(--color-surface)',
              border: '2px solid var(--color-forest)',
              boxShadow: 'var(--shadow-glow)',
            }}
          >
            <div className="mb-6 flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl text-white" style={{ backgroundColor: 'var(--color-forest)' }}>
                {activeView === 'owner' ? ownerIcon : cashierIcon}
              </div>
              <div>
                <p className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>Current View</p>
                <p className="text-lg font-bold" style={{ color: 'var(--color-text)' }}>{current.label}</p>
              </div>
            </div>

            <div className="space-y-3">
              {current.features.map((feature, i) => (
                <motion.div
                  key={feature}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.08 }}
                  className="flex items-start gap-3 rounded-xl px-4 py-3"
                  style={{ backgroundColor: 'var(--color-bg)' }}
                >
                  <span style={{ color: 'var(--color-forest)' }}>{checkIcon}</span>
                  <span className="text-sm font-medium" style={{ color: 'var(--color-text)' }}>{feature}</span>
                </motion.div>
              ))}
            </div>
          </motion.div>

          {/* Other view (locked) */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            className="relative rounded-2xl p-6 sm:p-8 opacity-60"
            style={{
              backgroundColor: 'var(--color-surface)',
              border: '1px solid var(--color-border)',
            }}
          >
            {/* Lock overlay */}
            <div className="absolute inset-0 z-10 flex items-center justify-center rounded-2xl" style={{ backgroundColor: 'rgba(var(--color-bg), 0.3)' }}>
              <div className="flex flex-col items-center gap-2 rounded-xl px-4 py-3" style={{ backgroundColor: 'var(--color-surface-elevated)', border: '1px solid var(--color-border)' }}>
                <span style={{ color: 'var(--color-text-muted)' }}>{lockIcon}</span>
                <span className="text-xs font-semibold" style={{ color: 'var(--color-text-muted)' }}>Restricted</span>
              </div>
            </div>

            <div className="mb-6 flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl" style={{ backgroundColor: 'var(--color-bg)', color: 'var(--color-text-muted)' }}>
                {other.icon === 'owner' ? ownerIcon : cashierIcon}
              </div>
              <div>
                <p className="text-xs font-medium" style={{ color: 'var(--color-text-muted)' }}>Not Visible</p>
                <p className="text-lg font-bold" style={{ color: 'var(--color-text)' }}>{other.label}</p>
              </div>
            </div>

            <div className="space-y-3">
              {other.features.map((feature) => (
                <div
                  key={feature}
                  className="flex items-start gap-3 rounded-xl px-4 py-3"
                  style={{ backgroundColor: 'var(--color-bg)' }}
                >
                  <span style={{ color: 'var(--color-text-muted)' }}>{lockIcon}</span>
                  <span className="text-sm font-medium" style={{ color: 'var(--color-text-muted)' }}>{feature}</span>
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
          className="mt-12 rounded-2xl p-6 sm:p-8 text-center"
          style={{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border)' }}
        >
          <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl" style={{ backgroundColor: 'rgba(232,184,46,0.12)', color: 'var(--color-gold)' }}>
            <svg className="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 5.25a3 3 0 013 3m3 0a6 6 0 01-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1 .43-1.563A6 6 0 1121.75 8.25z" />
            </svg>
          </div>
          <h3 className="text-xl font-bold" style={{ color: 'var(--color-text)' }}>
            Secure 24-Hour Invitation Codes
          </h3>
          <p className="mx-auto mt-2 max-w-lg text-sm" style={{ color: 'var(--color-text-secondary)' }}>
            Owners generate time-limited codes to onboard new cashiers. No shared credentials, no permanent access.
            Codes expire automatically and can be revoked instantly.
          </p>
        </motion.div>
      </div>
    </section>
  )
}
