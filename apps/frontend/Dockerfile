# syntax=docker/dockerfile:1
# Frontend (React + Vite). Se compila con Node y se sirve como estáticos con
# Nginx sin privilegios. Contexto de build: apps/frontend.
#   docker build -t autoops-frontend \
#     --build-arg VITE_API_BASE_URL=http://localhost:8000 \
#     --build-arg VITE_WS_BASE_URL=ws://localhost:8000/ws \
#     apps/frontend

# ── Etapa 1: build ──────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Vite incrusta las VITE_* en el bundle durante el build (son públicas: sin secretos).
ARG VITE_API_BASE_URL
ARG VITE_WS_BASE_URL
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL \
    VITE_WS_BASE_URL=$VITE_WS_BASE_URL

# Solo los manifiestos: la capa de dependencias se cachea mientras no cambien.
COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# ── Etapa 2: runtime ────────────────────────────────────────────
FROM nginx:alpine AS runtime

# Configuración completa de Nginx (reemplaza la por defecto, que exige root).
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=builder /app/dist /usr/share/nginx/html

# Escribe solo en /tmp (pid y temporales, ver nginx.conf); el contenido es de solo lectura.
USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD ["wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8080/"]

CMD ["nginx", "-g", "daemon off;"]
