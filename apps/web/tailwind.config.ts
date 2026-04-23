/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        brand: {
          50: "rgb(236 253 245 / <alpha-value>)",
          100: "rgb(209 250 229 / <alpha-value>)",
          400: "rgb(52 211 153 / <alpha-value>)",
          500: "rgb(16 185 129 / <alpha-value>)",
          600: "rgb(5 150 105 / <alpha-value>)",
          700: "rgb(4 120 87 / <alpha-value>)",
        },
        surface: {
          900: "#0a0f1a",
          800: "#0d1420",
          700: "#111827",
          600: "#1a2233",
          500: "#1e2a3a",
          400: "#2a3a52",
          300: "#3d526b",
        },
        muted: "#4a6b8a",
      },
      fontFamily: {
        sans: ["DM Sans", "system-ui", "sans-serif"],
        mono: ["JetBrains Mono", "monospace"],
      },
      borderRadius: {
        xl: "14px",
        "2xl": "18px",
      },
      animation: {
        "fade-in": "fadeIn 0.2s ease-in-out",
        "slide-up": "slideUp 0.25s ease-out",
      },
      keyframes: {
        fadeIn: { "0%": { opacity: 0 }, "100%": { opacity: 1 } },
        slideUp: {
          "0%": { transform: "translateY(10px)", opacity: 0 },
          "100%": { transform: "translateY(0)", opacity: 1 },
        },
      },
    },
  },
  plugins: [],
};
