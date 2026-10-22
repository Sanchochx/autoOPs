"""Streaming WebSocket endpoint."""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from apps.api_gateway.connection_manager import manager

router = APIRouter(tags=["websocket"])


@router.websocket("/ws/stream")
async def stream(websocket: WebSocket) -> None:
    """Acknowledge the connection and echo received messages."""
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
