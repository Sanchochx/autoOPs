# 🚀 AutoOps - Plan de Implementación

<!--
  Estados de US (el checkbox del título es la ÚNICA fuente de verdad):
    [ ]  Pendiente
    [~]  En progreso (solo UNA a la vez)
    [x]  Completada
  El workflow (TASK_EXECUTION.md) actualiza este archivo al cerrar cada US.
-->

**Última actualización:** 2026-10-18
**Versión:** 2.3

---

## 📊 Dashboard General

```
┌─────────────────────────────────────────────────────────────┐
│  PROGRESO GLOBAL DEL PROYECTO                               │
├─────────────────────────────────────────────────────────────┤
│  Total Historias de Usuario:     23                         │
│  ✅ Completadas:                 14                         │
│  ⏳ En Progreso:                 0                          │
│  ⏸️  Pendientes:                 9                          │
│                                                             │
│  Progreso: [██████░░░░] 60% (14/23)                          │
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
| 01 | Monorepo & Base Setup | MONO | 1 | 1 | 0 | 0 | [██████████] 100% |
| 02 | API Gateway & Comunicaciones (FastAPI + WebSockets) | GATE | 1 | 1 | 0 | 0 | [██████████] 100% |
| 03 | Servidores MCP (Logs y Métricas) | MCP | 1 | 1 | 0 | 0 | [██████████] 100% |
| 04 | Motor de IA (LangGraph: Triaje e Investigación) | LANG | 1 | 1 | 0 | 0 | [██████████] 100% |
| 05 | Frontend Dashboard (React + Vite + TailwindCSS) | FRONT | 1 | 1 | 0 | 0 | [██████████] 100% |
| 06 | Database & Persistence (PostgreSQL + SQLAlchemy + Alembic) | DB | 2 | 2 | 0 | 0 | [██████████] 100% |
| 07 | AI Integration (Gateway ↔ LangGraph) | INT | 2 | 2 | 0 | 0 | [██████████] 100% |
| 08 | Containerization & Orchestration | DOCK | 4 | 4 | 0 | 0 | [██████████] 100% |
| 09 | Host Access & Identity | HOST | 3 | 1 | 0 | 2 | [███░░░░░░░] 33% |
| 10 | Network Security | NET | 2 | 0 | 0 | 2 | [░░░░░░░░░░] 0% |
| 11 | OS Hardening & Runtime | SYS | 4 | 0 | 0 | 4 | [░░░░░░░░░░] 0% |
| 12 | Provisioning | PROV | 1 | 0 | 0 | 1 | [░░░░░░░░░░] 0% |

---

## 📅 Plan de Implementación por Fases

---

# 🎯 FASE 1: FUNDACIÓN Y CORE MULTI-AGENTE (Sprint 1-2)

**Objetivo:** Construcción de los cimientos aislados de los microservicios (Gateway, IA, MCP, Frontend) y definición de contratos de comunicación, sin integración profunda ni persistencia.
**Épicas:** 01 Monorepo & Base Setup, 02 API Gateway & Comunicaciones, 03 Servidores MCP, 04 Motor de IA, 05 Frontend Dashboard
**Total US:** 5
**Progreso:** [██████████] 100% (5/5)

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

# 🎯 FASE 2: INTEGRACIÓN LÓGICA Y PERSISTENCIA

**Objetivo:** Integrar los servicios y persistir el estado: PostgreSQL, ORM, conexión LangGraph-Gateway y Agente Ejecutor HITL.
**Épicas:** 06 Database & Persistence, 07 AI Integration (resto por definir)
**Total US:** 4
**Progreso:** [██████████] 100% (4/4)

---

## Epic 06: Database & Persistence - PostgreSQL, SQLAlchemy y Alembic

**Prioridad:** ALTA
**Carpeta:** `context/user_stories/epic_06_database/`

### Historias de Usuario

#### [x] US-DB-001: Configuración de ORM, Modelos y Migraciones
- **Archivo:** `context/user_stories/epic_06_database/US-DB-001_postgresql_alembic.md`
- **Prioridad:** ALTA
- **Estimación:** 5 pts
- **Dependencias:** Fase 1 (US-GATE-002)
- **Criterios de Aceptación:** 4

#### [x] US-DB-002: Persistencia Real y CRUD de Tickets
- **Archivo:** `context/user_stories/epic_06_database/US-DB-002_tickets_crud.md`
- **Prioridad:** ALTA
- **Estimación:** 5 pts
- **Dependencias:** US-DB-001
- **Criterios de Aceptación:** 4

---

## Epic 07: AI Integration - Integración del API Gateway con LangGraph

**Prioridad:** ALTA
**Carpeta:** `context/user_stories/epic_07_integration/`

### Historias de Usuario

#### [x] US-INT-001: Disparador del Agente de Triaje en Segundo Plano
- **Archivo:** `context/user_stories/epic_07_integration/US-INT-001_langgraph_trigger.md`
- **Prioridad:** ALTA
- **Estimación:** 5 pts
- **Dependencias:** US-DB-002, US-LANG-004
- **Criterios de Aceptación:** 3

#### [x] US-INT-002: Streaming de Razonamiento IA vía WebSockets
- **Archivo:** `context/user_stories/epic_07_integration/US-INT-002_websocket_streaming.md`
- **Prioridad:** ALTA
- **Estimación:** 5 pts
- **Dependencias:** US-INT-001, US-GATE-002
- **Criterios de Aceptación:** 3

---

# 🎯 FASE 3: CONTENEDORIZACIÓN AVANZADA

**Objetivo:** Dockerfiles, Docker Compose y redes aisladas.
**Épicas:** 08 Containerization & Orchestration
**Total US:** 4
**Progreso:** [██████████] 100% (4/4)

> Orden recomendado: DOCK-001 → DOCK-002 → DOCK-003 → DOCK-004 (la orquestación integra las tres imágenes anteriores).

---

## Epic 08: Containerization & Orchestration - Dockerfiles, Docker Compose y redes aisladas

**Prioridad:** ALTA
**Carpeta:** `context/user_stories/epic_08_containerization/`

### Historias de Usuario

#### [x] US-DOCK-001: Builds Multi-Stage para API Gateway y AI Engine
- **Archivo:** `context/user_stories/epic_08_containerization/US-DOCK-001_multi_stage_builds.md`
- **Prioridad:** ALTA
- **Estimación:** 5 pts
- **Dependencias:** US-INT-002
- **Criterios de Aceptación:** 3

#### [x] US-DOCK-002: Dockerfile Multi-Stage para el Frontend (Vite + Nginx)
- **Archivo:** `context/user_stories/epic_08_containerization/US-DOCK-002_frontend_dockerfile.md`
- **Prioridad:** ALTA
- **Estimación:** 3 pts
- **Dependencias:** US-DOCK-001
- **Criterios de Aceptación:** 3

#### [x] US-DOCK-003: Dockerfiles para los Servidores MCP
- **Archivo:** `context/user_stories/epic_08_containerization/US-DOCK-003_mcp_servers_dockerfiles.md`
- **Prioridad:** ALTA
- **Estimación:** 5 pts
- **Dependencias:** US-DOCK-001, US-MCP-003
- **Criterios de Aceptación:** 3

#### [x] US-DOCK-004: Orquestación Global con Docker Compose
- **Archivo:** `context/user_stories/epic_08_containerization/US-DOCK-004_docker_compose_orchestration.md`
- **Prioridad:** ALTA
- **Estimación:** 8 pts
- **Dependencias:** US-DOCK-001, US-DOCK-002, US-DOCK-003
- **Criterios de Aceptación:** 4

---

# 🎯 FASE 4: INFRAESTRUCTURA LINUX Y SEGURIDAD

**Objetivo:** Dejar un Ubuntu Server 24.04 LTS dedicado (validado en VM limpia de VirtualBox; EC2 como destino final) endurecido y reproducible, que ejecute el stack de Compose como servicio systemd, listo para la Fase 5.
**Épicas:** 09 Host Access & Identity, 10 Network Security, 11 OS Hardening & Runtime, 12 Provisioning
**Total US:** 10 (54 pts)
**Progreso:** [█░░░░░░░░░] 10% (1/10)

> Decisiones: provisioning con **scripts Bash idempotentes + `verify.sh`** (sin Ansible); **Docker estándar** con `daemon.json` endurecido (sin rootless); `auditd`/Lynis **excluidos**.
> Orden recomendado: HOST-001 → HOST-002 → HOST-003 → NET-001 → SYS-001 → SYS-002 → NET-002 → SYS-003 → SYS-004 → PROV-001. NET-002 va tras SYS-002 porque necesita Docker instalado; PROV-001 integra todo.
> Convención: cada US aporta su script en `scripts/provision/NN_nombre.sh` y su check en `scripts/provision/checks/`; las plantillas de configuración viven en `infra/`.

---

## Epic 09: Host Access & Identity - Usuarios, SSH y protección de acceso

**Prioridad:** CRÍTICA
**Carpeta:** `context/user_stories/epic_09_host_access/`

### Historias de Usuario

#### [x] US-HOST-001: Usuarios Nativos y Modelo de Privilegios
- **Archivo:** `context/user_stories/epic_09_host_access/US-HOST-001_native_users_privileges.md`
- **Prioridad:** CRÍTICA
- **Estimación:** 5 pts
- **Dependencias:** US-DOCK-004
- **Criterios de Aceptación:** 4

#### [ ] US-HOST-002: Hardening de SSH y Gestión de Llaves
- **Archivo:** `context/user_stories/epic_09_host_access/US-HOST-002_ssh_hardening_keys.md`
- **Prioridad:** CRÍTICA
- **Estimación:** 5 pts
- **Dependencias:** US-HOST-001
- **Criterios de Aceptación:** 4

#### [ ] US-HOST-003: Protección contra Fuerza Bruta (fail2ban)
- **Archivo:** `context/user_stories/epic_09_host_access/US-HOST-003_fail2ban.md`
- **Prioridad:** ALTA
- **Estimación:** 3 pts
- **Dependencias:** US-HOST-002
- **Criterios de Aceptación:** 3

---

## Epic 10: Network Security - Firewall y coherencia Docker ↔ UFW

**Prioridad:** CRÍTICA
**Carpeta:** `context/user_stories/epic_10_network_security/`

### Historias de Usuario

#### [ ] US-NET-001: Firewall UFW con Política Deny-by-Default
- **Archivo:** `context/user_stories/epic_10_network_security/US-NET-001_ufw_firewall.md`
- **Prioridad:** CRÍTICA
- **Estimación:** 5 pts
- **Dependencias:** US-HOST-002
- **Criterios de Aceptación:** 3

#### [ ] US-NET-002: Coherencia Docker ↔ UFW
- **Archivo:** `context/user_stories/epic_10_network_security/US-NET-002_docker_ufw_coherence.md`
- **Prioridad:** CRÍTICA
- **Estimación:** 5 pts
- **Dependencias:** US-NET-001, US-SYS-002
- **Criterios de Aceptación:** 4

---

## Epic 11: OS Hardening & Runtime - Baseline del SO, Docker Engine y systemd

**Prioridad:** ALTA
**Carpeta:** `context/user_stories/epic_11_os_runtime/`

### Historias de Usuario

#### [ ] US-SYS-001: Baseline del SO y Parches Automáticos
- **Archivo:** `context/user_stories/epic_11_os_runtime/US-SYS-001_os_baseline.md`
- **Prioridad:** ALTA
- **Estimación:** 5 pts
- **Dependencias:** US-HOST-001
- **Criterios de Aceptación:** 4

#### [ ] US-SYS-002: Docker Engine en el Host y `daemon.json` Endurecido
- **Archivo:** `context/user_stories/epic_11_os_runtime/US-SYS-002_docker_engine_daemon.md`
- **Prioridad:** ALTA
- **Estimación:** 5 pts
- **Dependencias:** US-SYS-001
- **Criterios de Aceptación:** 4

#### [ ] US-SYS-003: Servicio systemd para el Stack AutoOps
- **Archivo:** `context/user_stories/epic_11_os_runtime/US-SYS-003_systemd_service.md`
- **Prioridad:** ALTA
- **Estimación:** 8 pts
- **Dependencias:** US-HOST-001, US-SYS-002, US-NET-002
- **Criterios de Aceptación:** 4

#### [ ] US-SYS-004: Backups de PostgreSQL con systemd Timer
- **Archivo:** `context/user_stories/epic_11_os_runtime/US-SYS-004_postgres_backups_timer.md`
- **Prioridad:** ALTA
- **Estimación:** 5 pts
- **Dependencias:** US-SYS-003
- **Criterios de Aceptación:** 4

---

## Epic 12: Provisioning - Bootstrap idempotente y verificación

**Prioridad:** ALTA
**Carpeta:** `context/user_stories/epic_12_provisioning/`

### Historias de Usuario

#### [ ] US-PROV-001: Bootstrap Idempotente y Verificación del Host
- **Archivo:** `context/user_stories/epic_12_provisioning/US-PROV-001_bootstrap_verify.md`
- **Prioridad:** ALTA
- **Estimación:** 8 pts
- **Dependencias:** Todas las US de las épicas 09, 10 y 11
- **Criterios de Aceptación:** 4

---

# 🎯 FASE 5: EXPOSICIÓN SEGURA Y CI/CD

**Objetivo:** Traefik/Nginx, Let's Encrypt y GitHub Actions.
**Épicas:** Por definir
**Total US:** 0 (por redactar)
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
