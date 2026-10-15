# US-FRONT-005: Dashboard Admin e Integración de WebSockets

**Épica:** 05 — Frontend Dashboard
**Prioridad:** MEDIA
**Estimación:** 5 pts
**Dependencias:** US-LANG-004
**Estado:** Pendiente

---

## Historia de Usuario

**Como** agente de soporte,
**necesito** una interfaz gráfica construida en React y Vite que muestre los tickets y se conecte al servidor de WebSockets,
**para** observar el razonamiento del motor de IA en tiempo real.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [ ] **CA-1: Inicialización de React y TailwindCSS**
  - Se genera el proyecto base con Vite (React + TypeScript) dentro de `apps/frontend/`.
  - Se instalan y configuran `tailwindcss`, `postcss` y `autoprefixer` según la documentación oficial.
  - Se instalan `zustand` (estado) y `lucide-react` (iconografía básica).
  - `tsconfig` en modo `strict: true`.
  - **Verificación:** `npm run build` termina sin errores y una clase de Tailwind aplicada en `App.tsx` se refleja en el navegador.

- [ ] **CA-2: Store y Cliente WebSocket**
  - Se crea el store de Zustand `store/useAiStore.ts` con un arreglo de `logs` (mensajes de agentes) y acciones para añadirlos y limpiarlos, con tipos en `models/`.
  - Se crea el custom hook `hooks/useWebSocket.ts` que:
    - abre la conexión a la URL derivada de `VITE_WS_BASE_URL`;
    - reconecta automáticamente si la conexión cae (espera creciente, con límite);
    - despacha los mensajes entrantes al store;
    - cierra la conexión y cancela reintentos al desmontar.
  - Los mensajes entrantes se validan con `unknown` + type guard (sin `any`).
  - **Verificación:** al levantar el Gateway, el hook conecta y los mensajes llegan al store; al detener y reiniciar el Gateway, reconecta solo.

- [ ] **CA-3: Componentes de UI Básicos**
  - `DashboardLayout.tsx`: layout principal con barra lateral (Sidebar) y área principal, usando CSS Grid y enfoque mobile-first.
  - `AgentConsole.tsx`: vista tipo terminal de fondo oscuro que se suscribe al store y renderiza la lista de mensajes de la IA.
  - Accesibilidad: la consola usa `role="log"` y `aria-live="polite"`, contraste WCAG AA y `:focus-visible` en elementos interactivos.
  - La lógica vive en hooks; los componentes solo renderizan (máx. ~150 líneas por archivo).
  - **Verificación:** al llegar mensajes por WebSocket, la consola los muestra en orden y se desplaza al más reciente.

- [ ] **CA-4: Integración y Limpieza**
  - Se elimina el código por defecto de Vite (`App.css`, logos giratorios, contador de ejemplo).
  - `App.tsx` ensambla `DashboardLayout` y `AgentConsole`.
  - `npm run dev` lee el puerto desde `.env` (variable nueva en `.env.example`) y, si no está definida, usa el valor por defecto de Vite.
  - **Verificación:** `npm run dev` levanta en el puerto configurado y la app no contiene restos de la plantilla de Vite.

---

## Notas Técnicas

- **Estructura por features** (CLAUDE.md): `components/`, `hooks/`, `models/`, `services/` e `index.ts`; el cliente WebSocket va en `services/` y el hook lo consume. Las rutas de CA-2 y CA-3 se ubican dentro de esa estructura bajo `apps/frontend/src/`.
- **URL del WebSocket:** `VITE_WS_BASE_URL` ya incluye el prefijo `/ws` (`ws://localhost:8000/ws`); el endpoint del Gateway es `/ws/stream`, por lo que el cliente compone `${VITE_WS_BASE_URL}/stream`. Sin URLs hardcodeadas.
- **Alcance real del streaming:** hoy `/ws/stream` solo confirma la conexión y hace eco; el motor de IA aún no emite razonamiento al Gateway. La consola mostrará esos mensajes hasta que otra US conecte ambos.
- **Dependencia efectiva:** requiere el Gateway de US-GATE-002 (`/ws/stream`) y CORS configurado con el origen del frontend (`CORS_ALLOWED_ORIGINS`).
- **Puerto de desarrollo:** Vite solo expone al código las variables con prefijo `VITE_`; el puerto del servidor de desarrollo se lee en `vite.config.ts` con `loadEnv`.
- **Rendimiento:** limitar el tamaño del arreglo de logs y evitar re-renders innecesarios en el componente vinculado al stream.
- **Fuera de alcance:** autenticación, tabla de tickets, modal de aprobación HITL y llamadas REST.
- **Convenciones:** TypeScript `camelCase` para variables y funciones, `PascalCase` para componentes e interfaces; TailwindCSS para estilos.
