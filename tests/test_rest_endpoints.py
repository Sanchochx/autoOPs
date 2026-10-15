"""Pruebas de los endpoints REST del API Gateway (CA-2)."""

from uuid import UUID

import pytest
from fastapi.testclient import TestClient

from apps.api_gateway.main import app

client = TestClient(app)

VALID_PAYLOAD = {"title": "Disco lleno", "description": "/var al 100%", "severity": "high"}


def test_health_returns_ok() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "api_gateway"}


def test_create_ticket_returns_201_with_uuid4() -> None:
    response = client.post("/api/v1/tickets", json=VALID_PAYLOAD)
    assert response.status_code == 201
    body = response.json()
    assert UUID(body["id"]).version == 4
    assert body["title"] == VALID_PAYLOAD["title"]
    assert body["severity"] == "high"


@pytest.mark.parametrize(
    "payload",
    [
        {"description": "x", "severity": "low"},
        {**VALID_PAYLOAD, "severity": "apocalyptic"},
        {**VALID_PAYLOAD, "title": ""},
        {**VALID_PAYLOAD, "description": "   "},
    ],
)
def test_create_ticket_invalid_payload_returns_422(payload: dict[str, str]) -> None:
    response = client.post("/api/v1/tickets", json=payload)
    assert response.status_code == 422
    assert "detail" in response.json()
