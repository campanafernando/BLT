# AI log — BLT

Record of AI tooling usage in the project. It feeds the GenAI section of the delivery
and serves as evidence during code review.

## Format

Each entry has: goal, tool, prompt, what was accepted, what was corrected and why.

---

## 2026-11-10 — Initial scaffold

**Goal:** create the Django + DRF + React + HTMX base.

**Tool:** OpenCode (`deepseek-v4.1-flash`), with the ANA/LOGUS workspace as context.

**Prompt:** see `blt-project/docs/ai/01-scaffold-prompt.md`.

**Accepted without changes:**
- Settings structure driven by environment variables.
- SimpleJWT and drf-spectacular configuration.

**Corrected:**
- Dead permission class removed (0% coverage exposed it).
- OpenAPI schema repaired: explicit parameters and response serializers.
- Throttle state leaking between tests; cache cleared per test.
- 404/403 mismatch between the API and the HTMX client.
- MinIO image replaced by a pinned source build.

**Discarded:**
- Repository/use-case layers; they added ceremony without a rule.
- `drf-yasg`; unmaintained and Swagger 2 only.

**Lesson:** the prompt sets the rules; the failures were in what the prompt did not say.

---

## 2026-11-10 — Spec from issue

**Goal:** add one bounded GenAI feature, with no free-form prompt.

**Prompt:** see the spec block in `01-scaffold-prompt.md`.

**Accepted:**
- JSON contract shape and the fixed system prompt.
- Persisting model, prompt version, latency and input size with each spec.

**Corrected:**
- Gitea returns `pull_request: null` on regular issues; the guard rejected every issue.
- Provider requires an `x-opencode-session` header; a missing header was a 400.
- Publish path needed a read-only-by-default decision; writing is explicit and opt-in.

**Discarded:**
- Free chat, streaming and multiple providers.
- Creating tasks from the spec; postponed to keep one write path.

**Lesson:** the value of a GenAI feature is the contract around it, not the model call.

---

## 2026-11-11 — Audit and refactor with parallel subagents

**Goal:** audit the whole project, then fix what the audit found: security, the service
layer, the UI, and the missing "tasks from a spec" feature.

**Tool:** OpenCode with parallel subagents, one per area. The main session read the audit,
split the work, and integrated and verified the result.

**Plan:** eight workstreams (A–H) with disjoint file ownership, so no two agents edited the
same file. The areas were security and infrastructure, the `tasks` service layer, the spec
flow (including tasks from a spec), the React and HTMX UI, and documentation (agent F, this
entry). The per-letter assignment was not written down in the repository.

**Accepted:**
- Gitea repository allowlist, plain-text rendering of model output, idempotent publish
  claim, narrower `/auth/users/` and `/specs/config/`, a separate `spec_publish` throttle,
  `NUM_PROXIES`, a non-admin Gitea bot, per-service env in Compose, a read-only Postgres
  role and MinIO user, random secrets from `make env`.
- HackSoft naming: `task_*` services, `task_list`/`task_get`/`task_summary`/`assignee_list`
  selectors, a DRF exception handler for Django exceptions, `BaseModel`, a `CheckConstraint`
  on `completed_at`.
- HTMX views reusing the services; jargon removed from both UIs; spec → tasks (endpoint,
  React dialog, MCP tool with `confirm`).

**Corrected during integration:**
- The HTMX form was left prefilled after a successful create.
- `published` counted the `pending` publish marker as published.
- A test created a done task without `completed_at`, which the new constraint rejects.
- `postgres-readonly.sql` (now rewritten in `mcp_servers/`) had never worked.
- A psql variable was not expanded inside a `$$` block.

**Deviation kept on purpose:** one API class per URL, not one per resource, to keep the
published paths, operation ids and schema.

**Verified (by the orchestrator):** 186 tests at 96.76% coverage, ruff, `manage.py check`,
`makemigrations --check`, OpenAPI schema validation with no warnings, React typecheck and
build, `docker compose config -q`.

**Live run (same day, after the merge).** The stack was recreated from scratch
(`down -v`, with a database and Gitea backup first) and exercised end to end. It found
three things that tests with mocks had not:
- the Gitea seed got 403: creating a repository needs the `write:user` scope. I first
  kept the runtime token narrow (`write:issue`) and let the seed use the bot's password;
  the owner then decided the local stack should expose every scope so the app can use the
  whole Gitea API, so the token is `all` again and the repository allowlist is the guard;
- the MinIO read-only user could not list the bucket, because the built-in `readonly`
  policy has no `ListBucket`; it now has a policy scoped to the project bucket (list and
  get, and writes and deletes were checked to be denied);
