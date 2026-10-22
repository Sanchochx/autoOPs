"""API Gateway configuration (Twelve-Factor).

All parameters are read from environment variables; there are no origins,
hosts or ports hardcoded beyond the safe development fallbacks.
"""

import os


def get_cors_allowed_origins() -> list[str]:
    """Return the allowed CORS origins from ``CORS_ALLOWED_ORIGINS``.

    The value is a comma-separated list. If the variable is undefined or
    empty, returns an empty list (restrictive policy: no origin allowed;
    ``*`` is never used).
    """
    raw_origins = os.getenv("CORS_ALLOWED_ORIGINS", "")
    return [origin.strip() for origin in raw_origins.split(",") if origin.strip()]


def load_dotenv(path: str = ".env") -> None:
    """Load ``KEY=value`` pairs from a ``.env`` file into ``os.environ``.

    Does not overwrite variables already defined in the real environment. If
    the file does not exist, does nothing.
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
