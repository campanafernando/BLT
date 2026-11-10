# Handoff — BLT

Atualizado: 2026-11-10

## Estado

Base criada, executável e validada de ponta a ponta. Sem commit — aguardando autorização.

## Verificado nesta sessão

| Verificação | Resultado |
|---|---|
| Django check | 0 issues |
| pytest | 54 passed, 97% coverage (falha abaixo de 80%) |
| ruff check + format | limpo |
| drf-spectacular `--validate --fail-on-warn` | schema gerado sem warning |
| React typecheck | limpo |
| React build | 387 kB (121 kB gzip) |
| `docker compose config` | válido |
| `docker compose up` | db, redis, mailpit, api, worker, beat, web saudáveis |
| Fluxo real | login JWT, criação de tarefa, e-mail no Mailpit via worker, board HTMX autenticado |
| MinIO | Dockerfile validado no build; profile `storage` não subiu nesta rodada |

A stack do Compose ficou no ar em `127.0.0.1:8080` (web), `:8000` (api) e `:8025` (Mailpit).

## O que está pronto

- `blt-project/api`: Django 6.0.10, DRF 3.18.3, SimpleJWT 5.5.1, spectacular 0.29,
  django-filter 25.2, Celery 5.7, Postgres/SQLite, throttling, paginação, filtros.
- `blt-project/api/tasks`: modelo, serviços, seletores, filtros, views e testes.
- `blt-project/api/accounts`: JWT, refresh, me, usuários ativos.
- `blt-project/api/hypermedia`: board SSR com partials, OOB swap, 422, Alpine no dialog.
- `blt-project/web`: React 19 + Vite 7 + TanStack Query 5 + RHF, tokens da Ballast Lane.
- `blt-project/compose.yaml`: Postgres 16, Redis 7, Mailpit, API, worker, beat, Nginx.
- `blt-project/.github/workflows/ci.yml`: API em Postgres + web typecheck/build.
- `blt-project/docs/ai/`: prompt, revisão do código gerado e decisões.

## Próximo passo

1. `git init` + primeiro commit (autorização pendente).
2. Publicar `blt-project` no GitHub e colar a URL no README do BLT.
3. Revisar `docs/ai/02-review.md` com os prompts reais da sua sessão.
4. Ensaiar `docs/demo.md` e gravar um backup de 5 minutos.
5. Opcional: deploy público (Railway) para o link da demo.

## Pendências conhecidas

- Sem deploy público.
- Sem testes de componente no React (a API tem cobertura).
- `hypermedia` sem paginação de 20 por página? Tem paginação; sem edição inline.
- Refresh token em `localStorage` — trade-off documentado.
- MinIO depende de build local (imagens não são mais publicadas).
