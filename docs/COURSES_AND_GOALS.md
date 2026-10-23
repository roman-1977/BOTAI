# BOTAI Courses and Goals — v1

## Product boundary
BOTAI has one learning engine and three sources of learning goals.

- **Auto-course** — an author designs a sequence for a typical learner. Completing one goal activates the next automatically.
- **Teacher/class** — a teacher assigns the next goal to a specific learner based on observed progress. BOTAI does not advance the teacher's sequence on its own.
- **Self-directed** — the learner creates, pauses, resumes, completes and replaces personal goals.

These sources may coexist. A learner can have an active auto-course goal, a teacher assignment and a paused personal goal at the same time.

## Goal is the executable unit
A Goal answers: what to learn, which material/question sets are in scope, the completion criterion, and who controls progression. Daily workload (minutes/questions today) is separate from the learning Goal.

Initial lifecycle: `waiting → active ↔ paused → completed`, with cancellation/archive added when persistence is implemented.

## Auto-course v1
An AutoCourse is an ordered sequence of goals. It targets a typical learner and is intentionally simple in v1: no branching graph. Each step has a mastery/completion criterion. On completion, the next step unlocks. Later versions may add diagnostic skipping or remediation branches without changing Goal identity.

## Class v1
Teacher goals use the same Goal execution model, but completion returns control to the teacher. A future Assignment adds learner/class, due date and teacher context around the Goal.

## Self-directed v1
The learner owns sequencing. Personal goals can be paused and resumed independently. Creating a new goal does not destroy paused goals or their learning state.

## Course package
`.botai` Course Package v2 will carry course metadata, reusable materials, ordered auto-course goals, completion criteria, and portable media. Teacher assignments and learner progress are user-specific state and do not belong in a distributable course package.

## Personal course authoring UX
The first authoring workflow is learner-owned: `MyCourse → Section → Topic → existing QuestionSets`, plus an independent ordered list of Goals. Course structure organizes knowledge; goals organize the learner's intended progression. Question sets remain reusable library objects and are referenced, not copied. Goal order is a plan for self-study and does not lock navigation. The first editor supports course creation, reorderable sections/topics, linking existing personal quizzes, and reorderable goals with a mastery threshold.

## Course content v1 (implemented)
Course authoring is now persisted locally and deliberately precedes Goals. The content hierarchy is fixed to `Course → Section → Topic → QuestionSet reference`. Course metadata includes title, description, subject/category, audience, author, language, cover symbol, and optional estimated duration. Sections have title, description, optional estimated duration, and topics. Topics remain lightweight and reference stable material/question-rule UUID pairs. The same model drives authoring and read-only preview so imported/library `.botai v2` courses can use the same presentation later.

## Learning goals v1

A learning goal describes a result, not a daily workload. It references question sets already present in the course, has a mastery target and an optional deadline. Goals are ordered/planned independently from course content.

Daily study time is a user-level study budget shared by all active goals. It must not be stored as a per-goal setting. A future planner will distribute that budget between goals and recalculate required pace when a day is missed or progress differs from forecast.

Current goal lifecycle: planned, active, paused, completed. Mastery measurement and the global study-budget planner are separate follow-up layers; the current UI intentionally does not fake progress values before the Learning Engine provides them.

## User study budget

Study time belongs to the user profile, not to an individual course or goal. `StudyProfile` stores a default daily budget and optional per-weekday overrides (including zero-minute rest days). The budget is shared by all active goals. A future daily planner will allocate this time according to deadlines, mastery, due repetitions and schedule deviation.

## Daily planning and real question execution

The home screen no longer presents demo forecasts. `DailyPlanner` derives today's work from the user's study budget, course learning goals, deadlines, current mastery and due repetition state. Material question rules are converted into stable, direction-specific `StudyQuestion` IDs using `(ruleID,rowID)`, so spaced-repetition/mastery state survives future sessions. Goals can be activated or paused in the course editor; the home action launches the questions selected by the real plan.

### RC-04 course section/topic import and simulator isolation (2026-10-23)

Extended optional `.botai` `coursePlan` with `sections[]` and `topics[]`, each topic referring to validated enabled question-set indexes within the bundled material. The importer maps them to persistent `CourseSection`/`CourseTopic` and newly assigned rule IDs. Missing `sections` decodes as empty for backward compatibility. Empty sections/topics and invalid/disabled indexes reject before saving. Multi-material packages remain unsupported; do not describe this as a complete multi-material course importer.

Simulator build PASS (`/tmp/botai_rc04_section_import_build_20261023.log`); **175/175 unit PASS** (`/tmp/botai_rc04_section_import_units_20261023.log`), including section/topic JSON roundtrip and invalid-index rejection. Full UI suite started earlier was not isolated: subsequent test invocations targeted the same simulator while it was running, so its failures cannot be confidently attributed to the app. After stopping the long suite, isolated rerun showed `testMixedCardAndChoiceFormatsAvailableForEveryScope` PASS (48.408s), but `testPopulatedChoiceOnlyTestsFormatAndAnswer` failed with XCTest `Lost connection to the application` / simulator helper, not an assertion. Need a clean, **nonconcurrent** simulator UI run; never mark full UI PASS yet. RC-04 OPEN: adaptive difficulty, full course multi-material transport, complete UI acceptance and real-device checks.

