## Quick orientation for AI coding agents

This repository is a SvelteKit 2 + Svelte 5 admin dashboard template (pnpm-based). Below are the essential facts, patterns, and commands an automated coding agent must know to be productive and avoid introducing bugs.

### 1) Project entry points & dev commands
- Use pnpm (package.json) for all scripts. Key scripts:
  - `pnpm dev` — start Vite dev server (http://localhost:5173)
  - `pnpm build` / `pnpm preview` — production build/preview
  - `pnpm db:push` / `pnpm db:generate` / `pnpm db:studio` — Drizzle DB tasks (drizzle.config.ts points to `svelteforge.db`)
  - `pnpm db:seed` — run `src/lib/server/db/seed.ts` (uses `npx tsx`)
  - `pnpm test` / `pnpm test:e2e` — Vitest and Playwright

Always run `pnpm install` before executing scripts. Node 18+ (20+ recommended).

### 2) Big-picture architecture and boundaries
- Framework: SvelteKit server + client. Server-only code lives under `src/lib/server/` and must NOT be imported into client bundles.
  - Examples: `src/lib/server/auth.ts`, `src/lib/server/oauth.ts`, `src/lib/server/db/index.ts`, `src/lib/server/db/schema.ts`.
- Route groups separate concerns:
  - `(app)/` — protected routes (auth guard in `(app)/+layout.server.ts`), the app shell lives in `(app)/+layout.svelte`.
  - `(auth)/` — public auth endpoints (login, register, OAuth callbacks).
  - `(public)/` — publicly visible pages.
- `hooks.server.ts` runs on every request and populates `event.locals.user` and `event.locals.session` (see session cookie handling and auto-extension). Avoid changing session cookie names without updating both `auth.ts` and tests.

### 3) Database & tests patterns
- Drizzle + SQLite (better-sqlite3). `drizzle.config.ts` points schema to `src/lib/server/db/schema.ts` and database file to `svelteforge.db`.
- When editing schema, update tests: `test-utils.ts` includes an in-memory test schema constant (`SCHEMA_SQL`) and tests mock `'$lib/server/db/index.js'` to return the test DB. See CLAUDE.md notes on the required mocking pattern.

Example test mock pattern (used across tests):
```ts
vi.mock('$lib/server/db/index.js', () => ({
  get db() { return testDb; }
}));
const mod = await import('./+page.server.js');
```

### 4) Auth & sessions (critical)
- Sessions are cookie-based: raw token in HttpOnly cookie; only a hashed token is stored in DB. See `src/lib/server/auth.ts` and `src/hooks.server.ts` for validation, cookie refresh, and metadata updates.
- OAuth providers are environment-driven (Arctic). If env vars for Google/GitHub are missing, the OAuth buttons are intentionally hidden — do not add unconditional OAuth behavior.

### 5) Client vs server import rules
- Never import `src/lib/server/*` from client-side code. Use route server modules or endpoints to surface needed data.
- UI components live in `src/lib/components/` and `src/lib/components/ui/` (shadcn-svelte). Prefer reusing them rather than duplicating UI patterns.

### 6) Vite/SSR quirks to preserve
- `vite.config.ts` sets `ssr.noExternal: ['layerchart','svelte-ux']`. If adding server-side builds or packaging, keep these packages in `noExternal` to avoid SSR breakage.

### 7) Common code patterns to follow (examples)
- Forms: SvelteKit form actions with `use:enhance` for progressive enhancement; prefer existing actions in route +page.server.ts files.
- DB updates use Drizzle queries (see `(app)/+layout.server.ts` for example of `db.select`/`db.update`). Match column names and enums defined in `schema.ts` (roles: `admin|editor|viewer`).

### 8) Useful files to reference while coding
- `package.json` — scripts & tooling
- `README.md` / `CLAUDE.md` — repo-level guidance and commands
- `src/lib/server/auth.ts` — session handling
- `src/hooks.server.ts` — per-request session population
- `src/lib/server/db/schema.ts` — canonical DB schema
- `src/lib/server/db/seed.ts` — seeder used by `pnpm db:seed`
- `src/routes/(app)/+layout.server.ts` — protected-layout load logic and maintenance-mode checks

### 9) Safety checks for code edits (automated agent checklist)
1. Ensure server-only modules are not imported into client bundles.
2. If changing schema, update `drizzle` files and `test-utils.ts` test schema; re-run `pnpm db:push` and `pnpm test`.
3. Preserve cookie names and session lifetimes when touching auth logic; update tests that assert session behavior.
4. Run `pnpm lint` and `pnpm test` (and `pnpm test:e2e` if changing UI flows) before proposing changes.

### 10) If you need to run commands here
- Dev: `pnpm install && pnpm dev`
- DB push: `pnpm db:push`
- Seed: `pnpm db:seed`
- Unit tests: `pnpm test`
- E2E: `pnpm test:e2e`

If anything in these notes is unclear or you want additional coverage (e.g., more test examples, deeper schema notes, or component usage patterns), tell me which area to expand and I will iterate.
