"""Lab 2 sample app: shows its version and the container/pod serving the request.

If REDIS_HOST is set (Docker Compose), a visit counter is stored in Redis.
"""
import os
import socket

import redis
from flask import Flask, jsonify

APP_VERSION = os.getenv("APP_VERSION", "1.0")
REDIS_HOST = os.getenv("REDIS_HOST", "")

app = Flask(__name__)
cache = redis.Redis(host=REDIS_HOST, port=6379, socket_connect_timeout=1) if REDIS_HOST else None


def visits():
    if cache is None:
        return "n/a (no Redis)"
    try:
        return cache.incr("visits")
    except redis.RedisError:
        return "Redis unavailable"


@app.route("/")
def index():
    color = "#2b7a0b" if APP_VERSION.startswith("1") else "#1f5fbf"
    return (
        f"<html><head><title>Lab 2 App v{APP_VERSION}</title></head>"
        f"<body style='font-family:sans-serif;margin:40px'>"
        f"<h1 style='color:{color}'>Lab 2 - Containerization &amp; Kubernetes</h1>"
        f"<p><b>Version:</b> {APP_VERSION}</p>"
        f"<p><b>Served by (container / pod):</b> {socket.gethostname()}</p>"
        f"<p><b>Visits:</b> {visits()}</p>"
        f"</body></html>"
    )


@app.route("/health")
def health():
    if os.getenv("BROKEN") == "1":  # used to demonstrate a failed rollout + rollback
        return jsonify(status="unhealthy", version=APP_VERSION), 500
    return jsonify(status="healthy", version=APP_VERSION, host=socket.gethostname())


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)  # nosec B104 - must listen on all interfaces inside the container
