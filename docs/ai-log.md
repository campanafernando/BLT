# AI log — BLT

Record of AI tooling usage in the project. It feeds the GenAI section of the delivery
and serves as evidence during code review.

## Format

Each entry has: goal, tool, prompt, what was accepted, what was corrected and why.

---

## 2026-11-10 — Initial scaffold

**Goal:** create the Django + DRF + React + HTMX base.

**Tool:** OpenCode (`deepseek-v4.1-flash`), with the ANA/LOGUS workspace as context.

**Prompt:** see `blt-project/GENAI.md` (2.5 and 2.6).

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

## 2026-11-11 — Rotating the shared password

**Goal:** the password that had been committed had to stop meaning anything, without rewriting the
public history, and the new one had to apply to every login, Gitea included.

**Approach:** make the rotation a command (`make password`) instead of a one-off: new password in
`secrets/blt_password`, a new Django key so no earlier session or token survives, API recreated so
the seed sets the new password, Gitea init re-run for the three accounts.

**What the check found that my first check missed:**
- `gitea admin user change-password` marks the account "must change password" unless told
  otherwise, and Gitea then refuses its API until the web flow is done. My first login check
  counted any page other than the login form as success, which included the forced-change page, so
  it passed while the bot was blocked. The API call that failed and a 403 on the token list exposed
  it. The init now passes `--must-change-password=false`, and the check classifies the landing page.
- `ballast` and `lane` were only created, never updated, so a rotation would have left them on the
  old password.
- Gitea keeps old API tokens alive after a password change. The init now revokes every token of
  the bot except the new one (one token remains, and the API reads the issue with it).

**Verified:** all three BLT users and all four Gitea logins accept the new password on the web and
the API and refuse the old one; a token and a refresh token issued before the rotation get 401; no
container's `docker inspect`, no tracked file and no commit contains the new value.

**Left on purpose:** the old password stays in the git history (now useless), and backups from
before the rotation sit outside the repositories until they are deleted.


---

## 2026-11-12 — Preparing BLT to adopt the FEFO pattern

**Goal:** structure BLT's agents and knowledge base so a later session can turn it into a FEFO
workspace in place, with the base already updated. BLT only; `blt-project` stays frozen.

**Tool:** OpenCode (Claude Sonnet 5.5). Read both repositories and FEFO's generator
(`tools/fefo.py`) before writing anything, to learn what `fefo sync` overwrites and what it keeps.

**Found:**
- `sync` regenerates `AGENTS.md`, `opencode.json`, `.mcp.json` and `codegraph/README.md`. BLT's rules
  lived in `AGENTS.md`, so a plain adoption would have deleted them.
- `fefo add` snaps to the Git root, so `api` and `web` (one root, two indexes, two MCP names) cannot
  be registered by the CLI; the stack guess for `blt-project` would be `infra`.
- FEFO's `docs/architecture.md` collides with BLT's; its Django commands are not BLT's (pytest, make).
- Stale text in BLT: a `codegraph/README.md` pointing to a script that does not exist, two broken
  links in `docs/architecture.md`, "secrets only in `.env`" and "`blt-specs` writes only issues".

**Accepted:** a hand-written manifest; a vault in FEFO's layout whose rules each cite a file and a
test; two read-only specialists (`blt-domain`, `blt-genai`); the rules moved to `AGENTS.local.md`
by the script at adoption time; a script that rehearses the whole adoption on a throwaway copy and
refuses to apply on a dirty tree.

**Corrected:** the vault's first draft claimed a test baseline I had not run; it now points to the
HANDOFF record and says to re-run `make check`. Dates of D1–D8 were guessed; they now say they were
distilled on 2026-11-12 from the build of 2026-11-10/11.

**Discarded:** copying FEFO's whole template (it would overwrite README and `docs/`); extra skills and
commands (the runbook and the vault carry the procedure); `fefo init` (it would guess the stack wrong).

**Lesson:** read the generator's overwrite rules before deciding where knowledge lives; then prove the
plan with a rehearsal instead of describing it.

