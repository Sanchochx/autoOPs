# US-DB-001: Configuración de ORM, Modelos y Migraciones

**Épica:** 06 — Database & Persistence
**Prioridad:** ALTA
**Estimación:** 5 pts
**Dependencias:** Fase 1 (US-GATE-002)
**Estado:** Completada

---

## Historia de Usuario

**Como** sistema con estado,
**necesito** integrar PostgreSQL en el API Gateway usando SQLAlchemy y Alembic,
**para** persistir los tickets y su estado de resolución.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [x] **CA-1: Dependencias y Configuración de Base de Datos**
  - Instalar `sqlalchemy`, `alembic` y `asyncpg` (motor estrictamente asíncrono) en `apps/api_gateway/requirements.txt`.
  - Crear `apps/api_gateway/database.py` con el motor de conexión (`create_async_engine` / `AsyncEngine`) y la fábrica de sesiones (`AsyncSession`), leyendo `DATABASE_URL` (`postgresql+asyncpg://...`) del entorno.
  - **Verificación:** el módulo importa sin errores y el motor asíncrono se conecta al contenedor PostgreSQL local (`SELECT 1`).

- [x] **CA-2: Modelos SQLAlchemy**
  - Crear `apps/api_gateway/models.py`.
  - Definir el modelo `Ticket` mapeando los campos de Pydantic: `id`, `title`, `description`, `severity`, `status`, `created_at`, `updated_at`.
  - **Verificación:** el modelo importa sin errores y `Base.metadata` contiene la tabla `tickets` con todas las columnas.

- [x] **CA-3: Configuración de Alembic**
  - Inicializar Alembic en la carpeta del Gateway.
  - Configurar `alembic/env.py` para leer `DATABASE_URL` del entorno y cargar el `Base.metadata` de los modelos.
  - **Verificación:** `alembic current` se ejecuta contra la base local sin errores.

- [x] **CA-4: Primera Migración**
  - Generar y aplicar la primera migración de esquema que cree la tabla `tickets` en la base de datos local.
  - **Comandos:** `alembic -c apps/api_gateway/alembic.ini <cmd>` desde la raíz del monorepo.
  - **Verificación:** `alembic upgrade head` crea la tabla `tickets`; `alembic downgrade base` la elimina limpiamente.

---

## Notas Técnicas

- **Fuera de alcance:** endpoints CRUD sobre la base de datos, conexión LangGraph-Gateway y Agente Ejecutor HITL (US posteriores de la Fase 2).
- **Doce factores:** `DATABASE_URL` se lee solo del entorno; sin credenciales ni URLs en el código. Se añade a `.env.example` como `DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/dbname`.
- **Aislamiento:** solo el API Gateway accede a PostgreSQL; el motor de IA nunca se conecta directamente a la base de datos.
- **Modelo de datos:** `schemas.py` se extiende con el enum `TicketStatus` (`open`, `investigating`, `pending_approval`, `resolved`) y los campos `status`, `created_at` y `updated_at` en el esquema de lectura (`TicketRead`).
- **Decisión:** código estrictamente asíncrono (`asyncpg` + `sqlalchemy.ext.asyncio`); Alembic usa el template `async`.
- **Convenciones:** archivos y funciones en `snake_case`, clases (`Ticket`, `Base`) en `PascalCase`, tabla `tickets` en plural.
- **Logging:** solo stdout/stderr; sin handlers que escriban o roten archivos.
