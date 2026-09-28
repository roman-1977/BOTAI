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
