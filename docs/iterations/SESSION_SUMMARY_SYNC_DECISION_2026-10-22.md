# BOTAI 0.3.0 — accepted session-summary sync architecture

Decision date: 2026-10-22. Status: **accepted product direction; not implemented**. This document supersedes the attempt-level cloud-sync implementation plan in `CONTENT_SYNC_AUDIT_2026-10-22.md`, but does not change the existing code or database.

## Boundaries

- **On device:** persist per-question attempts, correctness, spaced-repetition state, learning algorithm inputs, exact unfinished session and ordered question cursor. These remain usable offline.
- **On server:** store **aggregate results of a completed learning session**, not the text, choices or individual results of its questions. A session may cover multiple subjects, chapters or topics, so retain aggregate breakdowns by those dimensions.
- **Trigger:** queue a summary only when the session is explicitly/completely finished according to the session lifecycle. Backgrounding, app termination, suspension and resumable unfinished sessions MUST NOT submit a final summary.
- **Offline:** completion commits local summary and durable upload event atomically; network upload may happen later, including after restart/relogin. The same stable session ID must be idempotent across retries.
- **Identity/content:** stable `sessionId`, authenticated user identity, course ID and course version where applicable, session start/end, duration, total/correct/incorrect or rated counts, and aggregate subject/chapter/topic progress. Mixed-mode sessions must not be forced into a single course. Exact metric definitions and whether partial early finish counts as completed need implementation-time product verification.
- **Scope:** course content/versioning and public authoring are independent of learning statistics; do not publish questions to enable statistics sync. Local learning state is NOT restored across devices in this MVP; server summary is not sufficient for exact per-question restoration. Preserve a future backup/migration path without claiming it exists.

## Implementation plan / acceptance gates

1. Inventory actual finish/discard/resume lifecycle and local `StudySession`, `Attempt`, outbox, account isolation, and existing server tables. Define completion semantics, stable summary schema and topic breakdowns; avoid inventing metrics not captured by the client.
2. Add backward-compatible local schema for completed session summaries and pending summary uploads; ensure **exactly one** completion event and atomic commit with local stats. Migrate without deleting existing attempt history/outbox; define safe retirement policy for legacy attempt events.
3. Add server session-summary table/API, unique `(user_id, session_id)` idempotency, authenticated RLS and cross-account isolation; version content references as needed. Keep production/development backend untouched until separately authorized.
4. Implement provider-neutral summary upload, retry, ACK, account-change guards, and crash/relaunch handling. Do not send per-question details or text.
5. Test completed, abandoned, unfinished, interrupted, resumed, mixed-course, offline/reconnect, duplicate retry, account switch, and migration cases; run unit, UI and isolated seeded chemistry suites.
6. Update analytics, documentation and RC-06 only after verified implementation. Reassess legacy `RemoteQuestionPublisher`, `AttemptSyncCoordinator` and attempt outbox rather than silently removing them before migration.

## Explicit non-goals for this iteration

No new full-question answer snapshots, no server publication of answer options just to upload attempts, no automatic cross-device restoration of per-question repetition state, no TestFlight claim without acceptance checks.
