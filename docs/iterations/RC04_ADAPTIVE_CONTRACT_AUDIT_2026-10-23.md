# RC-04 — audit of accepted adaptive-planning contract (2026-10-23)

> **CURRENT AUTHORITATIVE SNAPSHOT (2026-10-23; baseline commit `6bce16f`).** Branch `feature/v0.3.0-chemistry-pilot`. Complete sequential iPhone 16e simulator run: **177/177 unit and 25/25 UI PASS**, exit 0, `/tmp/botai_rc04_full_final_20261023.log`. Separately seeded chemistry UI: **2/2 PASS** at an earlier checkpoint, not included in the full run. RC-08 PASS for this baseline, but **overall NOT RC**. RC-04 P0 OPEN: `.botai` one-material coursePlan imports goals/sections/topics/guidance, SQLite persistence and Today recommendation sheet work; teacher priority breaks observed-urgency ties and suggested pace is compared without overriding profile minutes. Difficulty is informational only; multi-material course transport and full teacher-guided acceptance remain OPEN. RC-05 multi-size/accessibility/device OPEN; RC-06 local aggregate-sync and disposable SQL gates PASS, hosted/device checks deferred by owner; RC-07 partial; RC-09 distribution deferred. User-owned `ios/BOTAI.xcodeproj/project.pbxproj` must never be staged, overwritten or reverted. Older dated checkpoints below are historical, not the current status.

## Accepted rules (not proposals)

- `docs/iterations/SESSION_LAUNCH_DECISIONS_2026-10-22.md`: teacher gives priorities, targets, difficulty and pace as *guidance*; BOTAI chooses the strategy from guidance **and actual student progress**, never a rigid teacher override.
- `docs/CHATGPT_REPOSITORY_GUIDE.md`: automatic study priority is due/weak → new → not-yet-due; `all` preserves the eligible set and authored order. No review-only mode. Per-session format/strategy overrides are transient. Resuming a session does not replan it.
- `docs/COURSES_AND_GOALS.md`: auto-course advances after completion, teacher-assigned sequence awaits teacher; personal goals are learner-controlled. Goals define mastery/deadline/scope; the study-minute budget belongs to the profile, not to a goal.
- `docs/GOALS_PROGRESS.md`: BOTAI recalculates after missed days without debt/punishment; never silently increases a user's daily target; progress and due/weak/new are distinct metrics.

## Actual code inventory — updated 2026-10-23 after `1f352f0`

- `ios/BOTAI/Services/DailyPlanner.swift`: deadline/mastery urgency, explicit priority and ordinal difficulty tie-break, shared profile-minute allocation, question dedup and due/weak → new → not-due selection. Difficulty does not multiply minutes.
- `ios/BOTAI/Domain/Courses.swift`: goals persist optional `CourseLearningGuidance` (priority, rationale, difficulty 1...5, suggested daily minutes), mastery/deadline/scope. Separate teacher assignment ownership and authority are **not** persisted.
- `ios/BOTAI/Services/BOTAIPackageService.swift`: legacy-compatible one-material `.botai` archive can include sections/topics/goals/guidance. Import validates mapping, saves material and course, and compensates a failed course write by deleting the new material. **Not** a cross-store ACID transaction.
- `ios/BOTAI/Features/Today/GameHomeView.swift`: recommendation sheet displays guidance and learner pace comparison.
- `ios/BOTAITests/DailyPlanTests.swift`, `PackageRoundTripTests.swift`: ordinal priority/difficulty, overlap, actual ZIP → SQLite → daily plan, and import rollback/success coverage. Latest focused unit result **181/181 PASS**, `/tmp/botai_atomic_import_units_final.log`; focused importer UI **1/1 PASS**. Last fully completed UI regression **25/25 PASS** at older baseline; a new full run is in progress.

## Genuine remaining functional work

