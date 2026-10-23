# BOTAI v0.3.0 — Release Candidate readiness audit
> **ПРИОРИТЕТ БЛИЖАЙШЕГО РЕЛИЗА (2026-10-23):** дать двум независимым ученикам начать изучать химию на iPhone 15 Pro Max и 16 Pro Max. Приватный chemistry learner release — раньше полного публичного MVP; остальные принятые требования остаются в roadmap. Текущий chemistry seed удаляет локальные учебные данные и годится только для disposable тестов; недеструктивная доставка и маршрут с 70% ещё НЕ готовы. Проверка chemistry Python 5/5 PASS, preview 323 вопроса / 102 набора. Источник: `docs/iterations/RELEASE_TARGET_DECISION_2026-10-23.md`.

> **РЕШЕНИЕ ВЛАДЕЛЬЦА 2026-10-23 — ЦЕЛЬ РЕЛИЗА:** довести полный согласованный MVP до релиза; два независимых ученика на iPhone 15 Pro Max и iPhone 16 Pro Max, начать с химии; контент и охват ЕГЭ — ответственность преподавателя, работа приложения — наша. Полная регрессия 181/181 unit + 25/25 UI PASS на iPhone 16e, **NOT RC** до приёмки целевых устройств и закрытия RC-гейтов. Подробности: `docs/iterations/RELEASE_TARGET_DECISION_2026-10-23.md`. Подготовка TestFlight/App Store не означает разрешения на отправку. Старые исторические снимки ниже не отменяют это решение.


> **CURRENT AUTHORITATIVE SNAPSHOT (2026-10-23; baseline commit `6bce16f`).** Branch `feature/v0.3.0-chemistry-pilot`. Complete sequential iPhone 16e simulator run: **177/177 unit and 25/25 UI PASS**, exit 0, `/tmp/botai_rc04_full_final_20261023.log`. Separately seeded chemistry UI: **2/2 PASS** at an earlier checkpoint, not included in the full run. RC-08 PASS for this baseline, but **overall NOT RC**. RC-04 P0 OPEN: `.botai` one-material coursePlan imports goals/sections/topics/guidance, SQLite persistence and Today recommendation sheet work; teacher priority breaks observed-urgency ties and suggested pace is compared without overriding profile minutes. Difficulty is informational only; multi-material course transport and full teacher-guided acceptance remain OPEN. RC-05 multi-size/accessibility/device OPEN; RC-06 local aggregate-sync and disposable SQL gates PASS, hosted/device checks deferred by owner; RC-07 partial; RC-09 distribution deferred. User-owned `ios/BOTAI.xcodeproj/project.pbxproj` must never be staged, overwritten or reverted. Older dated checkpoints below are historical, not the current status.

Audit opened 2026-10-22; last verified implementation `6bce16f` on `feature/v0.3.0-chemistry-pilot`. Status: **NOT RC / reconciled 2026-10-23**. No release tag, archive, TestFlight upload or push.

## Evidence and boundaries

- Local-first learning, account-scoped GRDB, v15 resumable-session snapshot, atomic answer+cursor: implemented. Last full `LaunchSmokeTests` before atomic change: **14/14 PASS** (`/tmp/botai_resume_regression_20261022.log`). After atomic change: focused UI **2/2 PASS** (`/tmp/botai_resume_atomic_ui_20261022.log`), focused unit **2/2 PASS** (`/tmp/botai_resume_unit_20261022.log`). Full subsequent verification: **105/105 Swift Testing, 15/15 standard UI, 2/2 separately seeded chemistry UI PASS** (2026-10-22; `docs/iterations/USER_TESTING_READINESS_2026-10-22.md`).
- Live Supabase development checks dated 2026-10-21: 11/11 RLS checks and explicitly enabled `LiveSupabaseSyncTests` passed per `docs/STAGE6_SYNC_VERIFICATION.md`. Coverage limited to supported text publishing/attempts. Choice and media/LaTeX attempts currently stay local. Do not claim all modes cloud-synced.
- `docs/MVP_ACCEPTANCE.md` describes implemented verticals but is not a signed-off acceptance test report. Product decisions in `docs/UI_SPEC.md` and iteration logs take precedence over outdated status prose.
- No real iPhone/TestFlight/Apple review acceptance has been verified in this audit. User-owned `ios/BOTAI.xcodeproj/project.pbxproj` is modified independently and must not be staged or reverted.

## Mandatory RC gates (all must be PASS or explicitly scoped out by owner)

