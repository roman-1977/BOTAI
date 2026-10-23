# BOTAI — AI Development Context
> **LIVE BACKEND AUDIT VERIFIED 2026-10-23:** read-only probe found Apple auth provider DISABLED and both aggregate REST tables 404 PGRST205. Immediate local logout lockout fix. Full post-change regression **184/184 unit + 28/28 UI PASS**. See `docs/iterations/LIVE_BACKEND_RELEASE_BLOCKERS_2026-10-23.md`.

> **REAL BACKEND AUDIT 2026-10-23 — BLOCKERS CONFIRMED:** Auth health HTTP 200, email provider enabled, confirmation required; **Apple provider DISABLED** in configured Supabase project. REST tables `completed_session_summaries` and `completed_session_topic_aggregates` both **404 PGRST205** (not exposed in schema cache). Supabase CLI migration listing blocked by IPv6, local Docker unavailable. No backend mutation. Added reproducible read-only probe `tools/release/check_live_auth_and_schema.sh`; fixed `AuthStore.signOut()` to lock local account **before** awaiting remote logout. `docs/iterations/LIVE_BACKEND_RELEASE_BLOCKERS_2026-10-23.md`.

> **IOS DEVICE ARCHIVE AUDIT 2026-10-23:** unsigned Release **arm64 iOS archive 0.3.0 (1) PASS**, compiled ChemistryPilot asset verified; `/tmp/BOTAI-Chemistry-0.3.0-PreRC.xcarchive`. Reproducible read-only audit `tools/release/archive_chemistry_prerc.sh`. **Not signed/installable**; hosted auth/sync and distribution signing remain blockers. See `docs/iterations/CHEMISTRY_IOS_ARCHIVE_AUDIT_2026-10-23.md`.

> **TWO-STUDENT FULL REGRESSION PASS 2026-10-23:** 184/184 unit + 28/28 UI PASS, `xcodebuild` exit 0, `/tmp/botai_two_student_full_verified_20261023.log`. Actual chemistry-question attempt persisted independently across two SQLite account DBs, reopen and repeated provisioning. Hosted auth/sync, signed archive, physical acceptance remain OPEN. `docs/iterations/CHEMISTRY_TWO_STUDENT_DURABILITY_2026-10-23.md`.

> **TWO-STUDENT DURABILITY 2026-10-23:** Added disk-backed chemistry test: two account-specific SQLite files, same real chemistry question, distinct attempt IDs/streaks, cold reopen in reverse order and repeated provisioning without progress loss. Verification pending final post-change regression. `docs/iterations/CHEMISTRY_TWO_STUDENT_DURABILITY_2026-10-23.md`.

> **FINAL PRE-RC SIMULATOR REGRESSION 2026-10-23:** Release simulator build PASS; **183/183 unit + 28/28 UI PASS** after new Apple/email/recovery entry test, exit 0, `/tmp/botai_pre_rc_full_20261023.log`. Signed iOS archive, hosted auth/sync and multi-day learner acceptance still BLOCK RELEASE. Install phones only after release is ready. `docs/iterations/CHEMISTRY_LEARNER_PRE_RELEASE_GATE_2026-10-23.md`.

> **PRE-RELEASE ORDER 2026-10-23:** owner requires release candidate FIRST, physical installation SECOND. Release simulator build PASS; new Apple/email account-entry UI PASS; full post-change regression running. Hosted auth, multi-day durability, hosted aggregate sync, signed archive and final accessibility still OPEN; no RC declaration. `docs/iterations/CHEMISTRY_LEARNER_PRE_RELEASE_GATE_2026-10-23.md`.

> **FULL REGRESSION 2026-10-23:** chemistry built into iOS app, initial guest and each new account provisioned independently; 323 knowledge rows, 102 materials, 25 topics, 5 sections, 70% staged route. **183/183 unit + 27/27 UI PASS**, serial iPhone 16e simulator, `/tmp/botai_chemistry_install_full_final.log`, exit 0. Real 15/16 Pro Max physical devices, hosted auth and multi-day acceptance still OPEN. See `docs/iterations/RELEASE_TARGET_DECISION_2026-10-23.md`.

> **CHEMISTRY INSTALL CHECKPOINT 2026-10-23:** `ChemistryPilot.dataset` bundled in iOS app; deterministic per-account first-install provisioning (323 questions, 102 materials, 25 topics, 5 sections, card + choice), no destructive Python seed required, preserves existing course/progress on relaunch. 183/183 unit PASS; focused chemistry UI PASS. Full simulator suite running; real devices/auth/multi-day acceptance remain open. `docs/iterations/RELEASE_TARGET_DECISION_2026-10-23.md`.

> **РЕШЕНИЕ ВЛАДЕЛЬЦА 2026-10-23 — ЦЕЛЬ РЕЛИЗА:** довести полный согласованный MVP до релиза; два независимых ученика на iPhone 15 Pro Max и iPhone 16 Pro Max, начать с химии; контент и охват ЕГЭ — ответственность преподавателя, работа приложения — наша. Полная регрессия 181/181 unit + 25/25 UI PASS на iPhone 16e, **NOT RC** до приёмки целевых устройств и закрытия RC-гейтов. Подробности: `docs/iterations/RELEASE_TARGET_DECISION_2026-10-23.md`. Подготовка TestFlight/App Store не означает разрешения на отправку. Старые исторические снимки ниже не отменяют это решение.


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