- a real spec generation failed with "invalid JSON": the reasoning tokens share
  `max_tokens`, so longer answers were cut off. The cap is 4000 and a truncated or empty
  answer has its own message. The failure was intermittent and was reproduced by forcing a
  small limit, not by waiting for it.

**A wrong turn, reverted.** A request to make the product repository self-contained was
read as "move the MCP launchers into `blt-project`". The intent was the opposite:
`blt-project` is the logic-only repository that gets presented and `BLT` keeps the AI
orchestration. The move was stopped, reverted file by file (the moved files had mixed edits
from two agents) and `blt-project/opencode.json` was reduced to its own `blt-specs` server.

**Not verified:** no browser or E2E run of the React and HTMX flows (no driver available);
`unblock_account()` is still called by the seed and worked on the fresh volume, but was not
tested for removal.

**Lesson:** disjoint ownership kept the parallel work from colliding, but every seam
(constraint vs. test data, marker vs. counter, SQL vs. psql variables, token scope vs.
seed) showed up only when the pieces ran together against real services. And an ambiguous
instruction is cheaper to confirm than to move and revert.

## 2026-11-11 — UI aligned with ballastlane.com

**Goal:** make the fonts, colours and components of both clients match the Ballast Lane site,
as the argument for the UI choices in the presentation.

**Tool:** OpenCode with two parallel subagents (React and HTMX) after measuring the site
myself in a headless browser.

**Method:** the previous palette was recalled, not measured. I read the computed styles of
the live site (body, headings, buttons, links, nav, fields, labels, cards, footer) and wrote
them down as one token table, then gave the same table to both agents with disjoint files.
The measurement corrected three assumptions: the body font is Space Grotesk, not Poppins;
the primary button is orange with dark text, not blue with white text; and the corners are
8 px (controls) and 10 px (cards), not 10 and 14.

**Verification:** a script compares 60 computed values in both running clients with the
measured tokens (all match), checks that no font other than Space Grotesk and IBM Plex Mono
loads, computes the WCAG contrast of the key pairs (all at least 4.5:1) and takes desktop,
mobile and dialog screenshots that I looked at. The functional browser smoke test still
passes with no console errors.

**Corrected / kept on purpose:** orange text fails AA on light backgrounds, so it is used
only for fills and borders; an HTMX mobile bug (the check button clipped by a CSS
specificity clash) was fixed along the way; no dark theme.

**Lesson:** "follows the site" is only a claim until the numbers are read from the site and
compared with the running app.

## 2026-11-11 — Task table alignment

**Goal:** the screenshot showed status badges drifting per row, the edit icon sliding when a
task could not be deleted, and the same labels repeated on every row.

**Method:** I named the causes from the screenshot (no status column, an actions cell whose
width depended on permissions, per-row labels), wrote one spec for both clients (fixed grid,
what each per-row difference looks like, tooltips, hover) and gave it to two agents in
parallel. The check was a script, not a look: it creates deliberately uneven rows (a title of
140 characters, no date, no assignee, overdue, due today and tomorrow, done, created by someone
else) and measures every cell's position in both clients at five widths.

**Result and a correction:** 56 checks pass. Reading the screenshots side by side still found
three inconsistencies the numbers did not (HTMX dates in a different font and without a leading
zero, and an extra badge that made overdue rows taller), which I fixed afterwards.

**Gitea login:** the Gitea bot now signs in with `blt@mail.com` and the shared password. Gitea refuses
short passwords by default, so `MIN_PASSWORD_LENGTH` was lowered for the local stack; the email
of an existing account cannot be changed by the CLI, so the Gitea volume was recreated and the
seed rebuilt the repository and the 13 issues.

## 2026-11-11 — Passwords moved into secret files

**Goal:** no password or key in code, docs, `.env`, tests or the container environment, keeping
every current login working.

**Design:** one mechanism instead of per-service tweaks: files in `secrets/`, mounted by Compose
under `/run/secrets` and read by `config/secret_files.py` (the environment is only a fallback for
CI). `make env` creates them and moves any value still in an old `.env` with the same value, so
the existing logins and database volumes needed no change.

**Checked, not assumed:** every migrated value was compared by hash with the old one; a scan of
`docker inspect` for all 13 containers found no secret value; each service was listed to confirm
it only reads what it needs (the worker does not see the shared password or the AI key); the
three BLT logins, the Gitea logins and the Postgres MCP launcher all worked with the file values;
production refuses to start without a Django key.

**What it cannot fix:** the shared password was committed before this change, so it is in the
history of both repositories on GitHub. Real secrets (database, Django key, MinIO, AI key) never
were. Cleaning the history means rewriting and force-pushing a public repository, which needs an
explicit decision.

