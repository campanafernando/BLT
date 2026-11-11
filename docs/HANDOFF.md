# Handoff — BLT

Updated: 2026-11-11

## State

The audit and refactor of 2026-11-10/11 is committed in both repositories; `blt-project` is
the repository presented for the selection process, `BLT` keeps the AI orchestration
(MCP launchers, plan, AI log) as a backup of how the work was done.

- https://github.com/campanafernando/blt-project
- https://github.com/campanafernando/BLT

## Verified (orchestrator, after the refactor)

| Check | Result |
|---|---|
| pytest | 160 passed, 96.86% coverage (80% floor) |
| ruff check + format | clean |
| `manage.py check`, `makemigrations --check` | clean |
| drf-spectacular `--validate --fail-on-warn` | `schema.yaml` regenerated, no warnings |
| React typecheck + build | clean |
| `docker compose config -q` | ok |

Live stack (`docker compose --profile storage up -d --build` on fresh volumes): every service
healthy; the non-admin Gitea bot seeds the repository and issues; login through Nginx, task
list and summary; a foreign repository is rejected; a real spec is generated (about 20 s),
turned into tasks and published as a Gitea issue, and a second publish is refused. The
Postgres role `blt_mcp` reads `tasks_task`, `specs_spec` and `mcp_users` and is denied on
`auth_user`, the token blacklist and writes. The MinIO read-only user lists and reads the
bucket and is denied writes and deletes.

Not verified: the React and HTMX flows in a browser (no driver available).

## What changed

- **Security.** Gitea repository allowlist (`GITEA_ALLOWED_REPOS`, default `GITEA_REPO`; if
  set it must include `GITEA_REPO` or bootstrap fails). Publish is claimed first, so it is
  idempotent. Model output is rendered as plain text in the issue Markdown. `/auth/users/`
  returns only id and names; `/specs/config/` only `ai_enabled` and `publish_enabled`.
  `spec_publish` throttle (30/h) and the `spec` throttle only on `POST`. `NUM_PROXIES`, and
  Nginx overwrites `X-Forwarded-For`. The Gitea bot is not an admin (the runtime
  token only has `write:issue`; the one-shot seed bootstraps with the bot's password). Per-service env in Compose. The Postgres MCP role sees
  `tasks_task`, `specs_spec` and the `mcp_users` view; the MinIO MCP uses a read-only user with a bucket-scoped list/get policy (the built-in
  `readonly` policy cannot list);
  the `cli` MCP user is inactive with an unusable password. `make env` generates random
  secrets. Details: [`mcp.md`](mcp.md).
- **Service layer (HackSoft style).** Services `task_create/update/complete/reopen/assign/
  delete`, selectors `task_list/get/summary` and `assignee_list`, `core/exceptions.py`,
  `core.models.BaseModel`, a `CheckConstraint` on `completed_at`, thin Celery tasks. One API
  class per URL is kept on purpose to preserve the published contract. HTMX views call the
  same services; the delete rule exists only in `task_delete`.
- **UI.** Jargon removed from React and HTMX. HTMX fixes: dialog button, duplicate id,
  double filter request, visible errors, assignee select, SRI on the CDN scripts. English
  dates, dev-only links and hints in React, search debounce.
- **Spec generation fix.** The provider reply was sometimes cut at `max_tokens=1200` (reasoning
  tokens count) and surfaced as "invalid JSON"; the cap is now 4000 and a truncated or empty
  answer gets its own message.
- **New feature: spec → tasks.** `POST /api/v1/specs/{id}/tasks/`, a React dialog, and the MCP
  tool `create_tasks_from_spec` (draft unless `confirm=true`). No new model call.

Layout and names: [`blt-project/docs/architecture.md`](../blt-project/docs/architecture.md).
Reasons: [`architecture.md`](architecture.md).

## Open items

- Tailwind, `class-variance-authority`, `clsx` and `tailwind-merge` against the
  "no UI framework" rule in `AGENTS.md`: needs a decision.
- `unblock_account()` in `specs/gitea.py` is probably redundant; validate on a fresh Gitea
  volume.
- `ensure_repo` is not covered by the allowlist.
- `Spec` does not use `BaseModel`.
- Fonts still load from Google Fonts.
- React filters are not in the URL.
- No browser or E2E test of the React and HTMX flows; no React component tests.
- `seed_demo` bypasses the services on purpose.
- A `pending` publish marker needs a manual reset if the process dies mid-publish.
- No public deployment. Refresh token in `localStorage` (documented trade-off). MinIO needs
  a local build. GitHub Actions is disabled; checks run locally.
- GenAI backlog: text → task draft, issue triage before the spec, per-user AI budget and
  token usage logging, golden-issue evals.

## Next steps

1. Walk through both clients in a browser and record a five-minute backup of
   `blt-project/docs/demo.md`.
2. Decide on Tailwind (see Open items).
3. Publish a demo (Railway or a VPS) with seed data and the sample issues; run
   `manage.py check --deploy` first.
4. Pick items from the GenAI backlog.
