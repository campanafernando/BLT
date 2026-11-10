#!/usr/bin/env bash
# Shared helpers for the BLT MCP launchers.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ROOT}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "Missing ${ENV_FILE}. Copy .env.example and fill the MCP credentials." >&2
    exit 1
fi

env_get() {
    python3 - "${ENV_FILE}" "$1" <<'PY'
import sys
from pathlib import Path

key = sys.argv[2]
for line in Path(sys.argv[1]).read_text().splitlines():
    if line.startswith(f"{key}="):
        print(line.split("=", 1)[1].strip())
        break
PY
}

urlencode() {
    python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}