### RC-04 bundled import mapping consolidation — 2026-10-23

Extracted a single `BundledCourseImporter.course(plan:manifest:references:)` mapping contract from the SwiftUI file importer. It validates the package before indexing, verifies the generated rule-reference count, constructs section/topic and goal links from the same mapped UUIDs, and preserves imported teacher guidance. The UI now calls this mapper rather than duplicating mapping logic. Added repository-level regression covering the actual built `StudyCourse` saved and reloaded from SQLite, section/topic references, goal references, guidance, and invalid reference-count rejection. Existing material-only packages remain supported. No multi-material archive support yet.

Verification logs: `/tmp/botai_rc04_import_mapping_units_20261023.log` (unit tests), `/tmp/botai_rc04_choice_ui_clean_20261023.log` (sequential choice UI regression). **Do not mark either PASS until the corresponding final test summary is confirmed.** Earlier isolated UI `testMixedCardAndChoiceFormatsAvailableForEveryScope` passed, while `testPopulatedChoiceOnlyTestsFormatAndAnswer` suffered a simulator helper disconnect; these are separate outcomes. RC-04 OPEN: adaptive difficulty policy, multi-material import, complete sequential UI acceptance and physical device.

RC-04 import mapper verification (2026-10-23): 176/176 simulator unit PASS, `/tmp/botai_rc04_import_mapping_units_20261023.log`; isolated choice UI PASS, `/tmp/botai_rc04_choice_ui_clean_20261023.log`. Full UI regression and adaptive difficulty remain OPEN.

### Deterministic generated choice order — 2026-10-23

Fixed nonreproducible `StudyQuestionBuilder` distractor selection and answer ordering: SHA-256 ranking derived from stable rule ID, row ID and candidate text now gives the same answer list and correct indexes for a given material snapshot, including when a question is rebuilt after restart. This does **not** change the persisted snapshot for an in-progress session, or the automatic due/weak/new study priority. New regression covers repeated builds of six four-choice questions. **177/177 simulator unit PASS**, `/tmp/botai_rc04_stable_choice_units_20261023.log` (`TEST_EXIT:0`); targeted UI not run for this pure question builder change. Full signed UI regression remains OPEN.

### RC-04 ordinal difficulty adaptation — 2026-10-23

Teacher difficulty (1...5) now participates in actual goal scheduling **only after** observed mastery/deadline urgency and explicit teacher priority are equal. Higher difficulty wins that tie, and global question dedup assigns overlapping material to the selected goal once. No arbitrary numeric weights, no change to user-owned daily minutes, no invented extra questions, and no override of stronger actual urgency or critical priority. Missing/invalid difficulty is treated as unspecified. Added one ordinal boundary unit and one real SQLite/material/goal end-to-end planner integration test, including overlapping references and priority precedence. **179/179 unit PASS** on iPhone 16e simulator, `/tmp/botai_rc04_difficulty_units_20261023.log`, `TEST_EXIT:0`. Last complete UI baseline remains **25/25 PASS** at `6a2a5d7` before this code change; UI not rerun for this checkpoint. **RC-04 remains PARTIAL**: multi-material archive and full adaptive/teacher authority acceptance pending.

### RC-04 real archive to daily plan acceptance — 2026-10-23

Added `actualBotaiArchiveImportPersistsTeacherPlanAndSchedulesQuestions`: actual `.botai` ZIP -> manifest read/validation -> imported material and generated rule IDs -> section/topic/goal mapping -> persisted and reloaded course in SQLite -> learner DailyPlanner -> two concrete chemistry questions and pace shortfall (teacher 25 vs profile 15 minutes). The student budget remains capped at 15 minutes. **180/180 unit PASS**, `TEST_EXIT:0`, `/tmp/botai_archive_test.log`. Last complete sequential UI suite remains **25/25 PASS before this change**; no claim of a new full UI run. This test covers the existing single-material archive format; **multi-material course archive remains NOT IMPLEMENTED** and must not be implied by this checkpoint. RC-04 remains OPEN; teacher authority/advanced adaptation and full acceptance pending.

### RC-04 course import consistency checkpoint — 2026-10-23

Refactored UI `.botai` import into `LearnerPackageImport.run`: validate manifest and course mapping before writing; import material, then persist the learner course via new throwing `CourseStore.saveOrThrow`; if course persistence fails, remove only the just-imported material and its media, preserving unrelated library data. Rollback failures are surfaced explicitly rather than swallowed. Once a course write commits, a later UI refresh failure cannot be misreported as a failed write and cause dangling course references. Added real SQLite tests for failure rollback and successful linked import. **181/181 unit PASS**, `/tmp/botai_atomic_import_units_final.log`, exit 0. Focused import-browser UI **1/1 PASS**, `/tmp/botai_atomic_import_ui.log`, exit 0. Last full sequential UI suite **25/25 PASS before these code changes**; no new full-suite claim. This is a compensating rollback across two repository writes, **not an ACID cross-store transaction**; multi-material course packages and full teacher acceptance remain OPEN.
