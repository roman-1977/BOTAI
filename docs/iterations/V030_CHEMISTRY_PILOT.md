# BOTAI v0.3.0 — Chemistry learning pilot

Status: IN PROGRESS. Branch: `feature/v0.3.0-chemistry-pilot`. Base: `refactor/v0.2.0` / `17ed830`.
Created: 2026-10-22. This is the resumable source of truth for the iteration.

## Accepted product scope

- One real pilot subject: chemistry, 323 knowledge questions / 5 sections / two assessment variants.
- Goal: at least 90% durable mastery by **2026-12-31** (291 of 323), with coverage and mastery measured separately.
- No teacher app, teacher accounts, or finalized import/export format in this iteration. Seed directly from developer-controlled local fixtures.
- Keep domain identifiers course/goal/section/topic/question/session/attempt stable and extensible to Russian, mathematics and biology.
- Build: adaptive new/due/weak question selection, session persistence, local basic statistics, offline-first synchronization, central PostgreSQL detailed reporting.
- Preserve source, Git history and migrations. Existing local demo courses, goals, quizzes, sessions, attempts and progress **may be reset** by explicit user authorization (2026-10-21); do not erase Supabase production or unrelated data.
- Do not overwrite pre-existing local user edit `ios/BOTAI.xcodeproj/project.pbxproj`.

## Starting workload (hypothesis, not a validated forecast)

From 2026-10-22 to 2026-12-31: 71 calendar days (~61 study days at six days/week).
Start with **25 min/day**, ~5–6 new knowledge questions per study day plus all due repetitions as capacity permits. Recalibrate after 3–5 actual sessions from measured seconds/question, answer success and repetition load. A 90% retention/mastery goal is not equivalent to 90% correct in a single quiz.

Milestones (coverage, not mastery): 2026-10-31 45; 2026-11-15 135; 2026-11-30 230; 2026-12-10 323. By 2026-12-20 run mixed delayed recall checks; by 2026-12-31 reach >=291 durably mastered. Milestones may be recalculated; preserve versions and reason for every revision.

## Execution stages and acceptance

1. **Fixture + audit**: validate two CSV files; create deterministic seed with one knowledge identity and two modes; verify all 323 pairs and source metadata.
2. **Local integration**: seed SQLite idempotently and reset only approved learning entities in a dedicated dev-only reset path. Verify course, sections, question sets and goals appear in app.
3. **Session engine**: persist each attempt with session and question identity; pause/resume, background, duplicate-answer protection, distinct recall vs multiple-choice evidence.
4. **Mastery and scheduler**: deterministic, testable time-injected spaced repetitions; coverage/mastery independent; due repetitions prioritized, no silent question starvation.
5. **Planning + UI**: calculate time budget, achievable forecast, intermediate milestones, basic statistics by section and mode; display forecast uncertainty.
6. **Sync**: append-only idempotent attempts/sessions, RLS isolation, offline queue and retry, recover on second device; never naive last-write-wins for learning state.
7. **Central reporting**: SQL summaries by course/section/topic/goal/day/session/mode, reconcile with client, test with two isolated accounts.
8. **Regression and release candidate**: run unit + UI tests and offline/online recovery. Document limitations; tag only after checks.

## Development history

- 2026-10-21: user approved chemistry-only pilot, direct local seeding, no teacher UI or final import formats, authorized reset of current test learning data.
- 2026-10-22: created branch `feature/v0.3.0-chemistry-pilot`; inspected existing `CourseStore`, `DailyPlanner`, local persistence and prior v0.2.0 baseline. Noted pre-existing modified `project.pbxproj`.
- 2026-10-22: implemented fixture builder `tools/chemistry_pilot/build_seed.py` and generated `chemistry_seed.json` from the two original CSVs in Downloads. Validated 323 matched IDs, all answer texts, four options and correct-choice correspondence. **Not yet integrated into running iOS SQLite.**
- Next: map fixture into existing Material/QuestionSet/Course repository schema and implement safe development reset + idempotent seed, then run tests.

