# RC-04 — accepted student-side recommendation contract (2026-10-23)

**Owner decision, superseding the previous 'teacher guidance after MVP' interpretation:** Student iOS MVP **must fully ingest, persist, process, use and visualize teacher recommendations**. The teacher interface is not required yet. Recommendation input is imported with a course or supplied directly during content population (the existing chemistry-pilot fixture is the first example).

## Mandatory acceptance chain

1. Import or direct local seeding carries recommendation metadata with stable course/goal/topic identifiers. Legacy course payloads without recommendations still open unchanged. Validate malformed and missing values without data loss.
2. Save guidance offline in account-isolated SQLite alongside the associated course; preserve it across cold relaunch, course updates and export/import where applicable. No production Supabase migration without separate review.
3. Plan deterministically from teacher priorities, target, difficulty and recommended pace **together with** observed mastery, weak/due knowledge, deadline, profile study budget and missed days. Teacher inputs guide but never rigidly override the learning engine. Preserve due-first/new/not-due behavior and stable ties; never silently increase the learner's budget.
4. Show the recommendation and its impact in student Today/goal UI: goal, teacher priority, target, planned workload, actual progress and ahead/behind pace. Distinguish teacher-supplied facts from BOTAI-calculated suggestions. Keep home one-screen/no-scroll per accepted UI.
5. Acceptance: legacy and new imports, seeded chemistry, malformed guidance, multi-goal conflict, missing/overdue deadlines, shared knowledge, rest days, offline relaunch, changed mastery, deterministic repeat, UI accessibility and regression.

## Current verified baseline and gap

`DailyPlanner` already computes goal mastery, deadline deficit, minute budget and due/new/not-due question ordering. Chemistry fixture contains `course.deadline`, `mastery_target`, `daily_minutes_initial`, `study_days_per_week`, but no explicit teacher priority/difficulty recommendation. The seed currently turns those into one active goal and study profile; that is **not full recommendation processing**. `LearningGoal` has no persisted teacher-guidance field; no teacher-priority/difficulty/pace scoring or explanation is rendered. Therefore RC-04 **must remain P0 OPEN** until this entire student-side chain is implemented and verified. Do not classify it as post-MVP.

## Architecture boundary

No teacher-facing authoring, class administration or remote recommendation distribution is required for this release. The input contract must remain transport-neutral: direct fixture now, course import later. Do not confuse teacher-supplied daily pace with user-owned profile minutes; avoid changing learner budget silently. Existing course authoring and imported course compatibility must remain intact.

## Next implementation batch

Add a backwards-compatible guidance payload to course/goal models and import/direct-seed path, implement deterministic priority/pace handling and explainable learner-facing display, then run focused persistence/planner/UI/seed tests and full milestone regression. Keep all related code, tests, status and docs in one coherent tested commit; do not introduce unapproved numeric weights without documenting and validating policy.

### In-progress implementation checkpoint — 2026-10-23

Added optional backward-compatible `LearningGoal.guidance` (priority/rationale), chemistry local fixture metadata, and a Codable compatibility regression. This is **partial groundwork only**, not the complete required pipeline: recommendation import for general course packages, difficulty/pace, deterministic adaptive effect and student UI are still missing. No arbitrary scoring weights were accepted. Simulator unit run initiated; do not mark tests PASS until log confirms.

### Student UI checkpoint — 2026-10-23

The Today goal card now displays persisted guidance priority and optional rationale from the associated `LearningGoal` (with VoiceOver label). This is an initial visible indication, **not** a complete recommendation visualization, priority-based planning or multi-goal pace explanation. `xcodebuild ... build GENERATE_INFOPLIST_FILE=YES CODE_SIGN_IDENTITY=-` succeeded on iPhone 16e simulator (`/tmp/botai_rc04_guidance_ui_build_20261023.log`). The preceding commit verified 160/160 unit tests; no new UI test was run for this display, so visual acceptance is still pending.

### Deterministic recommendation use checkpoint — 2026-10-23

`DailyPlanner.make` now uses imported teacher priority **only to break exact ties in observed deadline/mastery urgency**. Order: `critical > elevated > standard == missing`; no numeric weight was invented, and due/new/not-due ordering within a goal is unchanged. This is a deliberately bounded initial use, **not** full adaptive recommendation processing. Added rank/legacy-default unit test; signed iPhone 16e simulator 161/161 unit PASS (`/tmp/botai_rc04_guidance_order_units_20261023.log`, exit 0). Missing: teacher difficulty, recommended pace, general course import, multi-goal acceptance and UI tests.

