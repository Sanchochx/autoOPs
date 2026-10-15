"""Servicio que invoca el grafo de LangGraph para un ticket recién creado."""

import asyncio
import logging
from typing import Any
from uuid import UUID

from apps.api_gateway.database import get_session_factory
from apps.api_gateway.models import Ticket
from apps.api_gateway.schemas import TicketSeverity, TicketStatus

logger = logging.getLogger(__name__)


def _load_compiled_graph() -> Any:
    """Importa de forma diferida el grafo compilado con el modelo del entorno."""
    from ai_engine.graph import compiled_graph

    return compiled_graph


async def process_ticket_with_ai(
    ticket_id: UUID,
    graph: Any | None = None,
    session_factory: Any | None = None,
) -> None:
    """Ejecuta el triaje del ticket y persiste el resultado.

    Corre como tarea en segundo plano, por lo que abre su propia sesión (la de
    la petición ya está cerrada). Nunca propaga excepciones: ante un fallo
    registra el error y el ticket conserva su estado previo.

    Args:
        ticket_id: ticket a procesar.
        graph: grafo compilado inyectable (por defecto, ``compiled_graph``).
        session_factory: fábrica de sesiones inyectable (por defecto, la del entorno).
    """
    factory = session_factory or get_session_factory()
    try:
        async with factory() as session:
            ticket = await session.get(Ticket, ticket_id)
            if ticket is None:
                logger.warning("Ticket %s no encontrado; se omite el triaje", ticket_id)
                return

            active_graph = graph or _load_compiled_graph()
            # ``invoke`` es bloqueante: se ejecuta en un hilo para no frenar el event loop.
            state = await asyncio.to_thread(
                active_graph.invoke,
                {"ticket_id": str(ticket.id), "description": ticket.description},
            )

            ticket.severity = TicketSeverity(state["severity"])
            ticket.status = TicketStatus.INVESTIGATING
            await session.commit()
            logger.info(
                "Ticket %s triado: severity=%s status=%s",
                ticket_id,
                ticket.severity.value,
                ticket.status.value,
            )
    except Exception:
        logger.exception("Falló el procesamiento con IA del ticket %s", ticket_id)
