# US-INT-002: Streaming de Razonamiento IA vía WebSockets

**Épica:** 07 — AI Integration
**Prioridad:** ALTA
**Estimación:** 5 pts
**Dependencias:** US-INT-001, US-GATE-002 (WebSocket y `ConnectionManager`)
**Estado:** Completada

---

## Historia de Usuario

**Como** usuario del dashboard,
**necesito** ver en tiempo real lo que la IA está pensando y haciendo mientras procesa un ticket,
**para** entender el razonamiento del agente a medida que ocurre, enviando los eventos de LangGraph a través del WebSocket del API Gateway.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [x] **CA-1: Captura de Eventos de LangGraph**
  - Modificar `process_ticket_with_ai` en `apps/api_gateway/services/ai_service.py` para usar el modo de streaming de LangGraph (`.astream_events()` o `.astream()`) en lugar de la invocación bloqueante única (`invoke()`).
  - Conservar el comportamiento de US-INT-001: el estado final alimenta la actualización de `severity` y `status`, y los fallos dejan el ticket en `medium`/`open`.
  - **Verificación:** con un grafo simulado que emite varios eventos, el servicio los consume todos en orden y obtiene el mismo estado final que con `invoke()`.

- [x] **CA-2: Emisión al WebSocket**
  - Conectar el generador de eventos asíncronos de la IA con el `ConnectionManager` de WebSockets creado en la Fase 1.
  - Enviar mensajes JSON al frontend por cada paso significativo del agente (p. ej. "Iniciando triaje", "Evaluando severidad...", "Actualizando base de datos").
  - **Verificación:** con clientes WebSocket conectados, cada paso significativo produce un mensaje JSON válido con el `ticket_id` y la descripción del paso; sin clientes conectados no se produce error.

- [x] **CA-3: No Bloqueo del Gateway**
  - Garantizar que la emisión de eventos por WebSocket se mantenga dentro de la `BackgroundTask` sin interrumpir la experiencia asíncrona.
  - **Verificación:** la respuesta `201` de `POST /api/v1/tickets` sigue sin esperar al grafo; un cliente WebSocket lento o desconectado no detiene ni hace fallar el procesamiento del ticket.

---

## Notas Técnicas

- **Fuera de alcance:** el Agente Ejecutor y el flujo HITL, el consumo de los eventos en el frontend, reintentos, colas externas (Celery, Redis) y autenticación JWT.
- **Dependencia GATE:** el `ConnectionManager` y el endpoint WebSocket (`apps/api_gateway/connection_manager.py`, `routers/ws.py`) provienen de US-GATE-002; no existe una US-GATE-003 en el plan.
- **Decisiones cerradas:**
  - **Contrato del mensaje JSON:** `{"type": "ai_event", "ticket_id": "<uuid>", "node": "<nombre_del_nodo>", "message": "<descripción de la acción>"}`.
  - **Estrategia de conexión:** broadcast global con el `ConnectionManager` existente; el frontend filtra por `ticket_id`.
  - **Método de streaming:** `compiled_graph.astream(..., stream_mode="updates")`; por cada nodo que termina se emite un evento.
- **Aislamiento MCP:** el motor de IA nunca se conecta directamente a PostgreSQL; el Gateway lee y escribe el ticket y solo pasa datos al grafo.
- **Pruebas:** mantener `dependency_overrides` y mocks; simular el grafo con un generador asíncrono de eventos y el `ConnectionManager` con un mock; no se invoca un LLM real en los tests.
- **Logging:** los errores se emiten a stdout/stderr, sin archivos locales.
- **Doce factores:** sin claves de API ni URLs en el código; todo desde variables de entorno.
- **Convenciones:** archivos y funciones en `snake_case`, clases en `PascalCase`.