| ID | Gate / measurable acceptance | Current state | Next executable verification |
|---|---|---|---|
| RC-01 | Session launch, scope, format, strategy, reset and resume | **IMPLEMENTED / broad tested; final acceptance PARTIAL** | 36 card/choice availability states + 18 mixed catalog states, real launch, resume, shared scopes PASS. Distinct multi-subject and exhaustive end-to-end matrix not verified |
| RC-02 | Durable session resume and atomic answers | **IMPLEMENTED / tested; edge acceptance PARTIAL** | Answered/unanswered relaunch and persistence PASS; explicit discard/background/crash/account matrix not fully evidenced |
| RC-03 | Cards, pair, single/multiple choice, chemistry | **IMPLEMENTED / tested; final acceptance PARTIAL** | Choice feedback, multiple choice, mixed fixture, separately seeded chemistry 2/2 PASS; exhaustive end-to-end across formats not evidenced |
| RC-04 | Teacher-guided adaptive planning | **P0 OPEN — student recommendation pipeline required** | Goal mastery/deadline/budget and due/new/not-due baseline implemented; guidance imported and persisted with one-material coursePlan, shown in Today; priority tie-break and pace comparison implemented; difficulty ordinal tie-break implemented; deeper adaptation/multi-material/teacher authority OPEN |
| RC-05 | Home visual and accessibility on devices | **OPEN — unverified** | Multi-size no-scroll, Dynamic Type, VoiceOver, Reduce Motion and device sign-off pending |
| RC-06 | Offline account and aggregate-only sync | **LOCAL GATES PASS / owner accepted deferred external checks** | Signed Keychain, durable restart/retry/ACK, SQL RLS 3/3, account isolation, 177 units + 25 UI PASS at `6a2a5d7`. Hosted Supabase and real device/network not tested; never claim full external PASS |
| RC-07 | UGC authoring/publication/moderation/privacy | **PARTIAL — operational checks pending** | Verify actual author/edit/publish, report/block, moderator and deletion workflows; do not infer from schema |
| RC-08 | Standard + seeded chemistry regression | **PASS at last verified checkpoints** | `6a2a5d7`: 177/177 unit + 25/25 standard UI; seeded chemistry 2/2 from prior isolated run. Repeat final regression after subsequent functional changes |
| RC-09 | Signed distribution and App Store assets | **DEFERRED by owner / not verified** | No TestFlight/App Store upload authorized; simulator Release build previously PASS, not an IPA |
| RC-10 | Reproducible docs, migrations, handoff | **PARTIAL — reconciliation underway** | SQL runner and commits exist; keep live status synchronized, verify scoped clean release handoff |

## Prioritization

**P0 before internal RC:** RC-01, RC-02, RC-03, RC-04 (or explicit bounded MVP policy), RC-05, RC-06, RC-08. **P0 before external TestFlight/App Store:** RC-07, RC-09, RC-10. Some gates overlap; do not treat this table as independent day estimates.

**Post-MVP unless owner reopens:** AI exam/BOLDAI, richer social features, advanced multimedia beyond agreed MVP. Existing moderation/account/privacy obligations are **not** deferrable if their corresponding features are exposed.

## Risk register

1. **High:** server publication currently excludes choice and media/LaTeX attempt paths; offline and multi-device behavior may diverge.
2. **High:** teacher-guided adaptive strategy not fully implemented; product behavior must be specified before claiming learning quality acceptance.
3. **High:** public UGC/moderation/account deletion and Apple compliance require operational checks, not just schema presence.
4. **Resolved for tested paths:** two-question resume and unanswered-question resume both passed end-to-end UI tests.
5. **Medium:** home screen no-scroll visual gate and accessibility unverified across devices.

## Handoff / exact next action

1. Implement an isolated UI test that answers question 1 of 2+, terminates the app, relaunches, verifies question 2, completes and verifies exactly two persisted attempts.
2. Run serial full UI regression and existing BOTAITests on iPhone 16e simulator (`33176212-1247-4722-B8F4-4E53438502E4`) with `CODE_SIGNING_ALLOWED=NO`; separately run guarded chemistry fixture script `tools/chemistry_pilot/run_simulator_smoke.sh` on disposable simulator only.
3. Audit format/strategy selection and adaptive planning against accepted decisions; turn findings into concrete tests and fix plan.
4. Keep `docs/IMPLEMENTATION_STATUS.md` and active iteration log synchronized. Preserve user-owned `project.pbxproj`. Do not touch physical iPhone or production data without authorization.

### RC-06 product decision update (2026-10-22)

The accepted sync contract is now **completed-session aggregates only**; detailed question attempts and spaced repetition stay local. The previously proposed expansion of server choice-question publication is **cancelled**. RC-06 remains PARTIAL until durable completion-only summary sync, migration, RLS, retries, and tests are implemented. Authoritative plan: `docs/iterations/SESSION_SUMMARY_SYNC_DECISION_2026-10-22.md`.

## Owner decision — 2026-10-22: publication deferred

