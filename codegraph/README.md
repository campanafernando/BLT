# CodeGraph — BLT

Independent snapshots per project, in the same format as ANA and LOGUS.

| Project | Scope |
|---|---|
| `api` | `blt-project/api` |
| `web` | `blt-project/web` |

## Prepare

```sh
python3 .opencode/bin/codegraph-repos.py sync BLT
```

The command restores the snapshot when needed and uses incremental sync. Do not index
the whole repository on every session.

## Query

Use the `codegraph` MCP with the absolute `projectPath`:

- `/home/fefo/BLT/blt-project/api`
- `/home/fefo/BLT/blt-project/web`

The orchestrator index does not include `blt-project/` because it is an independent
repository.
