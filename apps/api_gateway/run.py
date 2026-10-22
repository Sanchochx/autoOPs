"""Local startup of the API Gateway.

Usage (from the monorepo root): ``python -m apps.api_gateway.run``
Reads ``HOST`` and ``PORT`` from the environment (loading ``.env`` if present).
"""

import os

import uvicorn

from apps.api_gateway.config import load_dotenv

DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 8000


def main() -> None:
    """Start Uvicorn with the host and port configured via the environment."""
    load_dotenv()
    host = os.getenv("HOST", DEFAULT_HOST)
    port = int(os.getenv("PORT", str(DEFAULT_PORT)))
    reload = os.getenv("DEBUG", "").lower() == "true"
    uvicorn.run("apps.api_gateway.main:app", host=host, port=port, reload=reload)


if __name__ == "__main__":
    main()
