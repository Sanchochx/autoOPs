"""Nodos del grafo: Triaje e Investigador.

Cada nodo se construye con una fábrica que recibe sus dependencias (modelo de
chat y, opcionalmente, un proveedor de contexto MCP), de modo que pueden
probarse con un modelo falso sin llamar a la API.
"""

import logging
from collections.abc import Callable

from langchain_core.language_models.chat_models import BaseChatModel
from langchain_core.messages import HumanMessage, SystemMessage

from ai_engine.state import SEVERITIES, AgentState, Severity

logger = logging.getLogger(__name__)

DEFAULT_SEVERITY: Severity = "medium"

TRIAGE_PROMPT = (
    "Eres un agente de triaje SRE de nivel 1. Clasifica la severidad del "
    "incidente descrito. Responde únicamente con una palabra: "
    "low, medium, high o critical."
)

INVESTIGATOR_PROMPT = (
    "Eres un agente investigador SRE. Dada la descripción de un incidente y su "
    "severidad, resume las hipótesis de causa raíz más probables y qué "
    "información técnica habría que consultar. Sé conciso."
)

# Punto de inyección del cliente MCP: recibe el estado y devuelve contexto
# técnico (logs, métricas). Se conectará a los servidores MCP en otra US.
ContextProvider = Callable[[AgentState], str]


def parse_severity(raw_text: str) -> Severity:
    """Extrae una severidad válida del texto del modelo.

    Si no hay ninguna reconocible, usa ``DEFAULT_SEVERITY`` y lo registra.
    """
    text = raw_text.strip().lower()
    for severity in SEVERITIES:
        if severity in text:
            return severity
    logger.warning("Severidad no reconocida %r; se usa %s", raw_text, DEFAULT_SEVERITY)
    return DEFAULT_SEVERITY


def make_triage_node(model: BaseChatModel) -> Callable[[AgentState], dict]:
    """Crea el nodo de triaje que asigna ``severity`` al ticket."""

    def triage_node(state: AgentState) -> dict:
        response = model.invoke(
            [SystemMessage(content=TRIAGE_PROMPT), HumanMessage(content=state["description"])]
        )
        severity = parse_severity(str(response.content))
        logger.info("Triaje ticket=%s severity=%s", state.get("ticket_id"), severity)
        return {
            "severity": severity,
            "status": "triaged",
            "messages": [response],
            "agent_notes": [f"triage: severidad asignada = {severity}"],
        }

    return triage_node


def make_investigator_node(
    model: BaseChatModel, context_provider: ContextProvider | None = None
) -> Callable[[AgentState], dict]:
    """Crea el nodo investigador.

    Args:
        model: modelo de chat usado para razonar sobre el incidente.
        context_provider: función opcional que aporta contexto técnico (MCP).
    """

    def investigator_node(state: AgentState) -> dict:
        severity = state.get("severity", DEFAULT_SEVERITY)
        context = context_provider(state) if context_provider else "sin contexto técnico"
        response = model.invoke(
            [
                SystemMessage(content=INVESTIGATOR_PROMPT),
                HumanMessage(
                    content=(
                        f"Severidad: {severity}\n"
                        f"Incidente: {state['description']}\n"
                        f"Contexto técnico: {context}"
                    )
                ),
            ]
        )
        logger.info("Investigación ticket=%s severity=%s", state.get("ticket_id"), severity)
        return {
            "status": "investigated",
            "messages": [response],
            "agent_notes": [f"investigator: {response.content}"],
        }

    return investigator_node
