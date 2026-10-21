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
- Authenticated UUID identities continue to use separate account-specific directories. The full simulator suite for the preceding fail-closed revision passed **50/50** (`Test-BOTAI-2026.10.21_18-11-53-+0300.xcresult`); guest continuity full simulator regression **50/50 passed, 0 failed, 0 skipped** (`Test-BOTAI-2026.10.21_18-15-34-+0300.xcresult`).

## Canonical storage path regression
- `LocalAccountStorage.directoryName(.guest)` now resolves to the existing legacy `BOTAI` directory (or `BOTAI-UITests` in UI testing). This avoids contradictory guest path definitions in runtime and migration helpers.
- Added explicit unit assertions for both guest directory names. Full simulator regression **50/50 passed, 0 failed, 0 skipped** (`Test-BOTAI-2026.10.21_18-20-52-+0300.xcresult`).

## Account navigation reset
- Root tab navigation is now keyed by the active storage identity. On account switch, SwiftUI recreates the root view hierarchy rather than retaining the previous user's selected course, editing sheet, or navigation stack.
- Full simulator regression for navigation reset **50/50 passed, 0 failed, 0 skipped** (`Test-BOTAI-2026.10.21_18-25-49-+0300.xcresult`). This is an additional defense alongside repository rebinding, not a substitute for live account-transition tests.

## Legacy migration safety
- The optional legacy copy helper now rejects guest-as-destination (which resolves to the source directory) and refuses copies if either SQLite WAL or SHM sidecars exist.
- Added a unit regression for guest destination and SHM sidecar; focused storage suite **4/4 passed** (`Test-BOTAI-2026.10.21_18-32-12-+0300.xcresult`), and complete suite **51/51 passed, 0 failed, 0 skipped** (`Test-BOTAI-2026.10.21_18-32-50-+0300.xcresult`). An earlier overlapping simulator run crashed before test bootstrap; the isolated retry passed. This helper remains intentionally opt-in; no automatic account ownership assignment occurs.

## Auth bootstrap error containment
- Bootstrap distinguishes `AuthError.sessionMissing` (confirmed guest) from other auth errors (network/refresh/storage). Unexpected errors keep private content hidden and display a retry action rather than silently opening the guest library.
- The app compiles with this handling (`/tmp/botai_stage6_auth_error_build.log`). Added a unit regression asserting that only explicit `AuthError.sessionMissing` allows guest bootstrap; network/storage errors do not. Full simulator regression for the fail-closed bootstrap **51/51 passed, 0 failed, 0 skipped** (`Test-BOTAI-2026.10.21_18-36-36-+0300.xcresult`). The focused auth/sync suite **3/3 passed** (`Test-BOTAI-2026.10.21_18-40-24-+0300.xcresult`); live Supabase error-injection tests remain required.

## Guest and multi-account persistence isolation
- Added a disk-backed test with guest, account A and account B, each recording a different number of attempts. Reopening every SQLite database preserves its own outbox count without mixing data across identities.
- Focused `LocalAccountStorageTests` suite **5/5 passed** (`Test-BOTAI-2026.10.21_18-44-02-+0300.xcresult`). Complete simulator regression **53/53 passed, 0 failed, 0 skipped** (`Test-BOTAI-2026.10.21_18-44-45-+0300.xcresult`). This is local persistence verification; it does not establish Supabase RLS or end-to-end sign-in correctness.
- Supabase CLI lists the BOTAI cloud project. Attempting `supabase link --project-ref` reveals the actual blocker: **the cloud project is paused** (`project is paused`; admin must unpause it in the Supabase dashboard). An earlier migration-list attempt also reported IPv6 connectivity limitations. No production database changes were attempted. Live RLS and migration checks must wait until the project is resumed.

## Portable backend contract and bootstrap race guard
- Added `BOTAIBackendAPI` with transport-neutral versioned attempt upload DTOs and acknowledgements. No Supabase types appear in the contract. The adapter and authoritative server question mapping are still pending; no upload has been enabled.
- Added a bootstrap-in-progress guard so SwiftUI does not show the root view or rebind an identity while auth session resolution is in flight.
- Full simulator suite after the bootstrap guard **53/53 passed** (`Test-BOTAI-2026.10.21_19-01-53-+0300.xcresult`); API contract compile succeeded and focused API test **1/1 passed** (`Test-BOTAI-2026.10.21_19-05-37-+0300.xcresult`). Full suite including the new API test remains to run.

