# AI log — BLT

Record of AI tooling usage in the project. It feeds the GenAI section of the delivery
and serves as evidence during code review.

## Format

Each entry has: goal, tool, prompt, what was accepted, what was corrected and why.

---

## 2026-11-10 — Initial scaffold

**Goal:** create the Django + DRF + React + HTMX base.

**Tool:** OpenCode (`deepseek-v4.1-flash`), with the ANA/LOGUS workspace as context.

**Prompt:** see `blt-project/docs/ai/01-scaffold-prompt.md`.

**Accepted without changes:**
- Settings structure driven by environment variables.
- SimpleJWT and drf-spectacular configuration.

**Corrected:**
- Dead permission class removed (0% coverage exposed it).
- OpenAPI schema repaired: explicit parameters and response serializers.
- Throttle state leaking between tests; cache cleared per test.
- 404/403 mismatch between the API and the HTMX client.
- MinIO image replaced by a pinned source build.

**Discarded:**
- Repository/use-case layers; they added ceremony without a rule.
- `drf-yasg`; unmaintained and Swagger 2 only.

**Lesson:** the prompt sets the rules; the failures were in what the prompt did not say.

---

## 2026-11-10 — Spec from issue

**Goal:** add one bounded GenAI feature, with no free-form prompt.

**Prompt:** see the spec block in `01-scaffold-prompt.md`.

**Accepted:**
- JSON contract shape and the fixed system prompt.
- Persisting model, prompt version, latency and input size with each spec.

**Corrected:**
- Gitea returns `pull_request: null` on regular issues; the guard rejected every issue.
- Provider requires an `x-opencode-session` header; a missing header was a 400.
- Publish path needed a read-only-by-default decision; writing is explicit and opt-in.

**Discarded:**
- Free chat, streaming and multiple providers.
- Creating tasks from the spec; postponed to keep one write path.

**Lesson:** the value of a GenAI feature is the contract around it, not the model call.
