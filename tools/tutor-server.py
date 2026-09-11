#!/usr/bin/env python3
"""Local server for the Q2 tutor workbench.

Serves tools/tutor.html at http://localhost:8765 and proxies
/v1/* API calls to your configured endpoint — killing the CORS
problem entirely (same-origin from the page's point of view).

Usage:  python3 tools/tutor-server.py
Then open http://localhost:8765 in your browser.
"""
import json
import os
import re
import sys
import urllib.request
import urllib.error
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
PORT = 8765

CONFIG = {}


def load_config():
    """Read tools/tutor-config.js (written by set-tutor-key.py)."""
    path = os.path.join(HERE, "tutor-config.js")
    if not os.path.exists(path):
        return None
    src = open(path, encoding="utf-8").read()
    m = re.search(r"window\.TUTOR_CFG = (\{.*?\});", src, re.S)
    return json.loads(m.group(1)) if m else None


class Handler(BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        if self.path in ("/", "/index.html", "/tutor.html"):
            page = open(os.path.join(HERE, "tutor.html"), "rb").read()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(page)))
            self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
            self.send_header("Pragma", "no-cache")
            self._cors()
            self.end_headers()
            self.wfile.write(page)
        elif self.path == "/healthz":
            self.send_response(200)
            self._cors()
            self.end_headers()
            self.wfile.write(b"ok")
        else:
            self.send_error(404)

    def do_POST(self):
        if not self.path.startswith("/v1/"):
            self.send_error(404, "Only /v1/* is proxied")
            return

        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)

        # Build upstream request using the LOCAL config — the browser never
        # needs to send the Authorization header itself, so no preflight.
        upstream_url = (CONFIG or {}).get("url", "").rstrip("/") + self.path[len("/v1"):]
        headers = {
            "Content-Type": "application/json",
            "Authorization": "Bearer " + (CONFIG or {}).get("key", ""),
        }
        req = urllib.request.Request(upstream_url, data=body, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                payload = r.read()
                self.send_response(r.status)
                self.send_header("Content-Type", r.headers.get("Content-Type", "application/json"))
                self.send_header("Content-Length", str(len(payload)))
                self._cors()
                self.end_headers()
                self.wfile.write(payload)
        except urllib.error.HTTPError as e:
            payload = e.read()
            self.send_response(e.code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self._cors()
            self.end_headers()
            self.wfile.write(payload)
        except Exception as e:
            msg = json.dumps({"error": {"message": str(e)}}).encode()
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(msg)))
            self._cors()
            self.end_headers()
            self.wfile.write(msg)

    def log_message(self, format, *args):
        sys.stderr.write("[tutor] " + (format % args) + "\n")


def main():
    global CONFIG
    CONFIG = load_config()
    if not CONFIG:
        print("No tools/tutor-config.js found. Run:  python3 tools/set-tutor-key.py")
        sys.exit(1)
    # never print the key
    print(f"config: url={CONFIG['url']}  model={CONFIG['model']}  key=({len(CONFIG['key'])} chars)")
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"serving tutor.html at http://localhost:{PORT}")
    print("Ctrl+C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nbye")


if __name__ == "__main__":
    main()
