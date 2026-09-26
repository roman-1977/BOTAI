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

Product discovery / requirements.

Do not begin implementation until MVP scope and architecture are explicitly approved.

## Accepted architecture

- iOS: Swift + SwiftUI.
- Architecture: feature-based and local-first.
- Backend: Supabase / PostgreSQL.
- Backend access must be isolated behind repository/sync layers.
- Core study must work offline.
- Sign in with Apple is planned.
- Published content has a lifecycle independent from author account deletion.
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
