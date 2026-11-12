# Domain rules — tasks

Verified 2026-11-12 against `blt-project@7956a12`. If a row and the code disagree, the code wins:
fix the row and say so in `decisions.md`.

Terms: a **task** has `status` (`todo`, `in_progress`, `done`), an optional `due_date`, one creator
(`created_by`) and at most one assignee (`assigned_to`). A **spec** is covered in `spec-flow.md`.

## Rules

| # | Rule | Where it lives | Proof |
|---|---|---|---|
| R1 | A task is visible only to its creator or its assignee. A stranger gets **404**, not 403. | `tasks/selectors.py::_tasks_for` | `test_api_tasks::test_stranger_gets_404`, `test_selectors::test_task_get_returns_none_when_not_visible` |
| R2 | Only the creator deletes; the assignee gets 403. React, HTMX and the API share one rule. | `tasks/services.py::task_delete` | `test_services::test_assignee_cannot_delete`, `hypermedia/tests/test_delete_rule.py` |
| R3 | Completing twice keeps the first `completed_at`. | `services.task_complete` | `test_services::test_complete_is_idempotent` |
| R4 | Reopening clears `completed_at`; reopening a task that is not done is a no-op. | `services.task_reopen` | `test_reopen_clears_completed_at`, `test_reopen_is_idempotent` |
| R5 | `completed_at` is set if and only if `status == done`, also enforced in the database. | `services._completed_at_sync`, constraint `task_completed_at_iff_done` in `tasks/models.py` | `test_models::test_database_rejects_completed_at_out_of_sync_with_status` |
| R6 | Assigning needs an **active** user. | `services._assignee_validate` | `test_assign_inactive_user_is_rejected`, `test_create_rejects_inactive_assignee` |
| R7 | `is_overdue` is derived, never stored: `due_date < today and status != done`. The `overdue=true` filter and `task_summary` apply the same rule in the query. | `Task.is_overdue`, `tasks/filters.py`, `selectors.task_summary` | `test_models` overdue tests, `test_api_tasks::test_filter_overdue` |
| R8 | A past due date is accepted (backfill) and shown as overdue. | `services.task_create` | `test_create_with_past_due_date_is_allowed` |
| R9 | The title is trimmed and not blank; `task_update` accepts only `TASK_UPDATE_FIELDS`. | `services.task_update` | `test_create_rejects_blank_title`, `test_update_rejects_fields_outside_the_whitelist` |
| R10 | Services are keyword-only, atomic, call `full_clean()` and raise Django `ValidationError` / `PermissionDenied`; the DRF handler turns them into the API error shape. | `tasks/services.py`, `core/exceptions.py` | `test_services_are_keyword_only` |
| R11 | The assignment e-mail is scheduled with `transaction.on_commit`: a rolled-back task sends nothing. The due-soon digest sends one e-mail per task due tomorrow and survives one failing send. | `services._notify`; `notifications.assignment_notify_send`, `notifications.due_soon_digest_send` | `test_assignment_sends_email_after_commit`, `test_digest_continues_after_a_failed_send` |

## Entry points that must reach the same rule

| Client | Path to the service |
|---|---|
| React | `web/src/features/tasks/api.ts` → `/api/v1/tasks/…` → `tasks/views.py` → `services` / `selectors` |
| HTMX + Alpine | `hypermedia/views.py` → `services` / `selectors` (no rule in the view or the template) |
| `blt-specs` MCP | `create_tasks_from_spec` → `specs.services.spec_tasks_create` → `task_create` |

A rule added to one entry point and not to the service is a defect.

## Out of scope (by decision)

Comments, attachments, labels, subtasks, realtime notifications, multi-tenancy, drag-and-drop,
free-form AI chat. Source: `docs/tasks/mvp.md`.

## Seed data

Three users (`fernando`, `ballast`, `lane`), 19 tasks, and Gitea issues mirrored from the tasks of
`ballast` and `lane`. The shared password is a file in `blt-project/secrets/`; it never goes in
the vault. `seed` writes through the ORM on purpose, not through the services.
