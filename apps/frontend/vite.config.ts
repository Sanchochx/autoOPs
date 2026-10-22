import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'
import { defineConfig, loadEnv } from 'vite'

// The dev server port is read from VITE_DEV_SERVER_PORT (.env).
// If undefined, Vite's default value is used.
// Variables are read from the centralized .env at the monorepo root.
const ENV_DIR = '../..'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, ENV_DIR, 'VITE_')
  const port = env.VITE_DEV_SERVER_PORT ? Number(env.VITE_DEV_SERVER_PORT) : undefined

  return {
    envDir: ENV_DIR,
    plugins: [react(), tailwindcss()],
    server: { port },
  }
})
