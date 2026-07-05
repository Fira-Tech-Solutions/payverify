import { steps } from '../data'

export default function HowItWorks() {
  return (
    <section id="how" className="bg-paper py-20 md:py-28 border-y border-ink/10">
      <div className="max-w-6xl mx-auto px-6">
        <div className="max-w-xl mb-14">
          <p className="font-mono text-xs tracking-widest uppercase text-birr-dark mb-4">Three ways in, one result</p>
          <h2 className="font-display text-3xl md:text-4xl font-semibold text-ink leading-tight">
            However the payment shows up, the check is the same
          </h2>
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          {steps.map((s, i) => (
            <div key={s.label} className="relative bg-paperlight rounded-2xl p-7 border border-ink/10">
              <div className="flex items-baseline justify-between mb-5">
                <span className="font-mono text-xs uppercase tracking-widest text-gold-dark">{s.label}</span>
                <span className="font-display text-3xl text-ink/15 font-semibold">0{i + 1}</span>
              </div>
              <h3 className="font-display text-xl font-semibold text-ink mb-2">{s.title}</h3>
              <p className="font-sans text-ink/65 leading-relaxed text-[15px]">{s.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
