"""Configuración del API Gateway (Twelve-Factor).

Todos los parámetros se leen desde variables de entorno; no hay orígenes,
hosts ni puertos hardcodeados fuera de los fallbacks seguros de desarrollo.
"""

import os


def get_cors_allowed_origins() -> list[str]:
    """Devuelve los orígenes CORS permitidos desde ``CORS_ALLOWED_ORIGINS``.

    El valor es una lista separada por comas. Si la variable no está definida
    o está vacía, retorna una lista vacía (política restrictiva: ningún
    origen permitido; nunca se usa ``*``).
    """
    raw_origins = os.getenv("CORS_ALLOWED_ORIGINS", "")
    return [origin.strip() for origin in raw_origins.split(",") if origin.strip()]


def load_dotenv(path: str = ".env") -> None:
    """Carga pares ``CLAVE=valor`` de un archivo ``.env`` en ``os.environ``.

    No sobrescribe variables ya definidas en el entorno real. Si el archivo
    no existe, no hace nada.
    """
    try:
        with open(path, encoding="utf-8") as env_file:
            lines = env_file.read().splitlines()
    except FileNotFoundError:
        return
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip().strip("\"'"))
