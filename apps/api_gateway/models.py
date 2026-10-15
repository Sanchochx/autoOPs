"""Modelos ORM (SQLAlchemy 2.x) del API Gateway."""

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from apps.api_gateway.database import Base
from apps.api_gateway.schemas import TicketSeverity, TicketStatus


def _enum_values(enum_cls: type[Enum]) -> list[str]:
    """Persiste el ``value`` del enum (p. ej. ``open``) y no su nombre."""
    return [member.value for member in enum_cls]


class Ticket(Base):
    """Ticket de incidente y su estado de resolución."""

    __tablename__ = "tickets"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    severity: Mapped[TicketSeverity] = mapped_column(
        Enum(TicketSeverity, name="ticket_severity", values_callable=_enum_values),
        nullable=False,
    )
    status: Mapped[TicketStatus] = mapped_column(
        Enum(TicketStatus, name="ticket_status", values_callable=_enum_values),
        nullable=False,
        default=TicketStatus.OPEN,
        server_default=TicketStatus.OPEN.value,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )
