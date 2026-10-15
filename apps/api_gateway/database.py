"""Conexión asíncrona a PostgreSQL (SQLAlchemy 2.x + asyncpg).

``DATABASE_URL`` se lee del entorno (Twelve-Factor). El motor y la fábrica de
sesiones se crean de forma diferida para que importar el módulo no exija una
base de datos disponible.
"""

import os
from collections.abc import AsyncIterator
from functools import lru_cache

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Base declarativa compartida por todos los modelos ORM."""


def get_database_url() -> str:
    """Devuelve ``DATABASE_URL`` o falla con un error explícito si falta."""
    url = os.getenv("DATABASE_URL", "").strip()
    if not url:
        raise RuntimeError("La variable de entorno DATABASE_URL no está definida.")
    return url


@lru_cache(maxsize=1)
def get_engine() -> AsyncEngine:
    """Crea (una sola vez) el motor asíncrono a partir de ``DATABASE_URL``."""
    return create_async_engine(get_database_url(), pool_pre_ping=True)


@lru_cache(maxsize=1)
def get_session_factory() -> async_sessionmaker[AsyncSession]:
    """Crea (una sola vez) la fábrica de sesiones asíncronas."""
    return async_sessionmaker(get_engine(), expire_on_commit=False)


async def get_db_session() -> AsyncIterator[AsyncSession]:
    """Dependencia de FastAPI: una sesión por petición, cerrada al terminar."""
    async with get_session_factory()() as session:
        yield session
