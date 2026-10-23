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
