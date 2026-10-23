# BOTAI Client — implementation plan

> **CURRENT AUTHORITATIVE SNAPSHOT (2026-10-23; baseline commit `6bce16f`).** Branch `feature/v0.3.0-chemistry-pilot`. Complete sequential iPhone 16e simulator run: **177/177 unit and 25/25 UI PASS**, exit 0, `/tmp/botai_rc04_full_final_20261023.log`. Separately seeded chemistry UI: **2/2 PASS** at an earlier checkpoint, not included in the full run. RC-08 PASS for this baseline, but **overall NOT RC**. RC-04 P0 OPEN: `.botai` one-material coursePlan imports goals/sections/topics/guidance, SQLite persistence and Today recommendation sheet work; teacher priority breaks observed-urgency ties and suggested pace is compared without overriding profile minutes. Difficulty is informational only; multi-material course transport and full teacher-guided acceptance remain OPEN. RC-05 multi-size/accessibility/device OPEN; RC-06 local aggregate-sync and disposable SQL gates PASS, hosted/device checks deferred by owner; RC-07 partial; RC-09 distribution deferred. User-owned `ios/BOTAI.xcodeproj/project.pbxproj` must never be staged, overwritten or reverted. Older dated checkpoints below are historical, not the current status.

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

| Priority | Work package | Verified progress and real remainder | State |
|---|---|---|---|
| P0 | Session launch, ordering, resume | Topic/subject/all, mixed/cards/tests, automatic/all, durable cursor and reset verified; 36 card/choice and 18 mixed availability states. Distinct-subject exhaustive E2E not evidenced | **IMPLEMENTED / acceptance PARTIAL** |
| P0 | Automated session matrix | Card-only 18, choice-only 18, mixed-catalog 18 availability states; actual launch/feedback and shared-set tests PASS. Exhaustive full-session multi-subject E2E remains | **SUBSTANTIALLY TESTED / edge matrix pending** |
| P0 | Teacher-guided adaptive planning | Due-first, new/future fallback, stable tie and date handling implemented. Teacher guidance imported/persisted/displayed; priority breaks observed-urgency ties, pace compared without changing budget; difficulty weighting and multi-material transport OPEN | **PARTIAL / difficulty adaptation and teacher authority OPEN** |
| P0 | Completed-session aggregate sync | Disk-backed retry/ACK, offline Keychain, account isolation, PostgreSQL migrations 0025/0026 and 3 RLS fixtures PASS. Owner accepts deferring hosted/device gates; not a live-backend PASS | **LOCAL ACCEPTANCE COMPLETE / external deferred** |
| P0 | Visual/accessibility audit | Small/standard/large iPhone, home no-scroll, chart, VoiceOver, Dynamic Type and Reduce Motion evidence still missing | **OPEN** |
| P0 | Final regression | At `6a2a5d7`: signed 177/177 unit + 25/25 UI PASS; separate seeded chemistry 2/2 PASS at earlier checkpoint. Rerun after final code changes | **PASS / 2026-10-23 clean serial full suite** |
| P1 | Public content and Apple policy | Authoring, moderation, reports, block, deletion and privacy operational acceptance not fully verified | **PARTIAL** |
| P1 | Distribution readiness | Local simulator Release build exists; signing, metadata, device and TestFlight not verified; publication explicitly deferred | **DEFERRED** |
| P1 | Handoff and RC signoff | Per-commit evidence exists; current summary reconciled after `6bce16f`; final signoff pending | **IN PROGRESS** |

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

### RC-04 contract audit — 2026-10-23

Existing daily planner already uses goal mastery, deadline deficit, profile budget, due/new/not-due priority and deterministic ordering. Teacher-guided assignment/priority/difficulty/pace is **not** implemented; separate teacher role and multi-goal time policy remain unresolved in `docs/OPEN_QUESTIONS.md`. No arbitrary scoring formula is authorized. Detailed gap audit: `docs/iterations/RC04_ADAPTIVE_CONTRACT_AUDIT_2026-10-23.md`.

### RC-04 MVP scope reconciliation — 2026-10-23

