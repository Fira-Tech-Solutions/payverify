import { useState } from 'react'
import { faqs } from '../data'

function FaqItem({ item, isOpen, onToggle }) {
  return (
    <div className="border-b border-ink/10 py-5">
      <button
        onClick={onToggle}
        className="w-full flex items-center justify-between text-left gap-4 focus-ring rounded"
        aria-expanded={isOpen}
      >
        <span className="font-display text-lg font-semibold text-ink">{item.q}</span>
        <span
          className={`shrink-0 w-7 h-7 rounded-full border border-ink/20 flex items-center justify-center font-sans text-lg transition-transform ${
            isOpen ? 'rotate-45 text-birr border-birr' : 'text-ink/50'
          }`}
        >
          +
        </span>
      </button>
      {isOpen && <p className="mt-3 font-sans text-ink/65 leading-relaxed max-w-2xl">{item.a}</p>}
    </div>
  )
}

export default function Faq() {
  const [openIndex, setOpenIndex] = useState(0)

  return (
    <section id="faq" className="bg-paperlight py-20 md:py-28">
      <div className="max-w-3xl mx-auto px-6">
        <p className="font-mono text-xs tracking-widest uppercase text-birr-dark mb-4">Questions</p>
        <h2 className="font-display text-3xl md:text-4xl font-semibold text-ink leading-tight mb-8">
          Before you install
        </h2>
        <div>
          {faqs.map((item, i) => (
            <FaqItem
              key={item.q}
              item={item}
              isOpen={openIndex === i}
              onToggle={() => setOpenIndex(openIndex === i ? -1 : i)}
            />
          ))}
        </div>
      </div>
    </section>
  )
}
