/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        "error": "#ef4444",
        "error-container": "#fee2e2",
        "on-error": "#ffffff",
        "on-error-container": "#991b1b",
        "primary": "#3b82f6", // Vibrant Blue
        "on-primary": "#ffffff",
        "primary-container": "#dbeafe",
        "on-primary-container": "#1e3a8a",
        "primary-fixed": "#93c5fd",
        "on-primary-fixed": "#1d4ed8",
        "secondary": "#0ea5e9", // Sky Blue
        "on-secondary": "#ffffff",
        "secondary-container": "#e0f2fe",
        "on-secondary-container": "#075985",
        "tertiary": "#8b5cf6", // Violet
        "on-tertiary": "#ffffff",
        "tertiary-container": "#ede9fe",
        "on-tertiary-container": "#4c1d95",
        "background": "#f8fafc",
        "on-background": "#0f172a",
        "surface": "#ffffff",
        "on-surface": "#0f172a",
        "surface-variant": "#f1f5f9",
        "on-surface-variant": "#475569",
        "outline": "#94a3b8",
        "outline-variant": "#cbd5e1",
        "surface-container-lowest": "#ffffff",
        "surface-container-low": "#f8fafc",
        "surface-container": "#f1f5f9",
        "surface-container-high": "#e2e8f0",
        "surface-container-highest": "#cbd5e1",
        "surface-bright": "#ffffff",
      },
      borderRadius: {
        "DEFAULT": "0.375rem",
        "md": "0.5rem",
        "lg": "0.75rem",
        "xl": "1rem",
        "2xl": "1.5rem",
        "full": "9999px"
      },
      spacing: {
        "component-padding-sm": "8px",
        "component-padding-md": "16px",
        "component-padding-lg": "24px",
        "unit": "8px",
        "gutter": "16px",
        "container-margin": "24px"
      },
      fontFamily: {
        "body-main": ["Inter"],
        "h1": ["Inter"],
        "body-sm": ["Inter"],
        "h3": ["Inter"],
        "label-caps": ["Inter"],
        "technical-data": ["Inter"],
        "h2": ["Inter"]
      },
    },
  },
  plugins: [],
}
