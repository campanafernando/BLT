# BLT

**Backlog, Lists & Tasks** — orchestration repository for the BLT project.

A full-stack reference project: a Django/DRF API with JWT and Celery, a React client,
and an alternative server-rendered client built with HTMX + Alpine.js over the same
service layer.

## Ecosystem

| Repository | Contents |
|---|---|
| `BLT` | Orchestration, documentation, delivery plan, AI log and CodeGraph snapshots |
| [`blt-project`](https://github.com/campanafernando/blt-project) | `api/` (Django), `web/` (React) and `hypermedia/` (HTMX + Alpine) |

`blt-project/` is an independent Git repository inside this folder, like `ana-api/` and
`ana-web/` in ANA and `logus-api/` in LOGUS. It is not a submodule.

## Quick start

```sh
cp .env.example .env          # fill the MCP credentials
cd blt-project
cp .env.example .env
make setup                    # uv + npm + migrate + seed
make api                      # http://127.0.0.1:8000
make web                      # http://127.0.0.1:5173  (another terminal)
```

Demo credentials: `demo` / `demo12345`.

With Docker (API, web, Postgres, Redis, Mailpit, Gitea):

```sh
cd blt-project
make up                       # Gitea at http://localhost:3000
```

## Documentation

| Document | Subject |
|---|---|
| [`docs/HANDOFF.md`](docs/HANDOFF.md) | Current state, decisions and next step |
| [`docs/architecture.md`](docs/architecture.md) | Boundaries between API, React and HTMX |
| [`docs/plan.md`](docs/plan.md) | Delivery plan and acceptance criteria |
| [`docs/ai-log.md`](docs/ai-log.md) | Record of AI tooling usage |
| [`docs/tasks/mvp.md`](docs/tasks/mvp.md) | Minimum functional scope |
| [`docs/mcp.md`](docs/mcp.md) | MCP topology and the FRETE-E gateway comparison |
| [`blt-project/README.md`](blt-project/README.md) | How to run, endpoints and decisions |

## MCP (bonus)

The orchestrator exposes five MCP connections, each with its own credential:

| Server | Source | Mode |
|---|---|---|
| `codegraph-api` / `codegraph-web` | indexes of `blt-project/api` and `web` | read |
| `postgres-blt` | Compose Postgres | read-only (`blt_mcp`) |
| `minio-blt` | Compose MinIO | read-only (no `put`/`delete`) |
| `blt-specs` | `blt-project` spec flow | read + publish issue |

Configuration in [`opencode.json`](opencode.json) and [`.mcp.json`](.mcp.json); launchers
in `.opencode/bin/`; MinIO server in `mcp_servers/`. The design, the FRETE-E gateway
comparison and the security model are in [`docs/mcp.md`](docs/mcp.md).

## Workflow

1. Actionable work in `docs/tasks/mvp.md`.
2. API contract before the client: OpenAPI schema → generated types.
3. Implement in `blt-project/`, with tests in the same delivery.
4. `make check` in the project before closing the task.
5. Record prompts, corrections and trade-offs in `docs/ai-log.md`.
6. Update `HANDOFF.md` and the project changelog.

## Rules

- Working branch: `main` (new project, no environments).
- Never commit or publish without explicit authorization.
- Secrets only in `.env`; `.env.example` documents every key.
- English in code, documentation and UI; Portuguese only in the personal study notes.
