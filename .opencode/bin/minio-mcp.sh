#!/usr/bin/env bash
# MinIO/S3 MCP, read-only. Uses an ephemeral uv environment.
set -euo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "${DIR}/../.." && pwd)"
# shellcheck source=mcp-common.sh
source "${DIR}/mcp-common.sh"

export MINIO_ENDPOINT="$(env_get MINIO_ENDPOINT)"
export MINIO_ACCESS_KEY="$(env_get MINIO_ACCESS_KEY)"
export MINIO_SECRET_KEY="$(secret_get minio_mcp_secret)"
export MINIO_BUCKET="$(env_get MINIO_BUCKET)"

exec uv run --quiet --python 3.12 \
    --with 'mcp>=1.2,<2' \
    --with 'boto3>=1.34,<2' \
    python "${ROOT}/mcp_servers/minio_server.py"
