"""Pruebas del endpoint WebSocket /ws/stream (CA-3)."""

from fastapi.testclient import TestClient

from apps.api_gateway.connection_manager import manager
from apps.api_gateway.main import app

client = TestClient(app)


def test_connect_echo_and_disconnect() -> None:
    with client.websocket_connect("/ws/stream") as websocket:
        assert websocket.receive_text() == "connected"
        assert len(manager.active_connections) == 1
        websocket.send_text("hola")
        assert websocket.receive_text() == "echo: hola"
    assert manager.active_connections == []
