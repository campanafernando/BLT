# Plano — BLT

Prazo alvo: sexta, 2026-11-13. Hoje: terça, 2026-11-10.

## Critérios de aceite

- [x] CRUD de tarefas com JWT
- [x] Atribuição e conclusão de tarefa
- [x] Filtro por status e por intervalo de vencimento
- [x] Paginação
- [x] Rate limiting
- [x] Celery + Redis com tarefa assíncrona
- [x] Testes com cobertura ≥ 80%
- [x] Dockerfile + compose (API, banco, Redis, worker, web)
- [x] README com setup, credenciais e decisões
- [x] OpenAPI em `/api/docs/`
- [x] Cliente React com CRUD, filtros e responsividade
- [x] Bônus HTMX + Alpine sobre a mesma camada de serviço
- [x] CI no GitHub Actions
- [ ] Deploy público
- [ ] Snapshot CodeGraph

## Sequência

| Bloco | Entrega | Estado |
|---|---|---|
| 1 | Estrutura, settings, modelos, JWT, CRUD, filtros | pronto |
| 2 | Celery, throttling, testes, cobertura | pronto |
| 3 | React: login, board, formulário, filtros | pronto |
| 4 | HTMX + Alpine: partials, modal, confirmação | pronto |
| 5 | Documentação de IA e ensaio da demo | pronto |
| 6 | CI, deploy, gravação | CI pronto; deploy e gravação pendentes |

## Riscos

| Risco | Mitigação |
|---|---|
| Review perguntar "por que não ViewSet" | README explica: views explícitas para serviços explícitos |
| Cobertura alta sem assert útil | Testes cobrem borda: idempotência, 404, inativo, data passada |
| Demo quebrar em clone limpo | Checklist de clone em `/tmp` antes de entregar |
| Excesso de abstração | Sem repositório, use case ou DTO; camadas só onde há regra |
| `localStorage` no React | Trade-off documentado em `docs/ai/03-decisions.md` |
