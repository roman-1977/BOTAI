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
