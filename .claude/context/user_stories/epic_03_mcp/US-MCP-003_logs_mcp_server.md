# US-MCP-003: Servidor MCP de Inspección de Logs y Métricas Simuladas

**Épica:** 03 — MCP Servers
**Prioridad:** ALTA
**Estimación:** 5 pts
**Dependencias:** US-GATE-002
**Estado:** Completada

---

## Historia de Usuario

**Como** orquestador de IA,
**necesito** un servidor Model Context Protocol (MCP) que exponga herramientas seguras para consultar logs y métricas,
**para** que el Agente Investigador pueda inspeccionar el estado del sistema sin tener acceso directo a la infraestructura.

---

## Criterios de Aceptación

> Trabajar UNO A LA VEZ, en orden. Marcar `[x]` al terminar cada uno y hacer pausa en el checkpoint final antes de cerrar la US.

- [x] **CA-1: Estructura del Servidor MCP**
  - Se crea la carpeta `services/mcp-servers/logs_server/`.
  - Se crea `requirements.txt` con la librería oficial `mcp` (SDK de Anthropic), usando su `FastMCP` (`mcp.server.fastmcp`) para declarar herramientas con decoradores.
  - Se crea `server.py` que inicializa el servidor MCP, preparado para comunicación estándar vía `stdio`.
  - **Verificación:** `server.py` importa sin errores y el servidor se instancia con un nombre identificable.

- [x] **CA-2: Herramienta `get_system_logs`**
  - Se expone una tool MCP que recibe el argumento `service_name` (ej. `"api_gateway"`, `"database"`).
  - Retorna un array (o string) con 5 líneas de logs recientes simulados de nivel error/info para ese servicio.
  - **Verificación:** al invocarla con un servicio válido devuelve exactamente 5 líneas que referencian dicho servicio.

- [x] **CA-3: Herramienta `get_db_metrics`**
  - Se expone una tool MCP sin argumentos.
  - Retorna un payload JSON simulado con la salud de la base de datos: conexiones activas, uso de CPU y transacciones lentas.
  - **Verificación:** la respuesta es JSON válido y contiene los tres campos indicados.

- [x] **CA-4: Configuración de ejecución**
  - `server.py` incluye el bloque `if __name__ == "__main__":` que arranca el servidor por `stdio`.
  - El servidor queda listo para ser lanzado como subproceso por un cliente (por ejemplo, LangGraph).
  - **Verificación:** `python services/mcp-servers/logs_server/server.py` arranca y queda a la espera por stdio sin errores.

---

## Notas Técnicas

- **Aislamiento (MCP):** el servidor no se conecta a PostgreSQL ni ejecuta comandos del SO; los datos son simulados en esta US.
- **Logging:** solo stdout/stderr. En transporte `stdio`, stdout es el canal del protocolo: los logs de diagnóstico deben ir a **stderr**.
- **Doce factores:** sin credenciales, URLs ni puertos en el código; cualquier variable nueva se documenta en `.env.example`.
- **Fuera de alcance:** conexión real a logs/métricas, integración con el motor de IA, transporte HTTP/SSE.
- **Convenciones:** archivos y funciones en `snake_case`.
