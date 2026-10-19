/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        background: '#1A1F2E',
        surface: '#252B3B',
        panel: '#252B3B',
        border: '#3A4156',
        accent: {
          primary: '#F0A500',
          secondary: '#C17F24',
          danger: '#CC2200',
          good: '#4A7C59',
        },
        text: {
          primary: '#E8E0D0',
          secondary: '#8A8FA8',
          accent: '#F0A500',
        },
        hud: {
          bg: 'rgba(26, 31, 46, 0.85)',
          border: '#F0A500',
        },
        steam: '#F5F0E8',
      },
      fontFamily: {
        heading: ['"Rubik Mono One"', 'sans-serif'],
        mono: ['"Space Mono"', 'monospace'],
        body: ['"Space Mono"', 'monospace'],
      },
    },
  },
  plugins: [],
}
