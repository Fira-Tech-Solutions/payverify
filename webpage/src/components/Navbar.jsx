import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

const navLinks = [
  { label: 'Features', href: '#features' },
  { label: 'Analytics', href: '#stats' },
  { label: 'Download', href: '#download' },
]

const navIcons = {
  features: (
    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zM3.75 15.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6A2.25 2.25 0 013.75 18v-2.25zM13.5 6a2.25 2.25 0 012.25-2.25H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zM13.5 15.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z" />
    </svg>
  ),
  stats: (
    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z" />
    </svg>
  ),
  download: (
    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
    </svg>
  ),
}

export default function Navbar({ theme, toggleTheme }) {
  const [scrolled, setScrolled] = useState(false)
  const [activeSection, setActiveSection] = useState('hero')

  const navItems = [
    { label: 'Features', href: '#features', key: 'features' },
    { label: 'Analytics', href: '#stats', key: 'stats' },
    { label: 'Download', href: '#download', key: 'download' },
  ]

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 20)
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  useEffect(() => {
    const handleScroll = () => {
      const sections = ['hero', 'features', 'stats', 'download']
      let currentSection = 'hero'

      for (const section of sections) {
        const element = document.getElementById(section)
        if (element) {
          const rect = element.getBoundingClientRect()
          if (rect.top <= 150 && rect.top > -window.innerHeight / 2) {
            currentSection = section
            break
          }
        }
      }

      setActiveSection(currentSection)
    }

    window.addEventListener('scroll', handleScroll, { passive: true })
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  return (
    <>
      {/* Top header - desktop & mobile logo */}
      <motion.header
        initial={{ y: -100 }}
        animate={{ y: 0 }}
        transition={{ type: 'spring', stiffness: 100, damping: 20 }}
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
          scrolled
            ? 'glass shadow-lg'
            : 'bg-transparent'
        }`}
      >
        <nav className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="flex h-16 items-center justify-between">
            {/* Logo */}
            <a href="#hero" className="group flex items-center gap-3 rounded-xl border border-white/10 px-3 py-2 transition-all hover:border-white/20 focus-ring">
              <div className="relative">
                <img src="/images/app_icons/payverify_icon_192x192.png" alt="PayVerify" className="h-9 w-9 rounded-xl border border-white/10 shadow-lg" />
                <div className="absolute -inset-1 rounded-xl bg-[var(--color-forest)] opacity-20 blur-md"></div>
              </div>
              <span className="font-display text-xl font-bold tracking-tight text-white">
                PayVerify
              </span>
            </a>

            {/* Desktop nav */}
            <div className="hidden md:flex items-center gap-2">
              {navItems.map((item) => (
                <a
                  key={item.label}
                  href={item.href}
                  className={`group relative rounded-xl px-5 py-3 text-sm font-medium transition-all duration-200 hover:bg-white/5 active:scale-95 focus-ring ${activeSection === item.href.replace('#', '') ? 'text-white' : 'text-white/90 group-hover:text-white'}`}
                >
                  <span className="relative z-10">{item.label}</span>
                </a>
              ))}
            </div>

            {/* Right side - Theme toggle */}
            <div className="flex items-center gap-3">
              <button
                onClick={toggleTheme}
                className="group relative flex h-11 w-11 items-center justify-center rounded-xl border border-white/10 bg-white/5 backdrop-blur-md transition-all duration-200 hover:border-white/20 hover:bg-white/10 active:scale-95 focus-ring"
                aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
              >
                <div className="relative h-5 w-5">
                  <AnimatePresence mode="wait">
                    {theme === 'dark' ? (
                      <motion.svg
                        key="sun"
                        initial={{ rotate: -90, opacity: 0 }}
                        animate={{ rotate: 0, opacity: 1 }}
                        exit={{ rotate: 90, opacity: 0 }}
                        transition={{ duration: 0.2 }}
                        className="h-5 w-5 text-yellow-400"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                        strokeWidth={2}
                      >
                        <circle cx="12" cy="12" r="5" />
                        <path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42" />
                      </motion.svg>
                    ) : (
                      <motion.svg
                        key="moon"
                        initial={{ rotate: 90, opacity: 0 }}
                        animate={{ rotate: 0, opacity: 1 }}
                        exit={{ rotate: -90, opacity: 0 }}
                        transition={{ duration: 0.2 }}
                        className="h-5 w-5 text-blue-400"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                        strokeWidth={2}
                      >
                        <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
                      </motion.svg>
                    )}
                  </AnimatePresence>
                </div>
              </button>
            </div>
          </div>
        </nav>
      </motion.header>

      {/* Bottom mobile nav - fixed at bottom */}
      <div className="fixed bottom-0 left-0 right-0 z-50 md:hidden">
        <div className="mx-3 mb-3 rounded-2xl border border-white/10 bg-black/70 backdrop-blur-xl">
          <div className="flex items-center justify-around px-2 py-2">
            {navItems.map((item) => {
              const isActive = activeSection === item.href.replace('#', '')
              return (
                <a
                  key={item.label}
                  href={item.href}
                  className={`group relative flex flex-1 flex-col items-center gap-1 rounded-xl px-3 py-2.5 transition-all duration-200 active:scale-95 ${
                    isActive ? 'text-white' : 'text-white/50'
                  }`}
                >
                  {isActive && (
                    <div className="absolute inset-0 rounded-xl bg-[var(--color-forest)]/25"></div>
                  )}
                  <span className="relative">{navIcons[item.key]}</span>
                  <span className="relative text-[10px] font-medium leading-none">{item.label}</span>
                </a>
              )
            })}
          </div>
        </div>
      </div>
    </>
  )
}