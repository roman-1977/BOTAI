# ADR-015: Local private data is isolated by account

Status: Accepted

## Decision

Private cached learning/social data must never become visible after switching to another account on the same device.

The preferred implementation is a separate GRDB database namespace/file per authenticated user, with public/bootstrap cache kept separate if useful. Logout closes the private database; account deletion removes its private local store after the deletion workflow reaches the appropriate stage.

## Reason

Per-user storage reduces the chance that a missing SQL predicate exposes another user's private learning history and makes account cleanup easier to reason about.

Shared public media/content caches may be reused only when they contain no private user data and their lifecycle permits retention.

This decision applies to sync cursors/outbox state as well as domain records.

After confirmed account deletion, discard that account's private local store/outbox so stale operations cannot be replayed.

The first implementation may keep downloaded public content in the per-user store; a shared public cache is optional optimization, not an MVP requirement.