`docs/REQUIREMENTS.md` requires learner-side goal/date/progress/budget/pace daily planning in MVP; this baseline is implemented but its multi-goal edge cases still need acceptance. Expanded teacher authoring tools are listed post-MVP in `docs/ROADMAP.md`, **but** accepted `docs/COURSES_AND_GOALS.md` and ADR-023 still describe teacher/class assignments; do not silently drop them. Teacher role/authority/scoring remain separate unresolved requirements. See RC04 audit.

### Owner correction — RC-04 mandatory student MVP, 2026-10-23

**P0: full student-side recommendations are required in this release.** Teacher-facing UI is deferred, **not** teacher-guidance processing. Input via course import or direct chemistry-style seed; local persistence, adaptive use, student visualization, tests all mandatory. Supersedes earlier interpretation that teacher-guided policy could be excluded from MVP. See `docs/iterations/RC04_STUDENT_RECOMMENDATIONS_DECISION_2026-10-23.md`.

RC-04 checkpoint: optional teacher priority now resolves equal-urgency goal ordering deterministically, preserving learner evidence as primary signal. Remaining P0: difficulty, pace, general course import, learner visualization of adaptive impact, multi-goal/UI acceptance. Test evidence: `/tmp/botai_rc04_guidance_order_units_20261023.log` 161/161 PASS.

RC-04 multi-goal allocation checkpoint: fair deterministic shared-minute budget, urgency-based remainder and bounded teacher tie-break; verified 164/164 simulator units (`/tmp/botai_rc04_multigoal_units_20261023.log`). Remaining mandatory recommendation ingestion/difficulty/pace/visualization/UI tests.

RC-04 metadata checkpoint: teacher difficulty and recommended pace are now accepted, validated, persisted with goals and shown on Today. They are not yet applied to adaptive scheduling; no silent learner-budget override. 167/167 unit PASS `/tmp/botai_rc04_difficulty_pace_units_20261023.log`.

RC-04 pace visualization checkpoint: teacher suggested daily minutes vs actual per-goal allocation now displayed; chemistry direct seed includes difficulty/pace. 168/168 unit PASS `/tmp/botai_rc04_pace_assessment_units_20261023.log`. General import/adaptive difficulty/UI acceptance still mandatory.

### RC-04 consolidated planner regression (2026-10-23)

Planner now removes overlapping question IDs **before** assigning shared study minutes, so goals with no remaining unique work do not consume time and the budget is reallocated to actionable goals. Due/new/not-due ordering and deterministic teacher-priority tie-break remain unchanged. Deadline urgency now counts calendar days (not truncated 24-hour intervals), including overdue deadlines. Added midnight/next-day/overdue/no-deadline regression. Full simulator unit + standard UI run: `/tmp/botai_rc04_batch_full_20261023.log` (check final result before claiming PASS). Outstanding: full teacher course import, adaptive difficulty policy, end-to-end UI guidance acceptance, physical device. RC-04 stays OPEN.

### RC-04 overlap integration verification — 2026-10-23

Added real in-memory SQLite material + two active goals referencing the exact same question set. DailyPlanner now demonstrably emits one goal, one question, and assigns the full 20-minute learner budget to that actionable goal rather than reserving time for an empty overlapping goal. Simulator unit suite **171/171 PASS** (`/tmp/botai_rc04_overlap_integration_20261023.log`). A separate full UI suite is still running (`/tmp/botai_rc04_batch_full_20261023.log`); do not mark UI PASS before its final summary. The `.botai` format currently represents individual materials rather than courses; a separate agreed course transport is still required to ingest full teacher plans. Difficulty guidance remains informational, not a verified adaptive input. RC-04 OPEN.

### RC-04 bundled course import (2026-10-23)

Added an **optional `coursePlan` field to version-1 `.botai` material packages**: course title/subject and one or more goals with question-set indexes, mastery target, deadline and optional teacher guidance (priority, rationale, difficulty, suggested minutes). Old material-only archives decode unchanged. The import preview identifies bundled courses. Import saves material, maps package question-set indexes to newly generated persistent material/rule IDs, then saves an active learner course with its goals/guidance. If course persistence fails, it attempts to delete the just-imported material. Manifest validation rejects empty goal/title, out-of-range targets and invalid/disabled question-set references. The contract currently supports **one bundled material and its goals**; multi-material course archives and section/topic structure are not implemented.

