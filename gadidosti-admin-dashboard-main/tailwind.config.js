/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ["class"],
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: "#1976FF",
          dark: "#1565C0",
          light: "#42A5F5",
          50: "#E3F2FD",
          100: "#BBDEFB",
        },
        secondary: {
          DEFAULT: "#041E42",
          dark: "#02122B",
          light: "#0A2E5C",
        },
        tertiary: {
          DEFAULT: "#17D86B",
          dark: "#12B85A",
          light: "#4EE88A",
        },
        neutral: {
          DEFAULT: "#F8FAFC",
          50: "#F8FAFC",
          100: "#F1F5F9",
          200: "#E2E8F0",
          300: "#CBD5E1",
          400: "#94A3B8",
          500: "#64748B",
          600: "#475569",
          700: "#334155",
          800: "#1E293B",
          900: "#0F172A",
        },
        success: "#17D86B",
        warning: "#F59E0B",
        danger: "#EF4444",
        info: "#1976FF",
        sidebar: {
          DEFAULT: "#041E42",
          hover: "#0A2E5C",
          active: "#1976FF",
        },
      },
      fontFamily: {
        poppins: ['Poppins', 'sans-serif'],
        inter: ['Inter', 'sans-serif'],
      },
      borderRadius: {
        xl: "12px",
        lg: "10px",
        md: "8px",
        sm: "6px",
        xs: "4px",
      },
      boxShadow: {
        card: "0 1px 3px rgba(0, 0, 0, 0.08), 0 1px 2px rgba(0, 0, 0, 0.04)",
        dropdown: "0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)",
        modal: "0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)",
      },
      keyframes: {
        "shimmer": {
          "0%": { backgroundPosition: "-200% 0" },
          "100%": { backgroundPosition: "200% 0" },
        },
        "fade-in": {
          "0%": { opacity: "0", transform: "translateY(8px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        "slide-in-left": {
          "0%": { transform: "translateX(-100%)" },
          "100%": { transform: "translateX(0)" },
        },
      },
      animation: {
        "shimmer": "shimmer 1.5s ease-in-out infinite",
        "fade-in": "fade-in 0.3s ease-out",
        "slide-in-left": "slide-in-left 0.3s ease-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
}
