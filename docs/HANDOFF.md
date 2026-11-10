# Handoff — BLT

Atualizado: 2026-11-10

## Estado

Projeto criado, validado de ponta a ponta e publicado. A feature de GenAI está na `main`:

- https://github.com/campanafernando/blt-project
- https://github.com/campanafernando/BLT

## Verificado nesta sessão

| Verificação | Resultado |
|---|---|
| Django check | 0 issues |
| pytest | 87 passed, 96,7% coverage (piso de 80%) |
| ruff check + format | limpo |
| drf-spectacular `--validate --fail-on-warn` | schema sem warning |
| React typecheck + build | limpos |
| `docker compose up` | db, redis, mailpit, api, worker, beat, web |
| Fluxo real | login JWT, tarefa, e-mail no Mailpit via worker, board HTMX |
| GenAI real | issue #1 → spec (9,2s no provedor) → issue #5 publicada |
| MCP | Postgres, CodeGraph api/web e specs respondendo por stdio |
| MinIO | build da release, bucket `blt-media`, objeto de teste e MCP read-only |
| CI | workflow válido; execução bloqueada por billing do GitHub |

## O que está pronto

- `blt-project/api`: Django 6.0.10, DRF 3.18.3, SimpleJWT 5.5.1, spectacular 0.29,
  django-filter 25.2, Celery 5.7, Postgres/SQLite, throttling, paginação, filtros.
- `blt-project/api/tasks`: modelo, serviços, seletores, filtros, views e testes.
- `blt-project/api/accounts`: JWT, refresh, me, usuários ativos.
- `blt-project/api/specs`: spec a partir de issue, contrato JSON, publicação de issue.
- `blt-project/api/hypermedia`: board SSR com partials, OOB swap, 422, Alpine no dialog.
- `blt-project/web`: React 19 + Vite 7 + TanStack Query 5 + RHF, tokens da Ballast Lane,
  aba **Spec** além do board.
- `blt-project/mcp_server`: quatro ferramentas MCP sobre os mesmos serviços.
- `blt-project/compose.yaml`: Postgres 16, Redis 7, Mailpit, API, worker, beat, Nginx,
  MinIO em profile `storage`.
- `blt-project/.github/workflows/ci.yml`: API em Postgres + web typecheck/build.

## MCP (bônus)

- `opencode.json` e `.mcp.json` com cinco servidores: CodeGraph api/web, Postgres,
  MinIO e specs.
- Postgres com role `blt_mcp` somente leitura; MinIO sem ferramenta de escrita.
- `blt-specs` aponta para `blt-project/mcp_server/run.sh`; testado por stdio.
- Detalhes e comparação com o gateway do FRETE-E em `docs/mcp.md`.

## Próximo passo

1. Resolver o billing do GitHub para o CI rodar (hoje os jobs nem iniciam).
2. Publicar a demo (Railway ou VPS) com seed e as issues de exemplo.
3. Revisar `docs/ai/02-review.md` com os prompts reais da sessão.
4. Ensaiar `docs/demo.md` e gravar um backup de 5 minutos.
5. Opcional: criar tarefas a partir da spec (write path deliberadamente adiado).

## Pendências conhecidas

- Sem deploy público.
- Sem testes de componente no React (a API cobre as regras).
- Refresh token em `localStorage` — trade-off documentado.
- MinIO depende de build local (imagens não são mais publicadas).
- CI configurado, mas bloqueado por billing da conta GitHub.
