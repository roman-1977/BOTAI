# Session mode/settings acceptance matrix — 2026-10-22

All scenarios are mandatory for MVP; this is a verification plan, not evidence of passing tests.

## Dimensions
- Scope: all subjects mixed; one subject; one topic; user daily-goal quick start.
- Format: mixed (reveal/pair/single-choice/multiple-choice), cards only (reveal/pair), tests only (single/multiple choice).
- Strategy: automatic (due first, then new, then not-yet-due reinforcement), all (source order). Review is a priority within automatic strategy, not a separate launch mode.
- Data: populated, no eligible format, no due items, some due items, duplicate references across topics, offline, resumed session.

## Expected invariants
1. Fresh session picker defaults to mixed format and automatic strategy; reopening resets temporary overrides.
2. Changing format filters out ineligible kinds; zero eligible questions disables the launch row; no empty session is created.
3. Absence of due questions must never block starting a session with eligible new or reinforcement questions. No separate review-only quick start.
4. All includes all eligible questions in source order. Automatic prioritizes due (weakest first), then new, then not-yet-due; equal-priority questions retain source order. Full teacher-guided adaptive policy remains pending.
5. Topic scope must not leak questions from other topics; subject scope contains only that subject's topics; all-subject scope covers the catalog.
6. An existing session resumes with its original ordered questions, answers and format; no new picker setting changes an in-progress session.
7. Multiple-choice requires exact correct set; single-choice one correct answer; reveal/pair record answers once, including relaunch after answering.
8. A question reused across topics must not be falsely attributed to one topic in aggregate sync.
9. Repeat each essential scenario with airplane-mode/offline storage and after app relaunch.

## Coverage audit (as of start)
- Existing UI: fresh picker, advanced-settings reset, two-question resume, chemistry two-answer persistence, importer.
- Existing unit: card generation, local learning persistence, attribution and sync queue.
- Missing automated matrix: format x strategy x scope with due/no-due, all four answer UIs, disabled empty-state rows, resumed mixed-format session.
- Gate: RC-01/03/04/06 remain PARTIAL/OPEN until missing scenarios are implemented and executed.

## Implementation and regression checkpoint — 2026-10-22

- Shared pure `StudyQuestionSelection.select` now powers both the session launcher and daily planner, with consistent mixed/cards/tests filtering, automatic/all ordering, duplicate-ID elimination, due-weak → new → not-yet-due priorities, and stable ties. The former duplicate filtering paths were consolidated.
- New deterministic Swift Testing cases cover all three formats, empty input, repeated IDs, both strategies, due-weak/new/future priorities, stable ties, and no-due fallback.
- **139/139 unit PASS and 16/16 standard UI PASS**, complete simulator command exit 0 (`/tmp/botai_selection_full_20261022.log`, iPhone 16e simulator `33176212-1247-4722-B8F4-4E53438502E4`). Separately seeded chemistry UI was **not rerun** after this change.
- **Remaining matrix gaps:** explicit subject/topic/all × format × strategy UI scenarios, disabled zero-eligible rows, per-format persisted answers, and account/offline/reconnect coverage. These are not implicitly closed by the green suite.

### Empty-catalog UI checkpoint — 2026-10-22

- Added `LaunchSmokeTests.testEmptyCatalogLaunchCannotCreateSessionAcrossFormats`: an empty library disables the mixed quick-start row before and after opening advanced settings, and closing the picker does not create a resumable session. **Focused UI PASS** (`/tmp/botai_empty_catalog_ui_20261022.log`, exit 0).
- This is **not** exhaustive format-by-format empty-state coverage; it verifies the empty catalog and settings disclosure only. Subject/topic populated UI paths and format-specific disabled rows remain open.

### Explicit topic attribution checkpoint — 2026-10-22

- Fixed shared-question attribution: an explicit topic launch now records all selected question IDs against that chosen course/section/topic, even when another topic references the same question set. Subject/mixed launch retains ambiguity-safe `uniqueAttributions` behavior.
- Added deterministic `explicitTopicOverridesSharedQuestionAmbiguity` test, including duplicate input and empty selection. **140/140 unit PASS** (`/tmp/botai_scope_attribution_unit_20261022.log`, exit 0).
- **Verified:** full regression 140/140 unit + 17/17 UI PASS (`/tmp/botai_topic_attribution_full_20261022.log`, exit 0). **Pending:** UI test for choosing a populated topic that shares a question set.

### Populated catalog UI checkpoint — 2026-10-22

