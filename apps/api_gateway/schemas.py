"""Esquemas Pydantic del API Gateway."""

from datetime import datetime
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class TicketSeverity(str, Enum):
    """Niveles de severidad permitidos para un ticket."""

    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class TicketStatus(str, Enum):
    """Estados del ciclo de vida de un ticket."""

    OPEN = "open"
    INVESTIGATING = "investigating"
    PENDING_APPROVAL = "pending_approval"
    RESOLVED = "resolved"


class TicketCreate(BaseModel):
    """Payload de entrada para crear un ticket."""

    model_config = ConfigDict(str_strip_whitespace=True)

    title: str = Field(min_length=1, strict=True)
    description: str = Field(min_length=1, strict=True)
    severity: TicketSeverity


class TicketRead(TicketCreate):
    """Ticket devuelto por la API, con los campos generados por el servidor."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    status: TicketStatus
    created_at: datetime
    updated_at: datetime


class HealthResponse(BaseModel):
    """Respuesta del endpoint de salud."""

    status: str
    service: str


class TicketUpdate(BaseModel):
    """Payload parcial para actualizar un ticket (todos los campos opcionales)."""

    model_config = ConfigDict(str_strip_whitespace=True)

    title: str | None = Field(default=None, min_length=1, strict=True)
    description: str | None = Field(default=None, min_length=1, strict=True)
    severity: TicketSeverity | None = None
    status: TicketStatus | None = None
