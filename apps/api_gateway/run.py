"""Arranque local del API Gateway.

Uso (desde la raíz del monorepo): ``python -m apps.api_gateway.run``
Lee ``HOST`` y ``PORT`` del entorno (cargando ``.env`` si existe).
"""

import os

import uvicorn

from apps.api_gateway.config import load_dotenv

DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 8000


def main() -> None:
    """Levanta Uvicorn con el host y puerto configurados por entorno."""
    load_dotenv()
    host = os.getenv("HOST", DEFAULT_HOST)
    port = int(os.getenv("PORT", str(DEFAULT_PORT)))
    reload = os.getenv("DEBUG", "").lower() == "true"
    uvicorn.run("apps.api_gateway.main:app", host=host, port=port, reload=reload)


if __name__ == "__main__":
    main()
