"""AI engine configuration (Twelve-Factor).

The model and the API key come from environment variables.
"""

import os

from langchain_core.language_models.chat_models import BaseChatModel
from langchain_openai import ChatOpenAI


def build_chat_model() -> BaseChatModel:
    """Build the chat model from the environment.

    Requires ``AI_MODEL_NAME``; ``OPENAI_API_KEY`` is read by the OpenAI
    client directly from the environment.

    Raises:
        RuntimeError: if ``AI_MODEL_NAME`` is not defined.
    """
    model_name = os.getenv("AI_MODEL_NAME")
    if not model_name:
        raise RuntimeError("La variable de entorno AI_MODEL_NAME no está definida")
    return ChatOpenAI(model=model_name)
