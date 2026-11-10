# Handoff — BLT

Updated: 2026-11-10

## State

Project created, validated end to end and published. The GenAI feature is on `main` and
now targets Gitea.

- https://github.com/campanafernando/blt-project
- https://github.com/campanafernando/BLT

## Verified in this session

| Check | Result |
|---|---|
| Django check | 0 issues |
| pytest | 87 passed, 95.5% coverage (80% floor) |
| ruff check + format | clean |
| drf-spectacular `--validate --fail-on-warn` | schema with no warnings |
| React typecheck + build | clean |
| `docker compose up` | db, redis, mailpit, gitea, api, worker, beat, web |
| Real flow | JWT login, task, email in Mailpit through the worker, HTMX board |
| GenAI | Gitea issue #1 → spec (19.2s in the provider) → Gitea issue #5 |
| MCP | Postgres, CodeGraph api/web, MinIO and specs answering over stdio |
| CI | workflow valid; execution blocked by GitHub billing |

## What is ready

- `blt-project/api`: Django 6.0.10, DRF 3.18.3, SimpleJWT 5.5.1, spectacular 0.29,
  django-filter 25.2, Celery 5.7, Postgres/SQLite, throttling, pagination, filters.
- `blt-project/api/tasks`: model, services, selectors, filters, views and tests.
- `blt-project/api/accounts`: JWT, refresh, me, active users.
- `blt-project/api/specs`: spec from a Gitea issue, JSON contract, publish as issue.
- `blt-project/api/hypermedia`: SSR board with partials, OOB swap, 422, Alpine dialog.
- `blt-project/web`: React 19 + Vite 7 + TanStack Query 5 + RHF, Ballast Lane tokens,
  **Spec** tab in addition to the board.
- `blt-project/mcp_server`: four MCP tools over the same services.
- `blt-project/compose.yaml`: Postgres 16, Redis 7, Mailpit, Gitea 1.24, API, worker,
  beat, Nginx; MinIO behind the `storage` profile.
- `blt-project/.github/workflows/ci.yml`: API on Postgres + web typecheck/build.

## MCP (bonus)

- `opencode.json` and `.mcp.json` with five servers: CodeGraph api/web, Postgres, MinIO
  and specs.
- Postgres uses `blt_mcp`, a SELECT-only role; MinIO has no write tool.
- `blt-specs` points at `blt-project/mcp_server/run.sh`; tested over stdio.
- Design and the FRETE-E gateway comparison in `docs/mcp.md`.

## Next step

1. Fix GitHub billing so CI can run (jobs do not even start today).
2. Publish a demo (Railway or a VPS) with seed data and the sample issues.
3. Review `docs/ai/02-review.md` with the real prompts from the session.
4. Rehearse `docs/demo.md` and record a five-minute backup.
5. Optional: create tasks from a spec (write path deliberately postponed).

## Known gaps

- No public deployment.
- No React component tests (the API covers the rules).
- Refresh token in `localStorage` — documented trade-off.
- MinIO depends on a local build (images are no longer published).
- CI configured but blocked by the GitHub account billing.
