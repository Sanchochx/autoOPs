# syntax=docker/dockerfile:1
# API Gateway (FastAPI). El motor de IA (`ai_engine`) se importa en proceso, por
# lo que la imagen incluye también sus dependencias (decisión A de US-DOCK-001).
# Contexto de build: raíz del monorepo.
#   docker build -f apps/api_gateway/Dockerfile -t autoops-api-gateway .

# ── Etapa 1: dependencias ───────────────────────────────────────
FROM python:3.11-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Solo los requirements: la capa se cachea mientras no cambien las dependencias.
COPY apps/api_gateway/requirements.txt /tmp/gateway-requirements.txt
COPY services/ai-engine/requirements.txt /tmp/ai-engine-requirements.txt
RUN pip install -r /tmp/gateway-requirements.txt -r /tmp/ai-engine-requirements.txt

# ── Etapa 2: runtime mínimo ─────────────────────────────────────
FROM python:3.11-slim AS runtime

# Usuario sin privilegios y sin shell de login.
RUN groupadd --system --gid 10001 autoops \
    && useradd --system --uid 10001 --gid autoops --no-create-home \
        --shell /usr/sbin/nologin autoops

COPY --from=builder /opt/venv /opt/venv

WORKDIR /app
COPY --chown=autoops:autoops apps/__init__.py ./apps/__init__.py
COPY --chown=autoops:autoops apps/api_gateway ./apps/api_gateway
COPY --chown=autoops:autoops services/ai-engine/ai_engine ./services/ai-engine/ai_engine

# PYTHONUNBUFFERED: logs inmediatos a stdout/stderr. HOST/PORT son valores por
# defecto del contenedor; en ejecución se sobrescriben desde el entorno.
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONPATH=/app:/app/services/ai-engine \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    HOST=0.0.0.0 \
    PORT=8000

USER autoops

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD ["python", "-c", "import os, urllib.request; urllib.request.urlopen(f'http://127.0.0.1:{os.environ[\"PORT\"]}/health', timeout=4)"]

# Forma shell + exec: expande HOST/PORT del entorno y deja a uvicorn como PID 1.
CMD ["sh", "-c", "exec uvicorn apps.api_gateway.main:app --host \"$HOST\" --port \"$PORT\""]
