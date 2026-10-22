# Completed-session summary server contract — checkpoint

2026-10-22. Status: migration written and local ACK behavior tested; **not deployed**.

## Server migration

`backend/supabase/migrations/0025_completed_session_summaries.sql` defines append-only, authenticated session summaries. Composite `(user_id, session_id)` primary key deduplicates uploads. RLS permits only the owning authenticated user to SELECT and INSERT. No UPDATE or DELETE grants to authenticated users. Counts must be nonnegative, correct <= answered, and end >= start. Deleting the auth user cascades to summaries.

## Local durability and ACK

`LearningRepository.completeSession` atomically persists the local session and immutable upload payload; `acknowledgeSessionSummaries` marks only confirmed local IDs, is idempotent, and does not delete historical sessions. Focused 9/9 `RemoteQuestionMappingTests` passed (`/tmp/botai_summary_ack_tests_20261022.log`).

## Unresolved acceptance gates

- Server migration must be applied **only after approval** to a selected development environment, then RLS probed with two accounts and duplicate/conflicting IDs.
- Provider-neutral network uploader, authenticated ACK verification, retry/foreground trigger and account-switch isolation are **not yet implemented**.
- Current payload covers overall session counts and active time; per-subject/topic breakdowns and versioned course references require a model/UX pass.
- Legacy per-attempt outbox and sync code remain active; they must be retired/migrated safely, not dropped while old pending data exists.
- Full UI and migration regression is pending. Do not label RC-06 complete.

## Network transport checkpoint

Implemented `SessionSummaryBackendAPI`, Supabase adapter, and auth-guarded `SessionSummarySyncCoordinator`. The adapter inserts immutable aggregate rows with ignore-duplicates and verifies server-visible persisted fields before returning ACK IDs. Coordinator validates ACK subset, retries pending events on subsequent flushes, and refuses stale-account ACKs. `SyncService` invokes it during existing foreground/auth flush triggers. Focused Xcode suite passed (`/tmp/botai_summary_network_build_20261022.log`). **No live server call tested.** Existing legacy per-answer upload still runs for compatibility and must be deliberately retired after migration policy is agreed. Network coordinator has no dedicated fake-backend tests yet.

## Completion trigger and coordinator regression (2026-10-22)

`LearningStore.completedSessionSignal` now triggers the app's existing flush orchestration on successful session completion, **instead of each answered question**. Foreground, initial login and account-change retry triggers remain. Seven fake-backend coordinator tests cover unfinished sessions, aggregate-only upload, verified ACK, transient failure/no ACK retry, forged ACK, pre-upload account rejection, account change mid-request, and overlapping flush. Combined legacy + summary coordinator suites: **16/16 PASS**, `/tmp/botai_summary_coordinator_tests_20261022.log`. Legacy attempt uploader is still present and can flush historical pending attempts on session completion or app foreground; complete removal requires a migration/retention decision. Server migration still not deployed and live E2E not verified.

## Legacy upload disabled, history preserved (2026-10-22)

`SyncService` now executes **only** completed-session summary uploads. It no longer publishes local questions or transmits individual attempts, even when legacy pending outbox events exist. Old `attempts`, mappings and outbox rows are **not deleted**; retained local history and migration compatibility remain intact. Legacy helper types stay compiled temporarily but are unreachable from active sync orchestration. This avoids violating the accepted aggregate-only server policy. In a separate cleanup migration, decide how to retire old outbox entries without losing local study history.

Completion now atomically removes the resumable-session checkpoint in the same SQLite transaction that writes the final session and its upload event; an interrupted finish cannot resurrect an already-completed session. Added regression coverage. Focused 17/17 tests PASS (`/tmp/botai_summary_retirement_tests_20261022.log`). No server deployment or live network verification. Remaining: subject/topic breakdown, real RLS tests, full regression.

## SQL RLS regression fixture

Added `backend/tests/completed_session_summary_rls.sql`, a transaction-rolled-back two-user SQL probe for owner reads, cross-user read/write isolation, immutability, duplicate session IDs and invalid aggregate counts. Requires migration 0025 on a **disposable** Supabase/PostgreSQL environment and a privileged psql connection. The fixture is prepared but **not executed**; this is not evidence of live RLS correctness.

## Subject/topic breakdown design gate

The current `StudyQuestion` model contains `id`, `knowledgeID`, content and answer format but **no stable course/section/topic provenance**. `ResumableStudySession` stores only ordered questions and session counters. Therefore the uploader cannot honestly infer per-subject/topic results from the completed session without extending the local answer-time data model. Do **not** assign all answers to `sessionTitle` or guess topic from prompt text. Next implementation must persist immutable per-answer *local* attribution (course/section/topic IDs and content revision where known), accumulate counts per attribution, and upload **only aggregated breakdown rows** on completion. Mixed sessions must preserve separate attribution buckets. The versioned server schema should be extended only after these local invariants are tested.
