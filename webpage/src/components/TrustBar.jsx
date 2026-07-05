import { paymentMethods } from '../data'

export default function TrustBar() {
  return (
    <section className="bg-ink py-10">
      <div className="max-w-6xl mx-auto px-6">
        <p className="text-center font-mono text-[11px] uppercase tracking-widest text-paperlight/50 mb-6">
          Verifies against 8 banks and wallets, growing every quarter
        </p>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-x-6 gap-y-5">
          {paymentMethods.map((m) => (
            <div key={m.name} className="flex items-center justify-center sm:justify-start gap-2">
              <span
                className={`w-1.5 h-1.5 rounded-full ${
                  m.type === 'Bank' ? 'bg-gold' : 'bg-birr-light'
                }`}
              />
              <span className="font-sans text-sm text-paperlight/85">{m.name}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
