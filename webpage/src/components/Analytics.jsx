import { useEffect, useRef, useState } from 'react'
import { Area, AreaChart, ResponsiveContainer, Tooltip, XAxis } from 'recharts'

const weekly = [
  { day: 'Mon', verifications: 412, blocked: 9 },
  { day: 'Tue', verifications: 468, blocked: 12 },
  { day: 'Wed', verifications: 501, blocked: 7 },
  { day: 'Thu', verifications: 486, blocked: 14 },
  { day: 'Fri', verifications: 612, blocked: 18 },
  { day: 'Sat', verifications: 734, blocked: 21 },
  { day: 'Sun', verifications: 589, blocked: 11 },
]

const stats = [
  { label: 'Verifications this week', value: 3802, suffix: '' },
  { label: 'Fraud attempts caught', value: 92, suffix: '' },
  { label: 'Median check time', value: 1.8, suffix: 's', decimals: 1 },
  { label: 'Active shops in Adama & Addis', value: 47, suffix: '' },
]

function useCountUp(target, decimals = 0, active) {
  const [value, setValue] = useState(0)
  useEffect(() => {
    if (!active) return
    let raf
    const duration = 1200
    const start = performance.now()
    const tick = (now) => {
      const progress = Math.min((now - start) / duration, 1)
      const eased = 1 - Math.pow(1 - progress, 3)
      setValue(target * eased)
      if (progress < 1) raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [target, active])
  return decimals ? value.toFixed(decimals) : Math.round(value).toLocaleString()
}

function StatCard({ stat, active }) {
  const display = useCountUp(stat.value, stat.decimals || 0, active)
  return (
    <div className="bg-ink rounded-2xl p-6">
      <p className="font-mono text-[11px] uppercase tracking-widest text-paperlight/45 mb-3">{stat.label}</p>
      <p className="font-display text-3xl md:text-4xl font-semibold text-paperlight">
        {display}
        {stat.suffix}
      </p>
    </div>
  )
}

function CustomTooltip({ active, payload, label }) {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-ink text-paperlight rounded-lg px-3 py-2 font-mono text-xs">
      <p className="text-paperlight/50 mb-1">{label}</p>
      <p>{payload[0].value} verified</p>
      <p className="text-gold">{payload[0].payload.blocked} blocked</p>
    </div>
  )
}

export default function Analytics() {
  const ref = useRef(null)
  const [inView, setInView] = useState(false)

  useEffect(() => {
    const obs = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) setInView(true)
      },
      { threshold: 0.3 }
    )
    if (ref.current) obs.observe(ref.current)
    return () => obs.disconnect()
  }, [])

  return (
    <section id="analytics" ref={ref} className="bg-paperlight py-20 md:py-28">
      <div className="max-w-6xl mx-auto px-6">
        <div className="max-w-xl mb-14">
          <p className="font-mono text-xs tracking-widest uppercase text-birr-dark mb-4">What owners see</p>
          <h2 className="font-display text-3xl md:text-4xl font-semibold text-ink leading-tight">
            One dashboard, every branch, no spreadsheet
          </h2>
          <p className="mt-4 font-sans text-ink/65 text-lg">
            Every check a cashier runs feeds straight into the owner’s dashboard — live, per
            branch, exportable to CSV for the accountant.
          </p>
        </div>

        <div className="grid md:grid-cols-4 gap-4 mb-8">
          {stats.map((s) => (
            <StatCard key={s.label} stat={s} active={inView} />
          ))}
        </div>

        <div className="bg-ink rounded-2xl p-6 md:p-8">
          <div className="flex items-center justify-between mb-6">
            <p className="font-mono text-xs uppercase tracking-widest text-paperlight/45">
              Verifications, last 7 days
            </p>
            <div className="flex items-center gap-4 font-mono text-[10px] text-paperlight/50">
              <span className="flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-birr-light" /> verified
              </span>
              <span className="flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-gold" /> blocked
              </span>
            </div>
          </div>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={weekly} margin={{ top: 6, right: 6, left: 0, bottom: 0 }}>
                <defs>
                  <linearGradient id="verifiedFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#17916A" stopOpacity={0.5} />
                    <stop offset="100%" stopColor="#17916A" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <XAxis
                  dataKey="day"
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: 'rgba(246,242,231,0.45)', fontSize: 11, fontFamily: 'IBM Plex Mono' }}
                />
                <Tooltip content={<CustomTooltip />} cursor={{ stroke: '#D9A441', strokeWidth: 1 }} />
                <Area
                  type="monotone"
                  dataKey="verifications"
                  stroke="#17916A"
                  strokeWidth={2.5}
                  fill="url(#verifiedFill)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </section>
  )
}
