# 🚀 AutoOps - Plan de Implementación

<!--
  Estados de US (el checkbox del título es la ÚNICA fuente de verdad):
    [ ]  Pendiente
    [~]  En progreso (solo UNA a la vez)
    [x]  Completada
  El workflow (TASK_EXECUTION.md) actualiza este archivo al cerrar cada US.
-->

**Última actualización:** 2026-10-15
**Versión:** 2.0

---

## 📊 Dashboard General

```
┌─────────────────────────────────────────────────────────────┐
│  PROGRESO GLOBAL DEL PROYECTO                               │
├─────────────────────────────────────────────────────────────┤
│  Total Historias de Usuario:     7                          │
│  ✅ Completadas:                 5                          │
│  ⏳ En Progreso:                 0                          │
│  ⏸️  Pendientes:                 2                          │
│                                                             │
│  Progreso: [███████░░░] 71% (5/7)                           │
└─────────────────────────────────────────────────────────────┘
```

<!--
  Barra de progreso de referencia (10 caracteres):
  0%   → [░░░░░░░░░░]    50%  → [█████░░░░░]
  10%  → [█░░░░░░░░░]    60%  → [██████░░░░]
  20%  → [██░░░░░░░░]    70%  → [███████░░░]
  30%  → [███░░░░░░░]    80%  → [████████░░]
  40%  → [████░░░░░░]    90%  → [█████████░]
                          100% → [██████████]
-->

---

## 🎯 Progreso por Épica

| Epic | Nombre | Prefijo | Total US | Completadas | En Progreso | Pendientes | Progreso |
|------|--------|---------|----------|-------------|-------------|------------|----------|
| 01 | Monorepo & Base Setup | MONO | 3 | 1 | 0 | 2 | [███░░░░░░░] 33% |
| 02 | API Gateway & Comunicaciones (FastAPI + WebSockets) | GATE | 1 | 1 | 0 | 0 | [██████████] 100% |
| 03 | Servidores MCP (Logs y Métricas) | MCP | 1 | 1 | 0 | 0 | [██████████] 100% |
| 04 | Motor de IA (LangGraph: Triaje e Investigación) | LANG | 1 | 1 | 0 | 0 | [██████████] 100% |
| 05 | Frontend Dashboard (React + Vite + TailwindCSS) | FRONT | 1 | 1 | 0 | 0 | [██████████] 100% |

---

## 📅 Plan de Implementación por Fases

---

# 🎯 FASE 1: FUNDACIÓN Y CORE MULTI-AGENTE (Sprint 1-2)

**Objetivo:** Entregar el flujo end-to-end en desarrollo local (sin contenedores): ticket → triaje → investigación vía MCP → plan de remediación con aprobación HITL, visible en tiempo real en el dashboard.
**Épicas:** 01 Monorepo & Base Setup, 02 API Gateway & Comunicaciones, 03 Servidores MCP, 04 Motor de IA, 05 Frontend Dashboard
**Total US:** 7
**Progreso:** [███████░░░] 71% (5/7)

> Orden recomendado de ejecución: 01 → 02 → 03 → 04 → 05 (MCP depende del Gateway; el motor de IA necesita MCP y el Gateway; el Frontend consume el Gateway). Las dependencias de cada US son la fuente de verdad.

---

## Epic 01: Monorepo & Base Setup - Estructura, configuración y calidad base

**Prioridad:** CRÍTICA
**Carpeta:** `context/user_stories/epic_01_monorepo/`

### Historias de Usuario

#### [x] US-MONO-001: Monorepo Setup
- **Archivo:** `context/user_stories/epic_01_monorepo/US-MONO-001_monorepo_setup.md`
- **Prioridad:** CRÍTICA
- **Estimación:** 3 pts
- **Dependencias:** Ninguna
- **Criterios de Aceptación:** 5

#### [ ] US-MONO-002: Configuración 12-Factor y Logging Cloud-Native compartidos
- **Archivo:** `context/user_stories/epic_01_monorepo/US-MONO-002_config_logging_base.md` *(por redactar)*
- **Prioridad:** CRÍTICA
- **Estimación:** 3 pts
- **Dependencias:** US-MONO-001
- **Criterios de Aceptación:** Por definir

