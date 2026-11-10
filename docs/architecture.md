# BLT architecture

## Overview

```
                    ┌──────────────────────────┐
  React (Vite) ────▶│  Django API + DRF + JWT  │
                    │  views → services        │
  HTMX + Alpine ───▶│        → selectors       │
  (server-rendered) │        → models          │
                    └────────────┬─────────────┘
                                 │
                     Postgres ◀──┴──▶ Redis ──▶ Celery
                                 │
                              Gitea (issues)
```

Both clients use the **same service layer**. The API returns JSON; the `hypermedia` app
renders HTML. No business rule is duplicated. The spec flow talks to Gitea through a
small adapter (`api/specs/gitea.py`).

## API layers

| Layer | File | Responsibility |
|---|---|---|
| Model | `tasks/models.py` | Data invariants, indexes, `is_overdue` |
| Selector | `tasks/selectors.py` | Which rows the user may see; queries |
| Filter | `tasks/filters.py` | Status, date and search filters |
| Service | `tasks/services.py` | Create, update, complete, reopen, assign |
| Serializer | `tasks/serializers.py` | Input and output contract |
| View | `tasks/views.py` | Validate input, call a service, respond |
| Permission | inline in the view | Only the creator deletes |

The view does not know the ORM. The serializer does not decide a rule. The template does
not calculate anything.

## Why two clients

The role uses HTMX + Alpine as the SSR default and React for legacy interfaces. BLT
demonstrates both halves over one domain:

- `web/` — React SPA, server state with TanStack Query, forms with React Hook Form.
- `hypermedia/` — Django pages, HTMX partials, Alpine for local UI state.

The architectural point: **the rule exists once**. If the React client is removed, the API
remains; if the API becomes public, the HTMX client remains.

## Authentication

- API: JWT (access 30 min, refresh 7 days, rotation and blacklist).
- HTMX: Django session, CSRF in the form and in `hx-headers`.
- Both coexist in the same project. The demo user serves both.

Documented trade-off: the refresh token lives in `localStorage` in React. In production
the correct approach is an `HttpOnly` cookie with `SameSite` and CSRF; BLT keeps the API
stateless to stay simple. See `blt-project/docs/ai/03-decisions.md`.

## Queue

Celery uses Redis as broker and backend. Two jobs:

- `notify_assignment` — email (console locally) when a task is assigned.
- `send_due_soon_digest` — daily summary of tasks due tomorrow.

Sending is scheduled with `transaction.on_commit`: if the transaction fails, no email is
sent for a task that does not exist. In tests, `CELERY_TASK_ALWAYS_EAGER=True`.

## Data

`Task` stores `status`, `due_date` and `completed_at` separately. `is_overdue` is derived,
not stored: it avoids a nightly write job and inconsistent data. The cost is computing it
on read — irrelevant at this volume, and documented.

`assigned_to` uses `PROTECT`: deleting a user with assigned tasks fails instead of
erasing history.

## Gitea

Gitea provides the issue tracker for the GenAI flow and runs in Compose on port 3000. A
management command creates the demo repository and four issues; a Compose one-shot service
runs it on every `up` (idempotent). The API accepts a token or basic auth, so the local
demo needs no token provisioning.

## Known limits

- No multitenancy. Every task belongs to one user (creator or assignee).
- No attachments, comments or change history.
- `hypermedia` has no inline editing and no drag-and-drop.
- The spec flow supports one tracker (Gitea). The adapter is small enough to add another.
