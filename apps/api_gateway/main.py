"""Punto de entrada del API Gateway de AutoOps (FastAPI)."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from apps.api_gateway.config import get_cors_allowed_origins
from apps.api_gateway.routers import health, tickets, ws


def create_app() -> FastAPI:
    """Construye la aplicación FastAPI con su middleware.

    Se usa una fábrica para que los orígenes CORS se lean del entorno en el
    momento de crear la app (útil para pruebas y para el arranque).
    """
    application = FastAPI(title="AutoOps API Gateway", version="0.1.0")

    application.add_middleware(
        CORSMiddleware,
        allow_origins=get_cors_allowed_origins(),
        allow_methods=["*"],
        allow_headers=["*"],
    )
    application.include_router(health.router)
    application.include_router(tickets.router)
    application.include_router(ws.router)
    return application


app = create_app()
