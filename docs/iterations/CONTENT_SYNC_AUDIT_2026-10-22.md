# BOTAI 0.3.0 — content and sync implementation audit

Date: 2026-10-22. Scope: RC-03, RC-06, RC-07. Status: **in progress, not accepted**.

## Verified implementation facts

- `LearningRepository` stores answers, original answer-time text snapshots, durable outbox and (v15) resumable session. `mappedUploadBatch` never fabricates remote IDs. `AttemptSyncCoordinator` is single-flight, checks account ownership before/after network IO, and ACKs only verified server results.
- `SyncService` retries pending snapshot publication and current-card publication; `RemoteQuestionPublisher` supports only `reveal` and `pair` **without** media/LaTeX. This is deliberate: attempts from choice/media cards are **local-only**, not cloud-synced.
- Server choice model is `answer_options` plus `answer_option_versions` tied to a `question_version`; migration `0022_question_authoring_insert_grants.sql` grants INSERT only for `questions` and `question_versions`. Existing `0006_authoring_rls.sql` does not establish owner INSERT/SELECT policies for option tables. Merely removing the Swift guard would fail or compromise ownership semantics.
- Chemistry smoke requires isolated, explicitly reset/seeded `BOTAI-UITests` SQLite. Seed now also deletes v15 `resumableStudySession`; the smoke test accepts randomized recall and choice order. Last seeded run: **2/2 PASS** `/tmp/botai_chemistry_seed_snapshot_fix_20261022.log`.

## Implementation sequence (do not skip security gates)

1. Extend **answer-time snapshot persistence** to preserve immutable choice text, correctness, and media/LaTeX metadata; otherwise edited cards cannot safely publish historical choice attempts. Add SQLite migration with backward compatibility, fixture migration tests, and rollback documentation.
2. Implement owner-only RLS/GRANTs for answer options and their versions; ensure unowned options are invisible and unwritable. Add live RLS tests, including hostile cross-account writes and reads, and ensure the question/version owner cannot be impersonated.
3. Add deterministic/idempotent choice option identities and publish each version with its complete ordered options; verify remote question/version/options under the same JWT before mapping. Simulate partial writes and retry without duplicates.
4. Test single- and multiple-choice attempts through offline→online, edit/delete-before-sync, account switch, server retry, relaunch and duplicate flush. Keep media/LaTeX explicitly unsupported until a safe media upload/storage/RLS flow exists.
5. Expose honest user-facing sync state, and audit author/edit/private/public and moderation/account-deletion flows separately for RC-07.

## Release constraint

Do not mark RC-06 PASS, advertise cloud sync for all four formats, or publish to TestFlight while these gates remain open. The 122 verified tests in the preceding iteration cover the existing supported paths, not the missing choice/media sync feature.