Verification: simulator build PASS (`/tmp/botai_rc04_course_import_final_build_20261023.log`); **173/173 unit PASS** (`/tmp/botai_rc04_course_import_units_20261023.log`), including JSON compatibility, invalid references and SQLite material/course persistence. Full UI regression `/tmp/botai_rc04_batch_full_20261023.log` has at least one failing existing UI test (`testMixedCardAndChoiceFormatsAvailableForEveryScope` at line 562, course title not found); this is **not a passing UI suite**. End-to-end document picker, process restart and adaptive difficulty remain open. RC-04 OPEN.

### RC-04 import archive and UI triage — 2026-10-23

Added integration test that creates an actual `.botai` ZIP with a `coursePlan`, opens it through `BOTAIPackageService.read`, and verifies that teacher guidance and question-set mapping survive the archive boundary. Simulator **174/174 unit PASS** (`/tmp/botai_rc04_zip_course_units_20261023.log`). The earlier full UI run (`/tmp/botai_rc04_batch_full_20261023.log`) is **NOT PASS**: `testMixedCardAndChoiceFormatsAvailableForEveryScope` fails at `LaunchSmokeTests.swift:562` while waiting for the newly created course title; `testPopulatedChoiceOnlyTestsFormatAndAnswer` fails at line 518 while waiting for the session scope screen after launch. Do not relabel these as passed or delete tests; investigate simulator state and navigation persistence and rerun. Course import currently only supports one bundled material and goals, not full multi-material/section/topic course; teacher difficulty is not yet an adaptive signal. RC-04 OPEN.

### RC-04 course section/topic import and simulator isolation (2026-10-23)

Extended optional `.botai` `coursePlan` with `sections[]` and `topics[]`, each topic referring to validated enabled question-set indexes within the bundled material. The importer maps them to persistent `CourseSection`/`CourseTopic` and newly assigned rule IDs. Missing `sections` decodes as empty for backward compatibility. Empty sections/topics and invalid/disabled indexes reject before saving. Multi-material packages remain unsupported; do not describe this as a complete multi-material course importer.

Simulator build PASS (`/tmp/botai_rc04_section_import_build_20261023.log`); **175/175 unit PASS** (`/tmp/botai_rc04_section_import_units_20261023.log`), including section/topic JSON roundtrip and invalid-index rejection. Full UI suite started earlier was not isolated: subsequent test invocations targeted the same simulator while it was running, so its failures cannot be confidently attributed to the app. After stopping the long suite, isolated rerun showed `testMixedCardAndChoiceFormatsAvailableForEveryScope` PASS (48.408s), but `testPopulatedChoiceOnlyTestsFormatAndAnswer` failed with XCTest `Lost connection to the application` / simulator helper, not an assertion. Need a clean, **nonconcurrent** simulator UI run; never mark full UI PASS yet. RC-04 OPEN: adaptive difficulty, full course multi-material transport, complete UI acceptance and real-device checks.

### RC-04 bundled import mapping consolidation — 2026-10-23

Extracted a single `BundledCourseImporter.course(plan:manifest:references:)` mapping contract from the SwiftUI file importer. It validates the package before indexing, verifies the generated rule-reference count, constructs section/topic and goal links from the same mapped UUIDs, and preserves imported teacher guidance. The UI now calls this mapper rather than duplicating mapping logic. Added repository-level regression covering the actual built `StudyCourse` saved and reloaded from SQLite, section/topic references, goal references, guidance, and invalid reference-count rejection. Existing material-only packages remain supported. No multi-material archive support yet.

