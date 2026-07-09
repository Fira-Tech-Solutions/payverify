/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        forest: {
          DEFAULT: '#276B47',
          light: '#3A855D',
          dark: '#17452E',
        },
        obsidian: {
          DEFAULT: '#080C0A',
          light: '#1A231F',
        },
        gold: {
          DEFAULT: '#E8B82E',
          muted: '#B88F2E',
        },
        surface: {
          DEFAULT: '#0E1612',
          light: '#141E19',
        },
        foreground: '#F2EDE4',
        muted: '#998E7A',
        border: '#262E2A',
        destructive: '#D43D3D',
      },
      fontFamily: {
        display: ['"Playfair Display"', 'serif'],
        sans: ['"DM Sans"', 'sans-serif'],
        mono: ['"IBM Plex Mono"', 'monospace'],
      },
      borderRadius: {
        '2xl': '1rem',
        '3xl': '1.5rem',
      },
      keyframes: {
        'fade-in-up': {
          '0%': { opacity: '0', transform: 'translateY(24px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'pulse-glow': {
          '0%, 100%': { boxShadow: '0 0 20px rgba(39, 107, 71, 0.3)' },
          '50%': { boxShadow: '0 0 40px rgba(39, 107, 71, 0.6)' },
        },
        shimmer: {
          '0%': { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-12px)' },
        },
        scanline: {
          '0%': { transform: 'translateY(0%)' },
          '100%': { transform: 'translateY(280%)' },
        },
        stamp: {
          '0%': { transform: 'scale(2.5) rotate(-20deg)', opacity: '0' },
          '50%': { transform: 'scale(0.9) rotate(-8deg)', opacity: '1' },
          '70%': { transform: 'scale(1.08) rotate(-10deg)' },
          '100%': { transform: 'scale(1) rotate(-8deg)', opacity: '1' },
        },
      },
      animation: {
        'fade-in-up': 'fade-in-up 0.7s ease-out forwards',
        'pulse-glow': 'pulse-glow 3s ease-in-out infinite',
        shimmer: 'shimmer 2s linear infinite',
        float: 'float 6s ease-in-out infinite',
        scanline: 'scanline 2.8s ease-in-out infinite',
        stamp: 'stamp 0.8s cubic-bezier(.2,.8,.2,1) 0.5s both',
      },
    },
  },
  plugins: [],
}
