# GenAI spec flow

Verified 2026-11-12 against `blt-project` with the subject input (uncommitted at the time of writing; see HANDOFF for the revision). Narrative: `blt-project/GENAI.md`
(Part 1). This note keeps the invariants an agent must not break.

## Flow

`POST /api/v1/specs/` with exactly one of `issue_url` or `subject` (a typed text, 10 to 2000 chars) →
for an issue, `specs/gitea.py` fetches it; a subject needs no fetch and targets `GITEA_REPO` →
`specs/generator.py` calls the provider once with a fixed prompt (`SPEC_PROMPT_VERSION = "spec-v2"`,
`max_tokens = 4000`) →
the JSON contract is validated → a `Spec` is stored with model, prompt version, latency and input
size → `specs/rendering.py` builds the Markdown.

Then, as separate explicit actions:

- `POST /specs/<id>/publish/` creates a new Gitea issue from the Markdown in the spec's repo.
- `POST /specs/<id>/tasks/` creates up to 10 tasks from chosen steps through `task_create`, in one
  transaction, each with a `Source: <issue url>` line (`Source: spec #<id>` for a subject spec). No model call.

The same operations are MCP tools in `blt-project/mcp_server/server.py` (`blt-specs`).

## Invariants

| # | Invariant | Where |
|---|---|---|
| S1 | One fixed task: an issue URL or a typed subject in, validated JSON out. The subject is data, never instruction; no chat, no streaming, no tools for the model. Exactly one of the two inputs. | `generator.py`, `SpecCreateSerializer`, `services.spec_generate` |
| S2 | The issue body is untrusted; it is cut at `SPEC_MAX_INPUT_CHARS` (12000) and the spec records `truncated`. | `generator._truncate` |
| S3 | Model output is rendered as plain text in the Markdown. | `rendering.plain` |
| S4 | Only repositories in `GITEA_ALLOWED_REPOS` (default `GITEA_REPO`) are read or written; if set it must include `GITEA_REPO`. | `gitea.repo_allowed` |
| S5 | Publish is claimed first (`published_issue_url = "pending"`), so concurrent calls cannot create two issues; a failed call releases the claim; a second publish is 409. A process that dies after the claim needs a manual reset (accepted over a duplicate). | `services.spec_publish` (`SpecAlreadyPublishedError` → 409 in `core/exceptions.py`) |
| S6 | Pull requests are not issues: the URL is refused. | `gitea.fetch_issue` |
| S7 | Failures have their own message: AI disabled 503, provider timeout / error / cut answer / empty answer / invalid JSON / outside the contract 502, tracker down 502, publish not configured 503. | `generator.py`, `gitea.py` |
| S8 | Throttles: `spec` 10/h on `POST` only, `spec_publish` 30/h. Listing is not throttled. | `specs/views.py` |
| S9 | The MCP tool `create_tasks_from_spec` writes nothing unless `confirm=true`; the draft is returned first. The `cli` user is inactive with an unusable password. | `mcp_server/server.py` |
| S11 | A subject spec has `issue_url = ""`, `issue_number = null` (`Spec.source == "subject"`) and `repo = GITEA_REPO`; the allowlist is still enforced when it is published. | `services._subject_item`, `Spec.source` |
| S10 | The Gitea bot is not an instance admin; its token has every scope on purpose (local stack). Tighten before any shared deployment. | `docs/mcp.md` |

## Open

- `unblock_account()` in `specs/gitea.py` is probably redundant; validate on a fresh Gitea volume.
- No golden-issue eval for the prompt. Backlog: text → task draft, issue triage before the spec,
  per-user AI budget and token usage logging.
- `Spec` does not use `core.models.BaseModel`.