## 2026-11-12 — Final round on blt-project: review, fixes, consistency

**Goal:** check the HackSoft styleguide use against the exercise, remove what a reviewer could knock
down in ten seconds, and close in one round.

**Tool and workflow:** OpenCode from the orchestrator; CodeGraph queried with the project path of
`blt-project/api`; three `general` agents with disjoint file sets (backend, specs, docs), then
`blt-domain` and `blt-genai` as read-only reviewers; my own run of the checks. The first backend
agent refused to edit because of the freeze written in `AGENTS.local.md`; it could not see the
user's grant, so it was relayed explicitly rather than weakening the rule.

**Found:** docs claimed the styleguide groups endpoints in one class (it says one API per operation);
`AGENTS.md` still said secrets live in `.env`; services imported DRF; a circular import was patched
with a function-level import; specs had not been through the earlier refactor; test counts differed
between documents.

**Corrected after review:** the reviewers found a doc using the old exception name, a stale comment,
a doc promising a link in the 409 message the code does not return, and an MCP claim that overstated
"same services". Fixed by hand.

**Discarded:** a `compose.test.yaml` and Factory Boy from FRETE-E (surface without a need here).

**Lesson:** pinning the tracker URL in tests found a network call a mock had hidden; an agent's
refusal on a freeze was correct behaviour, and the fix was to state the grant, not to bypass it.

**Found only by a clean clone:** `test_create_rejects_invalid_url` passed here because the AI key exists on this machine and failed (503) without it. Neither the agents nor the reviewers could see it; a clone in `/tmp` without secrets did. Fixed by pinning `AI_ENABLED` in the test.

## 2026-11-12 (later) — Subject → spec → issue, and the claims around it

**Goal:** make the system go both ways with the tracker through the AI (issue → spec, and a typed
subject → spec → new issue), with one generic prompt; state the user's directives and audit in
GENAI.md; fix the caveats found in the delivery check.

**Tool and workflow:** two `general` agents with disjoint file sets (specs backend; web), the
contract fixed by me beforehand; I read the diffs, ran the checks and a live round trip myself.

**Accepted:** the serializer-plus-service guard for "exactly one input"; a nullable `issue_number` and
a `source` property instead of a second model; the vague-input rule in the prompt.

**Corrected:** the agents reported lint clean; running `pre-commit` showed it reformatted
`mcp_server/` to 88 columns because the hook ran without the project's ruff config. The hooks are now
scoped to `api/`. I also left a docs claim to check: "services do not depend on DRF" is true for
`tasks` and for `specs/services.py`, but the adapters it calls raise DRF exceptions, so the Clean
Architecture note says so.

**Lesson:** a live run against the real model and tracker is the only check of this feature that
the mocked tests cannot give; it took one script and left the Gitea seed as it was.


## 2026-11-12 (evening) — pyproject, `make up`, a browser round

**Goal:** meet the exercise's `pyproject.toml` requirement, run the real stack, and test both clients
and the API in Chromium without leaving data behind.

**Tool and workflow:** one `general` agent for the dependency migration (owned files, no Docker);
I ran `make up`, wrote the round as a Node script outside the repository (`playwright-core` with the
Chromium already cached), read the failures and the screenshots myself. The model calls were real.

**Accepted:** uv with a lock file and `package = false`; a round that creates its own users so no
seeded secret is read; cleanup verified against counts taken first.

**Corrected:** most first failures were my assumptions, not the product: a substring selector that
also matched a history button, a Delete button that is hidden (correctly) for a non-creator, a user
whose task count changed between phases, and a Chromium `ERR_ABORTED` for a 204 `DELETE` that a bare
`fetch` reproduced. Five were real and were fixed (see HANDOFF).

**Discarded:** committing the browser script (a new dependency and a harness that drives Docker);
making `overdue` strict (django-filter treats an unknown boolean as empty).

**Lesson:** a screenshot found two defects that every assertion passed (a clipped letter, a cut date);
and an assertion that passes because the page had nothing to check (no unassigned row) proves nothing,
so look at the evidence.
