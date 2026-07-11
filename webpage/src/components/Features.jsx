import { motion } from 'framer-motion'
import { features, paymentMethods } from '../data'

const iconMap = {
  qr: (
    <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 4.875c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5A1.125 1.125 0 013.75 9.375v-4.5zM3.75 14.625c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5a1.125 1.125 0 01-1.125-1.125v-4.5zM13.5 4.875c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5A1.125 1.125 0 0113.5 9.375v-4.5z" />
      <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 6.75h.75v.75h-.75v-.75zM6.75 16.5h.75v.75h-.75v-.75zM16.5 6.75h.75v.75h-.75v-.75zM13.5 13.5h.75v.75h-.75v-.75zM13.5 19.5h.75v.75h-.75v-.75zM19.5 13.5h.75v.75h-.75v-.75zM19.5 19.5h.75v.75h-.75v-.75zM16.5 16.5h.75v.75h-.75v-.75z" />
    </svg>
  ),
  receipt: (
    <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
    </svg>
  ),
  bank: (
    <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 21v-8.25M15.75 21v-8.25M8.25 21v-8.25M3 9l9-6 9 6m-1.5 12V10.332A48.36 48.36 0 0012 9.75c-2.551 0-5.056.2-7.5.582V21M3 21h18M12 6.75h.008v.008H12V6.75z" />
    </svg>
  ),
  offline: (
    <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M9.348 14.651a3.75 3.75 0 010-5.303m5.304 0a3.75 3.75 0 010 5.303m-7.425 2.122a6.75 6.75 0 010-9.546m9.546 0a6.75 6.75 0 010 9.546M5.106 18.894c-3.808-3.808-3.808-9.98 0-13.789m13.788 0c3.808 3.808 3.808 9.981 0 13.79M12 12h.008v.007H12V12zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z" />
    </svg>
  ),
}

const container = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.1 },
  },
}

const item = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5, ease: [0.25, 0.46, 0.45, 0.94] } },
}

export default function Features() {
  return (
    <section id="features" className="relative py-20 sm:py-28 overflow-x-hidden">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-20"
        >
          <p className="text-xs font-semibold uppercase tracking-wider text-[var(--color-forest)]">
            The Problem & Solution
          </p>
          <h2 className="mt-3 font-display text-3xl font-bold text-white sm:text-4xl lg:text-5xl">
            Fake Screenshots Stop Here
          </h2>
          <p className="mx-auto mt-5 max-w-2xl text-base leading-relaxed text-white/90">
            Every verification goes directly to the bank or wallet API. No more guessing, no more fraud.
          </p>
        </motion.div>

        {/* Bento grid */}
        <motion.div
          variants={container}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: '-100px' }}
          className="grid gap-6 sm:grid-cols-3"
        >
          {features.map((feature) => (
            <motion.div
              key={feature.id}
              variants={item}
              className={`group relative rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-6 sm:p-8 transition-all duration-300 hover:scale-[1.02] hover:border-white/20 hover:bg-white/10 ${feature.span}`}
            >
              <div
                className="mb-5 flex h-14 w-14 items-center justify-center rounded-xl border border-white/10 transition-all duration-300 group-hover:scale-110 group-hover:border-white/20"
                style={{ backgroundColor: `${feature.color}15`, color: feature.color }}
              >
                {iconMap[feature.icon]}
              </div>
              <h3 className="text-lg font-bold text-white">
                {feature.title}
              </h3>
              <p className="mt-2.5 text-sm leading-relaxed text-white/80">
                {feature.description}
              </p>
            </motion.div>
          ))}
        </motion.div>

        {/* Payment methods bar with real icons */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mt-20 rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-8 sm:p-10"
        >
          <p className="mb-8 text-center text-xs font-semibold uppercase tracking-wider text-white/60">
            Supported Payment Methods
          </p>
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4 lg:grid-cols-7">
            {paymentMethods.map((method) => (
              <motion.div
                key={method.name}
                whileHover={{ scale: 1.05 }}
                className="group flex flex-col items-center gap-3 rounded-xl border border-white/10 bg-white/5 p-5 transition-all duration-300 hover:border-white/20 hover:bg-white/10"
              >
                <div className="flex h-14 w-14 items-center justify-center overflow-hidden rounded-xl border border-white/10 bg-white/5 transition-all group-hover:border-white/20">
                  <img
                    src={method.icon}
                    alt={method.name}
                    className="h-10 w-10 object-contain"
                    loading="lazy"
                  />
                </div>
                <div className="text-center">
                  <p className="text-xs font-semibold text-white">{method.name}</p>
                  <p className="text-[10px] text-white/60">{method.type}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  )
}
