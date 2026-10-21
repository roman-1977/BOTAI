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

- Added UI regression `testCreateCourseAndCancelEditingKeepsOriginalTitle`: opens Courses from home, creates a course, edits title and cancels, verifies original title remains. Passed on iPhone 16 Pro Max simulator (`Test-BOTAI-2026.10.21_16-50-46-+0300.xcresult`). Added accessibility labels for Courses and Edit Course buttons.

- Added simulator UI regression `testCreateCourseSectionAndTopic`: create course, add section, open section, add topic, verify visible. **Passed** on iPhone 16 Pro Max simulator (`Test-BOTAI-2026.10.21_16-58-07-+0300.xcresult`).

- Added test-only seeded CSV question set and stable rule accessibility identifiers. Simulator UI regression `testCreateCourseSectionTopicAndGoal` verifies course → section → topic → select material rule → goal → select course content → activate goal. **Passed** (`Test-BOTAI-2026.10.21_17-02-18-+0300.xcresult`).

- Extended end-to-end goal test: activate → pause → resume → terminate app → relaunch without reset → reopen course and verify active goal persisted. **Passed** on iPhone 16 Pro Max (`Test-BOTAI-2026.10.21_17-07-12-+0300.xcresult`).

- Fixed session statistics for multiple/single-choice answers: `advanceAfterChoice` now increments `sessionAnswered`, `sessionCorrect` when appropriate and persists session immediately, matching reveal-mode recording.
- Extended UI E2E: after relaunch and reopening active goal, navigate home, start daily plan, reveal the seeded card, mark correct, verify end-of-questions result, and dismiss. **Passed** (`Test-BOTAI-2026.10.21_17-10-35-+0300.xcresult`).

- Full iPhone 16 Pro Max iOS 18.6 simulator suite completed **40/40 passed** (32 unit + 8 UI, zero skipped/failed), verified with `xcresulttool get test-results summary`: `Test-BOTAI-2026.10.21_17-13-41-+0300.xcresult`.

## Remaining
- Section cancel UI regression added: create course and section, edit title, Cancel, terminate/relaunch, verify original section name survives and unsaved edit does not. **Passed** (`Test-BOTAI-2026.10.21_17-18-17-+0300.xcresult`).
- Extended end-to-end UI regression to delete a seeded material referenced by an active course/goal, verify library removal and zero remaining goal question sets. **Passed** (`Test-BOTAI-2026.10.21_17-25-07-+0300.xcresult`).
- Add persisted-statistics assertions for multiple-choice and interrupted sessions (session counting fix is implemented; current E2E covers reveal answers).
- Re-run full suite after any further changes; stage remains open until these acceptance cases are covered.
