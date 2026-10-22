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
| Priority | Work package | Verified progress and real remainder | State |
|---|---|---|---|
| P0 | Session launch, ordering, resume | Topic/subject/all, mixed/cards/tests, automatic/all, durable cursor and reset verified; 36 card/choice and 18 mixed availability states. Distinct-subject exhaustive E2E not evidenced | **IMPLEMENTED / acceptance PARTIAL** |
| P0 | Automated session matrix | Card-only 18, choice-only 18, mixed-catalog 18 availability states; actual launch/feedback and shared-set tests PASS. Exhaustive full-session multi-subject E2E remains | **SUBSTANTIALLY TESTED / edge matrix pending** |
| P0 | Teacher-guided adaptive planning | Due-first, new/future fallback, stable tie and date handling implemented. Teacher inputs, difficulty/pace/weakness scoring remain unimplemented | **OPEN — functional gap** |
| P0 | Completed-session aggregate sync | Disk-backed retry/ACK, offline Keychain, account isolation, PostgreSQL migrations 0025/0026 and 3 RLS fixtures PASS. Owner accepts deferring hosted/device gates; not a live-backend PASS | **LOCAL ACCEPTANCE COMPLETE / external deferred** |
| P0 | Visual/accessibility audit | Small/standard/large iPhone, home no-scroll, chart, VoiceOver, Dynamic Type and Reduce Motion evidence still missing | **OPEN** |
| P0 | Final regression | At `95cd330`: signed 159/159 unit + 25/25 UI PASS; separate seeded chemistry 2/2 PASS at earlier checkpoint. Rerun after final code changes | **CURRENT PASS / final rerun pending** |
| P1 | Public content and Apple policy | Authoring, moderation, reports, block, deletion and privacy operational acceptance not fully verified | **PARTIAL** |
| P1 | Distribution readiness | Local simulator Release build exists; signing, metadata, device and TestFlight not verified; publication explicitly deferred | **DEFERRED** |
| P1 | Handoff and RC signoff | Per-commit evidence exists; current summary reconciled at `95cd330`; final signoff pending | **IN PROGRESS** |

**Execution order:** (1) close deterministic session-mode tests; (2) finish adaptive policy and tests; (3) disposable-backend/offline sync verification; (4) device visual/accessibility checks; (5) full isolated regressions; (6) privacy/moderation and release checklist. Re-evaluate remaining gaps after each gate; no RC tag until mandatory gates pass or owner explicitly scopes them out.

### Checkpoint — shared selection and deterministic tests, 2026-10-22

Unified `StudyQuestionSelection` is implemented in `DailyPlanner.swift` and reused by `GameHomeView.swift`. New unit matrix covers formats, duplicate IDs, both strategies, due/new/future priority and no-due fallback. **139/139 unit + 16/16 standard UI PASS** on iPhone 16e simulator (`/tmp/botai_selection_full_20261022.log`). **Still OPEN:** full UI cross-product, disabled empty launch, answer persistence per format and chemistry seeded rerun. Next: extend targeted UI acceptance without relying on source-only assertions.

### Empty-library UI checkpoint — 2026-10-22

Empty-catalog quick-start disabled-state and no-spurious-session UI test **PASS** (`/tmp/botai_empty_catalog_ui_20261022.log`). Still to verify populated scope/format matrix and format-specific empty states; run full suite after these additions.

### Explicit topic attribution — 2026-10-22

Chosen-topic sessions now override ambiguous shared-question ownership with the explicit course/section/topic selection; mixed/subject sessions retain conservative unique ownership. 140/140 unit tests PASS. Full regression 140/140 unit + 17/17 UI PASS; populated scope cross-product remains pending.

### Обязательная передача контекста перед релизом

Каждый значимый checkpoint и финальная приёмка должны актуализировать `docs/iterations/CURRENT_HANDOFF_AND_PROMPT.md` (текущее состояние, тесты, ограничения, следующий шаг и копируемый промпт для нового чата). Источник правил: `docs/iterations/DEVELOPMENT_HANDOFF_STANDARD.md`. Передача без документации и промпта не считается завершённой.

### Chemistry seeded checkpoint — 2026-10-22

На отдельном disposable iPhone 16e после guarded seed **2/2 ChemistryPilotSmokeTests PASS** (`/tmp/botai_chemistry_disposable_seeded_20261022.log`, exit 0). Вместе с предыдущей стандартной регрессией **140/140 unit + 23/23 UI PASS** это закрывает текущий автоматизированный regression checkpoint, но не остальные RC-гейты. Далее cross-product режимов и shared-set attribution.

### Shared questionnaire semantics — 2026-10-22

