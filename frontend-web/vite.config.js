import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: true, // Expone el frontend a toda la red local (Wi-Fi)
    port: 5173,
  },
})
