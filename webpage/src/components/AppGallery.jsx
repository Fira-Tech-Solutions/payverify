import { useState, useRef, useEffect } from 'react'
import { motion } from 'framer-motion'
import { appScreenshots } from '../data'

function ScreenshotCard({ screenshot, index }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ delay: index * 0.1 }}
      className="flex-shrink-0 w-[260px] sm:w-[280px] snap-center"
    >
      <div
        className="relative overflow-hidden rounded-2xl"
        style={{
          backgroundColor: 'var(--color-surface)',
          border: '1px solid var(--color-border)',
        }}
      >
        {/* Phone frame */}
        <div className="relative mx-auto w-full pt-[190%]">
          <div className="absolute inset-0 flex items-center justify-center" style={{ backgroundColor: 'var(--color-bg-secondary)' }}>
            {screenshot.placeholder ? (
              <div className="flex flex-col items-center gap-3 p-6 text-center">
                <div className="flex h-16 w-16 items-center justify-center rounded-2xl" style={{ backgroundColor: 'rgba(39,107,71,0.12)' }}>
                  <svg className="h-8 w-8" style={{ color: 'var(--color-forest)' }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M6.827 6.175A2.31 2.31 0 015.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 00-1.134-.175 2.31 2.31 0 01-1.64-1.055l-.822-1.316a2.192 2.192 0 00-1.736-1.039 48.774 48.774 0 00-5.232 0 2.192 2.192 0 00-1.736 1.039l-.821 1.316z" />
                    <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 12.75a4.5 4.5 0 11-9 0 4.5 4.5 0 019 0z" />
                  </svg>
                </div>
                <p className="text-sm font-bold" style={{ color: 'var(--color-text)' }}>{screenshot.title}</p>
                <p className="text-xs leading-relaxed" style={{ color: 'var(--color-text-muted)' }}>{screenshot.description}</p>
              </div>
            ) : (
              <img src={screenshot.src} alt={screenshot.title} className="h-full w-full object-cover" />
            )}
          </div>
        </div>

        {/* Caption below phone */}
        <div className="p-4">
          <p className="text-sm font-bold" style={{ color: 'var(--color-text)' }}>{screenshot.title}</p>
          <p className="mt-1 text-xs" style={{ color: 'var(--color-text-muted)' }}>{screenshot.description}</p>
        </div>
      </div>
    </motion.div>
  )
}

export default function AppGallery() {
  const scrollRef = useRef(null)
  const [canScrollLeft, setCanScrollLeft] = useState(false)
  const [canScrollRight, setCanScrollRight] = useState(true)

  const checkScroll = () => {
    const el = scrollRef.current
    if (!el) return
    setCanScrollLeft(el.scrollLeft > 10)
    setCanScrollRight(el.scrollLeft < el.scrollWidth - el.clientWidth - 10)
  }

  useEffect(() => {
    const el = scrollRef.current
    if (!el) return
    el.addEventListener('scroll', checkScroll, { passive: true })
    checkScroll()
    return () => el.removeEventListener('scroll', checkScroll)
  }, [])

  const scroll = (direction) => {
    const el = scrollRef.current
    if (!el) return
    const amount = 300
    el.scrollBy({ left: direction === 'left' ? -amount : amount, behavior: 'smooth' })
  }

  return (
    <section id="gallery" className="relative py-20 sm:py-28 overflow-x-hidden">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mb-12 flex items-end justify-between"
        >
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-[var(--color-forest)]">
              App Preview
            </p>
            <h2 className="mt-3 font-display text-3xl font-bold text-white sm:text-4xl">
              See PayVerify in Action
            </h2>
            <p className="mt-2 max-w-md text-sm leading-relaxed text-white/90">
              A clean, dark interface built for fast verification at the counter.
            </p>
          </div>

          {/* Scroll arrows */}
          <div className="hidden sm:flex gap-2">
            <button
              onClick={() => scroll('left')}
              disabled={!canScrollLeft}
              className="flex h-10 w-10 items-center justify-center rounded-xl transition-all disabled:opacity-30"
              style={{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border)', color: 'var(--color-text)' }}
              aria-label="Scroll left"
            >
              <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
              </svg>
            </button>
            <button
              onClick={() => scroll('right')}
              disabled={!canScrollRight}
              className="flex h-10 w-10 items-center justify-center rounded-xl transition-all disabled:opacity-30"
              style={{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border)', color: 'var(--color-text)' }}
              aria-label="Scroll right"
            >
              <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
              </svg>
            </button>
          </div>
        </motion.div>

        {/* Horizontal scroll gallery */}
        <div className="relative">
          {/* Fade edges */}
          {canScrollLeft && (
            <div className="pointer-events-none absolute left-0 top-0 bottom-0 w-12 z-10" style={{ background: 'linear-gradient(to right, var(--color-bg), transparent)' }} />
          )}
          {canScrollRight && (
            <div className="pointer-events-none absolute right-0 top-0 bottom-0 w-12 z-10" style={{ background: 'linear-gradient(to left, var(--color-bg), transparent)' }} />
          )}

          <div
            ref={scrollRef}
            className="flex gap-4 overflow-x-auto snap-x snap-mandatory pb-4 scrollbar-hide"
            style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
          >
            {appScreenshots.map((screenshot, i) => (
              <ScreenshotCard key={screenshot.id} screenshot={screenshot} index={i} />
            ))}
          </div>
        </div>

        {/* Add screenshots CTA */}
        <motion.p
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          className="mt-8 text-center text-xs"
          style={{ color: 'var(--color-text-muted)' }}
        >
          Add your app screenshots to <code className="rounded px-1.5 py-0.5 text-[11px] font-mono" style={{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border)' }}>public/images/screenshots/</code> to replace placeholders
        </motion.p>
      </div>
    </section>
  )
}