### Rest-day correctness checkpoint — 2026-10-23

Fixed a verified planner inconsistency: zero-minute scheduled rest days previously created a **phantom mandatory minute** (`remaining=max(1,budget)`), even though the UI said zero minutes. Now allocated minutes remain zero; optional voluntary questions remain available. Added `plan.plannedMinutes == 0` regression assertion. Simulator signed unit tests 161/161 PASS, exit 0 (`/tmp/botai_rc04_restday_units_20261023.log`). Remaining: full recommendations import/difficulty/pace/UI acceptance and multi-goal starvation analysis.

### Multi-goal budget fairness checkpoint — 2026-10-23

Fixed `DailyPlanner` multi-goal starvation from the old `max(5, weighted)` greedy allocation: each eligible goal receives one minute when the profile budget permits, then remaining minutes are allocated proportionally to observed deadline/mastery urgency with deterministic largest-remainder rounding. If fewer minutes than goals, higher-urgency goals receive the limited minutes first; teacher priority breaks only equal-urgency ties. Budget is never exceeded. Zero-minute rest days retain voluntary questions with zero mandatory minutes. Added three deterministic allocation tests (fairness, low/zero budget, equal-urgency ties). Signed iPhone 16e simulator **164/164 unit PASS**, exit 0 (`/tmp/botai_rc04_multigoal_units_20261023.log`). General import, teacher difficulty/pace, end-to-end UI and device acceptance remain P0 open.

### Local persistence acceptance checkpoint — 2026-10-23

Added a real SQLite `CourseRepository` regression for a teacher-guided imported-source course: write → instantiate a fresh repository against the same database → reload → update course description → reload again. Verifies that priority and rationale remain intact, rather than only testing in-memory JSON. Signed simulator **165/165 unit PASS**, exit 0 (`/tmp/botai_rc04_guidance_persistence_units_20261023.log`). This does **not** verify a full app-process cold relaunch or a general `.botai` course import: both remain open.

### Teacher difficulty and suggested pace metadata — 2026-10-23

Extended the optional `CourseLearningGuidance` payload with `difficulty` (1–5) and `recommendedDailyMinutes` (1–240), backward-compatible Codable decoding, and defensive normalization of out-of-range imported values to nil. The student Today goal card displays these as **teacher suggestions**, not BOTAI's assigned daily budget. They are persisted in the same course JSON as priority/rationale. The learner's profile budget is deliberately unchanged. Added valid/legacy/malformed range tests; signed iPhone 16e simulator **167/167 unit PASS**, exit 0 (`/tmp/botai_rc04_difficulty_pace_units_20261023.log`). The planner does not yet adapt question selection to difficulty or pace, and general `.botai` course import still needs an agreed transport contract. No new UI test was run.

### Suggested pace comparison and chemistry direct seed — 2026-10-23

The direct chemistry SQLite seed now supplies `difficulty=4` and `recommendedDailyMinutes=25` alongside teacher priority and rationale. Student Today compares each goal's **actual allocated minutes** against teacher-suggested pace and labels the difference as a BOTAI plan comparison, not an automatic budget change. This respects multi-goal allocations and zero-minute rest days. The pure `DailyPlanner.assessPace` function has below/equal/above/absent/rest-day regression assertions; simulator **168/168 unit PASS** (`/tmp/botai_rc04_pace_assessment_units_20261023.log`), Python seed syntax PASS. Still missing: real adaptive difficulty use, course-level import, full UI tests, cross-goal question dedup and process restart.

### Cross-goal question deduplication — 2026-10-23

Repeated StudyQuestion IDs are scheduled once across active goals. Later goals fill from next eligible unique question; goals with no remaining unique questions are omitted. Allocated minutes for such empty goals are not yet redistributed (open). Mastery still deduplicates knowledge IDs separately. Simulator 169/169 unit PASS (`/tmp/botai_rc04_dedup_units_20261023.log`). Full import/adaptive difficulty/UI acceptance open.

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

### Import mapper verification completed — 2026-10-23

`BundledCourseImporter` extracted from UI; persisted section/topic/goal links and teacher guidance tested in SQLite. Simulator **176/176 unit PASS**, `TEST_EXIT:0`, `/tmp/botai_rc04_import_mapping_units_20261023.log`. Sequential isolated UI test `testPopulatedChoiceOnlyTestsFormatAndAnswer` PASS, `/tmp/botai_rc04_choice_ui_clean_20261023.log`; separate mixed-format UI PASS in `/tmp/botai_rc04_isolated_ui_20261023.log`. The complete UI suite remains unverified and had simulator transport failures. RC-04 OPEN.

