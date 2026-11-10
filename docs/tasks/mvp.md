# MVP — functional scope

## Story

As someone who organizes work, I want to record tasks, assign them to someone and track
what is late, so I do not miss deadlines and know who owns what.

## Flow

1. Sign in with username and password.
2. See my tasks (created by me or assigned to me), filtered by status and due date.
3. Create a task with title, description, due date and assignee.
4. Edit, complete and reopen.
5. Delete a task I created.
6. Generate an implementation spec from a Gitea issue and publish it back as an issue.

## Rules

- A task is visible only to its creator or assignee.
- Only the creator deletes.
- Completing is idempotent: completing twice does not change `completed_at`.
- Reopening clears `completed_at`.
- Assigning requires an active user.
- `is_overdue` is derived: due date before today and status not done.
- A past due date is accepted (backfill) and shown as overdue.

## Out of scope

- Comments, attachments, labels, subtasks.
- Realtime notifications.
- Multi-tenant organizations.
- Drag-and-drop.
- Free-form AI chat.