Владелец подтвердил: один опросник в разных темах освоен везде при освоении единого `knowledgeID`. Unit regression на durable reopen across topic contexts: **141/141 PASS**, `/tmp/botai_shared_knowledge_all_units_20261022.log`. Следующая проверка: UI E2E двух реальных тем и статистика уникального прогресса.

### Shared unique coverage checkpoint — 2026-10-22

Новый unit regression проверяет общий `knowledgeID` в двух темах и union для предмета: **142/142 PASS**, `/tmp/botai_shared_goal_all_units_20261022.log`. Осталось UI E2E на двух реальных темах и проверка агрегатов завершённой сессии.

### Two-topic shared questionnaire UI checkpoint — 2026-10-22

Реальный UI-сценарий двух тем с одним опросником: **1/1 PASS**, `/tmp/botai_shared_two_topics_ui_20261022.log`, subject question count deduplicated. Не проверено ещё завершение сессии с правильным topic breakdown и shared mastery в UI.

### Completed-session shared topic attribution — 2026-10-22

Проверено сохранение двух завершённых занятий по одному вопросу с разными выбранными темами: **143/143 unit PASS**, `/tmp/botai_shared_topic_summary_units_20261022.log`. Следующий gate: полный UI ответ→завершение→отчёт и интеграция backend.


### RC-06 account-bound sync hardening — 2026-10-23

Bound every `SyncService` instance to its originating authenticated UUID. A stale task may no longer start aggregate uploads from an old account database under a newly signed-in account; identity is rechecked at coordinator checkpoints. See `docs/iterations/RC06_ACCOUNT_BOUND_SYNC_2026-10-23.md`. Added regression coverage for account match, switch and sign-out. RC-06 remains OPEN pending end-to-end offline cold launch, reconnect, revoked-session and multi-account acceptance tests; no release approval.


### RC-06 offline revalidation fail-closed — 2026-10-23

`AuthStore.reconnectOfflineSession()` now locks local study on non-transport authorization failures and account mismatch, instead of leaving the offline identity active. Network outages still preserve local study access. See `docs/iterations/RC06_RECONNECT_AUTH_REJECTION_2026-10-23.md`. Signed unit suite: **156/156 PASS** (`/tmp/botai_rc06_revalidation_20261023.log`). Full offline/reconnect/ACK acceptance remains OPEN; never treat this regression as RC-06 closure.


### RC-06 foreground network restoration — 2026-10-23

Added `NWPathMonitor`-driven retry on offline→online transition even while the app stays foregrounded. Supabase account revalidation and existing account-bound aggregate sync are still required. Unit suite **157/157 PASS** (`/tmp/botai_rc06_connectivity_20261023.log`); UI regression log `/tmp/botai_rc06_connectivity_ui_20261023.log`. See `docs/iterations/RC06_FOREGROUND_CONNECTIVITY_RETRY_2026-10-23.md`. Full controlled network/hosted backend acceptance remains OPEN.


### RC-06 offline logout fail-closed — 2026-10-23

Local identity and offline binding are now always cleared on sign-out even when Supabase remote logout fails. The pinned Supabase SDK clears its persisted session before the remote call; remote token revocation is not claimed on network failure. See `docs/iterations/RC06_OFFLINE_LOGOUT_2026-10-23.md`. Signed regression evidence: `/tmp/botai_rc06_signout_20261023.log` (pending), UI regression `/tmp/botai_rc06_connectivity_ui_20261023.log` (earlier build). Full hosted backend acceptance remains open.


### Verification cadence (approved 2026-10-23)
Use targeted build + affected unit/UI tests for localized changes; run full signed unit/UI regression at completion of substantial milestones and before release. Auth/storage/sync require focused failure and isolation coverage. Record exact test evidence per commit; see `docs/iterations/DEVELOPMENT_HANDOFF_STANDARD.md`.

RC-06 (2026-10-23): deterministic SQLite cold-relaunch → offline failure → reconnect → idempotent ACK regression added. Next acceptance: opt-in development Supabase integration with migrations 0025/0026 and two-user RLS; no production migration or host-network interruption without explicit authorization.

RC-06 hosted acceptance harness: `LiveSupabaseSyncTests.aggregateOnlyIdempotentUploadAndTwoAccountIsolation` verifies server ACK, duplicate retry and cross-user RLS read on disposable Supabase. Keep disabled until test project and migrations 0025/0026 are explicitly confirmed; extend with topic ACK and revoked token tests. Routine focused compile/tests do not exercise the hosted service.

RC-06 repeatable SQL security gate: run `tools/verify_rc06_disposable_postgres.sh` only on the disposable Mac cluster; fail closed if absent/already running. Confirm all three fixtures PASS. This covers SQL RLS with shim only. Hosted Supabase ACK/RLS, genuine offline interruption and physical device remain separate acceptance gates.
