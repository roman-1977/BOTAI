# ADR-013: GRDB local database and transactional sync contract

Status: Accepted

## Decision

iOS uses SQLite through GRDB as its operational local store.

SwiftUI does not use Supabase responses as durable UI state. Repositories read/write GRDB; Sync Engine exchanges data between GRDB and Supabase.

## Atomic local writes

A domain mutation and its required `sync_outbox` entry are committed in the same SQLite transaction. This prevents a successful local action from being lost merely because the app terminates before enqueueing sync.

## Attempts

Attempts are append-oriented events with client-generated UUIDs. Retrying the same upload is idempotent.

## LearningState

Local LearningState is provisional/cached for immediate offline UX. Canonical server state is derived from merged Attempts and may replace/reconcile local cached state.

## Pulls

Remote streams use independent durable cursors. Applying a page and advancing its cursor is atomic locally.

## Conflict policy

There is no universal last-write-wins rule.

- published content: server lifecycle/version wins;
- Attempts: merge by UUID;
- LearningState: derive/reconcile from Attempts;
- challenge results and moderation: server wins;
- mutable personal records: explicit per-entity rules are required before implementation.

## Scope

The device does not mirror the complete public catalog. It caches selected/subscribed content and data required for current features.

This ADR defines the contract; concrete Swift/GRDB migrations are created with the iOS project.

## Account isolation

Private sync state is scoped to one authenticated user's local store. See ADR-015.

GRDB migrations become immutable once included in a released App Store build; later schema changes use forward migrations.

Transient retries use bounded exponential backoff with jitter; permanent validation/authorization failures are retained for diagnosis rather than retried aggressively.

Device timestamps are not treated as a globally reliable total order across devices.

Queued operation payloads are versioned because they can survive app upgrades while offline.

Sync correctness must not depend on iOS granting background execution time.

See `docs/LOCAL_DATABASE.md` for the expanded implementation contract.
