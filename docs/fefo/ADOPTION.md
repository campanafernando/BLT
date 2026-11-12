# Adopting FEFO in BLT — runbook for the next session

Prepared 2026-11-12 on `BLT@6b9b584` (+ the uncommitted preparation), `blt-project@5222d7f`,
`FEFO@63c94f7`. The preparation is finished and rehearsed; this session only executes it.

## Goal

BLT becomes a FEFO workspace **in place** (same repository, history and remote): manifest-driven
`opencode.json` / `.mcp.json` / `AGENTS.md`, FEFO base agents + commands + skills next to the BLT
specialists, the vault as the knowledge base, and the CLI (`./bin/fefo`) in the repository.

Not in scope: any change inside `blt-project/` (frozen, see `docs/vault/layout.md`), any change to
the FEFO repository, any commit or push without the user's explicit authorization.

## What is already prepared (do not redo)

| Piece | Where | Survives `fefo sync` |
|---|---|---|
| Manifest: `api`, `web`, three custom MCPs, harnesses `opencode` + `claude` | `.fefo/workspace.json` | input, never overwritten |
| Vault: layout, domain, contracts, spec-flow, mcp-and-secrets, decisions D1–D13, repo notes | `docs/vault/` | yes (only `00-INDEX.md`, `federation.md` and the marked block in `repos/*.md` are regenerated) |
| Specialists `blt-domain`, `blt-genai` (read-only) | `.opencode/agents/` | yes (BLT-owned names) |
| BLT routing, hard stops, vault pointers | `AGENTS.local.md` | yes, never overwritten |
| Adoption + rehearsal script | `.opencode/bin/fefo-adopt.sh` | yes |
| Launchers for postgres, minio | `.opencode/bin/*.sh` | yes (FEFO does not own that folder) |

What `sync` **overwrites**, and why nothing is lost: `AGENTS.md` (rules are first appended to
`AGENTS.local.md` by the script), `opencode.json` and `.mcp.json` (rebuilt from the manifest; the
five server names are asserted identical), `codegraph/README.md`, `.fefo/README.md`, `CLAUDE.md`,
`.claude/` (new).

## Preconditions (check, do not assume)

1. The user said go, or the submission is closed (Friday 2026-11-13 12:30, Brazil).
2. `git -C /home/fefo/BLT/blt-project status --short` is empty; note `git -C … rev-parse HEAD`.
3. `/home/fefo/FEFO` is clean at `63c94f7` (`git -C /home/fefo/FEFO rev-parse HEAD`). If it moved,
   run the rehearsal first and update `FEFO_REV` in the script only if it passes.
4. `codegraph`, `python3` and `uv` are on `PATH`.
5. Do not open or print `.env` or any file under `secrets/`. Nothing in this runbook needs them.

## Steps

1. **Rehearse.** `bash .opencode/bin/fefo-adopt.sh`. It builds a throwaway copy (no `.env`, no
   `secrets/`, `blt-project` symlinked read-only), copies the FEFO machinery by an explicit list,
   moves the rules, runs `sync` and checks: five MCP names, `AGENTS.local.md` and the vault
   untouched by `sync`, `doctor` with no error. Expected: `0 error(s), 2 warning(s)` (the two are
   "not a Git repository: api / web", decision D9). Anything else: stop and report.
2. **Ask the user to commit the preparation** (`.fefo/`, `docs/vault/`, `docs/fefo/`,
   `AGENTS.local.md`, `.opencode/agents/`, `.opencode/bin/fefo-adopt.sh` and the edits listed by
   `git status`). The script refuses to apply on a dirty tree, and git is the rollback.
3. **Apply.** `bash .opencode/bin/fefo-adopt.sh --apply`. Same steps as the rehearsal, in this repository.
4. **Index.** `./bin/fefo index` (runs `codegraph sync` on both projects; writes only the
   git-ignored `.codegraph/` inside `blt-project`). Then `./bin/fefo status`.
5. **Doctor.** `./bin/fefo doctor` → 0 errors; the two expected warnings.
6. **Restart OpenCode** at `/home/fefo/BLT` (the MCP config changed) and verify each server, one call each:
   `codegraph-api` and `codegraph-web` (`codegraph_status`), then, only if the Compose stack is up
   (`cd blt-project && make up`): `postgres-blt` (list schemas), `minio-blt` (`list_buckets`),
   `blt-specs` (`list_specs`). Report any server not verified as **not verified**, not as working.
7. **Close the loop in the docs** (BLT files only):
   - delete `.opencode/bin/codegraph-mcp.sh` (replaced by `codegraph serve`; D11) and fix its two
     mentions in `docs/mcp.md` ("Running it", step 3, and the "one launcher per source" list);
     `grep -rn codegraph-mcp` must then find only `docs/vault/decisions.md`;
   - `AGENTS.local.md`: replace the "Pending: adopt FEFO" line with "FEFO adopted on <date>";
   - `docs/mcp.md`: say the manifest is the source of truth for server definitions (`./bin/fefo mcp add`)
     and that the manifest plays the routing role the FRETE-E gateway plays at scale;
   - `README.md`: Ecosystem/Documentation/Workflow mention `docs/vault/`, `./bin/fefo` and this runbook;
   - `docs/HANDOFF.md` ("Next round" → done, add the verification results), `docs/plan.md` block 8,
     `docs/ai-log.md` (new dated entry: goal, tool, what was accepted/corrected/discarded);
   - `docs/vault/decisions.md`: append what changed from D9–D13 if reality differed.
8. **Run the BLT-side checks**: `python3 -I` link check of the Markdown files (no broken relative
   link), `./bin/fefo doctor`, `git status` showing only BLT files and **no change under `blt-project/`**
   (`git -C blt-project status --short` empty and `HEAD` unchanged).
9. **Report** what changed, what was verified with the exact commands, what was not, and ask for
   authorization to commit. Do not commit or push on your own.

## Stop and report if

- the rehearsal or `doctor` shows an error, or an unexpected warning;
- `sync` or any step touches a tracked file under `blt-project/`;
- a command would print or copy a secret;
- the diff of `AGENTS.local.md` after `sync` is not empty (the rules would be at risk);
- an MCP server name differs from the five in `docs/vault/mcp-and-secrets.md`.

## Rollback

The apply step starts from a clean, committed tree. Inspect with `git status` and `git diff`, then —
with the user's OK — `git restore .` and `git clean -fd -n` (dry run first; delete only what it lists
and what the apply step created: `bin/`, `tools/`, `.claude/`, `CLAUDE.md`, copied base agents, commands
and skills). `.codegraph/` indexes are git-ignored and harmless.

## Upstream notes for FEFO (do not act on them in this round)

Found while preparing this; worth an issue in the FEFO repository:

1. `00-INDEX.md` is regenerated and drops any user-owned link; BLT works around it with `docs/vault/README.md`.
2. `fefo add` always snaps to the Git root, so two directories of one repository (here `api` and
   `web`) cannot be registered from the CLI; the manifest has to be written by hand.
3. `doctor` warns "not a Git repository" for such entries.
4. There is no supported path for an existing workspace (roadmap v0.2, "bootstrap … without the FEFO
   template", is open). `fefo-adopt.sh` is a prototype of it; the copy list is the part to reuse.
5. FEFO's Django defaults (`python manage.py test`, `ruff check .`) are wrong for repositories that use
   pytest and `make`; the manifest overrides them.
6. `sync` rewrites `opencode.json` wholesale, so a hand-added key is lost; everything must come from the manifest.
