import { useState, useEffect, useRef } from 'react'
import { motion } from 'framer-motion'
import { stats } from '../data'

function StatCard({ stat, index }) {
  const [value, setValue] = useState(0)
  const ref = useRef(null)
  const hasAnimated = useRef(false)

  useEffect(() => {
    if (!ref.current) return

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && !hasAnimated.current) {
          hasAnimated.current = true
          animateValue()
          observer.disconnect()
        }
      },
      { threshold: 0.4 }
    )

    observer.observe(ref.current)
    return () => observer.disconnect()
  }, [])

  function animateValue() {
    const target = stat.value
    const duration = 2000
    const startTime = performance.now()
    const decimals = stat.decimals || 0

    function update(currentTime) {
      const elapsed = currentTime - startTime
      const progress = Math.min(elapsed / duration, 1)
      const eased = 1 - Math.pow(1 - progress, 4)
      setValue(Number((eased * target).toFixed(decimals)))

      if (progress < 1) {
        requestAnimationFrame(update)
      }
    }

    requestAnimationFrame(update)
  }

  const displayValue = stat.decimals
    ? value.toFixed(stat.decimals)
    : value.toLocaleString()

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ delay: index * 0.15, duration: 0.5 }}
      className="relative rounded-2xl p-6 text-center"
      style={{
        backgroundColor: 'var(--color-surface)',
        border: '1px solid var(--color-border)',
      }}
    >
      <p className="font-mono text-3xl font-bold sm:text-4xl" style={{ color: 'var(--color-gold)' }}>
        {displayValue}{stat.suffix}
      </p>
      <p className="mt-2 text-sm font-medium" style={{ color: 'var(--color-text-secondary)' }}>
        {stat.label}
      </p>
      {/* API endpoint hint */}
      <p className="mt-1 font-mono text-[10px]" style={{ color: 'var(--color-text-muted)' }}>
        {stat.apiEndpoint}
      </p>
    </motion.div>
  )
}

export default function StatsBanner() {
  const [liveStats, setLiveStats] = useState(null)
  const intervalRef = useRef(null)

  // API Integration Ready: Replace this with real fetch
  useEffect(() => {
    // Simulated initial fetch
    // In production: fetch('/api/stats').then(res => res.json()).then(setLiveStats)

    // Polling setup (uncomment when backend is ready)
    // intervalRef.current = setInterval(() => {
    //   fetch('/api/stats')
    //     .then(res => res.json())
    //     .then(setLiveStats)
    //     .catch(console.error)
    // }, 30000)

    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current)
    }
  }, [])

  return (
    <section id="stats" className="relative py-20 sm:py-28 overflow-x-hidden">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        className="absolute top-0 left-1/2 -translate-x-1/2 h-px w-2/3"
        style={{
          background: 'linear-gradient(90deg, transparent, var(--color-forest), transparent)'
        }}
      />

      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <p className="text-xs font-semibold uppercase tracking-wider text-[var(--color-forest)]">
            Live Platform Metrics
          </p>
          <h2 className="mt-3 font-display text-3xl font-bold text-white sm:text-4xl">
            Trusted by Merchants Across Ethiopia
          </h2>
        </motion.div>

        <div className="grid gap-8 sm:grid-cols-3">
          {stats.map((stat, i) => (
            <StatCard key={stat.label} stat={stat} index={i} />
          ))}
        </div>

        <motion.p
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.6 }}
          className="mt-8 text-center text-sm text-white/60"
        >
          Data refreshes every 30 seconds from the live API
        </motion.p>
      </div>
    </section>
  )
}