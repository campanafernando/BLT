#!/usr/bin/env bash
# PostgreSQL MCP for the BLT database, read-only by default.
set -euo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=mcp-common.sh
source "${DIR}/mcp-common.sh"

host="$(env_get BLT_PG_HOST)"
port="$(env_get BLT_PG_PORT)"
name="$(env_get BLT_PG_NAME)"
user="$(env_get BLT_PG_USER)"
password="$(secret_get blt_pg_password)"
mode="${POSTGRES_MCP_ACCESS_MODE:-restricted}"

if [[ -z "${host}" || -z "${name}" || -z "${user}" || -z "${password}" ]]; then
    echo "Set BLT_PG_HOST, BLT_PG_PORT, BLT_PG_NAME and BLT_PG_USER in .env." >&2
    exit 1
fi

if [[ "${mode}" != "restricted" ]]; then
    printf '⚠️  BLT PostgreSQL MCP in %s mode: writes allowed.\n' "${mode}" >&2
fi

export DATABASE_URI="postgresql://$(urlencode "${user}"):$(urlencode "${password}")@${host}:${port}/${name}"

# postgres-mcp 0.3.0 imports FastMCP from the pre-2.0 Python SDK and pins
# pglast==7.2.0, which is no longer published. Same workaround as FRETE-E.
exec uvx --from 'postgres-mcp==0.3.0' --with 'mcp>=1.5,<2' \
    --overrides "${DIR}/postgres-mcp-overrides.txt" postgres-mcp --access-mode "${mode}"
