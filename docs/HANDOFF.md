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
| pytest | 186 passed, 96.76% coverage (80% floor) |
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

Browser smoke test (headless Chromium, desktop and 390 px): React login, board, create, filter and
the Specs tab; HTMX login, new-task dialog, assignee select, filter, complete and delete. No
console errors, warnings or failed requests. It is a manual script, not part of the repository.

## What changed

- **Security.** Gitea repository allowlist (`GITEA_ALLOWED_REPOS`, default `GITEA_REPO`; if
  set it must include `GITEA_REPO` or bootstrap fails). Publish is claimed first, so it is
  idempotent. Model output is rendered as plain text in the issue Markdown. `/auth/users/`
  returns only id and names; `/specs/config/` only `ai_enabled` and `publish_enabled`.
  `spec_publish` throttle (30/h) and the `spec` throttle only on `POST`. `NUM_PROXIES`, and
  Nginx overwrites `X-Forwarded-For`. The Gitea bot is not an instance admin; its token has every scope on purpose (local test
  stack), and `GITEA_ALLOWED_REPOS` limits what the app touches. Per-service env in Compose. The Postgres MCP role sees
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
- **UI aligned with ballastlane.com.** Tokens measured in a browser (Space Grotesk and IBM
  Plex Mono, orange primary button with ink text, 8/10 px radii, dark footer) applied to both
  clients; 60 computed-style checks and the WCAG pairs pass. Table in `blt-project/README.md`.
- **Seed.** Three users (`fernando`, `ballast`, `lane`, shared password in `blt-project/secrets/blt_password`) and 19 tasks. Gitea
  has matching accounts and 13 issues: the tasks of `ballast` and `lane` are mirrored as
  assigned issues, and #13 ("Export the task list to CSV") is left without a task to try the
  spec flow. The mirroring is seed data, not a live sync.
- **Secrets in files.** No password or key is in the repository, in `.env` or in a container's
  environment. They are files in `blt-project/secrets/` (and `secrets/` here for the MCP
  launchers), mounted by Compose as `/run/secrets/*` only into the services that need them;
  `make env` creates them and migrates any value still in an older `.env`. Verified: a scan of
  `docker inspect` of every container finds none of the secret values. Real secrets never reached
  the git history; the shared password did, before this change, and is still there.
- **Gitea access.** The local Gitea login is `blt@mail.com` plus the shared password (user `blt`), the same
  password as the BLT users; `ballast` and `lane` share it in Gitea too. Defaults live in
  `.env.example` and `compose.yaml`.
- **Task table.** One fixed grid in both clients (React and HTMX): columns measured identical
  across rows at 1440, 1100 and 1024 px, stacked cards below 1024 px, per-row differences shown
  as captions, avatars, tags and a row hover. A browser script with deliberately uneven rows
  passes 56 checks.
- **Favicon and one-command start.** A checklist-mark favicon (SVG, ICO, touch icon) in both
  clients, and `make up` that waits for the seed and prints the addresses and the three users.
- **New feature: spec → tasks.** `POST /api/v1/specs/{id}/tasks/`, a React dialog, and the MCP
  tool `create_tasks_from_spec` (draft unless `confirm=true`). No new model call.

Layout and names: [`blt-project/docs/architecture.md`](../blt-project/docs/architecture.md).
Reasons: [`architecture.md`](architecture.md).

## Open items

- `unblock_account()` in `specs/gitea.py` is probably redundant; validate on a fresh Gitea
  volume.
- `Spec` does not use `BaseModel`.
- The shared password is in the git history of both repositories (it was committed before the
  secrets change). Removing it needs a history rewrite and a force push, or a new password.
- The Gitea token file lives in a named volume readable by the API and the seed containers.
- Fonts still load from Google Fonts. No dark theme (the Ballast Lane site has one).
- React filters are not in the URL.
- No automated browser or React component tests (the smoke test above is manual).
- `seed` bypasses the services on purpose.
- A `pending` publish marker needs a manual reset if the process dies mid-publish.
- No public deployment. Refresh token in `localStorage` (documented trade-off). MinIO needs
  a local build. GitHub Actions is disabled; checks run locally.
- GenAI backlog: text → task draft, issue triage before the spec, per-user AI budget and
  token usage logging, golden-issue evals.

## Next steps

1. Record a five-minute backup of
   `blt-project/docs/demo.md`.
2. Publish a deployment (Railway or a VPS) with seed data and the sample issues; run
   `manage.py check --deploy` first.
3. Pick items from the GenAI backlog.
