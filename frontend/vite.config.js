import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    cors: true
    // Note: For local development, use .env.local file with:
    // VITE_CATALOG_API=http://localhost:8001/api
    // VITE_CHECKOUT_API=http://localhost:8002/api
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
})
