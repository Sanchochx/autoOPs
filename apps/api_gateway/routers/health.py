"""Endpoint de salud del API Gateway."""

from fastapi import APIRouter

from apps.api_gateway.schemas import HealthResponse

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    """Indica que el servicio está levantado."""
    return HealthResponse(status="ok", service="api_gateway")
