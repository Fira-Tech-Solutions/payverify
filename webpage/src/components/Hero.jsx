import { useEffect, useState } from 'react'

export default function Hero() {
  const [cycle, setCycle] = useState(0)

  useEffect(() => {
    const id = setInterval(() => setCycle((c) => c + 1), 4200)
    return () => clearInterval(id)
  }, [])

  return (
    <section id="top" className="relative overflow-hidden bg-paperlight pt-32 pb-20 md:pt-40 md:pb-28">
      <div className="pointer-events-none absolute -top-40 -right-40 w-[560px] h-[560px] bg-stamp-ring" />

      <div className="max-w-6xl mx-auto px-6 grid md:grid-cols-2 gap-16 items-center">
        <div className="animate-rise">
          <p className="font-mono text-xs tracking-widest uppercase text-birr-dark mb-5">
            Built for Ethiopian tills
          </p>
          <h1 className="font-display text-4xl sm:text-5xl lg:text-[3.4rem] leading-[1.05] font-semibold text-ink">
            Know a payment is real
            <span className="block text-birr">before the customer walks out.</span>
          </h1>
          <p className="mt-6 font-sans text-lg text-ink/70 max-w-lg">
            BirrGuard checks TeleBirr, CBE, Awash, Dashen and five other Ethiopian payment
            methods against the source in seconds — by QR, by receipt photo, or by transaction
            ID. Fake screenshots stop working the day you install it.
          </p>

          <div className="mt-9 flex flex-wrap items-center gap-4">
            <a
              href="#download"
              className="font-sans font-semibold bg-ink text-paperlight px-6 py-3.5 rounded-full hover:bg-birr transition-colors focus-ring"
            >
              Download the APK
            </a>
            <a
              href="#how"
              className="font-sans font-semibold text-ink/80 px-6 py-3.5 rounded-full border border-ink/15 hover:border-birr hover:text-birr transition-colors focus-ring"
            >
              See how it verifies
            </a>
          </div>

          <div className="mt-10 flex items-center gap-6 font-mono text-xs text-ink/50">
            <span>Android 8.0+</span>
            <span className="w-1 h-1 rounded-full bg-ink/30" />
            <span>Works offline for scanning</span>
            <span className="w-1 h-1 rounded-full bg-ink/30" />
            <span>Amharic &amp; English</span>
          </div>
        </div>

        <div className="relative flex justify-center">
          {/* Phone frame */}
          <div className="relative w-[280px] sm:w-[300px] rounded-[2.4rem] border-[6px] border-ink bg-ink shadow-2xl">
            <div className="rounded-[2rem] overflow-hidden bg-paperlight aspect-[9/18.5] relative">
              {/* app header */}
              <div className="bg-birr text-paperlight px-5 pt-6 pb-4">
                <p className="font-mono text-[10px] uppercase tracking-widest opacity-80">Verify payment</p>
                <p className="font-display text-lg font-semibold mt-1">Receipt scan</p>
              </div>

              {/* receipt card */}
              <div className="px-5 -mt-2 relative">
                <div className="relative bg-white rounded-xl shadow-md p-4 font-mono text-[11px] leading-relaxed text-ink/70 overflow-hidden">
                  <div className="absolute inset-x-0 top-0 h-0.5 bg-gold/60 animate-scanline" key={cycle} />
                  <p className="text-ink font-semibold mb-2">TeleBirr Receipt</p>
                  <p>TXN: CBW4L9X2K7</p>
                  <p>Amount: ETB 640.00</p>
                  <p>To: Selam Mini-Mart</p>
                  <p>Date: 04 Jul 2026, 14:12</p>

                  {/* stamp */}
                  <div
                    key={`stamp-${cycle}`}
                    className="absolute -bottom-2 -right-3 rotate-[-8deg] animate-stamp"
                  >
                    <div className="border-[3px] border-birr text-birr rounded-lg px-3 py-1.5 font-sans font-extrabold text-sm tracking-wide bg-birr/5">
                      VERIFIED
                    </div>
                  </div>
                </div>

                <div className="mt-4 grid grid-cols-2 gap-2">
                  <div className="bg-white/70 rounded-lg px-3 py-2">
                    <p className="font-mono text-[9px] uppercase text-ink/40">Sender match</p>
                    <p className="font-sans text-xs font-semibold text-birr">Confirmed</p>
                  </div>
                  <div className="bg-white/70 rounded-lg px-3 py-2">
                    <p className="font-mono text-[9px] uppercase text-ink/40">Amount</p>
                    <p className="font-sans text-xs font-semibold text-ink">ETB 640.00</p>
                  </div>
                </div>
              </div>

              {/* bottom nav */}
              <div className="absolute bottom-0 inset-x-0 bg-white border-t border-ink/10 px-6 py-3 flex justify-between font-mono text-[9px] text-ink/40 uppercase">
                <span className="text-birr">Verify</span>
                <span>History</span>
                <span>Settings</span>
              </div>
            </div>
          </div>

          <div className="absolute -bottom-6 -left-6 bg-white rounded-xl shadow-lg px-4 py-3 font-mono text-xs hidden sm:block">
            <span className="text-ink/40">avg. check time</span>
            <p className="text-ink font-semibold text-base">1.8 sec</p>
          </div>
        </div>
      </div>
    </section>
  )
}