Verification logs: `/tmp/botai_rc04_import_mapping_units_20261023.log` (unit tests), `/tmp/botai_rc04_choice_ui_clean_20261023.log` (sequential choice UI regression). **Do not mark either PASS until the corresponding final test summary is confirmed.** Earlier isolated UI `testMixedCardAndChoiceFormatsAvailableForEveryScope` passed, while `testPopulatedChoiceOnlyTestsFormatAndAnswer` suffered a simulator helper disconnect; these are separate outcomes. RC-04 OPEN: adaptive difficulty policy, multi-material import, complete sequential UI acceptance and physical device.

RC-04 import mapper verification (2026-10-23): 176/176 simulator unit PASS, `/tmp/botai_rc04_import_mapping_units_20261023.log`; isolated choice UI PASS, `/tmp/botai_rc04_choice_ui_clean_20261023.log`. Full UI regression and adaptive difficulty remain OPEN.

### RC-04 learner-facing recommendation access — 2026-10-23

Found that `GameHomeView.goalsCard` existed but was **never inserted into the rendered view hierarchy**. Teacher priority, difficulty, suggested daily minutes, pace comparison, rationale, mastery and target were therefore invisible despite previous UI implementation claims. Added a compact `Рекомендации и цели` action in Today when actionable goals exist, opening a scrollable accessible goal-details sheet. The standard-size home remains one-screen and without scrolling. Existing active-goal UI scenario now checks the recommendations button, sheet title, goal name and actual mastery after app relaunch. This verifies access to persisted student guidance UI, not a new difficulty-scoring policy.

Verification pending: full sequential simulator suite `/tmp/botai_rc04_full_sequential_20261023.log` was launched **before** these UI edits and cannot verify them; run the focused changed UI scenario and unit suite after the full run exits. Do not report a green UI run before the final summary. Teacher difficulty still informational; an unapproved numeric weight must not be invented. RC-04 OPEN.

### RC-04 visible recommendations verification — 2026-10-23

Confirmed a product defect: `goalsCard` was defined but unreachable in the rendered Today hierarchy. Now a compact `Рекомендации и цели` button opens a scrollable sheet showing the real per-goal mastery/target, minutes, deadline and available teacher guidance without introducing scrolling on standard-size Today. The persisted-goal cold-relaunch UI test now opens the sheet and asserts the goal and `Освоено 0%`. **Focused simulator UI PASS** (`testCreateCourseSectionTopicAndGoal`, 75.867 s, `/tmp/botai_rc04_recommendations_ui_20261023.log`); **176/176 unit PASS** (`/tmp/botai_rc04_visible_guidance_units_20261023.log`). A full UI suite started before this fix was intentionally stopped so the updated UI could be verified; it is NOT a completed full UI regression. Full sequential regression remains required at RC closure. No change to teacher difficulty scoring or profile minute budget.

### Deterministic generated choice order — 2026-10-23

Fixed nonreproducible `StudyQuestionBuilder` distractor selection and answer ordering: SHA-256 ranking derived from stable rule ID, row ID and candidate text now gives the same answer list and correct indexes for a given material snapshot, including when a question is rebuilt after restart. This does **not** change the persisted snapshot for an in-progress session, or the automatic due/weak/new study priority. New regression covers repeated builds of six four-choice questions. **177/177 simulator unit PASS**, `/tmp/botai_rc04_stable_choice_units_20261023.log` (`TEST_EXIT:0`); targeted UI not run for this pure question builder change. Full signed UI regression remains OPEN.

### Full sequential simulator regression — 2026-10-23

**PASS:** signed iPhone 16e simulator `xcodebuild test -parallel-testing-enabled NO`, `/tmp/botai_rc04_full_final_20261023.log`, `TEST_EXIT:0`, `** TEST SUCCEEDED **`, **177/177 unit and 25/25 UI**. All UI tests ran sequentially without competing test sessions, including populated choice and mixed-scope launch, course/goal/recommendation cold relaunch, resume, import, shared-question dedup and visual smoke. This validates the current simulator baseline after commit `6a2a5d7`; it does **not** prove full RC-04 feature acceptance. Remaining: approved adaptive treatment of difficulty, multi-material course transport, complete teacher recommendation scenarios and real-device acceptance. User-owned Xcode project settings remain untouched.
