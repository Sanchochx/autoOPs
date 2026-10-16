# Resumen de Fase 2: Integración Lógica y Persistencia

**Proyecto:** AutoOps — Plataforma SRE Multi-Agente Autohospedada
**Fecha de cierre:** 2026-10-15
**Estado:** Completada (4/4 US)

| US | Épica | Commit |
|----|-------|--------|
| US-DB-001 Configuración de ORM, modelos y migraciones | 06 | `c734e2f` |
| US-DB-002 Persistencia real y CRUD de tickets | 06 | `fcdd971` |
| US-INT-001 Disparador del Agente de Triaje en segundo plano | 07 | `6000403` (cierre `c5551f4`) |
| US-INT-002 Streaming de razonamiento IA vía WebSockets | 07 | `b3750c3` |

---

## 📝 Changes Made

- **Persistencia:** PostgreSQL asíncrono (SQLAlchemy + asyncpg), modelo `Ticket` y migración inicial con Alembic. `docker-compose.yml` levanta la base de datos local con credenciales desde el entorno.
- **CRUD de tickets:** endpoints REST persistentes bajo `/api/v1/tickets`, probados con sesión simulada.
- **Disparador de IA:** `POST /api/v1/tickets` guarda el ticket (`severity=medium`, `status=open`), responde `201` y encola el triaje con `BackgroundTasks`.
- **Servicio de IA (`ai_service.py`):** `process_ticket_with_ai` abre su propia sesión, ejecuta el grafo y actualiza `severity` y `status=investigating`. Ante fallo conserva el estado previo y no propaga la excepción.
- **Streaming:** el grafo se consume con `astream(stream_mode="updates")` y cada nodo emite un evento JSON `{"type":"ai_event","ticket_id","node","message"}` por broadcast global.

## 📂 Files Modified/Created

| Ruta | Propósito |
|------|-----------|
| `apps/api_gateway/{database,models}.py`, `alembic/` | Conexión asíncrona, modelo `Ticket` y migraciones |
| `apps/api_gateway/routers/tickets.py` | CRUD y encolado del triaje |
| `apps/api_gateway/services/ai_service.py` | Invocación, streaming y persistencia post-triaje |
| `tests/test_ai_service.py`, `tests/test_rest_endpoints.py` | Pruebas con grafo, sesión y `ConnectionManager` simulados (27 tests en total) |
| `.env.example` | `DATABASE_URL`, `WS_BROADCAST_TIMEOUT_SECONDS`, `PYTHONPATH` |

## 🎯 Rationale

- **Qué se completó y por qué:** el flujo ticket → triaje con IA → persistencia → eventos en tiempo real funciona de extremo a extremo y fue validado manualmente (BD, LangSmith y `wscat`).
- **Decisiones de diseño:**
  - **Sesión propia en la tarea de fondo:** la sesión de la petición ya está cerrada.
  - **Aislamiento:** el motor de IA no toca PostgreSQL; el Gateway lee y escribe el ticket y solo pasa datos al grafo.
  - **Emisión tolerante a fallos:** `broadcast` con timeout configurable; un cliente lento o caído no detiene el triaje.
  - **Broadcast global:** el frontend filtra por `ticket_id`.
  - **Dependencias inyectables** (`graph`, `session_factory`, `ws_manager`) para probar sin LLM ni red.

### Alcance entregado frente al objetivo original
El objetivo mencionaba el **Agente Ejecutor con HITL**, que **no se implementó**. Tampoco están:
- El cliente MCP real en el investigador (solo el punto de inyección `context_provider`).
- Autenticación JWT.
- El consumo de los eventos `ai_event` y la tabla de tickets en el frontend.
- El AI Engine sigue siendo una librería importada en proceso por el Gateway, no un servicio.

## 🚀 Next Steps

1. **Fase 3 (contenerización):** Epic 08, US-DOCK-001 (builds multi-stage). Decisión abierta: AI Engine como librería dentro de la imagen del Gateway (A) o como servicio independiente (B).
2. **Pendientes de producto:** Agente Ejecutor y HITL, cliente MCP real, JWT y consumo de `ai_event` en el frontend; deben asignarse a una fase.
3. **Migraciones:** definir cómo se ejecuta Alembic en contenedor.
