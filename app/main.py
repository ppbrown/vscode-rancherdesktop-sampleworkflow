"""k-app: a trivial HTTP service for exercising the container dev cycle.

Stdlib only, so there is nothing to install and the image stays small.
"""
import json
import logging
import os
import signal
import socket
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ.get("PORT", "8080"))
VERSION = os.environ.get("APP_VERSION", "dev")
GREETING = os.environ.get("GREETING", "Hello from k-app")
STARTED = time.time()

logging.basicConfig(
    stream=sys.stdout,
    level=os.environ.get("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s %(message)s",
)
log = logging.getLogger("k-app")


class Handler(BaseHTTPRequestHandler):
    def _send(self, status, body):
        data = json.dumps(body, indent=2).encode() + b"\n"
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/":
            self._send(200, {
                "message": GREETING,
                "version": VERSION,
                "hostname": socket.gethostname(),
                "uptime_seconds": round(time.time() - STARTED, 1),
            })
        elif self.path in ("/healthz", "/readyz"):
            self._send(200, {"status": "ok"})
        else:
            self._send(404, {"error": "not found", "path": self.path})

    def log_message(self, fmt, *args):
        # Route access logs through logging (stdout) instead of stderr.
        log.info("%s %s", self.address_string(), fmt % args)


def main():
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)

    # Kubernetes sends SIGTERM on pod shutdown; exit cleanly.
    def shutdown(signum, _frame):
        log.info("received signal %s, shutting down", signum)
        raise KeyboardInterrupt

    signal.signal(signal.SIGTERM, shutdown)

    log.info("k-app %s listening on :%d", VERSION, PORT)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        log.info("stopped")


if __name__ == "__main__":
    main()
