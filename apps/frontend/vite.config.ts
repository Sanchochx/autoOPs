import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'
import { defineConfig, loadEnv } from 'vite'

// El puerto del servidor de desarrollo se lee de VITE_DEV_SERVER_PORT (.env).
// Si no está definido, se usa el valor por defecto de Vite.
// Las variables se leen del .env centralizado en la raíz del monorepo.
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
