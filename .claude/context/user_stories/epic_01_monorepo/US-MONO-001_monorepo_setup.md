# US-MONO-001: Monorepo Setup

**Épica:** 01 — Monorepo & Base Setup
**Prioridad:** CRÍTICA
**Estimación:** 3 pts
**Dependencias:** Ninguna
**Estado:** Completada

---

## Historia de Usuario

**Como** desarrollador del equipo AutoOps,
**quiero** un monorepo con la estructura de directorios, el `.gitignore`, la plantilla de variables de entorno y el README definidos,
**para** que cada microservicio tenga su lugar, ningún secreto llegue al repositorio y cualquier persona pueda levantar el proyecto siguiendo una única guía.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno.

- [x] **CA-1: Árbol de directorios del monorepo**
  Se crea la estructura definida en `CLAUDE.md`:
  ```
  autoops/
  ├── apps/
  │   ├── frontend/
  │   └── api_gateway/
  ├── services/
  │   ├── ai-engine/
  │   └── mcp-servers/
  ├── .claude/
  │   ├── CLAUDE.md
  │   └── context/
  │       ├── user_stories/
  │       └── summaries/
  ├── .env.example
  ├── .gitignore
  └── README.md
  ```
  - Los directorios vacíos contienen un `.gitkeep` para que Git los versione.
  - No se escribe código de aplicación (sin `main.py`, `package.json`, etc.): solo estructura.
  - `.claude/context/` ya existe (con `IMPLEMENTATION_PLAN.md`, `TASK_EXECUTION.md` y las carpetas de épicas) y permanece ahí; no se mueve ni se sobrescribe.

- [x] **CA-2: `.gitignore` estricto**
  Un único `.gitignore` en la raíz que cubra como mínimo:
  - **Secretos:** `.env`, `.env.*` y `*.pem`, `*.key` (con excepción explícita `!.env.example`).
  - **Python:** `venv/`, `.venv/`, `__pycache__/`, `*.py[cod]`, `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`, `.coverage`, `htmlcov/`, `*.egg-info/`.
  - **Node/Frontend:** `node_modules/`, `dist/`, `.vite/`, `*.tsbuildinfo`, `npm-debug.log*`.
  - **Docker/datos locales:** volúmenes locales de datos (p. ej. `pgdata/`) y `docker-compose.override.yml`.
  - **Archivos de log:** `*.log` (coherente con la regla de logging a stdout/stderr).
  - **IDE/SO:** `.idea/`, `.vscode/` (salvo configuración compartida explícita), `.DS_Store`, `Thumbs.db`.
  - Verificación: revisión manual del patrón (`.env` ignorado, `.env.example` no); `git check-ignore -v` solo si existe repo.

- [x] **CA-3: `.env.example` centralizado**
  Plantilla única en la raíz con **todas** las variables del proyecto, agrupadas por secciones y comentadas, usando solo valores de ejemplo (nunca secretos reales):
  - **Servidor & Gateway:** `PORT`, `DEBUG`, `ENVIRONMENT`, `SECRET_KEY`
  - **Base de Datos PostgreSQL:** `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
  - **Modelos de IA & Telemetría:** `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `LANGCHAIN_TRACING_V2`, `LANGCHAIN_API_KEY`
  - **Servidores MCP:** `MCP_LOGS_SERVER_URL`, `MCP_DB_SERVER_URL`
  - **Frontend (Vite):** `VITE_API_BASE_URL`, `VITE_WS_BASE_URL`
  - Cada sección indica qué servicio consume las variables.
  - Los valores de ejemplo de claves usan placeholders obvios (`tu_clave_openai`, `cambia_esta_clave`).
  - Regla para futuras US: toda variable nueva se añade aquí en la misma US que la introduce.

- [x] **CA-4: `README.md` raíz**
  Documento en español que incluye:
  1. Descripción breve de AutoOps y su propósito (soporte Tier-1 autónomo con agentes Triaje/Investigador/Ejecutor y HITL).
  2. Stack tecnológico resumido.
  3. Árbol del monorepo con una línea de propósito por directorio.
  4. Prerrequisitos (Python 3.11+, Node.js, PostgreSQL; Docker en Fase 2).
  5. Primeros pasos: clonar, `cp .env.example .env`, y enlaces a los comandos de backend/frontend (marcados como "disponibles tras las US correspondientes").
  6. Principios clave: Twelve-Factor (cero hardcoding), aislamiento vía MCP, logging a stdout/stderr.
  7. Flujo de trabajo SDD: enlaces a `context/IMPLEMENTATION_PLAN.md` y `context/TASK_EXECUTION.md`, y estrategia de ramas (`main`, `develop`, `feature/*`, `fix/*`).

- [x] **CA-5: Validación final de la estructura**
  - `find` / `tree` del repo muestra exactamente el árbol de CA-1 (sin carpetas sobrantes).
  - `git status` (solo si el repo ya existe; no se inicializa en esta US) no lista `.env` ni artefactos ignorados.
  - Todas las variables de `CLAUDE.md` aparecen en `.env.example` y viceversa (sin diferencias).
  - Todos los enlaces relativos del README resuelven a archivos existentes.

---

## Notas Técnicas

- **Fuera de alcance:** código de aplicación, Dockerfiles, `docker-compose.yml` (Fase 2), CI (US-MONO-003), configuración/logging compartido (US-MONO-002).
- **Nombre de directorio:** `apps/api_gateway/` (guion bajo) para mantener compatibilidad con imports de Python y el comando `uvicorn apps.api_gateway.main:app`.
- **Ubicación de `context/`:** permanece en `.claude/context/` (decisión confirmada).
- **Git:** NO se inicializa el repositorio en esta US (decisión confirmada); `git check-ignore` y `git status` de CA-2/CA-5 se validan solo cuando exista el repo, o se difieren.
