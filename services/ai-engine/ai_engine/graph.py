"""Construcción y compilación del grafo: START -> triage -> investigator -> END."""

from typing import Any

from langchain_core.language_models.chat_models import BaseChatModel
from langgraph.graph import END, START, StateGraph

from ai_engine.config import build_chat_model
from ai_engine.nodes import ContextProvider, make_investigator_node, make_triage_node
from ai_engine.state import AgentState


def build_graph(model: BaseChatModel, context_provider: ContextProvider | None = None) -> Any:
    """Compila el grafo con las dependencias inyectadas."""
    workflow = StateGraph(AgentState)
    workflow.add_node("triage_node", make_triage_node(model))
    workflow.add_node("investigator_node", make_investigator_node(model, context_provider))
    workflow.add_edge(START, "triage_node")
    workflow.add_edge("triage_node", "investigator_node")
    workflow.add_edge("investigator_node", END)
    return workflow.compile()


def __getattr__(name: str) -> Any:
    """Expone ``compiled_graph`` de forma diferida.

    Se construye con el modelo del entorno al primer acceso, para que importar
    el módulo no exija ``AI_MODEL_NAME`` ni credenciales.
    """
    if name == "compiled_graph":
        return build_graph(build_chat_model())
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
