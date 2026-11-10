# CodeGraph — BLT

Snapshots independentes por projeto, no mesmo formato do ANA e do LOGUS.

| Projeto | Escopo |
|---|---|
| `api` | `blt-project/api` |
| `web` | `blt-project/web` |

## Preparar

```sh
python3 .opencode/bin/codegraph-repos.py sync BLT
```

O comando restaura o snapshot quando necessário e usa sync incremental. Não indexe o
repositório inteiro a cada sessão.

## Consultar

Use o MCP `codegraph` com o `projectPath` absoluto:

- `/home/fefo/BLT/blt-project/api`
- `/home/fefo/BLT/blt-project/web`

O índice do orquestrador não inclui `blt-project/` por ser um repositório independente.