1. Define and persist *source* of a goal (auto-course/teacher/self-directed), teacher guidance and progression authority without overwriting existing local goals or assuming a server teacher role exists.
2. Define deterministic treatment of guidance priority, difficulty and pace together with observed weakness, overdue review, deadlines and available minutes. Existing due/new/not-due order must remain intact unless a new explicit product decision supersedes it.
3. Test multi-goal conflict, teacher-assigned vs personal goals, rest days, missed days, no due questions, equal priority, reused knowledge, migration/relaunch and offline planning.
4. Integrate only after the unresolved product policy is approved; do not invent numerical teacher weights or pretend teacher assignments already exist.

## Unresolved decisions — explicitly not approved

`docs/OPEN_QUESTIONS.md` still asks whether a separate teacher role exists and how time is distributed across multiple goals. Current deadline-deficit urgency is a **baseline heuristic**, not a formally approved teacher policy. A production scoring formula, teacher input storage/ownership and automatic progression for teacher assignments cannot be inferred from these documents. Do not change persistence schema or fabricate priority weights until these decisions are resolved.

## Release implication

RC-04 is **PARTIAL / teacher-guided portion BLOCKED ON PRODUCT DECISION**, not an untouched feature and not PASS. Existing due-first planning, goal mastery, deadline urgency and deterministic selection are real working functionality. The next implementation must start from an approved contract, not an assistant-created algorithm.

## Scope clarification from accepted MVP sources (2026-10-23)

- `docs/REQUIREMENTS.md` §§6–7 **requires in MVP** a BOTAI-recommended daily lesson and goal-aware date, material volume, progress, available time and required pace. These are **not** optional teacher features.
- `docs/ROADMAP.md` lists expanded **author and teacher tools after MVP**; it does **not** cancel the accepted `docs/COURSES_AND_GOALS.md` conceptual teacher/class goal source or `docs/decisions/023-library-courses-assignments.md` assignment ownership. Do not silently move teacher-assigned goals out of MVP.
- `docs/COURSES_AND_GOALS.md` explicitly says a future Assignment carries learner/class/teacher context; the current implemented local `LearningGoal` is not that assignment. A distinct teacher role is unresolved in `docs/OPEN_QUESTIONS.md`.
- Thus RC-04 has **two different remaining categories**: (A) verify/finish *required learner-side* daily planning and goal-pace behavior, which can proceed without teacher-role decisions; (B) full teacher-directed guidance and authority, which needs an approved contract and must remain visible as a separate gap, not be marked 'post-MVP' by inference.
- `docs/MVP_ACCEPTANCE.md` calls the adaptive daily plan an implemented vertical; this is evidence of a baseline, not evidence of complete teacher-guided acceptance.

**Next authorized work without policy invention:** targeted deterministic learner-side tests for multiple goals, dated vs undated urgency, rest days, shared-knowledge deduplication, due/new ordering and repeated planning; then address demonstrated defects. Teacher role, weighting and ownership require an explicit decision before adding schema or UX.

### Full sequential simulator regression — 2026-10-23 (current baseline)

**181/181 unit PASS; 25/25 UI PASS; zero failed UI cases; `xcodebuild` exit 0; `** TEST SUCCEEDED **`.** iPhone 16e simulator `33176212-1247-4722-B8F4-4E53438502E4`, `-parallel-testing-enabled NO`, complete serial suite, 730.46 seconds. Log `/tmp/botai_rc04_full_181_20261023.log`. This run includes latest learner-course import rollback, ordinal teacher difficulty, ZIP -> SQLite -> planner tests, importer UI, recommendations after relaunch, resume, and session strategies. This is the **new authoritative simulator regression baseline** superseding the 177+25 snapshot at `6bce16f` and all older intermediate test notes. **Not a release candidate yet**: RC-04 multi-material course packaging/teacher authority and complete adaptive acceptance, RC-05 device/accessibility, hosted acceptance and distribution gates remain open. User-owned pbxproj not touched.
