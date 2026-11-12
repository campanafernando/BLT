# BLT

**Backlog, Lists & Tasks** — orchestration repository for the BLT project.

A full-stack reference project: a Django/DRF API with JWT and Celery, a React client,
and an alternative server-rendered client built with HTMX + Alpine.js over the same
service layer.

## Ecosystem

| Repository | Contents |
|---|---|
| `BLT` | Orchestration, documentation, delivery plan and AI log; MCP wiring points into `blt-project` |
| [`blt-project`](https://github.com/campanafernando/blt-project) | `api/` (Django), `web/` (React) and `hypermedia/` (HTMX + Alpine) |

`blt-project/` is an independent Git repository inside this folder, like `ana-api/` and
`ana-web/` in ANA and `logus-api/` in LOGUS. It is not a submodule.

## Quick start

```sh
cp .env.example .env          # fill the MCP credentials
cd blt-project
make setup                    # .env with generated secrets, uv, npm, migrate, seed
make api                      # http://127.0.0.1:8000
make web                      # http://127.0.0.1:5173  (another terminal)
```

`make env` in `blt-project` creates its `.env` with random secrets and never overwrites an
existing one. Seeded users, not shown on the login pages: `fernando`, `ballast` and `lane`, all with
the password in `blt-project/secrets/blt_password`. Details, endpoints and `GITEA_ALLOWED_REPOS`:
[`blt-project/README.md`](blt-project/README.md).

With Docker (API, web, Postgres, Redis, Mailpit, Gitea):

```sh
cd blt-project
make up                       # Gitea at http://localhost:3000
```

## Documentation

| Document | Subject |
|---|---|
| [`docs/HANDOFF.md`](docs/HANDOFF.md) | Current state, open items and next steps |
| [`docs/architecture.md`](docs/architecture.md) | Decisions: why the project is built this way |
| [`docs/plan.md`](docs/plan.md) | Delivery plan and acceptance criteria |
| [`docs/tasks/mvp.md`](docs/tasks/mvp.md) | Minimum functional scope |
| [`docs/ai-log.md`](docs/ai-log.md) | Record of AI tooling usage |
| [`docs/mcp.md`](docs/mcp.md) | MCP topology, security model, FRETE-E gateway comparison |
| [`docs/vault/`](docs/vault/README.md) | Knowledge base for agents: layout, domain rules, contracts, spec flow, decisions |
| [`docs/fefo/ADOPTION.md`](docs/fefo/ADOPTION.md) | Runbook to turn BLT into a FEFO workspace (prepared, not yet executed) |

Product documentation (run, endpoints, code layout, GenAI flow, demo script) lives in
[`blt-project/README.md`](blt-project/README.md) (setup, architecture, decisions, demo) and
[`blt-project/GENAI.md`](blt-project/GENAI.md) (applied AI, and the tooling behind the code).

## MCP (bonus)

This workspace exposes five MCP connections, each with its own credential:

| Server | Source | Mode |
|---|---|---|
| `codegraph-api` / `codegraph-web` | indexes of `blt-project/api` and `web` | read |
| `postgres-blt` | Compose Postgres | read-only (`blt_mcp`: `tasks_task`, `specs_spec`, view `mcp_users`) |
| `minio-blt` | Compose MinIO | read-only user, no `put`/`delete` tool |
| `blt-specs` | `blt-project` spec flow | read; writes only an issue (publish) or tasks (`create_tasks_from_spec`, `confirm=true`) |

Agent rules in [`AGENTS.md`](AGENTS.md) and [`AGENTS.local.md`](AGENTS.local.md) (BLT specialists, hard stops).
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
- Plain configuration in `.env`; passwords and keys are files in `secrets/`. `.env.example` documents every key.
- English in code, documentation and UI; Portuguese only in the personal study notes.
