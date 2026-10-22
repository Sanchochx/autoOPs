"""Health endpoint of the API Gateway."""

from fastapi import APIRouter

from apps.api_gateway.schemas import HealthResponse

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    """Report that the service is up."""
    return HealthResponse(status="ok", service="api_gateway")
