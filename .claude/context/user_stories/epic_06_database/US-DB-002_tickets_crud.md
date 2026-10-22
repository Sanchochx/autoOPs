# US-DB-002: Real Persistence and Ticket CRUD

**Epic:** 06 — Database & Persistence
**Priority:** HIGH
**Estimate:** 5 pts
**Dependencies:** US-DB-001
**Status:** Completed

---

## User Story

**As** the orchestrating Gateway,
**I need** the ticket endpoints to interact directly with PostgreSQL to create, list, read and update ticket state using the SQLAlchemy async session,
**so that** the resolution state of each incident is persistent and queryable.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each is finished and pause at the final checkpoint before closing the US.

- [x] **AC-1: Ticket Creation (POST)**
  - Refactor `POST /api/v1/tickets` in `apps/api_gateway/routers/tickets.py` so that it receives the `AsyncSession` via Dependency Injection (`Depends(get_db_session)`).
  - Save the real ticket in the database using the SQLAlchemy `Ticket` model and return the serialized schema (`TicketRead`) with `201`.
  - **Verification:** after the `POST`, the record exists in the `tickets` table with `status=open` and database-generated timestamps.

- [x] **AC-2: Ticket Listing (GET)**
  - Create the `GET /api/v1/tickets` route that returns a list of all tickets ordered by creation date descending (newest first).
  - **Verification:** with several tickets created, the response is ordered by `created_at` descending; with no tickets, it returns `200` with an empty list.

- [x] **AC-3: Read by ID (GET)**
  - Create the `GET /api/v1/tickets/{ticket_id}` route.
  - If the UUID does not exist, return an `HTTPException` `404`.
  - **Verification:** an existing ID returns `200` with the ticket; a nonexistent UUID returns `404`; an ID that is not a UUID returns `422`.

- [x] **AC-4: State Update (PATCH)**
  - Create the `PATCH /api/v1/tickets/{ticket_id}` route.
  - It must accept a new Pydantic model `TicketUpdate` where all fields are optional, mainly `status` and `severity`.
  - Update the database record and the `updated_at` date.
  - **Verification:** after the `PATCH`, the submitted field changes, unsent fields are preserved and `updated_at` is later than `created_at`; a nonexistent UUID returns `404`.

---

## Technical Notes

- **Out of scope:** JWT authentication, ticket deletion, pagination and filters, and connection to the AI engine (later Phase 2 USs).
- **Strict asynchrony:** all handlers are `async def` and use `AsyncSession`; no blocking database calls.
- **Schema layer:** `TicketRead` already includes `status`, `created_at` and `updated_at` (US-DB-001); `TicketUpdate` is added to `schemas.py`, outside `routers/`.
- **Tests:** define the strategy for isolating the database in `pytest` (e.g. overriding `get_db_session`) before implementing; the current `POST` tests assume there is no persistence.
- **Twelve-Factor:** the connection comes only from `DATABASE_URL`; no credentials in the code.
- **Conventions:** REST routes in `kebab-case`, files and functions in `snake_case`, classes in `PascalCase`.
