# Servidores MCP

Cada servidor MCP es la **única vía** del motor de IA hacia la infraestructura y vive en su
propia imagen, sin LangGraph ni código del Gateway.

| Servidor | Carpeta | Puerto (env) | URL cliente (env) |
|---|---|---|---|
| Logs y métricas | `logs_server/` | `MCP_LOGS_PORT` | `MCP_LOGS_SERVER_URL` |
| BD (futuro) | `db_server/` | `MCP_DB_PORT` | `MCP_DB_SERVER_URL` |

## Transporte: HTTP + SSE

Los servidores usan `mcp.run(transport="sse")` (FastMCP sobre Starlette/uvicorn):
`GET /sse` abre el stream del servidor y los mensajes del cliente se envían por `POST /messages/`.
Host y puerto salen del entorno (`MCP_<NOMBRE>_HOST`, `MCP_<NOMBRE>_PORT`); el puerto es obligatorio.

## Añadir un servidor nuevo (p. ej. BD)

1. Crear `services/mcp-servers/<nombre>_server/` con `server.py`, `requirements.txt`,
   `.dockerignore` y un `Dockerfile` copiado de `logs_server/` (solo cambia el nombre del
   archivo/variables `MCP_<NOMBRE>_*`).
2. Reutilizar la convención de `_configure_network()` y de logs a stderr.
3. Declarar `MCP_<NOMBRE>_HOST`, `MCP_<NOMBRE>_PORT` y `MCP_<NOMBRE>_SERVER_URL` en `.env.example`.
4. Si necesita credenciales (BD), se inyectan solo en su contenedor, nunca en capas de la imagen.

## Imagen

```bash
docker build -t autoops-mcp-logs services/mcp-servers/logs_server
docker run --rm -p 5001:5001 -e MCP_LOGS_PORT=5001 autoops-mcp-logs
```

Usuario no-root `10001`, base `python:3.11-slim`, multi-stage (`builder` + `runtime`).

## Restricciones de runtime (para aplicar en Compose, US-DOCK-004)

```yaml
mcp-logs:
  build: ./services/mcp-servers/logs_server
  read_only: true
  cap_drop: [ALL]
  security_opt: ["no-new-privileges:true"]
  environment:
    MCP_LOGS_PORT: ${MCP_LOGS_PORT}
  expose: ["${MCP_LOGS_PORT}"]   # sin `ports:` → no se publica al host
  networks: [mcp_net]            # red interna compartida solo con el cliente MCP
networks:
  mcp_net:
    internal: true
```

Verificado: la imagen arranca con `--read-only --cap-drop ALL --security-opt no-new-privileges`.
