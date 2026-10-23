# RC-04 — audit of accepted adaptive-planning contract (2026-10-23)

## Accepted rules (not proposals)

- `docs/iterations/SESSION_LAUNCH_DECISIONS_2026-10-22.md`: teacher gives priorities, targets, difficulty and pace as *guidance*; BOTAI chooses the strategy from guidance **and actual student progress**, never a rigid teacher override.
- `docs/CHATGPT_REPOSITORY_GUIDE.md`: automatic study priority is due/weak → new → not-yet-due; `all` preserves the eligible set and authored order. No review-only mode. Per-session format/strategy overrides are transient. Resuming a session does not replan it.
- `docs/COURSES_AND_GOALS.md`: auto-course advances after completion, teacher-assigned sequence awaits teacher; personal goals are learner-controlled. Goals define mastery/deadline/scope; the study-minute budget belongs to the profile, not to a goal.
- `docs/GOALS_PROGRESS.md`: BOTAI recalculates after missed days without debt/punishment; never silently increases a user's daily target; progress and due/weak/new are distinct metrics.

## Actual code inventory

- `ios/BOTAI/Services/DailyPlanner.swift`: active goals with question sets; mastery deduplicated by `knowledgeID`; goal urgency = `(target - mastery) / max(days,1)`; shared minutes allocated by relative urgency; questions ordered by due/new/not-due via `StudyQuestionSelection`. Deterministic planning date and stable source-order ties are implemented.
- `ios/BOTAI/Domain/Courses.swift`: `LearningGoal` stores title, question-set references, mastery target, optional deadline and lifecycle. No teacher-priority, difficulty, recommended pace, assignment owner or teacher progression fields.
- `ios/BOTAI/Domain/StudyProfile.swift`: weekday minute budget only. There is no persisted teacher guidance.
- Existing regression `ios/BOTAITests/DailyPlanTests.swift` covers rest days, stable selection and unique mastery; selection matrices cover formats and strategies. None establishes a complete teacher-guided algorithm.

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
