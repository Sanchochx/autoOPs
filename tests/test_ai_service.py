"""Pruebas del servicio de triaje en segundo plano (grafo y sesión simulados)."""

from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4

import pytest

from apps.api_gateway.models import Ticket
from apps.api_gateway.schemas import TicketSeverity, TicketStatus
from apps.api_gateway.services.ai_service import process_ticket_with_ai

pytestmark = pytest.mark.anyio


@pytest.fixture
def anyio_backend() -> str:
    return "asyncio"


class FakeSessionFactory:
    """Imita ``async_sessionmaker``: ``factory()`` es un context manager async."""

    def __init__(self, session: AsyncMock) -> None:
        self.session = session

    def __call__(self) -> "FakeSessionFactory":
        return self

    async def __aenter__(self) -> AsyncMock:
        return self.session

    async def __aexit__(self, *exc: object) -> None:
        return None


@pytest.fixture
def session() -> AsyncMock:
    return AsyncMock()


@pytest.fixture
def ticket() -> Ticket:
    return Ticket(
        id=uuid4(),
        title="BD lenta",
        description="La BD responde lento",
        severity=TicketSeverity.MEDIUM,
        status=TicketStatus.OPEN,
    )


async def test_updates_severity_and_status_from_graph(
    session: AsyncMock, ticket: Ticket
) -> None:
    session.get.return_value = ticket
    graph = MagicMock()
    graph.invoke.return_value = {"severity": "critical", "status": "investigated"}

    await process_ticket_with_ai(ticket.id, graph, FakeSessionFactory(session))

    graph.invoke.assert_called_once_with(
        {"ticket_id": str(ticket.id), "description": "La BD responde lento"}
    )
    assert ticket.severity is TicketSeverity.CRITICAL
    assert ticket.status is TicketStatus.INVESTIGATING
    session.commit.assert_awaited_once()


async def test_missing_ticket_skips_graph(session: AsyncMock) -> None:
    session.get.return_value = None
    graph = MagicMock()

    await process_ticket_with_ai(uuid4(), graph, FakeSessionFactory(session))

    graph.invoke.assert_not_called()
    session.commit.assert_not_awaited()


async def test_graph_failure_keeps_ticket_and_does_not_raise(
    session: AsyncMock, ticket: Ticket
) -> None:
    session.get.return_value = ticket
    graph = MagicMock()
    graph.invoke.side_effect = RuntimeError("LLM caído")

    await process_ticket_with_ai(ticket.id, graph, FakeSessionFactory(session))

    assert ticket.severity is TicketSeverity.MEDIUM
    assert ticket.status is TicketStatus.OPEN
    session.commit.assert_not_awaited()
