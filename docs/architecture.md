# Arquitetura do BLT

## Visão

```
                    ┌──────────────────────────┐
  React (Vite) ────▶│  API Django + DRF + JWT  │
                    │  views → services        │
  HTMX + Alpine ───▶│        → selectors       │
  (server-rendered) │        → models          │
                    └────────────┬─────────────┘
                                 │
                     Postgres ◀──┴──▶ Redis ──▶ Celery
```

Os dois clientes usam a **mesma camada de serviço**. A API expõe JSON; o app
`hypermedia` renderiza HTML. Nenhuma regra de negócio é duplicada.

## Camadas da API

| Camada | Arquivo | Responsabilidade |
|---|---|---|
| Model | `tasks/models.py` | Invariantes de dados, índices, `is_overdue` |
| Selector | `tasks/selectors.py` | Quais registros o usuário pode ver; queries |
| Filter | `tasks/filters.py` | Filtros de status, data e busca |
| Service | `tasks/services.py` | Criar, editar, concluir, reabrir, atribuir |
| Serializer | `tasks/serializers.py` | Contrato de entrada e saída |
| View | `tasks/views.py` | Validação de entrada, chamada de serviço, resposta |
| Permission | `tasks/permissions.py` | Quem pode excluir |

A view não conhece ORM. O serializer não decide regra. O template não calcula nada.

## Por que dois clientes

A vaga trabalha com HTMX + Alpine como padrão SSR e React para interfaces legadas.
O BLT demonstra as duas metades sobre um domínio único:

- `web/` — SPA React, estado de servidor com TanStack Query, formulários com React Hook Form.
- `hypermedia/` — páginas Django, partials HTMX, Alpine para estado local de UI.

O ponto de arquitetura: **a regra existe uma vez**. Se amanhã o cliente React for
removido, a API continua; se a API virar pública, o HTMX continua.

## Autenticação

- API: JWT (access 30 min, refresh 7 dias, rotação e blacklist).
- HTMX: sessão Django, CSRF em formulário e em `hx-headers`.
- Os dois convivem no mesmo projeto. O usuário de demonstração serve aos dois.

Trade-off documentado: o refresh token fica em `localStorage` no React. Em produção
o correto é cookie `HttpOnly` + `SameSite`, com CSRF; o BLT usa `localStorage` para
manter a API stateless e o exercício simples. Ver `docs/ai/03-decisions.md`.

## Fila

Celery usa Redis como broker e backend. Dois trabalhos:

- `notify_assignment` — e-mail (console em dev) quando uma tarefa é atribuída.
- `send_due_soon_digest` — resumo diário de tarefas que vencem amanhã.

O envio é disparado com `transaction.on_commit`: se a transação falhar, não há e-mail
de uma tarefa que não existe. Em teste, `CELERY_TASK_ALWAYS_EAGER=True`.

## Dados

`Task` guarda `status`, `due_date` e `completed_at` separadamente. `is_overdue` é
derivado, não armazenado: evita job de escrita diário e dado inconsistente. O custo é
calcular na leitura — irrelevante no volume do domínio, e documentado.

`assigned_to` usa `PROTECT`: excluir usuário com tarefas atribuídas falha em vez de
apagar histórico.

## Limites conhecidos

- Sem multitenancy. Toda tarefa pertence a um usuário (dono ou responsável).
- Sem anexos, comentários ou histórico de alterações.
- `hypermedia` sem paginação e sem drag-and-drop.