**App Store submission and TestFlight upload are deferred until separate owner approval.** Continue normal development and testing. This decision does not change existing permissions for GitHub, Supabase, or physical-device testing. This readiness checklist is informational and is not authorization for App Store or TestFlight distribution.

## Verification checkpoint — 2026-10-22, after `944a12b`

- Latest unit regression: **137/137 PASS** (`/tmp/botai_adaptive_verified_20261022.log`).
- Standard UI regression: **15/15 PASS** (`/tmp/botai_release_ui_20261022.log`), including resumed sessions, advanced launch reset, importer, and home baseline.
- Chemistry UI regression: **2/2 PASS** (`/tmp/botai_chemistry_rc_20261022.log`) with isolated seeded simulator database. The combined unseeded UI run failed the two chemistry tests because the fixture was absent; this is not evidence of a functional regression. Keep both suites isolated.
- DailyPlanner now uses a stable tie-breaker and the requested planning date, but this does **not** close RC-04 teacher-guided adaptivity.
- RC-08 automated suite is green for this commit; RC-01/02/03/04/05/06 still require the acceptance evidence described above. The release remains **NOT RC**. In particular, backend migrations `0025` and `0026` and their RLS fixtures have not been applied/executed in disposable Postgres; no live backend acceptance is claimed.
- Do not stage or revert the independently modified `ios/BOTAI.xcodeproj/project.pbxproj`.

## Verification checkpoint — 2026-10-22, after `d5c4479` and `a4a0a08`

- Complete post-change simulator run: **137/137 Swift Testing unit tests and 16/16 standard `LaunchSmokeTests` PASS**, `xcodebuild` exit **0**, `** TEST SUCCEEDED **` (`/tmp/botai_final_session_gate_20261022.log`). This includes both answered and unanswered session resume paths and BOTAI import.
- The adaptive launch strategy treats due review as a priority, not a separate review-only session; then new, then not-yet-due questions. Equal-priority questions retain source order. The previous resume ordering failure was fixed and passed both a focused rerun and the complete UI suite.
- `RC-08`: **PASS for the current standard unit/UI suite**. Chemistry's separate seeded 2/2 PASS remains evidence from the earlier checkpoint, **not** a fresh chemistry run for these commits.
- `RC-01` and `RC-02`: tested launch/reset/resume paths pass; **PARTIAL** pending the full scope/format/strategy matrix, exact persisted attempt counts and finish/discard checks. `RC-04` remains **OPEN** for teacher-guided adaptive policy.
- **NOT RC**: no full format x strategy x scope matrix, offline/reconnect acceptance, fresh backend migration/RLS fixture verification, multi-device visual/accessibility sign-off, or App Store/TestFlight acceptance. No release tag or distribution authorized.
- User-owned `ios/BOTAI.xcodeproj/project.pbxproj` remains untouched and unstaged.

## Verification checkpoint — shared selection, 2026-10-22

- Common selection helper now serves launch picker and daily planner; format and adaptive priority unit matrix added. Full iPhone 16e simulator regression: **139/139 unit + 16/16 standard UI PASS**, exit 0 (`/tmp/botai_selection_full_20261022.log`).
- RC-08 standard suite PASS for this code; seeded chemistry suite must be rerun separately before final RC. RC-01/03/04 still PARTIAL/OPEN for cross-product UI acceptance and teacher guidance. Release **NOT RC**.

## RC-06 latest verified checkpoint — 2026-10-23

Status remains **PARTIAL**, not PASS. Signed simulator unit suite and 25/25 UI PASS at `820f07b` (`/tmp/botai_rc06_storage_guard_unit_20261023.log`, `/tmp/botai_rc06_storage_guard_ui_20261023.log`). Subsequent `353f603` adds a disk-backed cold-restart/offline-failure/reconnect/idempotent ACK fake-transport regression, 11/11 focused suite PASS (`/tmp/botai_rc06_reconnect_focused_20261023.log`). The actual migrations 0025/0026 and SQL RLS fixtures have already passed in disposable PostgreSQL 17 with a minimal auth shim; this is **not** a hosted Supabase Auth/PostgREST verification. Required before RC-06 PASS: controlled hosted development backend with two-account RLS, immutable conflict/idempotency and parent/topic ACK; real offline cold-start and reconnect with revoked/expired session; physical-device acceptance. Do not mutate production or disable host network without owner authorization.

2026-10-23 RC-06 security replay: `tools/verify_rc06_disposable_postgres.sh` PASS for summary RLS, topic RLS and negative-permission fixtures, log `/tmp/botai_rc06_sql_replay_20261023.log`, isolated loopback PostgreSQL 17 stopped afterward. This is a reproducible SQL-shim gate, not hosted Supabase acceptance. Live two-account parent/topic ACK fixture now exists but is disabled until explicit disposable URL/key are provided. RC-06 PARTIAL.

