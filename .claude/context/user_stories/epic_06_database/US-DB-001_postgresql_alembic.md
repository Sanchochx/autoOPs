# US-DB-001: ORM, Models and Migrations Setup

**Epic:** 06 — Database & Persistence
**Priority:** HIGH
**Estimate:** 5 pts
**Dependencies:** Phase 1 (US-GATE-002)
**Status:** Completed

---

## User Story

**As** a stateful system,
**I need** to integrate PostgreSQL into the API Gateway using SQLAlchemy and Alembic,
**so that** tickets and their resolution state are persisted.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each is finished and pause at the final checkpoint before closing the US.

- [x] **AC-1: Dependencies and Database Configuration**
  - Install `sqlalchemy`, `alembic` and `asyncpg` (strictly async engine) in `apps/api_gateway/requirements.txt`.
  - Create `apps/api_gateway/database.py` with the connection engine (`create_async_engine` / `AsyncEngine`) and the session factory (`AsyncSession`), reading `DATABASE_URL` (`postgresql+asyncpg://...`) from the environment.
  - **Verification:** the module imports without errors and the async engine connects to the local PostgreSQL container (`SELECT 1`).

- [x] **AC-2: SQLAlchemy Models**
  - Create `apps/api_gateway/models.py`.
  - Define the `Ticket` model mapping the Pydantic fields: `id`, `title`, `description`, `severity`, `status`, `created_at`, `updated_at`.
  - **Verification:** the model imports without errors and `Base.metadata` contains the `tickets` table with all columns.

- [x] **AC-3: Alembic Configuration**
  - Initialize Alembic in the Gateway folder.
  - Configure `alembic/env.py` to read `DATABASE_URL` from the environment and load the models' `Base.metadata`.
  - **Verification:** `alembic current` runs against the local database without errors.

- [x] **AC-4: First Migration**
  - Generate and apply the first schema migration that creates the `tickets` table in the local database.
  - **Commands:** `alembic -c apps/api_gateway/alembic.ini <cmd>` from the monorepo root.
  - **Verification:** `alembic upgrade head` creates the `tickets` table; `alembic downgrade base` drops it cleanly.

---

## Technical Notes

- **Out of scope:** CRUD endpoints on the database, LangGraph-Gateway connection and the HITL Executor Agent (later Phase 2 USs).
- **Twelve-Factor:** `DATABASE_URL` is read only from the environment; no credentials or URLs in the code. It is added to `.env.example` as `DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/dbname`.
- **Isolation:** only the API Gateway accesses PostgreSQL; the AI engine never connects directly to the database.
- **Data model:** `schemas.py` is extended with the `TicketStatus` enum (`open`, `investigating`, `pending_approval`, `resolved`) and the `status`, `created_at` and `updated_at` fields in the read schema (`TicketRead`).
- **Decision:** strictly async code (`asyncpg` + `sqlalchemy.ext.asyncio`); Alembic uses the `async` template.
- **Conventions:** files and functions in `snake_case`, classes (`Ticket`, `Base`) in `PascalCase`, plural `tickets` table.
- **Logging:** stdout/stderr only; no handlers that write or rotate files.
