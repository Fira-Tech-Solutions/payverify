export default function Download() {
  return (
    <section id="download" className="bg-birr-dark py-20 md:py-28">
      <div className="max-w-6xl mx-auto px-6 grid md:grid-cols-5 gap-12 items-center">
        <div className="md:col-span-3">
          <p className="font-mono text-xs tracking-widest uppercase text-gold-light mb-4">Get BirrGuard</p>
          <h2 className="font-display text-3xl md:text-4xl font-semibold text-paperlight leading-tight mb-5">
            Install it on the till before your next shift
          </h2>
          <p className="font-sans text-paperlight/75 text-lg mb-8 max-w-lg">
            Direct APK install for Android 8.0 and above. A Play Store listing is in review —
            the direct download stays available either way.
          </p>

          <div className="flex flex-wrap items-center gap-4">
            <a
              href="#"
              className="inline-flex items-center gap-3 bg-paperlight text-ink font-sans font-semibold px-6 py-3.5 rounded-full hover:bg-gold-light transition-colors focus-ring"
            >
              <span aria-hidden>⬇</span> Download APK · v1.4.0 · 21 MB
            </a>
            <span className="inline-flex items-center gap-2 font-mono text-xs text-paperlight/60 border border-paperlight/25 px-4 py-2 rounded-full">
              Google Play <span className="text-gold-light">in review</span>
            </span>
          </div>

          <p className="mt-6 font-mono text-xs text-paperlight/50">
            SHA-256 checksum published on every release for shops verifying the file before install.
          </p>
        </div>

        <div className="md:col-span-2 flex justify-center">
          <div className="bg-paperlight rounded-2xl p-6 text-center w-full max-w-[240px]">
            <div className="mx-auto w-full aspect-square rounded-lg bg-ink p-3">
              <div
                className="w-full h-full rounded"
                style={{
                  backgroundImage:
                    'repeating-conic-gradient(#F6F2E7 0% 25%, #1C2320 0% 50%)',
                  backgroundSize: '18px 18px',
                }}
                role="img"
                aria-label="QR code placeholder linking to the BirrGuard APK download"
              />
            </div>
            <p className="mt-4 font-mono text-[11px] text-ink/50">Scan to open the download link</p>
          </div>
        </div>
      </div>
    </section>
  )
}
