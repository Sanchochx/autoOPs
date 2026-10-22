# US-DOCK-002: Multi-Stage Dockerfile for the Frontend (Vite + Nginx)

**Epic:** 08 — Containerization & Orchestration
**Priority:** HIGH
**Estimate:** 3 pts
**Dependencies:** US-DOCK-001 (build conventions, `.dockerignore` and non-root user)
**Status:** Completed

---

## User Story

**As** a DevOps engineer,
**I need** to build the React/Vite dashboard in a build stage and serve only the resulting static files with Alpine Nginx,
**so that** I get a minimal image, with no Node.js or source code in production, ready to be deployed behind a reverse proxy.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each is finished and pause at the final checkpoint before closing the US.

- [x] **AC-1: Build Stage (Node)**
  - Create `apps/frontend/Dockerfile` with a `builder` stage based on `node:<pinned LTS version>-alpine` that first copies `package.json` and `package-lock.json`, runs `npm ci`, and then copies the code and runs `npm run build` (`tsc -b && vite build`).
  - The backend URLs (`VITE_API_BASE_URL`, `VITE_WS_BASE_URL`) are injected as build `ARG`s (Vite embeds them at compile time), with no default values containing credentials and no `COPY .env`.
  - **Verification:** `docker build` finishes without errors and the `dist/` bundle contains the URLs passed through `--build-arg`.

- [x] **AC-2: Runtime Stage (Alpine Nginx, non-root)**
  - `runtime` stage based on an unprivileged Alpine Nginx image (e.g. `nginxinc/nginx-unprivileged:<version>-alpine`) that only copies `dist/` and a versioned `nginx.conf` configuration in `apps/frontend/`.
  - The configuration serves the SPA with fallback to `index.html`, cache headers (immutable hashed assets, `index.html` uncached), gzip compression and basic security headers; access and error logs go to stdout/stderr.
  - **Verification:** `docker run -p 8080:8080` serves the dashboard; a deep route returns `index.html` with `200`; `docker run --rm <image> id -u` returns a UID other than `0`.

- [x] **AC-3: Efficiency and Documentation**
  - Reuse/extend the `.dockerignore` (excludes `node_modules/`, `dist/`, `.env`, `.git/`).
  - Document in `.env.example` and in the frontend README the use of the build `ARG`s and the container's listening port.
  - **Verification:** the final image contains neither Node.js nor `node_modules` and its size is recorded in the US summary.

---

## Technical Notes

- **Out of scope:** service in `docker-compose.yml` (US-DOCK-004), SSL termination and reverse proxy (Phase 5), CI/CD and registry publishing.
- **Build-time Vite variables:** `VITE_*` are not configurable at runtime with a static build; changing environment implies rebuilding the image (or introducing substitution at startup, out of scope for this US). Never include secrets in `VITE_*`: they are exposed to the browser.
- **`envDir`:** `vite.config.ts` reads `../..` (monorepo root) for `loadEnv`; the Docker build must respect that structure or depend only on process `ARG`/`ENV` variables.
- **Port:** the unprivileged image listens on a port > 1024 (8080 by default); the published port is decided by Compose.
- **CORS:** the origin from which the frontend is served must be in the Gateway's `CORS_ALLOWED_ORIGINS`.
- **Conventions:** named stages (`builder`, `runtime`); pinned base image versions (no `latest`).
