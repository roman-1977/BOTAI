# BOTAI — AI Development Context

Этот файл предназначен для AI-инструментов, работающих с репозиторием.

## Product

BOTAI — adaptive learning application.

Core concept:

**БОТАЙ → БОЛТАЙ → ЗНАЙ**

БОТАЙ = memorization and spaced repetition of approved content.

БОЛТАЙ / BOLDAI = separate AI examination based on already studied approved content.

## Important rules

1. Do not assume unresolved product decisions are accepted.
2. Check `/docs/OPEN_QUESTIONS.md` before making architectural assumptions.
3. Significant product or architecture decisions should be documented.
4. Prefer simple MVP implementations over speculative infrastructure.
5. Do not hard-code the architecture specifically for ЕГЭ.
6. Never commit API keys, tokens, signing secrets, passwords or credentials.
7. Keep documentation synchronized with accepted decisions.

## Current phase

Architecture approved; implementation preparation.

Implementation may begin in roadmap order; preserve accepted ADRs.

## Accepted architecture

- iOS: Swift + SwiftUI.
- Architecture: feature-based and local-first.
- Backend: Supabase / PostgreSQL.
- Backend access must be isolated behind repository/sync layers.
- Core study must work offline.
- Sign in with Apple is planned.
- Published UGC follows ADR-004 account-deletion lifecycle.
- BOLDAI and AI content generation are post-MVP.
- Product is designed App-Store-first.

## Data and synchronization

- Local persistence: SQLite via GRDB.
- All synchronized domain objects use stable UUIDs.
- Attempts are append-oriented learning events.
- LearningState is derived/cached current state.
- Never resolve learning progress using naive last-write-wins.
- Pair directions may have separate LearningState.
- Published content updates must preserve compatible user learning history.
- Device stores selected/downloaded content, not the complete public library.
- Sync operations must be idempotent.

## Publication and moderation

- Public user quizzes are UGC and use a moderated publication pipeline.
- Submission, moderation, publication and reports are separate domains.
- Normal clients cannot approve or publish their own submissions.
- Staff/moderator roles are server-controlled.
- Public access exposes published versions, never mutable drafts.
- Users must be able to report content and block abusive users.
- Ordinary published UGC does not automatically survive deletion of its
  responsible author's account.
- Account deletion is a trusted backend workflow, not a client-side cascade.
- Sign in with Apple deletion must include required credential/token revocation.

## Social model

- Learning data is private by default.
- Friendship requires explicit acceptance.
- Blocking overrides friendship/social visibility.
- Sharing creates explicit snapshots; do not expose raw Attempt history.
- Challenges use explicit invited participants.
- Challenge results are calculated server-side from Attempts.
- No global public learner leaderboard in MVP.

## Decision precedence

- Accepted ADRs are authoritative for architecture decisions.
- `docs/OPEN_QUESTIONS.md` contains only unresolved decisions.
- If older prose conflicts with an Accepted ADR, update the prose instead of reviving the old decision.

## Local database contract

- iOS operational persistence is SQLite via GRDB.
- Repositories use GRDB; SwiftUI does not treat Supabase responses as durable UI state.
- Domain writes and required outbox operations are one local transaction.
- Pull cursors advance atomically with application of the corresponding remote page.
- Local LearningState may be provisional; synchronized Attempts remain durable learning evidence.

## Relational integrity

When a record stores both a stable identity and one of its version IDs, enforce the pairing with a composite foreign key. Do not rely on independent FKs or application validation for this invariant.

## Local account isolation

Prefer a separate private GRDB store per authenticated user. Never allow account switching to expose another user's cached learning or social data. Public cache reuse is allowed only for non-private content with compatible lifecycle rules.

- Never edit a GRDB migration after it has shipped in an App Store build; add a new forward migration.

- Do not log private answer/content payloads by default when instrumenting sync failures.

- Do not use device wall-clock timestamps as a universal conflict resolver across devices.

- Version durable outbox payloads; queued operations may survive an app upgrade.

- Sync correctness must not depend on iOS background execution being granted.

- Authentication secrets belong in Keychain, never SQLite or source-controlled config.
