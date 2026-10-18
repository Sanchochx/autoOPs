# AutoOps — Dashboard (React + Vite + TypeScript + TailwindCSS)

## Desarrollo

```bash
cd apps/frontend
npm install
npm run dev      # puerto desde VITE_DEV_SERVER_PORT (.env); por defecto, el de Vite
npm run build
```

Variables (ver `.env.example` en la raíz): `VITE_API_BASE_URL`, `VITE_WS_BASE_URL`, `VITE_DEV_SERVER_PORT`.

## Docker

Imagen multi-stage: `node:20-alpine` compila el bundle y `nginx:alpine` lo sirve como
estáticos con el usuario sin privilegios `nginx`. La imagen final no contiene Node ni `node_modules`.

### Build-args

Vite incrusta las variables `VITE_*` **en tiempo de compilación**, por lo que se pasan como
`--build-arg` y no como variables de entorno del contenedor. Cambiarlas exige reconstruir la imagen.
Son públicas (quedan visibles en el bundle): nunca incluir secretos.

| Build-arg | Descripción | Ejemplo |
|---|---|---|
| `VITE_API_BASE_URL` | URL base de la API REST del Gateway | `http://localhost:8000` |
| `VITE_WS_BASE_URL` | URL base de WebSockets del Gateway | `ws://localhost:8000/ws` |

```bash
docker build -t autoops-frontend \
  --build-arg VITE_API_BASE_URL=http://localhost:8000 \
  --build-arg VITE_WS_BASE_URL=ws://localhost:8000/ws \
  apps/frontend

docker run --rm -p 3000:8080 autoops-frontend   # http://localhost:3000
```

El contenedor escucha en el puerto **8080**. El origen desde el que se sirve (p. ej.
`http://localhost:3000`) debe figurar en `CORS_ALLOWED_ORIGINS` del Gateway.