## Remote question mapping persistence
- SQLite migration `v8_remote_question_mapping` stores local question UUID -> server question UUID + version UUID and a verification timestamp. The mapping is isolated within each account's SQLite database.
- Added `RemoteQuestionMappingRepository`; it never derives remote IDs from local IDs. The caller must validate remote IDs against authoritative server content before storing them. No automatic sync is enabled.
- Full serial regression for the API adapter baseline **55/55 passed, 0 failed, 0 skipped** (`Test-BOTAI-2026.10.21_19-11-35-+0300.xcresult`). Focused new mapping persistence test **1/1 passed** (`Test-BOTAI-2026.10.21_19-15-58-+0300.xcresult`). Full suite including the mapping test is still pending.

## Safe attempt upload pipeline (2026-10-21)
- `SyncAcknowledgement` rejects duplicate, unknown and version-incompatible server acknowledgements. Four focused tests passed; full serial suite **61/61 passed** (`Test-BOTAI-2026.10.21_19-25-07-+0300.xcresult`).
- `LearningRepository.acknowledgeUploadedAttempts` deletes only confirmed attempt outbox events within a transaction, never learning history. Focused test passed.
- `LearningRepository.mappedUploadBatch` reads a consistent local snapshot, skips unmapped attempts and respects retry timestamps. Focused test passed. `RemoteQuestionMappingRepository.saveVerified` must only be called after authoritative remote validation; current method does not itself contact the server.
- `AttemptSyncCoordinator` joins batch preparation, `BOTAIBackendAPI.uploadAttempts` and ACK processing in an actor; five fake-backend tests passed (`Test-BOTAI-2026.10.21_19-35-03-+0300.xcresult`). It is not yet invoked by the app's production `SyncService`.
- **Network uploads remain disabled in `SupabaseBackendAPI` for nonempty batches.** A fake backend proves client behavior only, not real RLS, identity ownership, server mappings or production upload safety. The account-scoped app lifecycle must not start a coordinator for a stale identity.

## Remaining
1. Verify remote Question and QuestionVersion IDs against the authenticated server and account; implement real idempotent uploads, bounded retries and a durable cursor.
2. Complete optional, explicit guest-to-account migration without assuming ownership of legacy data; per-identity SQLite partitioning already exists.
3. Bind sync execution to a stable authenticated identity, reject stale-account results, and validate sign-in, sign-out, switching and cross-user RLS against a live backend.
4. Complete current full regression suite and physical-device checks.

## Verified baseline and live database availability (2026-10-21, later run)
- Serial iPhone 16 Pro Max iOS 18.6 simulator suite **71/71 passed**, zero failures/skips after both concurrency guards (`/tmp/BOTAI_stage6_serviceguard_full_20261021.xcresult`).
- `AttemptSyncCoordinator` and `SyncService` each reject overlapping `flush()` calls; focused suspended-backend regression covers actor reentrancy. Published commits: `b106310`, `efc6253` on `origin/main`.
- Supabase cloud is accessible again. `supabase migration list --workdir backend` reports matching local/remote versions **0001–0018**. This establishes migration history consistency, **not** live RLS correctness.
- Server attempts RLS restricts SELECT/INSERT to `auth.uid() = user_id`; no UPDATE policy. Question/version visibility depends on owner or publication policies.
- **Critical gate:** `RemoteQuestionMappingRepository.saveVerified` only persists IDs supplied by its caller; it performs no remote verification, and no production caller currently supplies authoritative mappings. `SupabaseBackendAPI` deliberately refuses all nonempty uploads. Do not bypass this guard using fabricated IDs.
- Remaining live acceptance: authenticated A/B sign-in and cross-user RLS tests, authoritative question/version mapping with server ownership checks, idempotent upload/ACK under retries, and physical-device verification.
