"""Endpoint WebSocket de streaming."""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from apps.api_gateway.connection_manager import manager

router = APIRouter(tags=["websocket"])


@router.websocket("/ws/stream")
async def stream(websocket: WebSocket) -> None:
    """Confirma la conexión y hace eco de los mensajes recibidos."""
    await manager.connect(websocket)
    try:
        await manager.send_personal_message("connected", websocket)
        while True:
            data = await websocket.receive_text()
            await manager.send_personal_message(f"echo: {data}", websocket)
    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect(websocket)
