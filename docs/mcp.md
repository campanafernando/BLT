# BLT MCP servers

The orchestrator exposes five MCP connections. Four are read-only views over the
infrastructure; one is the product tool (specs), which also writes — but only issues, and
only when explicitly asked.

| Server | Source | Mode | Tools |
|---|---|---|---|
| `codegraph-api` | index of `blt-project/api` | read | symbols, callers, callees, impact, context |
| `codegraph-web` | index of `blt-project/web` | read | symbols, callers, callees, impact, context |
| `postgres-blt` | Compose Postgres | **read-only** | schemas, tables, details, restricted SQL |
| `minio-blt` | Compose MinIO | **read-only** | buckets, objects, metadata, presigned URL |
| `blt-specs` | `blt-project/mcp_server` (same services as the API) | read + issue write | list issues, generate spec, list specs, publish, create tasks from a spec (needs `confirm=true`) |

## Why one server per source

Credentials are the main reason. The Postgres MCP uses `blt_mcp`, a role with `SELECT`
on a short list of objects and nothing else; the MinIO server has no `put` or `delete` in its code. A single server
would leak a write credential into read-only tools.

The other reasons are operational: a slow server does not take the others down, each one
restarts or reindexes on its own, and the owner of the data defines the contract
(CodeGraph exposes navigation, Postgres exposes SQL, MinIO exposes objects).

## Running it

```sh
cp .env.example .env      # fill BLT_PG_PASSWORD and MINIO_SECRET_KEY
                          # (MINIO_SECRET_KEY = MINIO_RO_SECRET_KEY, the read-only user)

# 1. Project database and MinIO
cd blt-project
make up                   # postgres, redis, mailpit, gitea, api, web
docker compose --profile storage up -d minio minio-init

# 2. Read-only role (once)
cd ..
docker compose -f blt-project/compose.yaml exec -T db psql -U blt -d blt \
  -v mcp_password="$(grep '^BLT_PG_PASSWORD=' .env | cut -d= -f2-)" \
  -f - < mcp_servers/postgres-readonly.sql

# 3. CodeGraph indexes (the launcher creates them if missing)
bash .opencode/bin/codegraph-mcp.sh api   # blocks; use another terminal
```

Clients read `opencode.json` (OpenCode) or `.mcp.json` (Claude Code, Cursor and any MCP
client). No secret lives in those files: the launchers read `.env`.

## The FRETE-E gateway case

BLT is the compact version of what FRETE-E does at scale. There, the number of
repositories, databases and indexes does not fit in one file per client, so a **MCP
gateway** exists: a single connection point that routes to the right server per project,
keeps credentials on the server, and lets an implementation change without reconfiguring
every client.

There is no gateway here because there is one project. The structure is already the same:

- one launcher per source (`postgres-mcp.sh`, `minio-mcp.sh`, `codegraph-mcp.sh`);
- credentials per source, not global;
- the product server lives in the product repository (`blt-project/mcp_server`);
- the client only knows server names.

When a second project arrives, the natural next step is the gateway: the launchers become
internal implementations and the client talks to a single endpoint that resolves
`project + source`. That is exactly how FRETE-E evolved.

## Security

- `postgres-blt` runs with `--access-mode restricted`. The `blt_mcp` role has `SELECT` on
  two tables (`tasks_task`, `specs_spec`) and one view (`mcp_users`: id, username, names,
  `is_active`). Password hashes, the JWT blacklist and sessions are not readable. New
  tables are not granted automatically; rerun `postgres-readonly.sql` to widen access.
- `minio-blt` implements no write, and its credential is a MinIO user created by `minio-init`
  with a policy scoped to the project bucket (list and get, no put or delete). The built-in
  `readonly` policy is not used: it cannot list a bucket. It never uses the root keys.
- `blt-specs` writes only issues, only in `GITEA_ALLOWED_REPOS`, and only with Gitea
  credentials. The Gitea bot is not an admin and the token the API uses has only the
  `write:issue` scope; the one-shot `gitea-seed` creates the repository with the bot's
  password instead, so no long-lived token can create repositories.
- Compose services get an explicit `environment:` each, not the whole `.env`. The worker
  and beat see no AI, Gitea or storage secrets; only the API (and the one-shot
  `gitea-seed`) see Gitea.
- The MCP `cli` user is inactive with an unusable password: it owns specs but cannot log in.
- Keys live in `.env` (gitignored). `.mcp.json` and `opencode.json` are versioned because
  they hold no secret.

### One-time rotation for an existing local setup

`make env` never touches an existing `.env`, so older secrets stay until you change them.

1. In `blt-project/.env`: set new random values for `POSTGRES_PASSWORD`, `S3_SECRET_KEY`,
   `GITEA_PASSWORD` and a non-`django-insecure` `SECRET_KEY` (`openssl rand -hex 16`);
   add `MINIO_RO_ACCESS_KEY`, `MINIO_RO_SECRET_KEY` and `GITEA_ALLOWED_REPOS`.
2. Postgres and MinIO keep the password they were created with. Either run
   `docker compose down -v` (wipes all local data, and also recreates the Gitea bot
   without admin), or change them in place (`ALTER USER`, `mc admin user`).
3. Recreate the MCP role with the new password: rerun the command in "Running it".
4. In the BLT `.env`: point `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY` at the read-only user,
   and update `BLT_PG_PASSWORD`.
5. If the old `blt_mcp` password or any JWT was ever exposed to an MCP client, treat it as
   leaked: the new `SECRET_KEY` invalidates all issued tokens.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `Missing .env` | copy `.env.example` at the BLT root |
| Postgres 401 | role not created or password differs from `BLT_PG_PASSWORD` |
| MinIO ConnectionError | `storage` profile not running, or wrong endpoint port |
| CodeGraph "index not found" | run `codegraph init` + `index` in the target repo |
| `blt-specs` fails | run `make setup` in `blt-project`; Gitea must be up for issue tools |
