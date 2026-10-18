# US-DOCK-002: Dockerfile Multi-Stage para el Frontend (Vite + Nginx)

**Épica:** 08 — Containerization & Orchestration
**Prioridad:** ALTA
**Estimación:** 3 pts
**Dependencias:** US-DOCK-001 (convenciones de build, `.dockerignore` y usuario no-root)
**Estado:** Completada

---

## Historia de Usuario

**Como** ingeniero DevOps,
**necesito** compilar el dashboard React/Vite en una etapa de build y servir únicamente los estáticos resultantes con Nginx alpino,
**para** obtener una imagen mínima, sin Node.js ni código fuente en producción, lista para desplegarse detrás de un reverse proxy.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [x] **CA-1: Etapa de Build (Node)**
  - Crear `apps/frontend/Dockerfile` con una etapa `builder` basada en `node:<versión LTS fijada>-alpine` que copia primero `package.json` y `package-lock.json`, ejecuta `npm ci` y después copia el código y ejecuta `npm run build` (`tsc -b && vite build`).
  - Las URLs del backend (`VITE_API_BASE_URL`, `VITE_WS_BASE_URL`) se inyectan como `ARG` de build (Vite las incrusta en tiempo de compilación), sin valores por defecto con credenciales ni `COPY .env`.
  - **Verificación:** `docker build` termina sin errores y el bundle de `dist/` contiene las URLs pasadas por `--build-arg`.

- [x] **CA-2: Etapa Runtime (Nginx alpino, no-root)**
  - Etapa `runtime` basada en una imagen Nginx alpina sin privilegios (p. ej. `nginxinc/nginx-unprivileged:<versión>-alpine`) que solo copia `dist/` y una configuración `nginx.conf` versionada en `apps/frontend/`.
  - La configuración sirve la SPA con fallback a `index.html`, cabeceras de caché (assets con hash inmutables, `index.html` sin caché), compresión gzip y cabeceras de seguridad básicas; los logs de acceso y error van a stdout/stderr.
  - **Verificación:** `docker run -p 8080:8080` sirve el dashboard; una ruta profunda devuelve `index.html` con `200`; `docker run --rm <imagen> id -u` devuelve un UID distinto de `0`.

- [x] **CA-3: Eficiencia y Documentación**
  - Reutilizar/ampliar el `.dockerignore` (excluye `node_modules/`, `dist/`, `.env`, `.git/`).
  - Documentar en `.env.example` y en el README del frontend el uso de los `ARG` de build y el puerto de escucha del contenedor.
  - **Verificación:** la imagen final no contiene Node.js ni `node_modules` y su tamaño queda registrado en el resumen de la US.

---

## Notas Técnicas

- **Fuera de alcance:** servicio en `docker-compose.yml` (US-DOCK-004), terminación SSL y reverse proxy (Fase 5), CI/CD y publicación en registry.
- **Variables Vite en build-time:** `VITE_*` no son configurables en runtime con un build estático; cambiar de entorno implica reconstruir la imagen (o introducir sustitución en el arranque, fuera de esta US). Nunca incluir secretos en `VITE_*`: se exponen al navegador.
- **`envDir`:** `vite.config.ts` lee `../..` (raíz del monorepo) para `loadEnv`; el build en Docker debe respetar esa estructura o depender solo de variables `ARG`/`ENV` del proceso.
- **Puerto:** la imagen sin privilegios escucha en un puerto > 1024 (8080 por defecto); el puerto publicado lo decide Compose.
- **CORS:** el origen con el que se sirva el frontend debe estar en `CORS_ALLOWED_ORIGINS` del Gateway.
- **Convenciones:** etapas nombradas (`builder`, `runtime`); versiones de imagen base fijadas (sin `latest`).
