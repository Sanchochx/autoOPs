# syntax=docker/dockerfile:1
# AI Engine (LangGraph). Today it is a library imported by the API Gateway, not a
# service: this image isolates its dependencies and verifies the graph compiles.
# Its default command is a smoke check (no network or real keys).
# Build context: monorepo root.
#   docker build -f services/ai-engine/Dockerfile -t autoops-ai-engine .

# ── Stage 1: dependencies ───────────────────────────────────────
FROM python:3.11-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY services/ai-engine/requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# ── Stage 2: minimal runtime ─────────────────────────────────────
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

# Smoke: imports the graph; fails if a dependency is missing or an import error occurs.
CMD ["python", "-c", "import ai_engine.graph; print('ai_engine.graph importado correctamente')"]
