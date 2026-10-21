# Stage 6 — Sync, authorization and data security

Status: active. Server integration and account isolation are not accepted.

## Findings
- The sync actor is not called by the application; offline outbox records are not currently uploaded.
- Local study question UUIDs are not authoritative server QuestionVersion IDs. The backend enforces a foreign key. Uploading fabricated IDs would fail.
- Previous grade mapping incorrectly converted `hard` to `correct`.
- Local SQLite database is not partitioned by authenticated user. Account switching is not yet safe.
- Migration `0002_learning.sql` defines per-user RLS for attempts with INSERT/SELECT only; deployment and cross-user denial require server integration tests.

## Implemented safety changes
- SyncService explicitly retains the local outbox instead of attempting uploads with invented server question/version IDs. No remote uploads are claimed.
- Added correct mapping for all three grades (again → incorrect, hard → hard, good → correct).
- Added two focused `SyncSafetyTests`: mapping and durable local pending attempt. **2/2 passed**, `Test-BOTAI-2026.10.21_17-48-47-+0300.xcresult`.

## Local identity namespace groundwork
- Added deterministic separate folder names for guest and authenticated UUID identities (`LocalAccountStorage`).
- Added `LocalAccountStorageTests` to check distinct identities and UI-test isolation: **1/1 passed** (`Test-BOTAI-2026.10.21_17-51-53-+0300.xcresult`).
- Namespace selection is NOT yet wired into `BOTAIApp`; the existing database path is deliberately unchanged until a safe legacy-data migration and auth-driven repository reopening are implemented.

## Safe legacy database migration preparation
- Added explicit-identity, non-destructive copy helper for checkpointed SQLite databases. It refuses WAL sidecars and refuses to overwrite an existing account database.
- Three focused namespace/migration tests passed: source retained, destination never overwritten, WAL guard enforced (`Test-BOTAI-2026.10.21_17-54-50-+0300.xcresult`).
- This is a migration primitive, **not** automatic account migration. The application still uses its existing database until ownership and repository switching are safely wired.

## Auth identity propagation
- `AuthStore` now records the authenticated Supabase user UUID after bootstrap and both sign-in flows; exposes a typed `localIdentity` for future storage switching.
- Sign-out clears identity **only after successful server sign-out**; failure leaves the current identity intact and exposes an error instead of silently claiming success.
- Simulator Debug build succeeded (`/tmp/botai_stage6_auth_build.log`). Repository rebinding is still pending, so this does not yet constitute account isolation.

## Runtime repository switching (under regression)
- `BOTAIApp` now watches the authenticated user UUID and reopens all four repositories together in an identity-scoped SQLite directory. It does not automatically claim legacy data for any signed-in account.
- The old unscoped database remains the initial guest/legacy store; explicit migration and bootstrap privacy handling still require acceptance tests.
- Simulator build succeeded (`/tmp/botai_stage6_switch_build.log`). Full simulator regression **50/50 passed, 0 failed, 0 skipped** (`Test-BOTAI-2026.10.21_17-59-57-+0300.xcresult`). Real sign-in/sign-out/account switching transitions remain unverified.

## Bootstrap privacy guard
- Root UI is now gated behind initial auth bootstrap and identity-scoped repository selection; no study/material/course content is rendered while the initial session is unresolved.
- The existing guest/legacy database is retained and not automatically claimed by authenticated accounts.
- Repository selection now reports success; root content stays hidden if an account-specific database fails to open, and identity changes hide the previous UI before rebinding.
- Full simulator suite **50/50 passed, 0 failed, 0 skipped** (`Test-BOTAI-2026.10.21_18-07-12-+0300.xcresult`) on the bootstrap gate revision. Subsequent fail-closed handling builds successfully (`/tmp/botai_stage6_failclosed_build.log`); full regression on that latest handling and live account transitions remain required.

## Guest continuity
- Returning to guest after sign-out now reopens the original legacy `BOTAI/learning.sqlite` (or `BOTAI-UITests`), instead of creating an empty `BOTAI-guest` database. Existing offline guest materials and attempts remain in their original location.
- Authenticated UUID identities continue to use separate account-specific directories. Full regression for this additional change is pending.

## Remaining
1. Map local question IDs to real server Question and QuestionVersion IDs; then implement idempotent uploads, bounded retries and a durable cursor.
2. Partition private local state by user identity and define guest-to-account migration.
3. Validate auth bootstrap, sign-out, account switching, and cross-user RLS with an actual backend.
4. Run full regression suite and physical-device checks.
