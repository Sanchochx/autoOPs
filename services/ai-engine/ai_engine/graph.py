"""Construction and compilation of the graph: START -> triage -> investigator -> END."""

from typing import Any

from langchain_core.language_models.chat_models import BaseChatModel
from langgraph.graph import END, START, StateGraph

from ai_engine.config import build_chat_model
from ai_engine.nodes import ContextProvider, make_investigator_node, make_triage_node
from ai_engine.state import AgentState


def build_graph(model: BaseChatModel, context_provider: ContextProvider | None = None) -> Any:
    """Compile the graph with the injected dependencies."""
    workflow = StateGraph(AgentState)
    workflow.add_node("triage_node", make_triage_node(model))
    workflow.add_node("investigator_node", make_investigator_node(model, context_provider))
    workflow.add_edge(START, "triage_node")
    workflow.add_edge("triage_node", "investigator_node")
    workflow.add_edge("investigator_node", END)
    return workflow.compile()


def __getattr__(name: str) -> Any:
    """Expose ``compiled_graph`` lazily.

    It is built with the environment model on first access, so importing the
    module does not require ``AI_MODEL_NAME`` or credentials.
    """
    if name == "compiled_graph":
        return build_graph(build_chat_model())
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
