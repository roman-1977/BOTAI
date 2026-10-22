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

## Attribution resolver checkpoint

Added `StudyQuestionAttribution` (stable course/section/topic UUIDs) and `StudyQuestionAttributionResolver.uniqueAttributions`. It maps locally generated questions to unique course/topic references; questions reused across different topics are intentionally left unattributed instead of misclassified. Added tests for both unique and ambiguous references. This is **only a preparatory local resolver**, not yet wired into session launch, answer-time checkpoints or server summary schema. Existing summaries still contain overall counts only. Xcode test run `/tmp/botai_attribution_tests_20261022.log`: **115/115 passed** (unit suites). Full UI regression remains running separately and must not be reported as passed.

## Local mixed-session accumulator

Implemented `SessionTopicAccumulator`: records answer-time counts into stable course/section/topic buckets, with a separate unattributed bucket for ambiguous or missing provenance. Supports deterministic breakdown order and Codable persistence; does not include question IDs or content. Tests cover mixed topics, unknown attribution and serialization round-trip. **This is a domain primitive only**: not yet connected to the active session checkpoint, launch resolver or backend migration. Do not claim server breakdown is implemented. Focused Xcode run `/tmp/botai_topic_aggregates_20261022.log` passed. The earlier full UI regression has reported failure; inspect log and diagnose separately.

## Session attribution wiring (2026-10-22)

The main session-launch picker now resolves unique stable course/section/topic UUIDs from selected material references and passes them into `LearningStore.use`. The active `LearnSessionView` records a local `SessionTopicAccumulator` **only after the answer and cursor are durably saved**. The accumulator and attribution map are stored in the same `ResumableStudySession` JSON checkpoint as the next cursor, so background/resume preserves answer-time attribution. Old checkpoints lacking the optional fields still decode and resume, with unknown attribution rather than invented metadata. Focused test run `/tmp/botai_session_attribution_checkpoint_20261022.log`: 4/4 PASS. This does not yet write the topic breakdown into the completed summary queue or upload it to Supabase. Other launch paths (daily goals and personal quizzes) still have no attribution and are counted as unknown. Follow-up: ensure final-question crash safety and make aggregate completion durable before extending the server contract. The earlier UI visual baseline failure was an accessibility snapshot acquisition error, not yet resolved.

## Durable completed topic aggregates (2026-10-22)

`CompletedSessionSummary` now optionally includes locally persisted `topicBreakdown`, `unattributedAnswered`, and `unattributedCorrect`. Completion writes these aggregates into the existing idempotent SQLite summary queue in the same transaction as final session and checkpoint deletion. A mismatch between the provided topic totals and overall session totals rejects the transaction. The view supplies its answer-time accumulator only when counters match; old sessions without attribution continue to use the legacy overall-only summary, with optional fields omitted. The Supabase network payload remains deliberately **overall-only** until a reviewed schema migration and RLS checks are ready. Tests cover mixed/unknown counts, idempotence, inconsistent counts, and backward-compatible decoding; 10/10 focused tests PASS (`/tmp/botai_completed_topics_20261022.log`). The targeted visual-baseline UI rerun was started; outcome must be verified before reporting success.

## Server topic aggregate draft (2026-10-22)

Added **unapplied** migration `0026_completed_session_topic_aggregates.sql`: one immutable owner-scoped aggregate per `(user, session, course, section, topic)` with parent session FK, nonnegative correctness checks, unique key and authenticated owner-only RLS. No per-question identifiers or content. Prepared rollback-only SQL fixture `backend/tests/completed_session_topic_aggregate_rls.sql` for owner/cross-user/duplicate/immutable checks. **Not executed on any server.** The topic transport is not yet wired, and the contract needs an explicit decision about unattributed bucket representation and parent/topic acknowledgement ordering. A separate UI visual baseline retry passed 1/1 after the earlier snapshot acquisition error (`/tmp/botai_visual_baseline_retry_20261022.log`).

## Topic upload transport and independent ACK (2026-10-22)

