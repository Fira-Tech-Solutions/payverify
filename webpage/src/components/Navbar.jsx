import { useEffect, useState } from 'react'

const links = [
  { href: '#how', label: 'How it works' },
  { href: '#analytics', label: 'Analytics' },
  { href: '#pricing', label: 'Pricing' },
  { href: '#faq', label: 'FAQ' },
]

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false)
  const [open, setOpen] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12)
    window.addEventListener('scroll', onScroll)
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  return (
    <header
      className={`fixed top-0 inset-x-0 z-50 transition-colors duration-300 ${
        scrolled ? 'bg-paperlight/90 backdrop-blur border-b border-ink/10' : 'bg-transparent'
      }`}
    >
      <nav className="max-w-6xl mx-auto flex items-center justify-between px-6 py-4">
        <a href="#top" className="flex items-center gap-2 focus-ring rounded">
          <span className="w-8 h-8 rounded-full bg-birr flex items-center justify-center text-paperlight font-display font-semibold text-sm">
            ⛛
          </span>
          <span className="font-display text-lg font-semibold tracking-tight">BirrGuard</span>
        </a>

        <div className="hidden md:flex items-center gap-8 font-sans text-sm text-ink/80">
          {links.map((l) => (
            <a key={l.href} href={l.href} className="hover:text-birr transition-colors focus-ring rounded">
              {l.label}
            </a>
          ))}
        </div>

        <div className="hidden md:block">
          <a
            href="#download"
            className="font-sans text-sm font-semibold bg-ink text-paperlight px-4 py-2 rounded-full hover:bg-birr transition-colors focus-ring"
          >
            Download APK
          </a>
        </div>

        <button
          className="md:hidden w-9 h-9 flex flex-col items-center justify-center gap-1.5 focus-ring rounded"
          onClick={() => setOpen((o) => !o)}
          aria-label="Toggle menu"
          aria-expanded={open}
        >
          <span className={`block w-5 h-0.5 bg-ink transition-transform ${open ? 'translate-y-2 rotate-45' : ''}`} />
          <span className={`block w-5 h-0.5 bg-ink transition-opacity ${open ? 'opacity-0' : ''}`} />
          <span className={`block w-5 h-0.5 bg-ink transition-transform ${open ? '-translate-y-2 -rotate-45' : ''}`} />
        </button>
      </nav>

      {open && (
        <div className="md:hidden bg-paperlight border-t border-ink/10 px-6 py-4 flex flex-col gap-4 font-sans text-sm">
          {links.map((l) => (
            <a key={l.href} href={l.href} onClick={() => setOpen(false)} className="text-ink/80">
              {l.label}
            </a>
          ))}
          <a
            href="#download"
            onClick={() => setOpen(false)}
            className="mt-2 text-center font-semibold bg-ink text-paperlight px-4 py-2 rounded-full"
          >
            Download APK
          </a>
        </div>
      )}
    </header>
  )
}
