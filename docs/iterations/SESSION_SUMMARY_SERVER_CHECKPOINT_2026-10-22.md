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
