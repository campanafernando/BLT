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
| `blt-specs` | BLT API | read + issue write | list issues, generate spec, list specs, publish |

## Why one server per source

Credentials are the main reason. The Postgres MCP uses `blt_mcp`, a role with `SELECT`
and nothing else; the MinIO server has no `put` or `delete` in its code. A single server
would leak a write credential into read-only tools.

The other reasons are operational: a slow server does not take the others down, each one
restarts or reindexes on its own, and the owner of the data defines the contract
(CodeGraph exposes navigation, Postgres exposes SQL, MinIO exposes objects).

## Running it

```sh
cp .env.example .env      # fill BLT_PG_PASSWORD and MINIO_SECRET_KEY

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

- `postgres-blt` runs with `--access-mode restricted`; the `blt_mcp` role has no `CREATE`,
  `INSERT`, `UPDATE` or `DELETE` (tested: `InsufficientPrivilege`).
- `minio-blt` implements no write: only `list`, `head` and a GET `presign`.
- `blt-specs` writes only issues in the spec's source repository, and only when Gitea
  credentials are configured.
- Keys live in `.env` (gitignored). `.mcp.json` and `opencode.json` are versioned because
  they hold no secret.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `Missing .env` | copy `.env.example` at the BLT root |
| Postgres 401 | role not created or password differs from `BLT_PG_PASSWORD` |
| MinIO ConnectionError | `storage` profile not running, or wrong endpoint port |
| CodeGraph "index not found" | run `codegraph init` + `index` in the target repo |
| `blt-specs` fails | run `make setup` in `blt-project`; Gitea must be up for issue tools |
