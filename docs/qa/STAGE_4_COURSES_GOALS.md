# Stage 4 — Courses, goals, study flow

Status: IN PROGRESS (2026-10-21).

## Initial inventory
- Course model: `StudyCourse` with sections, topics, question-set references and goals.
- Goals: `LearningGoal` with target mastery, deadline and planned/active/paused/completed states.
- `CourseRepository` persists course data via GRDB; `CourseStore` exposes creation, update, deletion and removal of references to deleted materials.

## Verified
- Added `CoursePersistenceTests.swift` for repository round-trip of nested sections, topics and goal properties; verifies goal state changes persist.
- Added backward-compatibility test for decoding legacy courses without a `goals` key.
- iPhone 16 Pro Max simulator: **31/31 unit tests passed**, result `Test-BOTAI-2026.10.21_16-38-09-+0300.xcresult`.

- Fixed cancel behavior in course and section edit sheets: fields now edit isolated `@State` drafts and only update bound models on explicit Save. Cancel discards drafts. Simulator build and **32/32 unit tests passed** (`Test-BOTAI-2026.10.21_16-46-37-+0300.xcresult`). UI-level cancel regression still to be added.

## Remaining
- Validate creation/editing of courses and goals via UI.
- Validate course-to-material references and deletion behavior.
- Verify learning session selection, daily goals, completion and resume paths.
- Run full unit + UI suite after implementation and fixes.
