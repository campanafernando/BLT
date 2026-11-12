# Handoff — BLT

Updated: 2026-11-12

## Next round: adopt FEFO (prepared, not executed)

BLT is to become a FEFO workspace in place. The preparation is done and rehearsed on a throwaway
copy; the execution is for a separate session, **after the submission is closed or when the user says
go**. Start at [`fefo/ADOPTION.md`](fefo/ADOPTION.md); the knowledge base is [`vault/`](vault/README.md).

| Prepared | Where |
|---|---|
| Manifest (`api`, `web`, 3 custom MCPs; hand-written, never `fefo init`) | `.fefo/workspace.json` |
| Knowledge vault (layout, domain rules, contracts, spec flow, MCP and secrets, decisions D1–D13) | `docs/vault/` |
| Specialists `blt-domain`, `blt-genai` (read-only) | `.opencode/agents/` |
| BLT routing and hard stops, loaded through `opencode.json` `instructions` | `AGENTS.local.md` |
| Rehearsal and apply script | `.opencode/bin/fefo-adopt.sh` |

Rehearsal result (2026-11-12, `FEFO@63c94f7`): five MCP names identical before and after, `sync`
leaves `AGENTS.local.md` and the vault untouched, `fefo doctor` 0 errors and the 2 expected warnings.
Not done yet: the apply, the indexes through FEFO, the OpenCode restart and the per-server checks.
Nothing was committed and nothing under `blt-project/` was touched.

## Delivery (from the company's e-mail)

One public repository only, `blt-project`, with the code, `GENAI.md` at the root and a
presentation (written and sent separately by the user; the repository no longer carries one); no symlinks; deadline Friday 13 Nov, 12:30 (Brazil). After the
submission the work is frozen until further notice. This repository is the optional companion
described in `GENAI.md` and is not what gets sent.

## State

The audit and refactor of 2026-11-10/11 is committed in both repositories; `blt-project` is
the repository presented for the selection process, `BLT` keeps the AI orchestration
(MCP launchers, plan, AI log) as a backup of how the work was done.

- https://github.com/campanafernando/blt-project
- https://github.com/campanafernando/BLT

## Verified (orchestrator, after the refactor)

| Check | Result |
|---|---|
| pytest | 231 passed, 95.75% coverage (80% floor), run 2026-11-12 after the end-to-end round |
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

## Final round (2026-11-12, `blt-project@4de40bd`, pushed)

Review of the styleguide use, then fixes, by `general` agents with owned file sets (backend, specs,
docs) and read-only review by `blt-domain` and `blt-genai`. Nothing was added to `blt-project` for FEFO.

- Circular import removed: e-mail code moved to `tasks/notifications.py`; `services.py` imports
  `notify_assignment` at the top.
- `UserListApi` uses `selectors.assignee_list`; one brief user serializer (`UserList` schema → `UserBrief`).
- `TaskInputSerializer` shared with `specs`; `assignee_field` defined once.
- HTMX form no longer repeats the title length; the service rejects it (422, tested).
- `specs`: `spec_generate`, `spec_publish`, keyword-only `spec_list`/`spec_get`, one 404 helper;
  `SpecAlreadyPublishedError` in `core/exceptions.py` (services no longer import DRF).
- Tests pin the tracker URL to `.invalid`; this exposed a test that called the network.
- Docs: a "why a service layer" section and the real deviations from the HackSoft styleguide
  (the old text claimed the opposite); why the spec flow and MCP exist; `AGENTS.md` fixed;
  no password in any file; `PRESENTATION.md` removed.
- Clean clone (`/tmp`, no AI key, no Docker): `make setup` + `make test` found a test that only passed with the AI key present (503 before URL validation); fixed in `4de40bd`, then 189 passed, 95.62%. The Docker stack and the browser were not re-run this round.
- `make lint` now covers `mcp_server/` as well (E402 allowed only in `server.py`, where `django.setup()` must run first), and the API tests cover a 201-character title on create and update.

## Second round (2026-11-12): subject → spec → issue, prompt, honesty fixes

- `POST /specs/` takes `issue_url` or a typed `subject`; prompt `spec-v2` is generic over both;
  `Spec.source`, migration `0002_spec_from_subject`; React has a two-option form; MCP
  `generate_spec(issue_url, subject)`. Verified live (real model, local Gitea, in-memory DB):
  subject → spec → issue → spec, second publish refused, issue deleted, Gitea back to 13 issues.
- `GENAI.md`: directives and audit paragraph (section 2), prompt framed as the one I would use,
  both directions, real run. `design-decisions.md`: Clean Architecture and TDD stated plainly,
  including that the `specs` adapters raise DRF exceptions.
- `.pre-commit-config.yaml` ruff hooks scoped to `api/`: from the repo root they used ruff defaults
  (88 columns) on `mcp_server/` and undid the project format. `make lint` covers `mcp_server/`.
- Not done: no browser run of the new React form; the Docker stack was not rebuilt (the running
  containers still hold the previous image).

## Third round (2026-11-12): `make up`, end-to-end in Chromium, `pyproject.toml`

- **Dependencies** are declared in `blt-project/api/pyproject.toml` (`[project]`, `[dependency-groups]`)
  and locked in `api/uv.lock`; `requirements*.txt/.in` are gone. The Dockerfile installs from the lock;
  `make install` is `uv sync`; `make lock` / `lock-check` (run by `make check`). Only boto3, botocore,
  coverage and psycopg moved version (minor or patch) against the old pins.
- **`make up` on the existing stack** rebuilt the images (first build of the uv Dockerfile) and ran
  migration `0002`. The seeded data and secrets were untouched.
- **End-to-end round**: API, React and HTMX in Chromium at 1440 and 390 px, live model and Gitea, with
  throwaway `e2e_*` users and a cleanup checked against the baseline. Final pass: API 29, React 52,
  HTMX 36, throttle 2, cleanup 3. Plan, results and defects: `blt-project/docs/e2e-round.md`. The
  script is outside the repository.
- **Defects found and fixed**: invalid filter values were silently ignored (now 400); "Unassigned"
  clipped in both clients; HTMX date filter cut on a phone; React summary lacked "Done"; row buttons
  lacked the task name. Observed and left: `overdue=maybe`, a 16 px checkbox on a phone, a toast over
  the nav, and a Chromium quirk that reports a 204 `DELETE` as `ERR_ABORTED` (reproduced with a bare
  `fetch`).
- **Pre-commit**: ruff hooks scoped to `api/`; verified with `uvx pre-commit run --all-files`.

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
  the git history. The shared password did, before this change; it was then rotated with
  `make password`, so the value in the history no longer opens anything.
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
- The old shared password is still in the git history, but it was rotated and is refused by the
  API and by Gitea; `make password` repeats the rotation.
- Old copies of `.env` and database/Gitea dumps from before the rotation may exist outside the
  repositories (`~/blt-backup-*`); they hold retired and still-live secrets and should be deleted.
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
