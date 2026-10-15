"""Gestión de conexiones WebSocket activas."""

import logging

from fastapi import WebSocket

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Mantiene las conexiones WebSocket activas y permite enviarles mensajes."""

    def __init__(self) -> None:
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket) -> None:
        """Acepta la conexión y la registra."""
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info("WebSocket conectado (activas=%d)", len(self.active_connections))

    def disconnect(self, websocket: WebSocket) -> None:
        """Elimina la conexión; es idempotente."""
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
            logger.info("WebSocket desconectado (activas=%d)", len(self.active_connections))

    async def send_personal_message(self, message: str, websocket: WebSocket) -> None:
        """Envía un mensaje a una conexión concreta."""
        await websocket.send_text(message)

    async def broadcast(self, message: str) -> None:
        """Envía un mensaje a todas las conexiones, descartando las rotas."""
        for connection in list(self.active_connections):
            try:
                await connection.send_text(message)
            except Exception:  # conexión caída: se limpia sin afectar al resto
                logger.warning("Fallo al emitir; se descarta la conexión")
                self.disconnect(connection)


manager = ConnectionManager()