Local SQLite migration `v17_topic_aggregate_ack` adds nullable `topicsUploadedAt` to existing summary queue. Parent summary upload and topic upload are now **separate idempotent phases**: topic rows are eligible only after the parent session was acknowledged; a topic failure does not lose the queued breakdown, even when the parent was successfully uploaded. The topic coordinator checks account ownership before/after network calls, rejects foreign ACK IDs, and only acknowledges verified complete topic sets. The Supabase transport upserts immutable `(user,session,course,section,topic)` aggregate rows, reads them back and checks exact counts before returning a session ACK. Unattributed counts remain in the local completed summary; they are not represented by fabricated topic IDs. The existing parent summary continues to hold total counts, so unattributed counts can be calculated as the difference between overall totals and attributed topic totals. Topic upload is attempted on normal sync after the parent phase. **Server migrations 0025 and 0026 remain unapplied**; network calls against an unprepared server will fail safely and leave local queues pending. No live RLS or end-to-end server test has been run.

Focused checks: topic queue 2/2 (`/tmp/botai_topic_queue_20261022.log`), transport build plus existing coordinator 9/9 (`/tmp/botai_topic_transport_20261022.log`), dedicated fake-backend topic coordinator 7/7 (`/tmp/botai_topic_coordinator_20261022.log`). Pending: full regression, real two-user RLS and parent/topic end-to-end test in disposable backend, handling server conflict with differing immutable row values, surfacing nonfatal sync errors.

2026-10-22: Both aggregate transports now reject duplicate keys before upsert. Unit regression: 131/131 PASS, /tmp/botai_unit_regression_20261022.log. UI regression running in /tmp/botai_ui_regression_20261022.log. RLS SQL tests remain unexecuted without a disposable backend.

2026-10-22: Added targeted topic-sync concurrency tests for account changes during an upload, overlapping flushes, and network failure; awaiting focused execution after full UI regression. Full UI regression log: /tmp/botai_ui_regression_20261022.log.

2026-10-22 regression: combined 17 UI tests yielded 15/15 general UI passes and 2/2 chemistry failures because chemistry fixture is intentionally absent in the general UI database. The chemistry suite must run separately with tools/chemistry_pilot/run_simulator_smoke.sh, which backs up and seeds only the disposable BOTAI-UITests SQLite. Combined log /tmp/botai_ui_regression_20261022.log. Topic concurrency initial run 2/3 due to bounded Task.yield scheduling race in test harness; replaced with bounded 2ms Task.sleep and rerun 3/3 PASS (/tmp/botai_topic_concurrency_retry_20261022.log). Chemistry seeded rerun launched; outcome pending. No physical device or production database touched.

2026-10-22: Seeded chemistry UI suite passed 2/2 (/tmp/botai_chemistry_isolated_20261022.log), with pre-seed isolated UI-test DB backup in .build/chemistry-pilot. General UI suite passed 15/15 in combined run; its 2 chemistry failures were missing seed, not a functional regression. Terminal cursor crash fix: final answered cursor (nextIndex == questions.count) remains a resumable checkpoint until transactional session completion, and restored view opens finished screen; malformed cursor beyond end remains invalid. Crash-recovery tests 2/2 passed (/tmp/botai_terminal_crash_retry_20261022.log). Server RLS and live end-to-end tests still pending.

2026-10-22 access recovery and final unit regression: Desktop Commander connection restored. The first complete 136-test unit run found two outdated assertions expecting the last-answer cursor to be deleted immediately. Updated the existing atomic answer/cursor test to require terminal checkpoint retention and deletion only after transactional completion. Strengthened terminal crash recovery test to persist the final answer and cursor through LearningRepository.record in one transaction, rather than manually saving the snapshot. Full unit rerun: 136/136 PASS, 44 suites, /tmp/botai_final_unit_retry_20261022.log. Targeted two UI resume tests launched, /tmp/botai_resume_ui_after_terminal_fix_20261022.log. Local environment has Supabase CLI but no psql or Docker, so disposable database RLS integration is still not run; do not apply migrations to production.

2026-10-22 account isolation audit: the application already stores guest and each authenticated user in separate SQLite directories via `LocalAccountStorage.directory(for:)`; `BOTAIApp.switchStorageIfNeeded()` recreates the repository and sync service on identity change. Therefore the aggregate table is not shared across accounts in the real app; an ownerID column is not required for this isolation mechanism. Added regression verifying that pending completed-session summaries persist for account A but are absent from account B's database, including topic queue and reopening A. Focused account storage tests 8/8 PASS (`/tmp/botai_account_summary_isolation_20261022.log`). Do not confuse repository-level in-memory test fixtures with the app's identity-scoped persistence. Continue testing real auth transitions and in-flight network requests separately.
