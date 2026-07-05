import { tiers } from '../data'

export default function Pricing() {
  return (
    <section id="pricing" className="bg-paper py-20 md:py-28 border-y border-ink/10">
      <div className="max-w-6xl mx-auto px-6">
        <div className="max-w-xl mb-14">
          <p className="font-mono text-xs tracking-widest uppercase text-birr-dark mb-4">One price per shop</p>
          <h2 className="font-display text-3xl md:text-4xl font-semibold text-ink leading-tight">
            No per-transaction fees, no per-seat surprises
          </h2>
          <p className="mt-4 font-sans text-ink/65 text-lg">
            Every plan starts with a 14-day trial, full features, no card required.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-6">
          {tiers.map((t) => (
            <div
              key={t.name}
              className={`rounded-2xl p-7 flex flex-col ${
                t.highlight
                  ? 'bg-ink text-paperlight ring-2 ring-gold relative md:-translate-y-3'
                  : 'bg-paperlight border border-ink/10'
              }`}
            >
              {t.highlight && (
                <span className="absolute -top-3 left-7 bg-gold text-ink text-[11px] font-mono uppercase tracking-widest px-3 py-1 rounded-full">
                  Most common
                </span>
              )}
              <p className={`font-mono text-xs uppercase tracking-widest mb-4 ${t.highlight ? 'text-gold' : 'text-birr-dark'}`}>
                {t.audience}
              </p>
              <h3 className="font-display text-2xl font-semibold mb-1">{t.name}</h3>
              <p className="mb-6">
                <span className="font-display text-3xl font-semibold">ETB {t.price}</span>
                <span className={`font-sans text-sm ${t.highlight ? 'text-paperlight/60' : 'text-ink/50'}`}> {t.period}</span>
              </p>
              <ul className="space-y-3 mb-8 flex-1">
                {t.features.map((f) => (
                  <li key={f} className="flex gap-2.5 font-sans text-sm">
                    <span className={t.highlight ? 'text-gold' : 'text-birr'}>✓</span>
                    <span className={t.highlight ? 'text-paperlight/85' : 'text-ink/75'}>{f}</span>
                  </li>
                ))}
              </ul>
              <a
                href="#download"
                className={`text-center font-sans font-semibold px-5 py-3 rounded-full transition-colors focus-ring ${
                  t.highlight
                    ? 'bg-gold text-ink hover:bg-gold-light'
                    : 'bg-ink text-paperlight hover:bg-birr'
                }`}
              >
                Start free trial
              </a>
            </div>
          ))}
        </div>

        <p className="mt-8 font-mono text-xs text-ink/45">
          Annual billing saves two months — e.g. ETB 1,990/year on Starter instead of ETB 2,388.
        </p>
      </div>
    </section>
  )
}
