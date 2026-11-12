# web

<!-- fefo:generated:start -->
# web

| Field | Value |
|---|---|
| Role | `web` |
| Stack | `react` |
| Path | `blt-project/web` |
| CodeGraph MCP | `codegraph-web` |
| Test | `—` |
| Lint | `npm --prefix blt-project/web run typecheck` |
| Build / run | `npm --prefix blt-project/web run build` |
<!-- fefo:generated:end -->

## Domain notes

Part of the `blt-project` Git root, shared with `api` (see [`../layout.md`](../layout.md)).

**Responsibility.** React 19 + Vite + TypeScript client: login, task board with filters, task
dialog, and the Specs tab (generate, publish, tasks from a spec).

**Layers.** `src/lib/api.ts` is the only code that calls `fetch` (tokens, single-flight refresh,
error mapping); `src/features/<area>/` holds `api.ts` (paths), `hooks.ts` (TanStack Query) and the
components; `src/lib/types.ts` is the hand-written contract; `src/components/ui/` are small local
primitives (no component library); `src/index.css` holds the design tokens, Tailwind utilities sit on them.

**Public entry points.** Served by Nginx in Compose on :8080 and by Vite on :5173; it calls `/api/v1/…`.

**Data stores.** None. Tokens live in `localStorage` (documented trade-off).

**External integrations.** Google Fonts (still loaded from the CDN).

**Read next.** [`../contracts.md`](../contracts.md) (change procedure: schema first, then `types.ts`),
[`../domain.md`](../domain.md), [`../decisions.md`](../decisions.md).

**Verify.** `npm --prefix blt-project/web run typecheck` and `… run build`; then a browser pass at
desktop and 390 px with no console warning. There is no test script and no component or E2E test yet.

**Known gaps.** Filters are not in the URL; no dark theme; no automated browser test.