## Continuation instructions

Read this file, `docs/COURSES_AND_GOALS.md`, `docs/OPEN_QUESTIONS.md`, `AGENTS.md`, and inspect `git status` before changes. Continue on this branch. Do not claim seed is installed in the app until verified. Update this log after each meaningful code/test milestone. Avoid resetting simulator user data without identifying the exact store and verifying scope.

- 2026-10-22: project owner mandated per-iteration documentation updates, progress/history, test extensions, reproducible verification and independent handoff. Adopted `docs/iterations/DEVELOPMENT_HANDOFF_STANDARD.md` as Definition of Done.

- 2026-10-22: added four reproducible Python unit tests for chemistry fixture pairing, valid four-option answer, mismatched answers, missing IDs and incorrect answer key. Verified `cd tools/chemistry_pilot && python3 -m unittest -v test_build_seed.py`: 4 tests passed, 0 failed. This verifies fixture generation only; iOS seed, SQLite reset, sync and end-to-end study remain unimplemented/unverified.

### 2026-10-22 — Local SQLite pilot seed, verification checkpoint

- Added `tools/chemistry_pilot/seed_local_sqlite.py`, a **developer-only**, explicitly destructive local SQLite fixture loader. It validates all 323 questions and populates 36 material sets, 323 knowledge rows, five course sections, one active 90% goal (2026-12-31), and a 25-minute/day study profile with Sunday off. IDs are deterministic. It refuses to mutate the database unless both `--apply` and `--reset-learning-data` are specified; requires an existing migrated SQLite database. **Do not run on live accounts without backup and exact account-store identification.**
- Implemented 1 SQLite integration test, verifying dry run and repeatable reset/seed. `cd tools/chemistry_pilot && python3 -m unittest discover -v`: **5 passed, 0 failed**. First test run exposed duplicate rows on repeat when FK cascades are absent; corrected by explicit dependent-table deletion and reran successfully.
- **Known limitation:** Existing `QuestionRule` represents one fixed correct-choice index per rule, but the source CSV uses row-specific correct-choice letters. The pilot loader preserves all choices in row values but activates **reveal/card mode only** until the domain and question builder support row-specific answer correctness. Do not claim both assessment modes are operational yet.
- Test ran on a disposable scratch SQLite schema, **not on the iOS simulator database**. Live iOS app, Swift model decoding, SQLite migration compatibility, session execution and full regression are **not yet verified**. Next: add per-row correct-choice support with Swift tests, then validate actual simulator DB and course screen.

### 2026-10-22 — Two-mode pilot fixture correction

- Updated the SQLite seed to group each knowledge set by its row's correct answer letter. This permits both reveal and single-choice rules with the existing Swift question rule model, without assigning incorrect answer keys. Result: **323 unique source knowledge rows, 102 material groups, 204 question rules, five course sections**. Both modes are available in course sections; the active goal references reveal rules only so mastery is not counted twice.
- Re-ran `cd tools/chemistry_pilot && python3 -m unittest discover -v`: **5 passed**. No live iOS simulator database modified.
- **Architecture debt / next priority**: a knowledge-level identity must unify both modes; current Swift question IDs are `(ruleID,rowID)`, so they are separate and goal progression currently uses reveal only. Implement a canonical knowledge ID + mode-specific attempts and test it before treating 90% mastery as validated.

### 2026-10-22 — Canonical knowledge identity in iOS question generation

