# BLT

**Backlog, Lists & Tasks** — repositório de orquestração do projeto BLT.

Projeto de referência full-stack: API Django/DRF com JWT e Celery, cliente React
(Vite) e um cliente alternativo server-rendered com HTMX + Alpine.js sobre a mesma
camada de serviços.

## Ecossistema

| Repositório | Conteúdo |
|---|---|
| `BLT` | Orquestração, documentação, plano, log de IA e snapshots CodeGraph |
| [`blt-project`](https://github.com/campanafernando/blt-project) | `api/` (Django), `web/` (React) e `hypermedia/` (HTMX + Alpine) |

`blt-project/` é um repositório Git independente dentro desta pasta, como
`ana-api/` e `ana-web/` no ANA e `logus-api/` no LOGUS. Não é submódulo.

## Início rápido

```sh
cp .env.example .env          # preencha OPENCODE_API_KEY se for usar IA
cd blt-project
cp .env.example .env
make setup                    # uv sync + bun install + migrate + seed
make api                      # http://127.0.0.1:8000
make web                      # http://127.0.0.1:5173  (outro terminal)
make htmx                     # http://127.0.0.1:8000/app/
```

Credenciais de demonstração: `demo` / `demo12345`.

## Documentação

| Documento | Assunto |
|---|---|
| [`docs/HANDOFF.md`](docs/HANDOFF.md) | Estado atual, decisões e próximo passo |
| [`docs/architecture.md`](docs/architecture.md) | Fronteiras entre API, React e HTMX |
| [`docs/plan.md`](docs/plan.md) | Plano de execução e critérios de aceite |
| [`docs/ai-log.md`](docs/ai-log.md) | Registro de uso de ferramentas de IA |
| [`docs/tasks/mvp.md`](docs/tasks/mvp.md) | Escopo funcional mínimo |
| [`blt-project/README.md`](blt-project/README.md) | Como rodar, endpoints e decisões |

## Workflow

1. Trabalho acionável em `docs/tasks/mvp.md`.
2. Contrato da API antes do cliente: schema OpenAPI → tipos gerados.
3. Implementar em `blt-project/`, com testes na mesma entrega.
4. `make check` no projeto antes de encerrar a tarefa.
5. Registrar prompts, correções e trade-offs em `docs/ai-log.md`.
6. Atualizar `HANDOFF.md` e o changelog do `blt-project`.

## Regras

- Branch de trabalho: `main` (projeto novo, sem ambientes).
- Nunca commitar ou publicar sem autorização explícita.
- Segredos apenas em `.env`; `.env.example` documenta as chaves.
- PT-BR na documentação e na UX; identificadores em inglês.
