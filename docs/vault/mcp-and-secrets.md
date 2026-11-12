# MCP and secrets

Verified 2026-11-12 against `BLT@6b9b584`. Full design, security model and the rotation
procedure: [`../mcp.md`](../mcp.md). This note keeps what an agent must not break.

## Servers

| Name | Source | Mode | Defined in |
|---|---|---|---|
| `codegraph-api`, `codegraph-web` | `.codegraph/` index of `blt-project/api` and `blt-project/web` | read | manifest repos (generated) |
| `postgres-blt` | Compose Postgres, role `blt_mcp` | read-only | manifest `mcp_servers` → `.opencode/bin/postgres-mcp.sh` |
| `minio-blt` | Compose MinIO, read-only user | read-only | manifest `mcp_servers` → `.opencode/bin/minio-mcp.sh` |
| `blt-specs` | `blt-project/mcp_server` (same services as the API) | writes issues, and tasks only with `confirm=true` | manifest `mcp_servers` → `blt-project/mcp_server/run.sh` |

Client names (`codegraph-api`, …) are the contract with every session and harness. Do not rename
them.

## Invariants

- One server per source, one credential per server.
- `postgres-blt` runs `--access-mode restricted`; `blt_mcp` reads `tasks_task`, `specs_spec` and
  the view `mcp_users`, nothing else. Rerun `mcp_servers/postgres-readonly.sql` to widen it.
- `minio-blt` has no `put`, `delete` or `policy` tool and never uses the root keys.
- Do not add a write tool, or widen a role, without reviewing the contract and the database role.
- `blt-specs` writes only issues (in `GITEA_ALLOWED_REPOS`) and, with `confirm=true`, tasks.

## Secrets

- Plain configuration is in `.env` (git-ignored, documented in `.env.example`).
- **Passwords and keys are files**, never `.env` entries: `secrets/` here (`blt_pg_password`,
  `minio_mcp_secret`, `opencode_api_key`) and `blt-project/secrets/` for the application. Mode 700.
- `secrets/minio_mcp_secret` must equal `blt-project/secrets/minio_ro_secret`.
- An agent never reads, prints, copies or commits a secret file or `.env`. A manifest, a vault note
  or a log never holds a secret value.
- The old shared password is still in the git history of `blt-project`; it was rotated. Old
  `~/blt-backup-*` copies may hold live secrets and are to be deleted by the owner.

## FEFO note

The manifest (`.fefo/workspace.json`) is the source of truth for server definitions; `opencode.json`
and `.mcp.json` are generated from it. Add a server with `./bin/fefo mcp add`, not by editing the
generated files. The launchers in `.opencode/bin/` stay hand-written: they read `.env` and the
secret files, which the manifest must not hold.
