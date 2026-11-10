#!/usr/bin/env bash
# CodeGraph MCP for one project: codegraph-mcp.sh api|web
set -euo pipefail

TARGET="${1:-}"
case "${TARGET}" in api | web) ;; *)
    echo "Usage: $0 api|web" >&2
    exit 2
    ;;
esac

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPO="${ROOT}/blt-project/${TARGET}"

if [[ ! -f "${REPO}/.codegraph/codegraph.db" ]]; then
    codegraph init "${REPO}" >&2
    codegraph index "${REPO}" >&2
fi

exec codegraph serve --mcp --path "${REPO}"