### Full sequential simulator regression — 2026-10-23

**PASS:** signed iPhone 16e simulator `xcodebuild test -parallel-testing-enabled NO`, `/tmp/botai_rc04_full_final_20261023.log`, `TEST_EXIT:0`, `** TEST SUCCEEDED **`, **177/177 unit and 25/25 UI**. All UI tests ran sequentially without competing test sessions, including populated choice and mixed-scope launch, course/goal/recommendation cold relaunch, resume, import, shared-question dedup and visual smoke. This validates the current simulator baseline after commit `6a2a5d7`; it does **not** prove full RC-04 feature acceptance. Remaining: approved adaptive treatment of difficulty, multi-material course transport, complete teacher recommendation scenarios and real-device acceptance. User-owned Xcode project settings remain untouched.

### RC-04 ordinal difficulty adaptation — 2026-10-23

Teacher difficulty (1...5) now participates in actual goal scheduling **only after** observed mastery/deadline urgency and explicit teacher priority are equal. Higher difficulty wins that tie, and global question dedup assigns overlapping material to the selected goal once. No arbitrary numeric weights, no change to user-owned daily minutes, no invented extra questions, and no override of stronger actual urgency or critical priority. Missing/invalid difficulty is treated as unspecified. Added one ordinal boundary unit and one real SQLite/material/goal end-to-end planner integration test, including overlapping references and priority precedence. **179/179 unit PASS** on iPhone 16e simulator, `/tmp/botai_rc04_difficulty_units_20261023.log`, `TEST_EXIT:0`. Last complete UI baseline remains **25/25 PASS** at `6a2a5d7` before this code change; UI not rerun for this checkpoint. **RC-04 remains PARTIAL**: multi-material archive and full adaptive/teacher authority acceptance pending.

### RC-04 real archive to daily plan acceptance — 2026-10-23

Added `actualBotaiArchiveImportPersistsTeacherPlanAndSchedulesQuestions`: actual `.botai` ZIP -> manifest read/validation -> imported material and generated rule IDs -> section/topic/goal mapping -> persisted and reloaded course in SQLite -> learner DailyPlanner -> two concrete chemistry questions and pace shortfall (teacher 25 vs profile 15 minutes). The student budget remains capped at 15 minutes. **180/180 unit PASS**, `TEST_EXIT:0`, `/tmp/botai_archive_test.log`. Last complete sequential UI suite remains **25/25 PASS before this change**; no claim of a new full UI run. This test covers the existing single-material archive format; **multi-material course archive remains NOT IMPLEMENTED** and must not be implied by this checkpoint. RC-04 remains OPEN; teacher authority/advanced adaptation and full acceptance pending.

### RC-04 course import consistency checkpoint — 2026-10-23

Refactored UI `.botai` import into `LearnerPackageImport.run`: validate manifest and course mapping before writing; import material, then persist the learner course via new throwing `CourseStore.saveOrThrow`; if course persistence fails, remove only the just-imported material and its media, preserving unrelated library data. Rollback failures are surfaced explicitly rather than swallowed. Once a course write commits, a later UI refresh failure cannot be misreported as a failed write and cause dangling course references. Added real SQLite tests for failure rollback and successful linked import. **181/181 unit PASS**, `/tmp/botai_atomic_import_units_final.log`, exit 0. Focused import-browser UI **1/1 PASS**, `/tmp/botai_atomic_import_ui.log`, exit 0. Last full sequential UI suite **25/25 PASS before these code changes**; no new full-suite claim. This is a compensating rollback across two repository writes, **not an ACID cross-store transaction**; multi-material course packages and full teacher acceptance remain OPEN.

### Full sequential simulator regression — 2026-10-23 (current baseline)

**181/181 unit PASS; 25/25 UI PASS; zero failed UI cases; `xcodebuild` exit 0; `** TEST SUCCEEDED **`.** iPhone 16e simulator `33176212-1247-4722-B8F4-4E53438502E4`, `-parallel-testing-enabled NO`, complete serial suite, 730.46 seconds. Log `/tmp/botai_rc04_full_181_20261023.log`. This run includes latest learner-course import rollback, ordinal teacher difficulty, ZIP -> SQLite -> planner tests, importer UI, recommendations after relaunch, resume, and session strategies. This is the **new authoritative simulator regression baseline** superseding the 177+25 snapshot at `6bce16f` and all older intermediate test notes. **Not a release candidate yet**: RC-04 multi-material course packaging/teacher authority and complete adaptive acceptance, RC-05 device/accessibility, hosted acceptance and distribution gates remain open. User-owned pbxproj not touched.
