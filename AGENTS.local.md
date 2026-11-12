<!-- FEFO never overwrites this file. BLT-specific routing and knowledge live here. -->
# Local instructions — BLT

## Where to start

1. Read `AGENTS.md` (the BLT rules; after the FEFO adoption they are the "BLT rules" section below).
2. Read `docs/vault/README.md`, then the note for the area you touch (`layout`, `domain`, `contracts`,
   `spec-flow`, `mcp-and-secrets`, `decisions`).
3. State and next work: `docs/HANDOFF.md`. **Pending: adopt FEFO** by following
   `docs/fefo/ADOPTION.md` (a separate session; the plan and the checks are already written).

## Federation

BLT orchestrates; `blt-project` implements. `blt-project` is one Git root with two federated
entries, `api` (`blt-project/api`) and `web` (`blt-project/web`). `mcp_server/`, Compose, `infra/`
and `scripts/` belong to no entry. The ownership map and the check commands are in
`docs/vault/layout.md`.

## BLT specialists (not in the generated routing table)

| Work | Agent |
|---|---|
| Task rules, visibility, assignment, status, notifications: state the rule and its proof | `blt-domain` (read-only), then `backend` |
| Gitea → spec → issue or tasks, the prompt, the contract around the model call | `blt-genai` (read-only), then `backend` |
| API ↔ React contract (schema, `types.ts`, error shape) | `cross-stack`, procedure in `docs/vault/contracts.md` |
| MCP servers, database roles, secrets | `security` (review) and `integration`, invariants in `docs/vault/mcp-and-secrets.md` |

A specialist advises; the layer agents edit. One owner per file set.

## Hard stops (in addition to the rules)

- `blt-project/` is frozen until the selection-process submission is closed (Friday 2026-11-13
  12:30, Brazil): no edit, format, commit or push there. `fefo index` may touch its git-ignored
  `.codegraph/` only.
- Never read, print, copy or commit `.env` or anything under `secrets/` or `blt-project/secrets/`.
- Never run `fefo init` or `fefo add blt-project` here: the manifest is hand-written (decision D9).
- Commit or push only with the user's explicit authorization, each time.
