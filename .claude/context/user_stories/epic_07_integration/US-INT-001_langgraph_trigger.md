# US-INT-001: Disparador del Agente de Triaje en Segundo Plano

**Épica:** 07 — AI Integration
**Prioridad:** ALTA
**Estimación:** 5 pts
**Dependencias:** US-DB-002, US-LANG-004
**Estado:** Pendiente

---

## Historia de Usuario

**Como** orquestador,
**necesito** que al crear un nuevo ticket (`POST`), el API Gateway lance el motor de LangGraph en segundo plano para que el Agente de Triaje asigne la severidad real,
**para** clasificar los incidentes automáticamente sin bloquear la respuesta HTTP al cliente.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [ ] **CA-1: Background Tasks en FastAPI**
  - Modificar `POST /api/v1/tickets` para inyectar `BackgroundTasks` de FastAPI.
  - El endpoint debe guardar el ticket en BD con severidad inicial `medium` y estado `open`, encolar la tarea de IA y responder inmediatamente `201`.
  - **Verificación:** la respuesta `201` llega sin esperar al grafo; el ticket queda en BD con `severity=medium` y `status=open`; la tarea de IA queda encolada con el `ticket_id` creado.

- [ ] **CA-2: Servicio de Invocación de LangGraph**
  - Crear `apps/api_gateway/services/ai_service.py`.
  - Crear la función asíncrona `process_ticket_with_ai(ticket_id, db_session)` que busque el ticket en la base de datos y llame al grafo compilado (`compiled_graph.invoke()`).
  - **Verificación:** con un `ticket_id` existente, el servicio carga el ticket y invoca el grafo con su contenido; con un ID inexistente, termina sin invocar el grafo y sin propagar la excepción.

- [ ] **CA-3: Actualización Post-Triaje**
  - Al terminar la ejecución de LangGraph, tomar el estado resultante (`AgentState`) y usarlo para actualizar la `severity` del ticket en la base de datos y cambiar su `status` a `investigating`.
  - **Verificación:** tras la tarea, el ticket persistido tiene la `severity` devuelta por el Agente de Triaje y `status=investigating`; si el grafo falla, el ticket conserva `severity=medium` y `status=open` y el error se registra en stdout/stderr.

---

## Notas Técnicas

- **Fuera de alcance:** el Agente Ejecutor y el flujo HITL, el streaming del razonamiento por WebSocket, reintentos y colas externas (Celery, Redis), y autenticación JWT.
- **Sesión propia de la tarea:** la sesión de `Depends(get_db_session)` se cierra al terminar la petición; la tarea en segundo plano debe abrir su propia sesión (p. ej. con `get_session_factory()`) y no reutilizar la de la petición. Es una decisión a cerrar antes de implementar `process_ticket_with_ai(ticket_id, db_session)`.
- **Grafo síncrono:** `compiled_graph.invoke()` es bloqueante; ejecutarlo con `asyncio.to_thread` (o usar `ainvoke`) para no bloquear el event loop. Es una decisión a cerrar antes de implementar.
- **Aislamiento MCP:** el motor de IA nunca se conecta directamente a PostgreSQL; el Gateway lee y escribe el ticket y solo pasa datos al grafo.
- **Pruebas:** mantener la estrategia de `dependency_overrides` con `AsyncMock` de la sesión y simular `compiled_graph` con un mock; no se invoca un LLM real en los tests.
- **Logging:** los errores de la tarea en segundo plano se emiten a stdout/stderr, sin archivos locales.
- **Doce factores:** sin claves de API ni URLs en el código; todo desde variables de entorno.
- **Convenciones:** archivos y funciones en `snake_case`, clases en `PascalCase`.
