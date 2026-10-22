# MCP Servers

Each MCP server is the AI engine's **only path** to the infrastructure and lives in its
own image, without LangGraph or Gateway code.

| Server | Folder | Port (env) | Client URL (env) |
|---|---|---|---|
| Logs and metrics | `logs_server/` | `MCP_LOGS_PORT` | `MCP_LOGS_SERVER_URL` |
| DB (future) | `db_server/` | `MCP_DB_PORT` | `MCP_DB_SERVER_URL` |

## Transport: HTTP + SSE

Servers use `mcp.run(transport="sse")` (FastMCP on Starlette/uvicorn):
`GET /sse` opens the server stream and client messages are sent via `POST /messages/`.
Host and port come from the environment (`MCP_<NAME>_HOST`, `MCP_<NAME>_PORT`); the port is mandatory.

## Adding a new server (e.g. DB)

1. Create `services/mcp-servers/<name>_server/` with `server.py`, `requirements.txt`,
   `.dockerignore` and a `Dockerfile` copied from `logs_server/` (only the file name and
   the `MCP_<NAME>_*` variables change).
2. Reuse the `_configure_network()` convention and logging to stderr.
3. Declare `MCP_<NAME>_HOST`, `MCP_<NAME>_PORT` and `MCP_<NAME>_SERVER_URL` in `.env.example`.
4. If it needs credentials (DB), they are injected only into its container, never into image layers.

## Image

```bash
docker build -t autoops-mcp-logs services/mcp-servers/logs_server
docker run --rm -p 5001:5001 -e MCP_LOGS_PORT=5001 autoops-mcp-logs
```

Non-root user `10001`, `python:3.11-slim` base, multi-stage (`builder` + `runtime`).

## Runtime restrictions (to apply in Compose, US-DOCK-004)

```yaml
mcp-logs:
  build: ./services/mcp-servers/logs_server
  read_only: true
  cap_drop: [ALL]
  security_opt: ["no-new-privileges:true"]
  environment:
    MCP_LOGS_PORT: ${MCP_LOGS_PORT}
  expose: ["${MCP_LOGS_PORT}"]   # no `ports:` → not published to the host
  networks: [mcp_net]            # internal network shared only with the MCP client
networks:
  mcp_net:
    internal: true
```

Verified: the image starts with `--read-only --cap-drop ALL --security-opt no-new-privileges`.
