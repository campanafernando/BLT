# Layout and ownership

Verified 2026-11-12 against `BLT@6b9b584` and `blt-project@5222d7f`.

## Two repositories, one product

| Repository | Git root | Role |
|---|---|---|
| `BLT` (this workspace) | `/home/fefo/BLT` | orchestration: agents, vault, MCP launchers, plan, AI log |
| `blt-project` | `/home/fefo/BLT/blt-project` | the product: API, two clients, MCP server, Compose |

`blt-project/` is an independent Git repository inside this folder (git-ignored by BLT), not a
submodule. It is the repository presented for the selection process; **nothing in it imports,
calls or depends on BLT** (`blt-project/GENAI.md` says so publicly). Keep that true.

## One Git root, two federated entries

FEFO registers a federated repository by Git root, but `blt-project` holds a Python API and a
React client with separate indexes and separate agents. The manifest therefore lists two entries
that share one Git root (`api` → `blt-project/api`, `web` → `blt-project/web`). Consequence:
`fefo doctor` warns "not a Git repository" for both; the warning is expected (see `decisions.md`, D9).
Never run `fefo add blt-project` or `fefo init`: both resolve to the Git root and guess the stack
wrong (`compose.yaml` makes it `infra`).

## Who owns what

| Path in `blt-project/` | Manifest entry | Agent route |
|---|---|---|
| `api/tasks`, `api/accounts`, `api/core`, `api/config` | `api` | `backend` → layer agents; rules by `blt-domain` |
| `api/specs` | `api` | `backend`; rules by `blt-genai` |
| `api/hypermedia` (HTMX + Alpine, plain CSS) | `api` | `backend` + `design`; no business rule here |
| `web/src` (React, Tailwind over `index.css` tokens) | `web` | `frontend` → `form`, `table`, `api-layer`, `design`, `i18n` |
| `mcp_server/` | none (Python, imports `api/` services) | `integration`; follow `api` rules |
| `compose.yaml`, `infra/`, `scripts/`, `api/Dockerfile`, `web/Dockerfile`, `web/nginx.conf` | none | `infra` |
| `docs/`, `GENAI.md`, `PRESENTATION.md`, `README.md` | none | frozen until the submission is closed |

A task that crosses `api` and `web` goes to `cross-stack` first (contract first, see `contracts.md`).

## Verification (cwd = `blt-project`)

| Check | Command |
|---|---|
| everything | `make check` (ruff, typecheck, pytest ≥ 80%, schema, web build) |
| API tests | `make test` |
| lint | `make lint` |
| OpenAPI | `make schema` |
| Django | `api/.venv/bin/python api/manage.py check` and `makemigrations --check` |
| web | `npm --prefix web run typecheck` and `npm --prefix web run build` (there is no web test script) |
| full stack | `make up` (Compose; Gitea at :3000) |

Baseline recorded in `docs/HANDOFF.md` (2026-11-11): 186 tests passed, 96.76% coverage, ruff, schema and builds clean.
Re-run `make check` before trusting it.

## State and freeze

The submission deadline is Friday 2026-11-13 12:30 (Brazil); after it the work is frozen until
further notice. While frozen: no edit, format, commit or push inside `blt-project/`. Only
`.codegraph/` (git-ignored) may change there, through `fefo index`.
