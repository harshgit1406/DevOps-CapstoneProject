import pytest
from app import app

@pytest.fixture()
def client():
    app.config.update(TESTING=True)
    return app.test_client()

@pytest.mark.parametrize("path", ["/", "/health", "/ready", "/metrics", "/api/status"])
def test_endpoints_are_available(client, path):
    assert client.get(path).status_code == 200

def test_status_schema(client):
    data = client.get("/api/status").get_json()
    assert data["status"] == "healthy"
    assert data["version"]
    assert data["hostname"]
    assert data["uptime_seconds"] >= 0

def test_prometheus_metrics(client):
    client.get("/health")
    body = client.get("/metrics").text
    assert "app_http_requests_total" in body
    assert "app_http_request_duration_seconds" in body

def test_dashboard_includes_tic_tac_toe(client):
    body = client.get("/").text
    assert "Tic-Tac-Toe" in body
    assert 'id="game-board"' in body
