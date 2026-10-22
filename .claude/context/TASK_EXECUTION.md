# 📋 TASK EXECUTION WORKFLOW

**Project:** AutoOps — Self-Hosted Multi-Agent SRE Platform

**Version:** 2.0
**Last updated:** 2026-10-15

---

## 📁 Context Files

Before starting any task, review these files:

- **`@context/IMPLEMENTATION_PLAN.md`** — Master plan with user stories (US) and progress by phase
- **`@CLAUDE.md`** — Project details, tech stack and code standards

> Throughout this document, "the plan" = `@context/IMPLEMENTATION_PLAN.md`.

### Directory map (per `CLAUDE.md`)

| Path | Contents |
|------|----------|
| `apps/frontend/` | React + Vite + TypeScript + TailwindCSS (Admin dashboard) |
| `apps/api_gateway/` | FastAPI (REST, WebSockets, Auth) |
| `services/ai-engine/` | LangGraph (Triage, Investigator and Executor agents) |
| `services/mcp-servers/` | MCP servers (DB, logs and metrics isolation) |
| `context/user_stories/epic_NN_slug/` | User stories by epic |
| `context/summaries/` | Phase summaries |

> The `context/...` paths in this document and in the plan are relative to `.claude/` (that is, `.claude/context/...`).

The files of each US must be created **only** inside the directory that corresponds to its epic.

---

## 🔄 Execution Process

### 1. Find the next US

- If a US is marked `[~]` in the plan, **resume it first**.
- If there is none, take the **first `[ ]` US** in the plan and mark it `[~]` before starting (only ONE `[~]` at a time).
- Read the full US file: ALL acceptance criteria and the **Dependencies** field (if present).
- If a dependency is not `[x]`, warn the user before continuing.

```markdown
[~] US-MONO-001: Monorepo Setup
```

ID prefixes: `MONO` (Epic 01), `GATE` (Epic 02), `MCP` (Epic 03), `LANG` (Epic 04), `FRONT` (Epic 05).
If the US is marked *(to be written)* in the plan, write it first in its epic folder and ask the user for validation before implementing it.

---

### 2. Implement each acceptance criterion

**Golden rule:** work on the criteria **ONE AT A TIME**.

For each criterion:

1. **Explain what you are going to build and why** (goal and relation to the architecture).
2. **Create/modify files** in the directories defined in `CLAUDE.md`, respecting the existing structure.
3. **Apply the standards and conventions** from `CLAUDE.md`, staying consistent with the existing code.
4. **Update the affected documentation** (it is part of the US scope).
5. **Mark the criterion `[x]`** in the US file when done.

```markdown
## Acceptance Criteria

- [x] [Completed criterion]
- [ ] [Pending criterion]
```

---

### 3. Close the US

When ALL criteria are `[x]`:

1. Go through the **Verification Checklist** (at the end of this document).
2. In the plan: mark the US `[x]` (replacing `[~]`).
3. Update the dashboard (counters) and the **epic** and **phase** progress bars.

```markdown
[x] US-MONO-001: Monorepo Setup
```

---

### 4. Checkpoint (mandatory)

Show a summary and **stop to wait for confirmation**:

```
✅ US-MONO-001 Completed

Files created/modified:
- [path/file] - [purpose]

Features:
- [Implemented feature]

Technical decisions:
- [Decision and reason]

Proceed with US-MONO-002?
```

- Do not move on to the next US without explicit user approval.
- Do not do anything outside this workflow while waiting.

---

### 5. Phase summary (only when applicable)

**When:** upon completing ALL the US of a **phase** (after the checkpoint of the last US).

**Where and name:** `context/summaries/phase-[N]-resume.md`

**Contents:**

- **📝 Changes Made:** modules, core features and integrations of the phase.
- **📂 Files Modified/Created:** path, purpose and main changes of each file.
- **🎯 Rationale:** what was completed and why, how it fits in the architecture, design decisions and patterns used.
- **🚀 Next Steps:** next phase, dependencies and considerations.

**Purpose:** so that future LLM sessions understand the state of the project without rereading all the code.

---

## ⚠️ Important Guidelines

- **Architecture:** follow `CLAUDE.md` (architecture, standards, file organization, naming).
- **Zero hardcoding (Twelve-Factor):** never write credentials, API keys, URLs or ports in code; everything is read from environment variables and documented in `.env.example`.
- **MCP isolation:** the AI engine (`services/ai-engine/`) NEVER connects directly to PostgreSQL nor runs OS commands; all infrastructure interaction goes through the servers in `services/mcp-servers/`.
- **Cloud-native logging:** all services emit logs to stdout/stderr; no libraries that write or rotate local files.
- **Frontend:** TypeScript `strict` without `any`, feature-based structure (`components/`, `services/`, `models/`, `hooks/`, `index.ts`), max. ~150 lines per file, mobile-first TailwindCSS and WCAG AA accessibility (see the "Frontend Standards" section of `CLAUDE.md`).
- **Naming conventions:** Python `snake_case`; TS/React `camelCase` and `PascalCase` for components/interfaces; constants `UPPER_SNAKE_CASE`; REST routes in `/kebab-case`.
- **Branches:** `main` (production), `develop` (integration), `feature/descriptive-name`, `fix/bug-name`.
- **Incremental work:** one criterion at a time; one US at a time.
- **Commits:** do not make commits unless the user asks. If asked, keep them small and atomic (one per criterion).
- **Testing:** implementation only. Do not write tests unless the US requires them in its criteria.
- **Doubts:** if a criterion is ambiguous or conflicts with the existing architecture, ask before implementing.
- **Scope:** do not modify files outside the scope of the current US.

---

## 🎯 Best Practices

### ✅ DO
- Read the entire US before starting
- Follow the order of the plan
- Mark progress in real time
- Explain technical decisions

### ❌ DO NOT
- Skip US
- Work on several US at once
- Assume implementations without reviewing the criteria
- Move forward without user authorization

---

## 🔍 Verification Checklist

Before marking a US as complete:

- [ ] All acceptance criteria are `[x]`
- [ ] Files are in the correct directories
- [ ] The code follows the standards in `CLAUDE.md`
- [ ] No hardcoded credentials, URLs or ports; new variables added to `.env.example`
- [ ] No direct PostgreSQL/OS access from `services/ai-engine/` (only via MCP)
- [ ] Logs to stdout/stderr, no local files
- [ ] (Frontend) TypeScript strict without `any`, a11y and `:focus-visible` verified
- [ ] Documentation is up to date
- [ ] No commented-out code without a reason
- [ ] The features meet the criteria

---

## 📌 Quick Reference

| File | Purpose |
|------|---------|
| `@context/IMPLEMENTATION_PLAN.md` | Master plan with all US and progress |
| `@CLAUDE.md` | Technical details and project standards |
| `context/user_stories/` | Individual user story files (one folder per epic) |
| `context/summaries/` | Phase summaries (`phase-[N]-resume.md`) |
| `.env.example` | Centralized environment variable template |
| `docker-compose.yml` | Container orchestration (Phase 2) |

---

**Important:** workflow designed for incremental and collaborative work. Always wait for user confirmation before moving on to the next US.
