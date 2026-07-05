export default function Footer() {
  return (
    <footer className="bg-ink py-12">
      <div className="max-w-6xl mx-auto px-6 flex flex-col md:flex-row justify-between gap-8">
        <div>
          <div className="flex items-center gap-2 mb-3">
            <span className="w-7 h-7 rounded-full bg-birr flex items-center justify-center text-paperlight font-display font-semibold text-xs">
              ⛛
            </span>
            <span className="font-display text-base font-semibold text-paperlight">BirrGuard</span>
          </div>
          <p className="font-sans text-sm text-paperlight/50 max-w-xs">
            Payment verification for Ethiopian merchants. Built in Adama, for shops everywhere.
          </p>
        </div>

        <div className="flex flex-wrap gap-x-12 gap-y-6 font-sans text-sm">
          <div>
            <p className="font-mono text-[11px] uppercase tracking-widest text-paperlight/40 mb-3">Product</p>
            <ul className="space-y-2 text-paperlight/70">
              <li><a href="#how" className="hover:text-gold-light">How it works</a></li>
              <li><a href="#pricing" className="hover:text-gold-light">Pricing</a></li>
              <li><a href="#download" className="hover:text-gold-light">Download</a></li>
            </ul>
          </div>
          <div>
            <p className="font-mono text-[11px] uppercase tracking-widest text-paperlight/40 mb-3">Contact</p>
            <ul className="space-y-2 text-paperlight/70">
              <li>hello@birrguard.et</li>
              <li>+251 9XX XXX XXX</li>
              <li>Adama, Oromia, Ethiopia</li>
            </ul>
          </div>
        </div>
      </div>
      <div className="max-w-6xl mx-auto px-6 mt-10 pt-6 border-t border-paperlight/10 font-mono text-[11px] text-paperlight/35">
        © {new Date().getFullYear()} BirrGuard. All amounts shown are illustrative.
      </div>
    </footer>
  )
}
