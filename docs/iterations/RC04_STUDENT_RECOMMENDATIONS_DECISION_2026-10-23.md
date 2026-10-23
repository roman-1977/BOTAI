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
