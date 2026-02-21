#!/bin/bash
# Robust, idempotent bootstrap for CPU-burn HTTP server (no Internet required)
set -Eeuo pipefail

log() { echo "[$(date -Is)] $*" | tee -a /var/log/cpuburn.log; }

# Ensure working dir
mkdir -p /opt/cpuburn
cd /opt/cpuburn

# Bash CPU burner
cat >/opt/cpuburn/cpuburn_bash.sh <<'EOF'
#!/bin/bash
# Usage: cpuburn_bash.sh <CORES> <SECONDS>
CORES="${1:-1}"
DUR="${2:-30}"
for i in $(seq 1 "${CORES}"); do
  bash -c "end=$((SECONDS+DUR)); while [ \$SECONDS -lt \$end ]; do :; done" &
done
disown
exit 0
EOF
chmod +x /opt/cpuburn/cpuburn_bash.sh

# Minimal Python HTTP server (stdlib only)
# AL2023 provides /usr/bin/python3 as system Python (no package install needed)
cat >/opt/cpuburn/cpuburn_server.py <<'PY'
#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
import subprocess

class H(BaseHTTPRequestHandler):
    def do_GET(self):
        p = urlparse(self.path)
        if p.path == "/health":
            self.send_response(200); self.end_headers(); self.wfile.write(b"OK"); return
        if p.path == "/burn":
            qs = parse_qs(p.query)
            cores = int(qs.get("cores", ["2"])[0])
            seconds = int(qs.get("seconds", ["30"])[0])
            subprocess.Popen(["/opt/cpuburn/cpuburn_bash.sh", str(cores), str(seconds)])
            self.send_response(200); self.end_headers()
            self.wfile.write(f"burning {cores} cores for {seconds}s\n".encode()); return
        self.send_response(200); self.end_headers()
        self.wfile.write(b"Use /health or /burn?cores=2&seconds=30")
    def log_message(self, *a): pass

if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8080), H).serve_forever()
PY
chmod +x /opt/cpuburn/cpuburn_server.py

# systemd unit (idempotent)
cat >/etc/systemd/system/cpuburn.service <<'UNIT'
[Unit]
Description=CPU Burn HTTP Server
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/python3 /opt/cpuburn/cpuburn_server.py
Restart=always
RestartSec=2s
User=root
WorkingDirectory=/opt/cpuburn

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now cpuburn.service

log "cpuburn service started."