- Added `StudyQuestion.knowledgeID` (defaults to `id` for backwards-compatible legacy/manual questions). Material-backed `StudyQuestionBuilder` sets `knowledgeID = KnowledgeRow.id`, so the reveal and single-choice presentations of the same row share a stable knowledge identity while retaining different mode-specific question IDs.
- Added two Swift Testing cases to the existing `ios/BOTAITests/CardGenerationTests.swift` project target: cross-mode canonical ID and backwards-compatible default. Xcode project has a pre-existing unrelated local modification; avoided editing it by placing tests in an already registered test source.
- Verified on iPhone 16 Pro Max iOS 18.6 simulator: `xcodebuild -project ios/BOTAI.xcodeproj -scheme BOTAI -destination 'platform=iOS Simulator,id=2322A47B-83E7-42FE-A708-5F1CFA018DBC' -only-testing:BOTAITests/KnowledgeIdentityTests test CODE_SIGNING_ALLOWED=NO` → **2 tests passed**, `TEST SUCCEEDED`; xcresult `Test-BOTAI-2026.10.22_12-32-23-+0300.xcresult`.
- Remaining: learning states and analytics are still keyed by mode-specific `questionID`, not `knowledgeID`. Do not report shared mastery/progress until storage and aggregation are migrated and tested. No active account SQLite data has been cleared or seeded.

### 2026-10-22 — Shared knowledge-level durable progress (checkpoint)

**Implementation:** added `v12_knowledge_progress` GRDB migration: `knowledgeStates` keyed by `knowledgeID` and nullable `attempts.knowledgeID`, backfilled for pre-existing records with `questionID` to preserve legacy learning history. New attempt writes atomically persist mode-specific `questionID`, canonical `knowledgeID`, shared knowledge state and outbox. `LearningStore` now loads and advances shared knowledge state; `DailyPlanner` and `GoalProgressService` use canonical knowledge state for mastery and due scheduling. Existing mode-specific `learningStates` are retained for compatibility; existing sync still publishes by questionID. Updated developer SQLite reset to include `knowledgeStates` and require migrated v12 schema.

**Tests:** added two Swift Testing tests to the existing `LearningRepositoryTests.swift` target: two modes increment the same durable knowledge state after restart while attempts/outbox remain distinct; legacy identity remains usable. Ran `xcodebuild -project ios/BOTAI.xcodeproj -scheme BOTAI -destination 'platform=iOS Simulator,id=2322A47B-83E7-42FE-A708-5F1CFA018DBC' -only-testing:BOTAITests/SharedKnowledgeProgressTests test CODE_SIGNING_ALLOWED=NO`: **2 passed**, `TEST SUCCEEDED`, xcresult `Test-BOTAI-2026.10.22_12-38-19-+0300.xcresult`. Ran `cd tools/chemistry_pilot && python3 -m unittest discover -v`: **5 passed**. Full iOS regression suite not run yet.

**Limitations/next:** existing global dashboard counts and some quiz-level statistics still use mode-specific states; unify display counts by knowledge identity and add regression tests. Validate a real simulator SQLite migration/seed and course UI before calling pilot integrated. No live account data changed.

### 2026-10-22 — Voluntary study on rest days, richer statistics and PDF report

**User decision:** The weekly schedule is a *plan*, not a permission system. A zero-minute/rest day must never block voluntary learning. Compare actual minutes with planned minutes in reports, reward extra practice, and encourage progress without shaming users for taking planned rest.

**Implementation:** `DailyPlanner` no longer drops active learning goals on zero-budget days; the home screen permits starting a voluntary session, displays rest-day context, and sets its target duration to zero (rather than inventing a planned requirement). The home dashboard's mastered/due/weak counts now use canonical `knowledgeStates`, preventing double counting across assessment modes. Added an on-device extended PDF report action to the home screen, with iOS share sheet. The PDF contains a 28-day plan-versus-actual daily log (including days with zero scheduled minutes), answers per day, aggregate planned/actual minutes, historical study time, attempts, canonical knowledge mastery, due items, active goals and supportive feedback. The report is generated locally; no upload.

**Tests:** Added two Swift tests in the existing `DailyPlanTests.swift` target: a zero-minute schedule still generates questions for active goals, and a rest-day report produces a nonempty valid PDF. Ran simulator tests for `RestDayAndPDFReportTests` and `SharedKnowledgeProgressTests` on iPhone 16 Pro Max iOS 18.6: **4 tests passed**, `TEST SUCCEEDED` (`/tmp/botai_v030_stats_final_tests.log`). Initial PDF compile error (double-escaped key path) and test compilation error (missing Foundation import) were fixed before final passing run. Full UI interaction, share sheet, visual PDF inspection and full regression suite remain unverified.

