"""Servidor MCP de inspección de logs y métricas (datos simulados).

Expone herramientas de solo lectura para el Agente Investigador. No accede a
la infraestructura real: todos los datos son simulados en esta versión.

Transporte: HTTP con SSE (Server-Sent Events), alcanzable por red desde otros
contenedores. El endpoint SSE queda en `/sse` y los mensajes del cliente se
publican en `/messages/`. Host y puerto se leen del entorno (MCP_LOGS_HOST,
MCP_LOGS_PORT); los logs se emiten a stderr.
"""

import logging
import os
import sys

from mcp.server.fastmcp import FastMCP

logging.basicConfig(stream=sys.stderr, level=logging.INFO)
logger = logging.getLogger("logs_server")

mcp = FastMCP("autoops-logs-server")


def _configure_network() -> None:
    """Aplica host y puerto de escucha desde el entorno (sin valores embebidos)."""
    port = os.environ.get("MCP_LOGS_PORT")
    if not port:
        raise RuntimeError("Falta la variable de entorno MCP_LOGS_PORT")
    # Por defecto solo loopback; en contenedor se define MCP_LOGS_HOST=0.0.0.0.
    mcp.settings.host = os.environ.get("MCP_LOGS_HOST", "127.0.0.1")
    mcp.settings.port = int(port)

# Plantillas simuladas (nivel, mensaje) por servicio conocido.
SIMULATED_LOGS: dict[str, list[tuple[str, str]]] = {
    "api_gateway": [
        ("INFO", "GET /health 200 3ms"),
        ("INFO", "POST /api/v1/tickets 201 18ms"),
        ("WARNING", "Latencia elevada en /api/v1/tickets: 850ms"),
        ("ERROR", "WebSocket /ws/stream: conexión cerrada de forma abrupta"),
        ("ERROR", "Timeout al contactar con el motor de IA tras 30s"),
    ],
    "database": [
        ("INFO", "checkpoint completado: 1204 buffers escritos"),
        ("WARNING", "conexiones activas al 85% del máximo"),
        ("ERROR", "deadlock detectado entre las transacciones 4821 y 4825"),
        ("ERROR", "consulta lenta (12.4s): SELECT * FROM tickets WHERE status = 'open'"),
        ("INFO", "autovacuum ejecutado sobre la tabla tickets"),
    ],
}


@mcp.tool()
def get_system_logs(service_name: str) -> list[str]:
    """Devuelve las 5 líneas de log más recientes (simuladas) de un servicio.

    Args:
        service_name: Nombre del servicio, p. ej. "api_gateway" o "database".
    """
    entries = SIMULATED_LOGS.get(service_name)
    if entries is None:
        known = ", ".join(sorted(SIMULATED_LOGS))
        raise ValueError(f"Servicio desconocido: {service_name!r}. Disponibles: {known}")
    logger.info("get_system_logs service_name=%s", service_name)
    return [f"[{level}] {service_name}: {message}" for level, message in entries]


@mcp.tool()
def get_db_metrics() -> dict[str, int | float]:
    """Devuelve métricas simuladas de salud de la base de datos."""
    logger.info("get_db_metrics")
    return {
        "active_connections": 42,
        "max_connections": 100,
        "cpu_usage_percent": 63.5,
        "slow_transactions": 3,
    }


if __name__ == "__main__":
    _configure_network()
    logger.info("Escuchando SSE en %s:%s", mcp.settings.host, mcp.settings.port)
    mcp.run(transport="sse")
