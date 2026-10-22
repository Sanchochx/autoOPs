# US-FRONT-005: Admin Dashboard and WebSocket Integration

**Epic:** 05 — Frontend Dashboard
**Priority:** MEDIUM
**Estimate:** 5 pts
**Dependencies:** US-LANG-004
**Status:** Completed

---

## User Story

**As** a support agent,
**I need** a graphical interface built with React and Vite that shows tickets and connects to the WebSocket server,
**so that** I can observe the AI engine's reasoning in real time.

---

## Acceptance Criteria

> Work ONE AT A TIME, in order. Mark `[x]` when each one is finished and pause at the final checkpoint before closing the US.

- [x] **AC-1: React and TailwindCSS initialization**
  - The base project is generated with Vite (React + TypeScript) inside `apps/frontend/`.
  - `tailwindcss`, `postcss` and `autoprefixer` are installed and configured per the official documentation.
  - `zustand` (state) and `lucide-react` (basic iconography) are installed.
  - `tsconfig` in `strict: true` mode.
  - **Verification:** `npm run build` finishes without errors and a Tailwind class applied in `App.tsx` is reflected in the browser.

- [x] **AC-2: Store and WebSocket Client**
  - The Zustand store `store/useAiStore.ts` is created with a `logs` array (agent messages) and actions to add and clear them, with types in `models/`.
  - The custom hook `hooks/useWebSocket.ts` is created, which:
    - opens the connection to the URL derived from `VITE_WS_BASE_URL`;
    - reconnects automatically if the connection drops (increasing wait, with a cap);
    - dispatches incoming messages to the store;
    - closes the connection and cancels retries on unmount.
  - Incoming messages are validated with `unknown` + type guard (no `any`).
  - **Verification:** when the Gateway is brought up, the hook connects and messages reach the store; when the Gateway is stopped and restarted, it reconnects on its own.

- [x] **AC-3: Basic UI Components**
  - `DashboardLayout.tsx`: main layout with a sidebar (Sidebar) and main area, using CSS Grid and a mobile-first approach.
  - `AgentConsole.tsx`: terminal-style dark-background view that subscribes to the store and renders the list of AI messages.
  - Accessibility: the console uses `role="log"` and `aria-live="polite"`, WCAG AA contrast and `:focus-visible` on interactive elements.
  - Logic lives in hooks; components only render (max ~150 lines per file).
  - **Verification:** when messages arrive over WebSocket, the console shows them in order and scrolls to the latest.

- [x] **AC-4: Integration and Cleanup**
  - The default Vite code is removed (`App.css`, spinning logos, sample counter).
  - `App.tsx` assembles `DashboardLayout` and `AgentConsole`.
  - `npm run dev` reads the port from `.env` (new variable in `.env.example`) and, if not defined, uses Vite's default value.
  - **Verification:** `npm run dev` starts on the configured port and the app contains no leftovers from the Vite template.

---

## Technical Notes

- **Feature-based structure** (CLAUDE.md): `components/`, `hooks/`, `models/`, `services/` and `index.ts`; the WebSocket client goes in `services/` and the hook consumes it. The paths in AC-2 and AC-3 are located within that structure under `apps/frontend/src/`.
- **WebSocket URL:** `VITE_WS_BASE_URL` already includes the `/ws` prefix (`ws://localhost:8000/ws`); the Gateway endpoint is `/ws/stream`, so the client composes `${VITE_WS_BASE_URL}/stream`. No hardcoded URLs.
- **Actual streaming scope:** today `/ws/stream` only confirms the connection and echoes; the AI engine does not yet emit reasoning to the Gateway. The console will show those messages until another US connects both.
- **Effective dependency:** requires the Gateway from US-GATE-002 (`/ws/stream`) and CORS configured with the frontend origin (`CORS_ALLOWED_ORIGINS`).
- **Development port:** Vite only exposes variables prefixed with `VITE_` to the code; the development server port is read in `vite.config.ts` with `loadEnv`.
- **Performance:** limit the size of the logs array and avoid unnecessary re-renders in the component bound to the stream.
- **Tailwind v4:** the current official documentation uses the `@tailwindcss/vite` plugin; `postcss` and `autoprefixer` are no longer needed and were not installed.
- **Out of scope:** authentication, tickets table, HITL approval modal and REST calls.
- **Conventions:** TypeScript `camelCase` for variables and functions, `PascalCase` for components and interfaces; TailwindCSS for styles.
