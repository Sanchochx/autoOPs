# syntax=docker/dockerfile:1
# Servidor MCP de logs y métricas (transporte HTTP + SSE). Sin credenciales: los
# datos son simulados y no se necesitan claves de BD ni de IA.
# Contexto de build: services/mcp-servers/logs_server
#   docker build -t autoops-mcp-logs services/mcp-servers/logs_server
#   docker run --rm -p 5001:5001 -e MCP_LOGS_PORT=5001 autoops-mcp-logs

# ── Etapa 1: dependencias ───────────────────────────────────────
FROM python:3.11-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Dependencias antes que el código: la capa se cachea mientras no cambien.
COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# ── Etapa 2: runtime mínimo ─────────────────────────────────────
FROM python:3.11-slim AS runtime

RUN groupadd --system --gid 10001 autoops \
    && useradd --system --uid 10001 --gid autoops --no-create-home \
        --shell /usr/sbin/nologin autoops

COPY --from=builder /opt/venv /opt/venv

WORKDIR /app
COPY --chown=autoops:autoops server.py ./server.py

# 0.0.0.0 para ser alcanzable desde otros contenedores; el aislamiento lo da la
# red (sin publicar al host). El puerto (MCP_LOGS_PORT) es obligatorio y se
# inyecta en runtime. Sin bytecode ni escritura en disco: apto para --read-only.
ENV PATH="/opt/venv/bin:$PATH" \
    MCP_LOGS_HOST=0.0.0.0 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER 10001:10001

CMD ["python", "server.py"]