### RC-04 learner-facing recommendation access — 2026-10-23

Found that `GameHomeView.goalsCard` existed but was **never inserted into the rendered view hierarchy**. Teacher priority, difficulty, suggested daily minutes, pace comparison, rationale, mastery and target were therefore invisible despite previous UI implementation claims. Added a compact `Рекомендации и цели` action in Today when actionable goals exist, opening a scrollable accessible goal-details sheet. The standard-size home remains one-screen and without scrolling. Existing active-goal UI scenario now checks the recommendations button, sheet title, goal name and actual mastery after app relaunch. This verifies access to persisted student guidance UI, not a new difficulty-scoring policy.

Verification pending: full sequential simulator suite `/tmp/botai_rc04_full_sequential_20261023.log` was launched **before** these UI edits and cannot verify them; run the focused changed UI scenario and unit suite after the full run exits. Do not report a green UI run before the final summary. Teacher difficulty still informational; an unapproved numeric weight must not be invented. RC-04 OPEN.

### RC-04 visible recommendations verification — 2026-10-23

Confirmed a product defect: `goalsCard` was defined but unreachable in the rendered Today hierarchy. Now a compact `Рекомендации и цели` button opens a scrollable sheet showing the real per-goal mastery/target, minutes, deadline and available teacher guidance without introducing scrolling on standard-size Today. The persisted-goal cold-relaunch UI test now opens the sheet and asserts the goal and `Освоено 0%`. **Focused simulator UI PASS** (`testCreateCourseSectionTopicAndGoal`, 75.867 s, `/tmp/botai_rc04_recommendations_ui_20261023.log`); **176/176 unit PASS** (`/tmp/botai_rc04_visible_guidance_units_20261023.log`). A full UI suite started before this fix was intentionally stopped so the updated UI could be verified; it is NOT a completed full UI regression. Full sequential regression remains required at RC closure. No change to teacher difficulty scoring or profile minute budget.

### Deterministic generated choice order — 2026-10-23

Fixed nonreproducible `StudyQuestionBuilder` distractor selection and answer ordering: SHA-256 ranking derived from stable rule ID, row ID and candidate text now gives the same answer list and correct indexes for a given material snapshot, including when a question is rebuilt after restart. This does **not** change the persisted snapshot for an in-progress session, or the automatic due/weak/new study priority. New regression covers repeated builds of six four-choice questions. **177/177 simulator unit PASS**, `/tmp/botai_rc04_stable_choice_units_20261023.log` (`TEST_EXIT:0`); targeted UI not run for this pure question builder change. Full signed UI regression remains OPEN.

### Full sequential simulator regression — 2026-10-23

**PASS:** signed iPhone 16e simulator `xcodebuild test -parallel-testing-enabled NO`, `/tmp/botai_rc04_full_final_20261023.log`, `TEST_EXIT:0`, `** TEST SUCCEEDED **`, **177/177 unit and 25/25 UI**. All UI tests ran sequentially without competing test sessions, including populated choice and mixed-scope launch, course/goal/recommendation cold relaunch, resume, import, shared-question dedup and visual smoke. This validates the current simulator baseline after commit `6a2a5d7`; it does **not** prove full RC-04 feature acceptance. Remaining: approved adaptive treatment of difficulty, multi-material course transport, complete teacher recommendation scenarios and real-device acceptance. User-owned Xcode project settings remain untouched.

### RC-04 ordinal difficulty adaptation — 2026-10-23

Teacher difficulty (1...5) now participates in actual goal scheduling **only after** observed mastery/deadline urgency and explicit teacher priority are equal. Higher difficulty wins that tie, and global question dedup assigns overlapping material to the selected goal once. No arbitrary numeric weights, no change to user-owned daily minutes, no invented extra questions, and no override of stronger actual urgency or critical priority. Missing/invalid difficulty is treated as unspecified. Added one ordinal boundary unit and one real SQLite/material/goal end-to-end planner integration test, including overlapping references and priority precedence. **179/179 unit PASS** on iPhone 16e simulator, `/tmp/botai_rc04_difficulty_units_20261023.log`, `TEST_EXIT:0`. Last complete UI baseline remains **25/25 PASS** at `6a2a5d7` before this code change; UI not rerun for this checkpoint. **RC-04 remains PARTIAL**: multi-material archive and full adaptive/teacher authority acceptance pending.
