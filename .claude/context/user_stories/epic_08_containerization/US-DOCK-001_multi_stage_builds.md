# US-DOCK-001: Multi-Stage Builds for API Gateway and AI Engine

**Epic:** 08 — Containerization & Orchestration
**Priority:** HIGH
**Estimate:** 5 pts
**Dependencies:** US-INT-002
**Status:** Completed

---

## User Story

**As** a DevOps engineer,
**I need** to package the API Gateway and the AI Engine into independent, efficient and reproducible Docker images using multi-stage builds,
**so that** I can deploy them in isolation on any host (local VM or AWS EC2) without depending on the development environment.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each is finished and pause at the final checkpoint before closing the US.

- [x] **AC-1: API Gateway Image**
  - Create a multi-stage `apps/api_gateway/Dockerfile`: a `builder` stage that installs dependencies (`requirements.txt`) and a minimal `runtime` stage (`python:3.11-slim`) that copies only what is needed.
  - The container listens on `0.0.0.0` (`HOST`), takes `PORT` and the rest of the configuration exclusively from the environment, and emits logs to stdout/stderr.
  - **Verification:** `docker build` finishes without errors; `docker run` with injected environment variables brings up the Gateway and `GET /health` (or the existing health endpoint) responds `200`.

- [x] **AC-2: AI Engine Image**
  - Create a multi-stage `services/ai-engine/Dockerfile` with only the dependencies of `services/ai-engine/requirements.txt`, without Gateway dependencies.
  - Define and document how the engine is run in a container (see open decision in Technical Notes).
  - **Verification:** `docker build` finishes without errors; inside the container `ai_engine.graph` imports and `build_graph` compiles with a simulated model, with no network or real keys.

- [x] **AC-3: Image Efficiency and Security**
  - Add `.dockerignore` (excludes `venv/`, `.env`, `.git/`, `tests/`, `__pycache__/`, `node_modules/`).
  - Run both processes as a non-root user and without secrets embedded in layers.
  - **Verification:** `docker history`/`docker run env` show no credentials; `docker run --rm <image> id -u` returns a UID other than `0`; the final size of each image is recorded in the US summary.

---

## Technical Notes

- **Out of scope:** full `docker-compose.yml` with all services and isolated networks, frontend Dockerfile, MCP servers, reverse proxy (Traefik/Nginx), CI/CD and registry publishing. They will be covered in later USs of Epic 08 and Phase 5.
- **Open decision (close before implementing AC-2):** today the AI Engine **is not a service**: it is a library that the Gateway imports in-process (`ai_engine.graph.compiled_graph`, via `PYTHONPATH=.:services/ai-engine`). Options:
  - **A) The Gateway image includes `ai_engine`:** a single runnable image; the AI Engine image exists as a build/verification artifact and dependency base. It requires no code changes, but there is no runtime isolation.
  - **B) AI Engine as an independent service:** requires an entrypoint (e.g. internal HTTP API) and the Gateway consuming it over the network instead of importing the module. It gives real isolation, but implies a prior refactor US (changes the contract of US-INT-001/002).
  - Recommendation: A for this US and open a separate US for B if network isolation is required.
- **`PYTHONPATH`:** must be set with `ENV` in the Dockerfile (see `.env.example`), not depend on a `.env` copied into the image.
- **Environment variables:** all injected at runtime (`--env-file` or `environment:`); never `COPY .env`. Includes `DATABASE_URL`, `AI_MODEL_NAME`, provider keys and `WS_BROADCAST_TIMEOUT_SECONDS`.
- **Migrations:** Alembic is not run when the image starts in this US; it remains an explicit step (separate command) for an orchestration US.
- **Docker/Compose:** `docker-compose.yml` currently defines only PostgreSQL; it is not modified in this US unless the decision requires it.
- **Logging:** stdout/stderr, with no local files or log volumes.
- **Conventions:** a single responsibility per Dockerfile; named stages (`builder`, `runtime`); pinned base image versions (no `latest`).
