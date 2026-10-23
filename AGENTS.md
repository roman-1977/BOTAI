# BOTAI — AI Development Context

> **Обязательная карта проекта для ChatGPT:** `docs/CHATGPT_REPOSITORY_GUIDE.md`. Перед изменениями прочитать её, текущий план (`docs/IMPLEMENTATION_PLAN.md`), статус (`docs/IMPLEMENTATION_STATUS.md`) и RC-чеклист (`docs/releases/RC_0.3.0_READINESS.md`). Исторический раздел «Current phase» ниже не является актуальным статусом v0.3.0.

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

Architecture approved; v0.3.0 chemistry pilot is in RC hardening (overall NOT RC). Verified 2026-10-23 simulator baseline: 177/177 unit and 25/25 UI PASS at `6bce16f`. Current gates and next steps are in `docs/releases/RC_0.3.0_READINESS.md` and `docs/IMPLEMENTATION_PLAN.md`; do not treat older phase notes as current.

Continue in roadmap order where practical; preserve accepted ADRs and keep accepted UX documentation synchronized with implementation.

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

## Current implementation status

The repository now contains an active iOS prototype, not only implementation preparation. Before changing learner UX, read ADR-019 plus `docs/UI_SPEC.md`, `docs/SCREEN_FLOW.md`, and `docs/GOALS_PROGRESS.md`.

`LearnSessionView` currently mixes production interaction decisions with demo/view-local state. Treat its accepted interaction invariants as product requirements, but do not extend view-local counters into a persistence architecture. Move durable session/day timing, goals, mode preferences and scheduling into domain/repository services as those features are implemented.

When an accepted UX decision changes, update the relevant docs/ADR in the same commit as the code. Do not leave product behavior documented only in chat history.

## Client v1 execution plan

`docs/IMPLEMENTATION_PLAN.md` is the current definition of done and delivery order for the fully working client. `docs/CLIENT_ARCHITECTURE.md`, ADR-019 and ADR-020 define the learner/session and offline material boundaries. New implementation work must preserve offline study and avoid per-user paid API dependencies.

## Mandatory iteration completion / handoff

Every development iteration MUST follow `docs/iterations/DEVELOPMENT_HANDOFF_STANDARD.md`: synchronize impacted docs and implementation status, update dated progress and next steps, extend relevant tests, record reproducible test results, and commit scoped changes. An iteration without tests and handoff documentation is not complete.

### Full sequential simulator regression — 2026-10-23 (current baseline)

**181/181 unit PASS; 25/25 UI PASS; zero failed UI cases; `xcodebuild` exit 0; `** TEST SUCCEEDED **`.** iPhone 16e simulator `33176212-1247-4722-B8F4-4E53438502E4`, `-parallel-testing-enabled NO`, complete serial suite, 730.46 seconds. Log `/tmp/botai_rc04_full_181_20261023.log`. This run includes latest learner-course import rollback, ordinal teacher difficulty, ZIP -> SQLite -> planner tests, importer UI, recommendations after relaunch, resume, and session strategies. This is the **new authoritative simulator regression baseline** superseding the 177+25 snapshot at `6bce16f` and all older intermediate test notes. **Not a release candidate yet**: RC-04 multi-material course packaging/teacher authority and complete adaptive acceptance, RC-05 device/accessibility, hosted acceptance and distribution gates remain open. User-owned pbxproj not touched.
