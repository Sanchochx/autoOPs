# US-DB-002: Persistencia Real y CRUD de Tickets

**Épica:** 06 — Database & Persistence
**Prioridad:** ALTA
**Estimación:** 5 pts
**Dependencias:** US-DB-001
**Estado:** Completada

---

## Historia de Usuario

**Como** Gateway orquestador,
**necesito** que los endpoints de tickets interactúen directamente con PostgreSQL para crear, listar, leer y actualizar el estado de los tickets utilizando la sesión asíncrona de SQLAlchemy,
**para** que el estado de resolución de cada incidente sea persistente y consultable.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [x] **CA-1: Creación de Ticket (POST)**
  - Refactorizar `POST /api/v1/tickets` en `apps/api_gateway/routers/tickets.py` para que reciba la `AsyncSession` vía Dependency Injection (`Depends(get_db_session)`).
  - Guardar el ticket real en la base de datos usando el modelo SQLAlchemy `Ticket` y retornar el esquema serializado (`TicketRead`) con `201`.
  - **Verificación:** tras el `POST`, el registro existe en la tabla `tickets` con `status=open` y timestamps generados por la base de datos.

- [x] **CA-2: Listado de Tickets (GET)**
  - Crear la ruta `GET /api/v1/tickets` que devuelva una lista de todos los tickets ordenados por fecha de creación descendente (los más nuevos primero).
  - **Verificación:** con varios tickets creados, la respuesta viene ordenada por `created_at` descendente; sin tickets, retorna `200` con lista vacía.

- [x] **CA-3: Lectura por ID (GET)**
  - Crear la ruta `GET /api/v1/tickets/{ticket_id}`.
  - Si el UUID no existe, retornar un `HTTPException` `404`.
  - **Verificación:** un ID existente retorna `200` con el ticket; un UUID inexistente retorna `404`; un ID que no es UUID retorna `422`.

- [x] **CA-4: Actualización de Estado (PATCH)**
  - Crear la ruta `PATCH /api/v1/tickets/{ticket_id}`.
  - Debe aceptar un nuevo modelo Pydantic `TicketUpdate` donde todos los campos son opcionales, principalmente `status` y `severity`.
  - Actualizar el registro en base de datos y la fecha `updated_at`.
  - **Verificación:** tras el `PATCH`, el campo enviado cambia, los no enviados se conservan y `updated_at` es posterior a `created_at`; un UUID inexistente retorna `404`.

---

## Notas Técnicas

- **Fuera de alcance:** autenticación JWT, borrado de tickets, paginación y filtros, y conexión con el motor de IA (US posteriores de la Fase 2).
- **Asincronía estricta:** todos los handlers son `async def` y usan `AsyncSession`; sin llamadas bloqueantes a la base de datos.
- **Capa de esquemas:** `TicketRead` ya incluye `status`, `created_at` y `updated_at` (US-DB-001); `TicketUpdate` se añade a `schemas.py`, fuera de `routers/`.
- **Pruebas:** definir la estrategia para aislar la base de datos en `pytest` (p. ej. override de `get_db_session`) antes de implementar; los tests actuales del `POST` asumen que no hay persistencia.
- **Doce factores:** la conexión proviene solo de `DATABASE_URL`; sin credenciales en el código.
- **Convenciones:** rutas REST en `kebab-case`, archivos y funciones en `snake_case`, clases en `PascalCase`.
