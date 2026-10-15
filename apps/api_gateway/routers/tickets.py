"""Endpoints REST de tickets con persistencia en PostgreSQL."""

from uuid import UUID

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.api_gateway.database import get_db_session
from apps.api_gateway.models import Ticket
from apps.api_gateway.schemas import (
    TicketCreate,
    TicketRead,
    TicketSeverity,
    TicketUpdate,
)
from apps.api_gateway.services.ai_service import process_ticket_with_ai

router = APIRouter(prefix="/api/v1/tickets", tags=["tickets"])


async def _get_ticket_or_404(session: AsyncSession, ticket_id: UUID) -> Ticket:
    ticket = await session.get(Ticket, ticket_id)
    if ticket is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Ticket no encontrado"
        )
    return ticket


@router.post("", response_model=TicketRead, status_code=status.HTTP_201_CREATED)
async def create_ticket(
    payload: TicketCreate,
    background_tasks: BackgroundTasks,
    session: AsyncSession = Depends(get_db_session),
) -> Ticket:
    """Crea el ticket con severidad ``medium`` y encola el triaje con IA.

    La severidad real la asigna el Agente de Triaje en segundo plano; la
    respuesta no espera al grafo.
    """
    data = payload.model_dump(exclude={"severity"})
    ticket = Ticket(**data, severity=TicketSeverity.MEDIUM)
    session.add(ticket)
    await session.commit()
    await session.refresh(ticket)
    background_tasks.add_task(process_ticket_with_ai, ticket.id)
    return ticket


@router.get("", response_model=list[TicketRead])
async def list_tickets(session: AsyncSession = Depends(get_db_session)) -> list[Ticket]:
    """Lista los tickets, los más recientes primero."""
    result = await session.execute(select(Ticket).order_by(Ticket.created_at.desc()))
    return list(result.scalars().all())


@router.get("/{ticket_id}", response_model=TicketRead)
async def get_ticket(
    ticket_id: UUID, session: AsyncSession = Depends(get_db_session)
) -> Ticket:
    """Devuelve un ticket por ID o 404 si no existe."""
    return await _get_ticket_or_404(session, ticket_id)


@router.patch("/{ticket_id}", response_model=TicketRead)
async def update_ticket(
    ticket_id: UUID,
    payload: TicketUpdate,
    session: AsyncSession = Depends(get_db_session),
) -> Ticket:
    """Actualiza parcialmente un ticket; solo cambia los campos enviados."""
    ticket = await _get_ticket_or_404(session, ticket_id)
    for field, value in payload.model_dump(exclude_unset=True, exclude_none=True).items():
        setattr(ticket, field, value)
    await session.commit()
    await session.refresh(ticket)
    return ticket
