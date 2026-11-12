# Decisions

Durable decisions: date, context, decision, consequence. Not a task tracker. The long reasoning
for D1–D8 is in [`../architecture.md`](../architecture.md) and
`blt-project/docs/design-decisions.md`; the entries here are the short form an agent can rely on. D1–D8 were made during the build
(2026-11-10/11) and distilled here on 2026-11-12; D9 onwards were made on 2026-11-12.

## D1 — Two clients over one service layer
React and HTMX + Alpine call the same services and selectors. A rule exists once.
Consequence: a rule in a view, serializer or template is a defect; `hypermedia/tests/test_delete_rule.py` guards it.

## D2 — Views validate, services decide, selectors scope, models keep invariants
HackSoft naming; no repository, use-case or DTO layer. Consequence: new rules go in `services.py`; new reads in `selectors.py`.

## D3 — One `APIView` per URL, not a `ViewSet`
Keeps published paths, operation ids and schema names; each endpoint is readable in about 15 lines.
Consequence: more classes; do not collapse them.

## D4 — A stranger gets 404, not 403
Detail lookups use the visibility selector. Only delete is creator-restricted (403).

## D5 — `is_overdue` is derived
No stored flag and no nightly job. Consequence: the filter and the summary repeat the same predicate in the query.

## D6 — Notifications use `on_commit`
A rolled-back transaction sends no e-mail; a dead broker does not block the request.

## D7 — JWT for React, session for HTMX
Refresh token in `localStorage` is a documented trade-off; production should use an `HttpOnly` cookie or a backend-for-frontend.

## D8 — The spec flow is bounded
One fixed task, JSON contract around the model call, no tools, publish and task creation as separate explicit actions. See `spec-flow.md`.

## D9 — Federate `api` and `web` as two entries of one Git root (2026-11-12)
Context: FEFO registers one entry per Git root and guesses the stack; `blt-project` is one root with a Django API and a React client.
Decision: the manifest is written by hand with `api` and `web` (names keep the MCP names `codegraph-api` / `codegraph-web`); `fefo init` and `fefo add blt-project` are not used.
Consequence: `doctor` warns "not a Git repository" for both entries (expected); the commands are BLT's (`make`, pytest), not FEFO's Django defaults.

## D10 — BLT rules move to `AGENTS.local.md` on adoption (2026-11-12)
Context: `fefo sync` regenerates `AGENTS.md`; the rules currently live there.
Decision: before the first sync the rules are appended to `AGENTS.local.md`, which FEFO never overwrites.
Consequence: `AGENTS.md` becomes the generated routing contract; BLT rules and specialist routing live in `AGENTS.local.md`.

## D11 — Custom MCP launchers stay; the manifest owns their definition (2026-11-12)
Decision: `postgres-blt`, `minio-blt` and `blt-specs` go in `mcp_servers` of the manifest and keep their launchers; `codegraph-mcp.sh` is replaced by FEFO's direct `codegraph serve`.
Consequence: secrets stay out of the manifest; the index must exist before the server starts (`fefo index`), the old launcher created it on demand.

## D12 — Harnesses: OpenCode and Claude Code only (2026-11-12)
Decision: `harnesses = ["opencode", "claude"]`. Cursor and Copilot add generated files with the same content and nobody uses them here.
Consequence: add `cursor` or `copilot` to the manifest and run `fefo sync` if that changes.

## D13 — BLT adopts FEFO in place, after the submission (2026-11-12)
Decision: the FEFO machinery (`bin/fefo`, `tools/fefo.py`, base agents, commands, skills) is copied into this repository by an explicit file list; FEFO's `README.md`, `docs/` and `AGENTS.md` are never copied. Execution follows `../fefo/ADOPTION.md` and waits until the `blt-project` submission is closed.
Consequence: BLT keeps its history and remote; `blt-project` is not touched.
