"""Esquemas Pydantic del API Gateway."""

from enum import Enum
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class TicketSeverity(str, Enum):
    """Niveles de severidad permitidos para un ticket."""

    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class TicketCreate(BaseModel):
    """Payload de entrada para crear un ticket."""

    model_config = ConfigDict(str_strip_whitespace=True)

    title: str = Field(min_length=1, strict=True)
    description: str = Field(min_length=1, strict=True)
    severity: TicketSeverity


class TicketRead(TicketCreate):
    """Ticket devuelto por la API, con el ``id`` generado por el servidor."""

    id: UUID


class HealthResponse(BaseModel):
    """Respuesta del endpoint de salud."""

    status: str
    service: str
