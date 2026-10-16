"""Servicio que invoca el grafo de LangGraph para un ticket recién creado."""

import asyncio
import json
import logging
import os
from typing import Any
from uuid import UUID

from apps.api_gateway.connection_manager import ConnectionManager
from apps.api_gateway.connection_manager import manager as default_manager
from apps.api_gateway.database import get_session_factory
from apps.api_gateway.models import Ticket
from apps.api_gateway.schemas import TicketSeverity, TicketStatus

logger = logging.getLogger(__name__)


def _load_compiled_graph() -> Any:
    """Importa de forma diferida el grafo compilado con el modelo del entorno."""
    from ai_engine.graph import compiled_graph

    return compiled_graph


def _build_event(ticket_id: UUID, node: str, message: str) -> str:
    """Serializa un evento del agente según el contrato del WebSocket."""
    return json.dumps(
        {"type": "ai_event", "ticket_id": str(ticket_id), "node": node, "message": message}
    )


async def _emit(manager: ConnectionManager, ticket_id: UUID, node: str, message: str) -> None:
    """Difunde un evento a los clientes sin que un fallo afecte al triaje.

    El envío tiene un tiempo máximo (``WS_BROADCAST_TIMEOUT_SECONDS``) para que
    un cliente lento no retenga la tarea en segundo plano.
    """
    timeout = float(os.environ.get("WS_BROADCAST_TIMEOUT_SECONDS", "2"))
    try:
        await asyncio.wait_for(
            manager.broadcast(_build_event(ticket_id, node, message)), timeout=timeout
        )
    except Exception:
        logger.warning("No se pudo emitir el evento '%s' del ticket %s", node, ticket_id)


def _describe_update(node: str, update: dict[str, Any]) -> str:
    """Resume la actualización de un nodo (última nota del agente, si existe)."""
    notes = update.get("agent_notes") or []
    if notes:
        return str(notes[-1])
    return f"Nodo {node} finalizado"


async def process_ticket_with_ai(
    ticket_id: UUID,
    graph: Any | None = None,
    session_factory: Any | None = None,
    ws_manager: ConnectionManager | None = None,
) -> None:
    """Ejecuta el triaje del ticket, emite su razonamiento y persiste el resultado.

    Corre como tarea en segundo plano, por lo que abre su propia sesión (la de
    la petición ya está cerrada). Nunca propaga excepciones: ante un fallo
    registra el error y el ticket conserva su estado previo.

    Args:
        ticket_id: ticket a procesar.
        graph: grafo compilado inyectable (por defecto, ``compiled_graph``).
        session_factory: fábrica de sesiones inyectable (por defecto, la del entorno).
        ws_manager: gestor de WebSockets inyectable (por defecto, el global).
    """
    factory = session_factory or get_session_factory()
    manager = ws_manager or default_manager
    try:
        async with factory() as session:
            ticket = await session.get(Ticket, ticket_id)
            if ticket is None:
                logger.warning("Ticket %s no encontrado; se omite el triaje", ticket_id)
                return

            active_graph = graph or _load_compiled_graph()
            await _emit(manager, ticket_id, "gateway", "Iniciando triaje")

            state: dict[str, Any] = {}
            async for chunk in active_graph.astream(
                {"ticket_id": str(ticket.id), "description": ticket.description},
                stream_mode="updates",
            ):
                for node, update in chunk.items():
                    state.update(update)
                    await _emit(manager, ticket_id, node, _describe_update(node, update))

            await _emit(manager, ticket_id, "database", "Actualizando base de datos")
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
        await _emit(manager, ticket_id, "error", "El procesamiento con IA falló")
