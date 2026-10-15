# US-GATE-002: Implementación Base del API Gateway en FastAPI

**Épica:** 02 — API Gateway & Comunicaciones
**Prioridad:** CRÍTICA
**Estimación:** 5 pts
**Dependencias:** US-MONO-001
**Estado:** Completada

---

## Historia de Usuario

**Como** desarrollador del equipo AutoOps,
**quiero** un API Gateway base en FastAPI con CORS configurable, endpoints REST iniciales validados con Pydantic, un canal WebSocket de streaming y un script de arranque local,
**para** contar con la columna vertebral de comunicación sobre la que el frontend y el motor de IA se integrarán en las siguientes historias.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [x] **CA-1: Estructura base de FastAPI y CORS**
  - Se crea `apps/api_gateway/requirements.txt` con las dependencias: `fastapi`, `uvicorn[standard]` y `pydantic`.
  - Se inicializa la aplicación FastAPI en `apps/api_gateway/main.py`.
  - Se configura el middleware CORS (`CORSMiddleware`) leyendo los orígenes permitidos desde una variable de entorno (`CORS_ALLOWED_ORIGINS`, lista separada por comas); sin orígenes hardcodeados en el código.
  - Si la variable no está definida, el comportamiento por defecto es restrictivo (ningún origen permitido) y no una apertura con `*`.
  - **Verificación:** la app importa sin errores y una petición con cabecera `Origin` permitida recibe `Access-Control-Allow-Origin`; una no permitida, no.

- [x] **CA-2: Endpoints REST iniciales y validación con Pydantic**
  - `GET /health` retorna `200` con `{"status": "ok", "service": "api_gateway"}`.
  - `POST /api/v1/tickets` recibe un modelo Pydantic `TicketCreate` con los campos `title`, `description` y `severity`.
    - `title` y `description`: texto no vacío.
    - `severity`: valor restringido a un conjunto cerrado (enumeración).
  - Retorna `201` con el ticket creado, incluyendo un `id` UUID4 generado por el servidor.
  - Un payload inválido retorna `422` con el detalle de validación de FastAPI/Pydantic.
  - Los modelos Pydantic usan tipado estricto y viven fuera de `main.py` (módulo de esquemas).
  - **Verificación:** pruebas con `TestClient` para el caso válido (UUID4 válido en `id`) y para casos inválidos (campo faltante, `severity` fuera del conjunto, texto vacío).
  - **Nota:** en esta US no hay persistencia; el ticket se devuelve sin guardarse en base de datos.

- [x] **CA-3: Endpoint de WebSockets para Streaming**
  - Ruta WebSocket `/ws/stream`.
  - Se implementa una clase `ConnectionManager` que:
    - Gestiona la lista de conexiones activas (`connect`, `disconnect`).
    - Permite enviar un mensaje a una conexión concreta y hacer broadcast a todas.
    - Maneja `WebSocketDisconnect` eliminando la conexión de forma limpia, sin dejar conexiones huérfanas ni propagar la excepción.
  - Al conectarse, el cliente recibe un mensaje de confirmación; el endpoint hace eco de los mensajes recibidos como comportamiento mínimo verificable.
  - Los eventos de conexión y desconexión se registran mediante logging a stdout/stderr.
  - **Verificación:** prueba con `TestClient.websocket_connect` que cubre conexión, mensaje/eco y desconexión (el manager queda sin conexiones activas).

- [x] **CA-4: Script de arranque local**
  - El arranque mediante Uvicorn lee el host y el puerto desde `.env` (`HOST`, `PORT`), sin valores hardcodeados; los valores por defecto se limitan a un fallback seguro de desarrollo.
  - El gateway puede levantarse con un único comando documentado desde la raíz del monorepo.
  - Se añaden a `.env.example` las variables nuevas introducidas en esta US (`HOST`, `CORS_ALLOWED_ORIGINS`), con su sección y comentario.
  - **Verificación:** al arrancar, `GET /health` responde en el puerto configurado y cambiar `PORT` en `.env` cambia el puerto de escucha.

---

## Notas Técnicas

- **Fuera de alcance:** autenticación JWT, persistencia (SQLAlchemy/Alembic), integración con el motor de IA y servidores MCP; todo ello pertenece a otras US de la Épica 02 y siguientes.
- **Doce factores:** ninguna URL, puerto, host u origen se escribe en el código; todo proviene de variables de entorno.
- **Logging:** solo stdout/stderr; sin handlers que escriban o roten archivos.
- **Imports:** el paquete es `apps.api_gateway` (guion bajo), comando de referencia: `uvicorn apps.api_gateway.main:app`.
- **Convenciones:** archivos y funciones en `snake_case`, clases (`TicketCreate`, `ConnectionManager`) en `PascalCase`, rutas REST en `kebab-case`.
- **Pruebas:** ubicadas en `tests/` y ejecutables con `pytest tests/ -v`.
