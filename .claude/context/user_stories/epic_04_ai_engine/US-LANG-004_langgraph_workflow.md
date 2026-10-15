# US-LANG-004: Grafo Base de Agentes (Triaje e Investigación)

**Épica:** 04 — AI Engine (LangGraph)
**Prioridad:** CRÍTICA
**Estimación:** 8 pts
**Dependencias:** US-MCP-003
**Estado:** Completada

---

## Historia de Usuario

**Como** sistema autónomo,
**necesito** un motor multi-agente basado en LangGraph que procese un ticket entrante, clasifique su severidad mediante un Agente de Triaje y luego invoque a un Agente Investigador preparado para usar herramientas MCP,
**para** contar con el flujo base de análisis sobre el que se construirán la investigación real y el Agente Ejecutor.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [x] **CA-1: Estructura base e instanciación**
  - Se crea la carpeta `services/ai-engine/`.
  - Se crea `requirements.txt` con `langgraph`, `langchain-anthropic`, `langchain-core`, `pydantic` y `mcp<2` (cliente MCP).
  - El modelo y su clave se configuran por variables de entorno (`ANTHROPIC_API_KEY` ya existe; el nombre del modelo se añade a `.env.example`); sin valores hardcodeados.
  - **Verificación:** las dependencias se instalan y los módulos del paquete importan sin errores.

- [x] **CA-2: Definición del Estado del Grafo (`state.py`)**
  - Se crea `AgentState` (`TypedDict`) con los campos: `ticket_id`, `description`, `severity`, `agent_notes`, `status` y `messages` (historial de mensajes de LangChain, con el reducer `add_messages`).
  - `severity` se restringe a `low | medium | high | critical` (mismos valores que `TicketSeverity` del Gateway).
  - **Verificación:** el estado se importa y un diccionario de ejemplo cumple el tipado.

- [x] **CA-3: Nodos Iniciales (`nodes.py`)**
  - `triage_node`: usa un prompt base para analizar `description` y asigna una severidad válida; si el modelo devuelve un valor fuera del conjunto, aplica un valor por defecto seguro y lo registra.
  - `investigator_node`: reacciona a la severidad y registra en `agent_notes` el contexto técnico recopilado; deja un punto de inyección explícito para el cliente MCP (sin conectarlo todavía).
  - Cada nodo recibe el modelo/cliente como dependencia inyectada, para poder probarlos con un modelo falso sin llamar a la API.
  - **Verificación:** pruebas con un modelo falso: el triaje devuelve una severidad válida y el investigador añade notas sin romper el estado.

- [x] **CA-4: Enrutamiento y Compilación (`graph.py`)**
  - Se configura el flujo `START -> triage_node -> investigator_node -> END`.
  - Se expone el grafo compilado como `compiled_graph`, invocable externamente.
  - **Verificación:** `compiled_graph.invoke(...)` con un modelo falso recorre ambos nodos y devuelve el estado final con `severity` y `agent_notes` poblados.

---

## Notas Técnicas

- **Aislamiento (MCP):** el motor de IA NUNCA se conecta a PostgreSQL ni ejecuta comandos del SO; la infraestructura solo se consulta mediante servidores MCP. En esta US el cliente MCP queda como punto de inyección, sin conexión real.
- **Doce factores:** modelo, claves y rutas de servidores MCP provienen de variables de entorno, documentadas en `.env.example`.
- **Logging:** solo stdout/stderr.
- **Fuera de alcance:** conexión efectiva al servidor MCP de logs, Agente Ejecutor, aprobación HITL, integración con el Gateway y persistencia del estado.
- **Convenciones:** archivos y funciones en `snake_case`; clases y tipos en `PascalCase`.
