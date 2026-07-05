import Navbar from './components/Navbar'
import Hero from './components/Hero'
import TrustBar from './components/TrustBar'
import Problem from './components/Problem'
import HowItWorks from './components/HowItWorks'
import Analytics from './components/Analytics'
import Pricing from './components/Pricing'
import Download from './components/Download'
import Faq from './components/Faq'
import Footer from './components/Footer'

export default function App() {
  return (
    <div className="font-sans text-ink">
      <Navbar />
      <main>
        <Hero />
        <TrustBar />
        <Problem />
        <HowItWorks />
        <Analytics />
        <Pricing />
        <Download />
        <Faq />
      </main>
      <Footer />
    </div>
  )
}
