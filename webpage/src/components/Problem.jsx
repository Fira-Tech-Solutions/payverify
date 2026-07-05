export default function Problem() {
  return (
    <section className="bg-paperlight py-20 md:py-28">
      <div className="max-w-6xl mx-auto px-6 grid md:grid-cols-5 gap-12 items-start">
        <div className="md:col-span-2">
          <p className="font-mono text-xs tracking-widest uppercase text-rust mb-4">The scam it stops</p>
          <h2 className="font-display text-3xl font-semibold leading-tight text-ink">
            The edited screenshot that never gets flagged
          </h2>
        </div>
        <div className="md:col-span-3 font-sans text-ink/70 text-lg leading-relaxed space-y-4">
          <p>
            A customer shows a TeleBirr or CBE confirmation screen. It looks right — correct
            logo, correct layout, a believable amount. The cashier waves them through. Only at
            closing time does the shop discover the transfer never arrived, or arrived for a
            fraction of the price.
          </p>
          <p>
            BirrGuard removes the guesswork from that moment. It doesn’t trust the screen the
            customer is holding — it checks the transaction against the bank or wallet itself,
            and gives the cashier a clear stamp: matched, mismatched, or not found. The decision
            takes under two seconds and never depends on how convincing the screenshot looks.
          </p>
        </div>
      </div>
    </section>
  )
}