#### [ ] US-MONO-003: Pipeline CI Base (lint + tests)
- **Archivo:** `context/user_stories/epic_01_monorepo/US-MONO-003_ci_base.md` *(por redactar)*
- **Prioridad:** MEDIA
- **Estimación:** 3 pts
- **Dependencias:** US-MONO-001
- **Criterios de Aceptación:** Por definir

---

## Epic 02: API Gateway & Comunicaciones - FastAPI, REST y WebSockets

**Prioridad:** ALTA
**Carpeta:** `context/user_stories/epic_02_gateway/`

### Historias de Usuario

#### [x] US-GATE-002: Implementación Base del API Gateway en FastAPI
- **Archivo:** `context/user_stories/epic_02_gateway/US-GATE-002_fastapi_gateway.md`
- **Prioridad:** CRÍTICA
- **Estimación:** 5 pts
- **Dependencias:** US-MONO-001
- **Criterios de Aceptación:** 4

---

## Epic 03: Servidores MCP - Inspección de Logs y Métricas

**Prioridad:** ALTA
**Carpeta:** `context/user_stories/epic_03_mcp/`

### Historias de Usuario

#### [x] US-MCP-003: Servidor MCP de Inspección de Logs y Métricas Simuladas
- **Archivo:** `context/user_stories/epic_03_mcp/US-MCP-003_logs_mcp_server.md`
- **Prioridad:** ALTA
- **Estimación:** 5 pts
- **Dependencias:** US-GATE-002
- **Criterios de Aceptación:** 4

---

## Epic 04: Motor de IA - LangGraph (Triaje e Investigación)

**Prioridad:** CRÍTICA
**Carpeta:** `context/user_stories/epic_04_ai_engine/`

### Historias de Usuario

#### [x] US-LANG-004: Grafo Base de Agentes (Triaje e Investigación)
- **Archivo:** `context/user_stories/epic_04_ai_engine/US-LANG-004_langgraph_workflow.md`
- **Prioridad:** CRÍTICA
- **Estimación:** 8 pts
- **Dependencias:** US-MCP-003
- **Criterios de Aceptación:** 4

---

## Epic 05: Frontend Dashboard - React + Vite + TailwindCSS

**Prioridad:** MEDIA
**Carpeta:** `context/user_stories/epic_05_frontend/`

### Historias de Usuario

#### [x] US-FRONT-005: Dashboard Admin e Integración de WebSockets
- **Archivo:** `context/user_stories/epic_05_frontend/US-FRONT-005_react_dashboard.md`
- **Prioridad:** MEDIA
- **Estimación:** 5 pts
- **Dependencias:** US-LANG-004
- **Criterios de Aceptación:** 4

---

# 🎯 FASE 2: CONTENEDORIZACIÓN AVANZADA (Sprint 3-4)

**Objetivo:** Contenerizar el ecosistema y automatizar el despliegue en Ubuntu Server (AWS EC2 / VirtualBox).
**Épicas:** Por definir (Docker Compose, Reverse Proxy Traefik/Nginx + SSL Let's Encrypt, CI/CD GitHub Actions por SSH)
**Total US:** 0 (sin historias por ahora; el foco es 100% la Fase 1)
**Progreso:** [░░░░░░░░░░] 0% (0/0)

---

## 📝 Notas de Implementación

### Cómo usar este plan

1. **Seguir el orden de las fases** — empezar siempre por la Fase 1
2. **Trabajo incremental** — completar una US antes de avanzar
3. **Marcar progreso** con el checkbox del título: `[ ]` pendiente, `[~]` en progreso (solo UNA), `[x]` completada
4. **Actualizar métricas** — al cerrar cada US: dashboard, fila de la épica en la tabla, barra de la fase y "Última actualización"
5. **Leer el archivo de cada US** — contiene los criterios de aceptación detallados
6. **Redactar la US antes de implementarla** — las marcadas *(por redactar)* no tienen archivo todavía; se escriben (y se validan con el usuario) justo antes de empezar

### Referencias del proyecto

- **Nota de rutas:** `context/...` es relativo a `.claude/` (ubicación definitiva: `.claude/context/`)
- **Historias de usuario:** `context/user_stories/`
- **Workflow de ejecución:** `@context/TASK_EXECUTION.md`
- **Resúmenes de fase:** `context/summaries/`
- **Detalles técnicos:** `@CLAUDE.md`
