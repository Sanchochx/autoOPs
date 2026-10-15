"""Endpoints REST de tickets (sin persistencia en esta US)."""

from uuid import uuid4

from fastapi import APIRouter, status

from apps.api_gateway.schemas import TicketCreate, TicketRead

router = APIRouter(prefix="/api/v1/tickets", tags=["tickets"])


@router.post("", response_model=TicketRead, status_code=status.HTTP_201_CREATED)
def create_ticket(payload: TicketCreate) -> TicketRead:
    """Crea un ticket y le asigna un UUID4 generado por el servidor.

    El ticket se devuelve sin guardarse: la persistencia llega en otra US.
    """
    return TicketRead(id=uuid4(), **payload.model_dump())
