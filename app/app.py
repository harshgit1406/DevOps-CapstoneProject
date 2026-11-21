import os
import socket
import time
from datetime import datetime, timezone

from flask import Flask, Response, jsonify, render_template
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

START_TIME = time.time()
REQUESTS = Counter("app_http_requests_total", "HTTP requests", ["method", "endpoint", "status"])
LATENCY = Histogram("app_http_request_duration_seconds", "HTTP request latency", ["endpoint"])

app = Flask(__name__)
app.config.update(
    APP_NAME=os.getenv("APP_NAME", "DevSecOps Control Center"),
    APP_ENV=os.getenv("APP_ENV", "development"),
    APP_VERSION=os.getenv("APP_VERSION", "1.0.0"),
    PORT=int(os.getenv("PORT", "5000")),
)


@app.before_request
def start_timer():
    from flask import g
    g.request_started = time.perf_counter()


@app.after_request
def record_metrics(response):
    from flask import g, request
    endpoint = request.endpoint or "unknown"
    REQUESTS.labels(request.method, endpoint, response.status_code).inc()
    LATENCY.labels(endpoint).observe(time.perf_counter() - g.request_started)
    return response


def status_payload():
    return {
        "status": "healthy",
        "name": app.config["APP_NAME"],
        "version": app.config["APP_VERSION"],
        "environment": app.config["APP_ENV"],
        "grafana_url": os.getenv("GRAFANA_URL", "http://localhost:3000"),
        "prometheus_url": os.getenv("PROMETHEUS_URL", "http://localhost:9090"),
        "hostname": socket.gethostname(),
        "uptime_seconds": round(time.time() - START_TIME, 2),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/")
def home():
    return render_template("index.html", data=status_payload())


@app.get("/health")
def health():
    return jsonify(status="healthy"), 200


@app.get("/ready")
def ready():
    return jsonify(status="ready"), 200


@app.get("/api/status")
def api_status():
    return jsonify(status_payload())


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=app.config["PORT"])  # nosemgrep