**Limitations / next:** 28-day PDF plan uses the *current* schedule for historical days; historical schedule revisions are not yet persisted, so historical plan adherence can change when the user edits the schedule. The report should ultimately include per-subject and per-topic trends, coverage, accuracy, durable mastery, due-overdue buckets, forecast to deadline and actual-vs-plan history snapshots. Build a versioned plan snapshot / daily aggregates before presenting historical adherence as authoritative. PDF output is a first functional version, not the final rich report design.

### 2026-10-22 — Report recommendation verification and reconnect

**Implementation:** completed the PDF section `ПРОГНОЗ И РЕКОМЕНДАЦИИ`: compare actual weekly minutes (14-day rolling sample) with planned weekly minutes; show weekly lead/lag, recommend a concrete number of 15-minute sessions or redistribute minutes when behind; avoid asking for extra workload when ahead. For active learning goals with deadlines, explicitly state that knowledge-completion forecast is unavailable until historical mastery snapshots exist; time-on-task is not presented as a prediction of durable mastery.

**Tests:** Desktop Commander initially rejected several calls; checked device listing (MacBookPro.lan online) and retried successfully. First rerun of `RestDayAndPDFReportTests`: **2 passed**. Added `ForecastRecommendationPDFTests` to `DailyPlanTests.swift`, verifying actual generated PDF text using PDFKit for both under-plan and ahead-of-plan scenarios. Simulator run `xcodebuild -project ios/BOTAI.xcodeproj -scheme BOTAI -destination 'platform=iOS Simulator,id=2322A47B-83E7-42FE-A708-5F1CFA018DBC' -only-testing:BOTAITests/ForecastRecommendationPDFTests test CODE_SIGNING_ALLOWED=NO`: **2 passed**, `TEST SUCCEEDED`, log `/tmp/botai_forecast_recommendation_tests.log`. Full suite not rerun.

**Remaining:** accurate knowledge-level deadline forecast requires time-series mastery snapshots; historical planned minutes still use the current profile. PDF visual layout and share-sheet UI remain unverified. Next add snapshots and forecast tests.

### 2026-10-22 — Persisted knowledge-level historical observations (forecast foundation)

**Implementation:** GRDB `v13_knowledge_history` creates `knowledgeProgressEvents` with one immutable event per recorded attempt: attemptID, canonical knowledgeID, occurredAt, intervalDays, streak, and durable-mastery flag. Events are inserted atomically with attempt, state, and sync outbox. `LearningRepository.knowledgeHistory()` exposes the chronological history, loaded into `LearningStore` and updated after successful saves. Existing historical attempts are intentionally *not* retroactively assigned fictional mastery snapshots; history starts when the migration is installed. The developer-only chemistry reset also deletes knowledgeProgressEvents, with corresponding scratch-DB fixture update.

**Tests:** New `KnowledgeProgressHistoryTests` in the existing Swift test target cover two assessment modes sharing canonical identity, durable history after reopening, distinct attempt IDs and outbox events, and no fabricated history on a fresh migrated DB. Initial test incorrectly assumed two `good` ratings always reach `known` and failed; assertion was corrected to verify the persisted event against the actual mastery rule. Final simulator run: **4 Swift tests passed** (`KnowledgeProgressHistoryTests` 2, `ForecastRecommendationPDFTests` 2), `TEST SUCCEEDED`, `/tmp/botai_history_final.log`. Chemistry Python tests: **5 passed**.

**Remaining:** Build per-goal, time-series forecast on top of these events with unique knowledge denominators and actual deadline target. Handle insufficient samples, knowledge regressions, course edits, and historical plan revisions; do not claim a readiness ETA until those calculations are validated. Full iOS suite and PDF visual QA not run.
