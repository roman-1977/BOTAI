# BOTAI Local Database (GRDB / SQLite)

Status: Accepted target architecture; first local implementation active.

Implementation snapshot (2026-10-01): AppDatabase migrations v1-v7 implement Attempts, LearningState, sync outbox, Materials/Fields/Rows/Rules, Courses, StudyProfile and StudySessions. Attempt + LearningState + outbox writes are transactional. Not yet implemented from the target contract below: pull cursors/tombstones, full reconciliation, per-account database isolation, social cache tables, explicit file-protection policy and migration-upgrade fixtures.

## Purpose

The iOS app is local-first. SwiftUI reads application state from repositories backed by GRDB, not directly from Supabase.

The local database contains only data required by this device: the signed-in user's private data, downloaded/subscribed content, learning history/state, social data needed for current UI, and durable sync metadata.

## Local authority

Locally authoritative while offline:

- newly created Attempts;
- StudySession progress;
- local calculated LearningState;
- user edits that are explicitly supported offline.

Server authoritative:

- publication/moderation state;
- public content versions;
- staff decisions;
- canonical LearningState after merged Attempts;
- challenge results.

## GRDB schema groups

Content cache:
`local_quizzes`, `local_quiz_versions`, `local_questions`, `local_question_versions`, `local_answer_options`, `local_answer_option_versions`, `local_quiz_version_items`, `local_media`.

Learning:
`local_enrollments`, `local_study_sessions`, `local_attempts`, `local_learning_states`, `local_goals`, `local_goal_quizzes`.

Social/cache:
`local_friendships`, `local_shared_results`, `local_challenges`, `local_challenge_participants`, `local_challenge_results`.

Sync infrastructure:
`sync_outbox`, `sync_cursors`, `sync_tombstones`, `sync_metadata`.

Server-only moderation tables do not need full local mirrors unless a future moderator client requires them.

## IDs and timestamps

Synchronized IDs are UUIDs generated before upload. Store timestamps as UTC instants. Preserve server receipt timestamps separately from device event timestamps where both exist.

## Outbox

Each local mutation that requires upload creates an outbox record in the same SQLite transaction as the domain mutation.

Minimum fields: `id`, `entity_type`, `entity_id`, `operation`, `payload_version`, `created_at`, `attempt_count`, `next_retry_at`, `last_error`.

An Attempt upload is idempotent because the Attempt UUID is the server primary key. Successful acknowledgement removes the corresponding outbox operation.

## Pull cursors

Each independently pulled stream has its own cursor. A failed pull must not advance its cursor. Apply a remote page and advance its cursor in one SQLite transaction.

## Reconciliation

After upload/pull, merged Attempts are authoritative evidence. The device may immediately calculate provisional LearningState offline; canonical server LearningState replaces/reconciles that cache after synchronization.

Never resolve LearningState by timestamp-based last-write-wins between devices.

## Cache withdrawal

Suspended/withdrawn publications stop being offered for new study. Cached presentation data is removed only when it is no longer required to render retained historical learning records and when the applicable UGC deletion policy permits retention.

## First implementation boundary

Do not mirror PostgreSQL mechanically. The first GRDB migration should contain the minimum records required for Home/Learn/Library/Goals plus sync infrastructure. Add social local tables when the corresponding UI is implemented.

Concrete GRDB table definitions belong in Swift migrations so they can be tested together with repository code.

## Multi-device invariant

A second device may upload Attempts that the first device has never seen. Therefore a device must be prepared for canonical LearningState to move backward or forward after reconciliation. The UI may explain synchronization but must not discard remote Attempts to preserve a locally preferred state.

## Media

Database rows store media identity/metadata; binary media is cached in the filesystem. Downloads should use content/version-aware cache keys and must tolerate eviction. Required study media can be rehydrated when online.

## Logout / account switch

Private local data is scoped to the authenticated user. Logout/account switch must not expose one user's cached private learning/social data to another account. The implementation may use per-user databases or a rigorously enforced user scope; choose before authentication UI is wired.

Preferred account isolation is a separate private GRDB store per authenticated user (ADR-015).

## Testing requirements

Sync tests must cover duplicate Attempt upload, app termination between local mutation and sync, retry after server timeout, two devices producing Attempts offline, cursor rollback on failed page application, withdrawn publication, and account switch isolation.

## Network scheduling

Sync is opportunistic: app foreground/start, connectivity recovery, explicit user actions that need freshness, and background opportunities where iOS permits. Core Learn must never wait for a successful network round trip when required content is already local.

## Security boundary

The local database is a cache/working store, not an authorization boundary. Server RLS/trusted operations must independently validate every synchronized mutation.

## Schema versioning

GRDB migrations are forward-only and named. Tests must open a fresh database through every migration and upgrade representative older fixtures. Never edit a released local migration after shipping it in an App Store build.

## First vertical slice

The first executable slice should prove: bundled/downloaded quiz → offline answer → Attempt + local LearningState + outbox in one transaction → app restart → state preserved → later idempotent upload. This validates the architecture before broader UI work.

The concrete first schema will be authored with the Swift project so GRDB migrations and repository tests evolve together.

## Observability

Sync errors should be inspectable without leaking private study content into logs. Record operation type, entity ID, retry metadata and sanitized server error information; avoid logging answer payloads by default.

## Retry

Outbox retry uses bounded exponential backoff with jitter for transient failures. Authorization/validation failures are surfaced as non-transient until user state or server rules change; do not hammer the backend indefinitely.

## Ordering

Do not assume global wall-clock ordering across devices. `answered_at` describes user event time but device clocks can drift; event identity and server receipt/order metadata must be preserved so reconciliation logic can define deterministic behavior.

## Payload compatibility

Outbox payloads carry a payload/schema version. Server and client changes must preserve backward compatibility for operations that may remain queued across an app upgrade.

Mutable personal/editor records require an explicit conflict strategy before offline editing is enabled for that entity; the Attempt merge model must not be copied blindly to mutable records.

## Background execution

Background sync is an optimization, not a correctness requirement. The outbox and cursors must remain correct if iOS suspends or kills the app at any point.

## Data protection

The iOS implementation should use an appropriate file-protection class for the private database and private cached media, consistent with required background behavior. Authentication secrets belong in Keychain, not SQLite.

Exact iOS file-protection/background tradeoff will be finalized with the app lifecycle implementation.

## Server deletion interaction

Account deletion is a server workflow. Once deletion is confirmed, the app clears the corresponding private local database and credentials; it must not re-upload stale outbox operations from a deleted account.

## Public/private split

A future implementation may keep a shared public content cache separate from per-user private databases. This is an optimization only; the first vertical slice may keep downloaded content inside the per-user database for simplicity.

This keeps the MVP simple while preserving a path to cache optimization later.

End of local database v1 contract.

