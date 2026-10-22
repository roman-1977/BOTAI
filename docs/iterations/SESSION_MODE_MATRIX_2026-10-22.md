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

### Shared knowledge across topics — 2026-10-22

- Product invariant reaffirmed by owner: a questionnaire reused in several topics has **one shared mastery state** per `knowledgeID`; studying it in one topic counts as learned in every referencing topic. Topic-level coverage can include it in each topic, but subject/global unique coverage must not double-count it. Session attribution is a reporting dimension, not a separate mastery key.
- Added durable SQLite regression `SharedKnowledgeProgressTests.sharedQuestionInTwoTopicsKeepsOneMasteryAfterReopen`: answer in first topic, reopen store from second topic, verify same streak and one state, answer again, reopen first topic, verify two attempts and one shared state.
- **141/141 Swift Testing unit PASS in 45 suites**, exit 0, `/tmp/botai_shared_knowledge_all_units_20261022.log`. An initial incorrectly scoped `-only-testing:BOTAITests/SharedKnowledgeProgressTests` ran **0 tests** and is not treated as evidence; reran entire `BOTAITests` target and verified test name in log.
- Still pending: UI-level shared-question reuse across two actual topics, topic aggregate semantics, and full mode matrix.

### Shared knowledge unique coverage checkpoint — 2026-10-22

- Added `KnowledgeDeadlineForecastTests.sharedQuestionCountsInEachTopicButOnlyOnceForCombinedGoal`: a shared knowledge ID contributes to coverage of both topics, but combined subject goal uses the union (3 unique IDs, not 4), and mastery of the shared ID counts once globally.
- **142/142 Swift Testing unit PASS (45 suites)**, exit 0, `/tmp/botai_shared_goal_all_units_20261022.log`. Last general UI 23/23 and seeded chemistry UI 2/2 were separate prior runs; no claim of a new full UI regression.
- **Still open:** actual two-topic UI E2E and session attribution/aggregate correctness across mixed scope.

### Two real topics, one shared questionnaire — UI checkpoint 2026-10-22

- Added `LaunchSmokeTests.testSharedQuestionSetInTwoTopicsIsNotDuplicatedForSubject`: via actual UI creates a course/section and two topics, assigns the **same seeded question set** to each, checks both topic launch rows and whole-subject row enabled, asserts identical nonzero question counts for each topic and subject (union, not sum), then launches the second topic and sees a real question.
- **Focused UI 1/1 PASS**, `xcodebuild` exit 0, `/tmp/botai_shared_two_topics_ui_20261022.log`. Unit target last **142/142 PASS**; prior general UI **23/23 PASS**, seeded chemistry **2/2 PASS**.
- This UI case proves shared-set launch/counts, **not** completed-session summary/attribution or actual mastered-state visibility in both topic screens. Those remain open; do not overclaim.

### Completed shared-question session attribution — 2026-10-22

- Added `CompletedSessionTopicPersistenceTests.sharedQuestionSessionReportsSelectedTopicWithoutSplittingMastery`: two completed sessions with the **same question ID and knowledge ID**, explicitly launched in different topics, persist two separate topic breakdowns with the correct chosen topic, each one answer, no unattributed answers; reporting itself creates no extra mastery state.
- Initial compile failures were incorrect test-only property access (`session` vs `sessionID`, `topicID` vs `attribution.topicID`); corrected. **143/143 unit PASS in 45 suites**, exit 0, `/tmp/botai_shared_topic_summary_units_20261022.log`.
- This verifies repository persistence and reporting semantics; complete real UI answer→finish→summary for shared topics and backend RLS integration remain pending.

### Shared knowledge across card and choice formats — 2026-10-22

- New deterministic `sharedKnowledgeAcrossFormatsUsesOneMasteryState`: two different question IDs (card and single-choice) intentionally share one knowledge ID; both inherit the same due priority, each format selects only its own kind, and goal mastery counts the shared knowledge once. **146/146 unit PASS**, `/tmp/botai_shared_format_mastery_units_20261022.log`.
- Important distinction: distinct question formats for the same knowledge may coexist in a session, while their learning state is shared; deduplicating solely by knowledgeID would incorrectly discard one format. A combined UI fixture remains outstanding.

### Choice-only scope × format × strategy UI checkpoint — 2026-10-22

- Expanded real single-choice material UI test to cover the opposite **18 states** across topic/subject/all-subject × mixed/cards/tests × automatic/all: mixed/tests enabled; cards disabled. Then launches an actual choice question and checks correct-answer feedback. **Focused UI 1/1 PASS**, xcodebuild exit 0, `/tmp/botai_choice_scope_matrix_ui_20261022.log`.
- Combined with card-only matrix, **36 enabled/disabled states** have now been verified across two isolated populated fixtures. This is not yet a single mixed-format catalog or distinct multi-subject fixture.

### Populated scope × format × strategy UI checkpoint — 2026-10-22

- Expanded `testPopulatedCatalogStrategyAllAndAutomatic` to verify all **18 enabled/disabled row states**: three launch scopes (topic/subject/all), three formats (mixed/cards/tests), and two strategies (automatic/all) on real card-only material. Mixed/cards enabled; tests disabled for all scopes. Then starts a card successfully. **Focused UI 1/1 PASS**, xcodebuild exit 0, `/tmp/botai_scope_format_strategy_ui_20261022.log`; result bundle saved.
- This is an **availability matrix with card-only fixture**, not a completed mixed-format multi-subject full E2E; distinct subjects, actual choice format cross-product, offline and resume remain open.

### Three-scope shared-set UI checkpoint — 2026-10-22

- Same questionnaire in two real topics: topic A, topic B, whole subject, all-subject mixed quick start show equal nonzero question counts; no double counting. Then answer, finish, relaunch and enter other topic. **1/1 UI PASS** `/tmp/botai_scope_matrix_ui_20261022.log`.
- Still missing the exhaustive scope×format×strategy UI matrix across distinct subject content and due/no-due states. Unit matrix already 145/145 PASS.

### Mixed catalog acceptance (2026-10-22)

UI fixture -botai-seed-mixed-course-material includes card and choice sets. New UI test validates all 18 enabled states across scope, format and strategy and checks choice feedback. 1/1 PASS /tmp/botai_mixed_catalog_ui_20261022.log. Multi-subject and full mixed-session completion still open.
