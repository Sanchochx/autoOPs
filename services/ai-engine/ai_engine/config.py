"""Configuración del motor de IA (Twelve-Factor).

El modelo y la clave de API provienen de variables de entorno.
"""

import os

from langchain_anthropic import ChatAnthropic
from langchain_core.language_models.chat_models import BaseChatModel


def build_chat_model() -> BaseChatModel:
    """Construye el modelo de chat a partir del entorno.

    Requiere ``AI_MODEL_NAME``; ``ANTHROPIC_API_KEY`` la lee el cliente de
    Anthropic directamente del entorno.

    Raises:
        RuntimeError: si ``AI_MODEL_NAME`` no está definida.
    """
    model_name = os.getenv("AI_MODEL_NAME")
    if not model_name:
        raise RuntimeError("La variable de entorno AI_MODEL_NAME no está definida")
    return ChatAnthropic(model=model_name)
