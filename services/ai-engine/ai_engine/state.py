"""Shared state that travels between the graph nodes."""

import operator
from typing import Annotated, Literal, TypedDict

from langchain_core.messages import AnyMessage
from langgraph.graph.message import add_messages

Severity = Literal["low", "medium", "high", "critical"]
TicketStatus = Literal["new", "triaged", "investigated"]

SEVERITIES: tuple[Severity, ...] = ("low", "medium", "high", "critical")


class AgentState(TypedDict, total=False):
    """Graph state for a ticket.

    ``messages`` accumulates the history with the ``add_messages`` reducer and
    ``agent_notes`` accumulates each agent's notes.
    """

    ticket_id: str
    description: str
    severity: Severity
    agent_notes: Annotated[list[str], operator.add]
    status: TicketStatus
    messages: Annotated[list[AnyMessage], add_messages]
