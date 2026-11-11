# Plan — BLT

Target date: Friday, 2026-11-13. Updated: Wednesday, 2026-11-11.

## Acceptance criteria

- [x] Task CRUD with JWT
- [x] Assign and complete a task
- [x] Filter by status and due date range
- [x] Pagination
- [x] Rate limiting
- [x] Celery + Redis with an async task
- [x] Tests with coverage ≥ 80%
- [x] Dockerfile + Compose (API, database, Redis, worker, web)
- [x] README with setup, credentials and decisions
- [x] OpenAPI at `/api/docs/`
- [x] React client with CRUD, filters and responsiveness
- [x] Bonus: HTMX + Alpine over the same service layer
- [x] GenAI: spec from a Gitea issue, with publish back to Gitea and tasks from the spec
- [x] MCP servers for CodeGraph, Postgres, MinIO and specs
- [x] Local delivery checks
- [ ] Public deployment
- [ ] CodeGraph snapshot committed

## Sequence

| Block | Delivery | State |
|---|---|---|
| 1 | Structure, settings, models, JWT, CRUD, filters | done |
| 2 | Celery, throttling, tests, coverage | done |
| 3 | React: login, board, form, filters | done |
| 4 | HTMX + Alpine: partials, modal, confirmation | done |
| 5 | Spec from issue + Gitea + MCP | done |
| 6 | Audit and refactor: HackSoft layers, security hardening, UI cleanup, tasks from a spec | done |
| 7 | Demo rehearsal, deployment | in progress |

## Risks

| Risk | Mitigation |
|---|---|
| Reviewer asks "why not a ViewSet" | README explains: explicit views for explicit services |
| High coverage without useful asserts | Tests cover edges: idempotency, 404, inactive user, past date |
| Demo breaks on a clean clone | Clone into `/tmp` checklist before delivery |
| Over-abstraction | No repository, use case or DTO; layers only where there is a rule |
| `localStorage` in React | Trade-off documented in `docs/ai/03-decisions.md` |
| GenAI provider unavailable | Seeded spec and a clear 503 path |
| GitHub Actions disabled | Delivery checks run locally; no hosted workflow |
