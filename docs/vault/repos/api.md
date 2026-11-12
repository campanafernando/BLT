# api

<!-- fefo:generated:start -->
# api

| Field | Value |
|---|---|
| Role | `api` |
| Stack | `django` |
| Path | `blt-project/api` |
| CodeGraph MCP | `codegraph-api` |
| Test | `make -C blt-project test` |
| Lint | `make -C blt-project lint` |
| Build / run | `make -C blt-project check` |
<!-- fefo:generated:end -->

## Domain notes

Part of the `blt-project` Git root, shared with `web` (see [`../layout.md`](../layout.md)).

**Responsibility.** Django 6 + DRF API for tasks, JWT authentication and the GenAI spec flow, plus
the server-rendered HTMX + Alpine client (`hypermedia/`) over the same services.

**Layers.** `tasks/` (domain), `accounts/`, `core/` (exception handler, `BaseModel`, pagination),
`specs/` (spec flow, Gitea adapter), `hypermedia/` (HTML client, no business rule), `config/`
(settings, Celery, secret files).

**Public entry points.** `/api/v1/…` and `/api/docs/` (JSON), `/app/` (HTML), `/admin/`. Celery
tasks in `tasks/tasks.py` only call services.

**Data stores.** SQLite locally (no Docker), PostgreSQL in Compose, Redis for Celery and the cache (Compose),
MinIO for media behind the `storage` profile.

**External integrations.** Gitea (issues, allowlisted repos), the OpenCode inference API (spec
generation), SMTP (Mailpit locally).

**Read next.** [`../domain.md`](../domain.md) (task rules and their proof),
[`../contracts.md`](../contracts.md) (schema, errors, auth, change procedure),
[`../spec-flow.md`](../spec-flow.md), [`../mcp-and-secrets.md`](../mcp-and-secrets.md),
[`../decisions.md`](../decisions.md). Specialists: `blt-domain`, `blt-genai`.

**Verify.** From `blt-project`: `make test` (pytest, coverage floor 80%), `make lint`
(ruff + typecheck), `make schema`, and `manage.py check` with no warning.

**Known gaps.** No optimistic locking (last write wins); `page_size` is validated by the paginator,
not the schema; `seed` bypasses the services on purpose; a `pending` publish marker needs a manual reset.
