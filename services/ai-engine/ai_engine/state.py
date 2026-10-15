"""Estado compartido que viaja entre los nodos del grafo."""

import operator
from typing import Annotated, Literal, TypedDict

from langchain_core.messages import AnyMessage
from langgraph.graph.message import add_messages

Severity = Literal["low", "medium", "high", "critical"]
TicketStatus = Literal["new", "triaged", "investigated"]

SEVERITIES: tuple[Severity, ...] = ("low", "medium", "high", "critical")


class AgentState(TypedDict, total=False):
    """Estado del grafo para un ticket.

    ``messages`` acumula el historial con el reducer ``add_messages`` y
    ``agent_notes`` acumula las notas de cada agente.
    """

    ticket_id: str
    description: str
    severity: Severity
    agent_notes: Annotated[list[str], operator.add]
    status: TicketStatus
    messages: Annotated[list[AnyMessage], add_messages]
