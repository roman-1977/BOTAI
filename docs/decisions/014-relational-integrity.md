# ADR-014: Redundant identity pairs use composite foreign keys

Status: Accepted

## Context

Several records intentionally store both a stable parent identity and a concrete version identity, for example `(quiz_id, quiz_version_id)` and `(question_id, question_version_id)`.

Independent foreign keys can each be valid while referring to different parents.

## Decision

Whenever both IDs are stored, the database enforces their relationship with a composite foreign key to a unique `(parent_id, version_id)` pair.

This applies to enrollment quiz versions, Attempt quiz/question versions, publication quiz versions, QuizVersion items, and answer-option versions.

## Reason

The invariant belongs in PostgreSQL rather than relying on application code or triggers. It prevents impossible cross-linked records from entering authoritative data through any client or trusted service.

## Deployment note

These migrations are still design migrations and have not been applied to production. Therefore the invariants are corrected in the original migration definitions so a fresh database is valid from migration 0001 onward. If any environment is created from an earlier revision, it must be rebuilt or receive an explicit compatibility migration.

The same principle should be mirrored in local schema constraints where the redundant pair is stored locally.