- New isolated UI test `testPopulatedTopicAndSubjectLaunchAreEnabled`: creates course/section/topic, attaches a real seeded question set, verifies topic/subject/mixed launch rows enabled and launches the topic into a real question. **PASS** (`/tmp/botai_populated_scope_ui_retry_20261022.log`).
- First test attempt failed because test navigation remained inside course editor; corrected test navigation, no product defect established.
- Still pending: format × strategy populated-catalog UI cross-product and shared-set topic-result attribution end-to-end.

### Populated format UI checkpoint — 2026-10-22

- `testPopulatedCardOnlyCatalogDisablesTestsFormat`: with card-only material, Tests disables topic launch; switching to Cards re-enables it and launches a card. **PASS** (`/tmp/botai_populated_format_ui_retry_20261022.log`).
- Initial run failed on exact accessibility lookup after Picker label changed; test corrected to retain a stable query. No product defect confirmed.
- Remaining: both strategy choices in populated UI; genuine multiple-choice material fixture; topic-attribution persistence end-to-end.

### Populated strategy UI checkpoint — 2026-10-22

- `testPopulatedCatalogStrategyAllAndAutomatic`: populated topic allows switching `All questions` → `System chooses`, remains launchable, opens actual question. **PASS** (`/tmp/botai_populated_strategy_ui_20261022.log`).
- UI verifies controls and launch, while ordering/priority differences are covered by `StudyQuestionSelectionMatrixTests` unit tests.
- Remaining: real multiple-choice UI fixture and shared-set topic-attribution end-to-end.

### Multiple-choice format UI checkpoint — 2026-10-22

- `testPopulatedChoiceOnlyTestsFormatAndAnswer`: isolated four-row chemistry fixture with generated single-choice questions (minimum four options), `Тесты` filter, topic launch, correct answer and feedback: **PASS** (`/tmp/botai_populated_choice_ui_retry4_20261022.log`).
- Generator intentionally drops choice questions with fewer than four available options; the fixture includes enough source rows for distractor completion. Test handles shuffled question order.
- Still pending: incorrect answer UI path, multiple-choice (multi-select) UI path, full regression after these fixture changes.

### Incorrect and multi-select UI checkpoints — 2026-10-22

- `testPopulatedChoiceIncorrectAnswerShowsFeedback`: wrong single-choice answer shows the correct-answer feedback — **PASS** (`/tmp/botai_wrong_choice_ui_20261022.log`).
- `testPopulatedMultipleChoiceRequiresSubmit`: two correct answers, submit disabled before selection, enabled after selecting both, then multi-select feedback — **PASS** (`/tmp/botai_multichoice_ui_20261022.log`).
- Both use isolated chemistry UI fixtures; generated choice questions require at least four options. Full suite regression subsequently PASSED.

### Full regression checkpoint — 2026-10-22

- Xcode simulator full regression: **140/140 unit tests in 45 suites PASS**, **23/23 general UI tests PASS**, **0 failures**, `xcodebuild` exit **0** (`/tmp/botai_full_regression_20261022.log`, `** TEST SUCCEEDED **`).
- Covers populated topic/subject/mixed launches, cards/tests formats, auto/all strategy controls, single-choice correct/incorrect feedback, multiple-choice submit/feedback, and resume across relaunch.
- This is not a release-candidate approval: separate seeded chemistry UI suite, shared-set attribution end-to-end, complete scope × format × strategy coverage, offline/reconnect, backend migration/RLS, visual/accessibility, and Apple compliance remain outstanding.

### Isolated chemistry regression — 2026-10-22

- Created a fresh disposable iPhone 16e iOS 18.6 simulator `62B01BED-4A72-43B9-A02D-351D9E82EE7A`, initial unseeded UI test run failed as expected (2 tests, missing chemistry fixture).
- Booted simulator, backed up only isolated UI-test SQLite to `.build/chemistry-pilot/ui-test-before-seed-20261022-214203.sqlite`, then ran `bash tools/chemistry_pilot/run_simulator_smoke.sh 62B01BED-4A72-43B9-A02D-351D9E82EE7A`. Seeded 323 knowledge rows, 102 materials, 5 sections and 1 goal.
- **Seeded chemistry: 2/2 UI PASS, zero failures, exit 0, `TEST SUCCEEDED`**, `/tmp/botai_chemistry_disposable_seeded_20261022.log`. Standard regression previously **140/140 unit + 23/23 UI PASS**. These are separate, correctly isolated runs.
- Next: remaining cross-product UI and shared-set attribution E2E; RC not approved.
