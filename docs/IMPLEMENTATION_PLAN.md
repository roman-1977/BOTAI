# BOTAI Client — implementation plan

Goal: make the current iOS client independently usable offline, with optional account/sync features and a future Studio that shares the package format.

## Definition of done for Client v1

1. Fresh install opens with demo material but does not require an account.
2. User can import a `.botai` package and create material from CSV.
3. Imported/created material survives relaunch and can be deleted without damaging learning history for other materials.
4. User can choose one or several installed materials and start/resume a study session.
5. Card, single-choice and multiple-choice flows follow ADR-019; daily questions/minutes/accuracy/coverage persist across launches.
6. User can pause, background the app, relaunch and continue without counting inactive time.
7. Account connection is optional; signed-in users can later sync. Basic offline study never depends on Supabase availability.
8. Class/group and Public Library are real acquisition routes when backend endpoints are enabled; they normalize into the same installed-material model.
9. Sample CSV and `.botai` fixtures exercise import end to end; unit tests cover parser, storage, generation and session lifecycle.
10. Documentation and migrations change in the same commits as behavior.

## Delivery order

### A. Local content foundation — in progress
Unified material/field/knowledge/rule model, GRDB v2 migration, package contract, fixtures and repository tests.

### B. Import and authoring
Secure `.botai` ZIP importer/exporter; CSV preview; field naming; rule editor; optional image references; transactional install.

### C. My Materials
Game-styled material library; source badges; search/filter; material detail; add flow with Package / CSV / Class / Library routes.

### D. Learning integration
Stable generated question IDs; material selection; multi-material session; persisted daily session, timing and coverage; adaptive local strategy.

### E. Account and distribution
Optional auth/sync, public library download, class join by code/QR, assignment ownership/read-only rules and conflict handling.

### F. Release hardening
Accessibility, localization-ready strings, malformed package tests, migration tests, offline/error states, privacy/account deletion, performance and App Store checklist.

## Active execution plan — v0.3.0 (2026-10-22)

This section supersedes the historical “in progress” labels above. **Goal: local RC acceptance, not publication.** Do not start TestFlight or App Store submission without separate owner approval. Preserve the independently modified `ios/BOTAI.xcodeproj/project.pbxproj`.

| Priority | Work package | Exit criteria / proof | State |
|---|---|---|---|
| P0 | Session launch, ordering and resume | All new-session scope choices; temporary format/strategy settings; due-first and equal-priority ordering; atomic resume; unit and UI regression | **Implemented; 137 unit + 16 standard UI PASS**. Full cross-product matrix pending |
| P0 | Automated session acceptance matrix | Deterministic tests for all/topic/subject × mixed/cards/tests × auto/all, no-due, empty format, duplicates, persisted attempts and restart | **OPEN** — see `SESSION_MODE_MATRIX_2026-10-22.md` |
| P0 | Adaptive teacher-guided planning | Document teacher inputs, weakness/urgency/pace scoring and tie rules; implement and test deterministic selection without a review-only mode | **OPEN** |
| P0 | Completed-session summary sync | Disposable Postgres migration `0025`/`0026`, RLS and idempotent retry tests, offline/reconnect and account isolation; question-level attempts remain local | **PARTIAL / backend acceptance pending** |
| P0 | Small/standard/large iPhone visual/accessibility audit | Home no-scroll, compact full-width chart, theme, VoiceOver, Dynamic Type, Reduce Motion evidence | **OPEN** |
| P0 | Final regression gate | Unit + standard UI + separately seeded chemistry UI after final code changes; no fixture contamination | **Standard 137+16 PASS; chemistry last 2/2 earlier checkpoint** |
| P1 | Public content and Apple policy | Author/edit/publish, moderation/report/block, account deletion, privacy disclosures and operational tests | **PARTIAL** |
| P1 | Distribution readiness | Signing, versioning, screenshots, privacy metadata, real-device checks, TestFlight install | **NOT VERIFIED; no distribution authorized** |
| P1 | Handoff and RC signoff | Updated docs, reproducible migration/rollback, clean scoped commit, owner acceptance | **IN PROGRESS** |

**Execution order:** (1) close deterministic session-mode tests; (2) finish adaptive policy and tests; (3) disposable-backend/offline sync verification; (4) device visual/accessibility checks; (5) full isolated regressions; (6) privacy/moderation and release checklist. Re-evaluate remaining gaps after each gate; no RC tag until mandatory gates pass or owner explicitly scopes them out.
