/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        ink: '#1C2320',
        paper: '#EDE6D6',
        paperlight: '#F6F2E7',
        birr: {
          DEFAULT: '#0F6B4F',
          dark: '#0A4C38',
          light: '#17916A',
        },
        gold: {
          DEFAULT: '#D9A441',
          dark: '#B9862B',
          light: '#EFC978',
        },
        rust: '#B5482D',
      },
      fontFamily: {
        display: ['"Fraunces"', 'serif'],
        sans: ['"Inter"', 'sans-serif'],
        mono: ['"IBM Plex Mono"', 'monospace'],
      },
      backgroundImage: {
        'stamp-ring': 'radial-gradient(circle, rgba(217,164,65,0.18) 0%, rgba(217,164,65,0) 70%)',
      },
      keyframes: {
        stamp: {
          '0%': { transform: 'scale(2.2) rotate(-18deg)', opacity: '0' },
          '55%': { transform: 'scale(0.92) rotate(-8deg)', opacity: '1' },
          '70%': { transform: 'scale(1.05) rotate(-10deg)' },
          '100%': { transform: 'scale(1) rotate(-8deg)', opacity: '1' },
        },
        rise: {
          '0%': { transform: 'translateY(14px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        scanline: {
          '0%': { transform: 'translateY(0%)' },
          '100%': { transform: 'translateY(220%)' },
        },
        countupdot: {
          '0%,100%': { opacity: '0.3' },
          '50%': { opacity: '1' },
        },
      },
      animation: {
        stamp: 'stamp 0.7s cubic-bezier(.2,.8,.2,1) 0.4s both',
        rise: 'rise 0.6s ease both',
        scanline: 'scanline 2.4s ease-in-out infinite',
        countupdot: 'countupdot 1.6s ease-in-out infinite',
      },
    },
  },
  plugins: [],
}
