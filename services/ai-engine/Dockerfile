# syntax=docker/dockerfile:1
# AI Engine (LangGraph). Hoy es una librería que importa el API Gateway, no un
# servicio: esta imagen aísla sus dependencias y verifica que el grafo compila.
# Su comando por defecto es una comprobación de humo (sin red ni claves reales).
# Contexto de build: raíz del monorepo.
#   docker build -f services/ai-engine/Dockerfile -t autoops-ai-engine .

# ── Etapa 1: dependencias ───────────────────────────────────────
FROM python:3.11-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY services/ai-engine/requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# ── Etapa 2: runtime mínimo ─────────────────────────────────────
FROM python:3.11-slim AS runtime

RUN groupadd --system --gid 10001 autoops \
    && useradd --system --uid 10001 --gid autoops --no-create-home \
        --shell /usr/sbin/nologin autoops

COPY --from=builder /opt/venv /opt/venv

WORKDIR /app
COPY --chown=autoops:autoops services/ai-engine/ai_engine ./ai_engine

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER autoops

# Humo: importa el grafo; falla si falta alguna dependencia o hay un error de import.
CMD ["python", "-c", "import ai_engine.graph; print('ai_engine.graph importado correctamente')"]
