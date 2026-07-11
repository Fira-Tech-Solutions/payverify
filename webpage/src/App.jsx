import { useTheme } from './hooks/useTheme'
import Navbar from './components/Navbar'
import Hero from './components/Hero'
import StatsBanner from './components/StatsBanner'
import Features from './components/Features'
import AppGallery from './components/AppGallery'
import DownloadSection from './components/DownloadSection'
import Footer from './components/Footer'

export default function App() {
  const { theme, toggleTheme } = useTheme()

  return (
    <div className="min-h-screen bg-noise pb-20 md:pb-0" style={{ backgroundColor: 'var(--color-bg)', color: 'var(--color-text)' }}>
      <Navbar theme={theme} toggleTheme={toggleTheme} />
      <main>
        <Hero />
        <StatsBanner />
        <Features />
        <AppGallery />
        <DownloadSection />
      </main>
      <Footer />
    </div>
  )
}
