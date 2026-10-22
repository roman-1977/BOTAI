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

### 2026-10-22 — First per-goal knowledge deadline forecast in exported PDF

**Implementation:** PDF report now enumerates active goals and resolves unique canonical `knowledgeID`s from their material/rule references (avoids counting multiple assessment modes twice). `KnowledgeDeadlineForecast.evaluate` calculates target count as `ceil(unique knowledge × masteryTarget%)`, current known count, remaining knowledge, observed knowledge-mastery growth from v13 event history, an approximate completion date, and days ahead/behind the goal deadline. Behind-schedule recommendations include the required knowledge/day rate and growth multiplier, and advise gradually increasing frequency or session duration while retaining repetitions. Completed goals and insufficient/flat history are treated separately; no fabricated ETA when no meaningful growth is observed. Forecast is explicitly labeled approximate. Report export is main-actor isolated to access the material store safely.

**Tests:** Added `KnowledgeDeadlineForecastTests` in registered `DailyPlanTests.swift`: no ETA with insufficient history, ahead-of-deadline ETA with positive mastery growth, behind-deadline recommendation, and no ETA for flat mastery. Simulator run: **4/4 passed** (`/tmp/botai_deadline_forecast_tests.log`). Existing PDF recommendation tests also rerun after export actor isolation: **2/2 passed** (`/tmp/botai_deadline_forecast_build3.log`). Initial build failed on actor isolation; fixed by `@MainActor` export and tests before final passing run. Full regression suite, PDF visual QA, and app end-to-end UI flow remain unverified.

**Forecast limits:** current first version uses first and last recorded mastery event dates; it is a linear estimate and sensitive to sparse data, changing goals and knowledge regressions. Current known count includes legacy state, but historical mastery events only exist since v13. Deadline forecasts should be enhanced with rolling-window smoothing, minimum observation count, confidence bands, and plan-history snapshots before claiming robust prediction. For zero/negative observed progress it refuses to fabricate a date.

### 2026-10-22 — Rolling knowledge forecast and regression checks

**Implementation:** knowledge deadline ETA now uses a rolling 28-calendar-day history window, requires activity on at least three separate calendar days, replays the latest knowledge state at the window boundary, and measures net gains (so mastery regressions reduce or eliminate the forecast). Old bursts outside the window no longer produce optimistic ETAs. With sparse recent observations or zero/negative net growth, the report withholds an ETA and offers a conservative recommendation.

**Tests:** Extended `KnowledgeDeadlineForecastTests` with regression cases for old activity outside the window and lost mastery. Existing fixtures were updated to include three observation days. Targeted iPhone simulator run: **6/6 passed**, `TEST SUCCEEDED`, `/tmp/botai_forecast_rolling_final.log`. First targeted run exposed 3 outdated test expectations because the new minimum-observation rule is stricter; fixtures corrected and final run passed. A full `xcodebuild test` run was started, but the log reported an Xcode device-service error (`device is passcode protected` / `notification_proxy`), so full-suite result must not be considered verified until a clean retry.

**Remaining:** historical schedule snapshots, minimum sample count/uncertainty bounds, knowledge regression visualizations, PDF visual QA and full-suite simulator regression. Forecast remains approximate.

### 2026-10-22 — v14 report history
Implementation: v14 studyPlanHistory saves profile revisions atomically; goalForecastSnapshots upserts one forecast per goal and local day on PDF export, with algorithm version, mastery and ETA. PDF reports textual first-to-last trend and uses historic plans when present.
Tests: ReportingSnapshotPersistenceTests 2/2 passed; PDF recommendation tests 2/2 passed; chemistry Python tests 5/5 passed. Full suite not run.
Limitations: snapshot trigger is PDF export, not automatic daily capture; no chart yet; pre-v14 historical plans are unknown.

### 2026-10-22 — UI regression and post-session forecast capture
Implementation: forecast snapshots now update after dismissal of a learning session as well as on PDF export, upserted by goal/day. Added UI test that opens the PDF share sheet and retains a screenshot attachment.
Tests: 4/4 targeted UI tests passed on iPhone 16 Pro Max iOS 18.6 (PDF share, fresh home, primary-screen screenshots, storage isolation across relaunch). Log /tmp/botai_ui_regression_oct22.log. PDF share test also passed separately after auto-capture change. Full UI and Swift suites not yet rerun.
Remaining: capture when study completes outside the home session dismissal, proper PDF chart and automated visual inspection.

### 2026-10-22 — PDF forecast chart and full UI suite attempt
Implementation: report now adds a vector chart page for goals with two or more forecast snapshots; plotted line shows known knowledge over recorded dates, with textual labels and PDFKit page merging. Removed outdated blanket claim that goal forecasting was not yet implemented.
Tests: ForecastChartPDFTests 2/2 passed on iPhone 16e iOS 18.6, covering presence of readable chart page and absence with no history. Existing PDF tests passed 2/2. Full UI suite started on iPhone 16 Pro Max with parallel testing disabled. One existing test testCreateCourseAndCancelEditingKeepsOriginalTitle failed waiting for the Edit Course button; further UI cases continued. Xcode also emitted a passcode-protected physical device service warning; this alone does not explain the failed assertion. Full UI suite outcome pending.

### 2026-10-22 — Full UI regression retry passed
Initial full UI suite: 10/11 passed, one navigation timing failure in testCreateCourseAndCancelEditingKeepsOriginalTitle. The failing test passed in isolation (18.614s). Reran the full UI suite serially, same simulator and no code changes: **11/11 passed, zero failures**, 192.095s, `TEST SUCCEEDED`; log `/tmp/botai_all_ui_oct22_retry.log`. The initial failure is likely intermittent UI timing, not confirmed as an application defect. No UI test code was changed; further repeated runs would be needed to characterize flakiness. Physical device notification_proxy passcode warning occurred during first run, but the rerun passed.

### 2026-10-22 — Deadline ETA trend chart and complete Swift suite
Implementation: each PDF history chart now includes a second line plot for predicted deadline deviation in days (positive = late, negative = early) when at least two snapshots have both ETA and a goal deadline. The zero line is drawn; missing ETA snapshots break the series rather than creating false interpolation. The first/latest deviation is labeled. Without enough valid ETAs the report explicitly says so.
Tests: full Swift `BOTAITests` suite passed **101/101** on iPhone 16 Pro Max before the new chart test was added (`/tmp/botai_all_unit_oct22.log`). The updated `ForecastChartPDFTests` passed **3/3** on iPhone 16e (`/tmp/botai_eta_chart_final.log`). An initial test failed because PDFKit text extraction maps some Cyrillic letters to lookalike Unicode characters; the chart itself was present and the assertion was corrected to match a stable substring. Full suite including this new test still needs a final rerun. UI suite was 11/11 on the previous iteration; not rerun after the chart edit.

### 2026-10-22 — Joint regression on 89d8192
Ran `xcodebuild test` (scheme BOTAI, iOS Simulator 2322A47B-83E7-42FE-A708-5F1CFA018DBC, serial execution, code signing disabled). Results: **102/102 Swift tests passed**, **11/11 UI tests passed**, `TEST SUCCEEDED`, 205.28s total. Full log `/tmp/botai_final_joint_oct22.log`. This confirms the combined suite on commit 89d8192. Visual manual inspection of the generated multi-goal PDF remains outstanding; PDFKit extraction tests do not prove absence of overlapping graphics.

### 2026-10-22 — Long-history PDF layout stress test
Added a dedicated PDFKit regression with eight goals and 60 forecast snapshots per goal (480 observations). It verifies multi-page pagination, that all eight goal labels survive text extraction, and that extracted line bounding rectangles remain within page media boxes. `ForecastChartPDFTests` passed 4/4 on iPhone 16e simulator, log `/tmp/botai_pdf_stress_oct22.log`. This checks text bounds but is not a human visual inspection of graph strokes or collision between adjacent graphs. Joint regression before this test was 102 Swift + 11 UI tests passed.

### 2026-10-22 — Visual PDF QA completed
Generated a real PDF fixture with 8 goals × 60 forecast snapshots (480 observations) using the actual `StudyPDFReport.export` implementation in simulator tests. Retrieved the fixture from the simulator container, rendered all 6 pages with PDFKit, and visually inspected the chart pages (3–6). Verified two goal chart groups per page, readable titles and dates, distinct blue mastery and orange deadline-offset lines, visible zero baselines, adequate whitespace, no clipping or label overlap in this stress fixture. The first two pages contain the narrative report; charts start on page 3. After QA, removed temporary fixture-writing code from the test; no production or test source changes remain. Re-ran `ForecastChartPDFTests`: **4/4 passed**, log `/tmp/botai_pdf_visual_final.log`. Reporting/PDF milestone accepted for the tested scenarios. Further enhancements (historical deadline edits, accessible chart descriptions) are future improvements, not blockers.

### 2026-10-22 — First real migrated-SQLite chemistry integration on simulator

- Took an SQLite `.backup` of the actual **iPhone 16e simulator** BOTAI v14-migrated `learning.sqlite` into `/tmp/botai-chemistry-integration/learning.sqlite` (not from a synthetic schema). Ran the developer-only chemistry seed against that disposable copy with explicit reset authorization. `PRAGMA integrity_check` returned `ok`; actual migrated schema accepted **323 knowledge rows, 102 materials, 204 rules, 5 course sections and 1 goal**.
- Loaded the seeded database into the simulator's **isolated BOTAI-UITests** store, not the ordinary simulator user database or a physical phone. Added `ChemistryPilotSmokeTests` to the existing UI test target. It launched the actual app, opened Courses, verified the chemistry course and five sections, opened Goals and verified the 90% chemistry goal. **UI test passed** (`/tmp/botai_chemistry_ui_integration.log`).
- Added `tools/chemistry_pilot/run_simulator_smoke.sh` to repeat this check against a specifically named disposable simulator with a pre-existing migrated UI-test DB; the script backs up that DB before replacing only UI-test learning records. It does not install or access a physical device.
- **Not yet verified:** answer correctness and session completion for both chemistry question modes, post-session history and forecast, app relaunch after a full chemistry session, bidirectional Supabase synchronization and cross-device recovery. Do not infer release readiness from this smoke test.

### 2026-10-22 — First chemistry question → persisted attempt → relaunch UI integration

Added `ChemistryPilotSmokeTests.testChemistryStudyAnswerPersistsAfterRelaunch` to the existing UI-test target. Against the previously seeded isolated simulator database, the test opens the actual home study action, enters the session, flips a chemistry recall card, explicitly requires and taps `ОТВЕТИЛ ЛЕГКО`, ends the session, terminates and relaunches the app, and verifies the home screen returns. Strict version passed on iPhone 16e simulator, `TEST SUCCEEDED`, `/tmp/botai_chemistry_session_ui_strict.log` (25 s). Before the strict rerun, an SQLite inspection after the first run found 1 persisted attempt, 1 session, 1 knowledgeProgressEvent and 1 course in the isolated UI-test database. This verifies a single recall attempt and a restart; it does **not** yet verify multiple-choice correctness, full-session exhaustion, progress values after restart or cross-device sync. No physical phone touched.

### 2026-10-22 — Two-answer audit exposed a persistence discrepancy (OPEN)

Extended chemistry UI test to submit **two** recall ratings and wait for accessibility markers `study-answered-1` and `study-answered-2`. The strict UI test passed (`/tmp/botai_chemistry_two_strict.log`). However, direct inspection of the current isolated simulator SQLite after the run reported `PRAGMA integrity_check = ok`, `attempts = 4` (previously 3) and the latest `studySessions.answered = 1`, despite the UI displaying two answers. **Do not consider the two-answer persistence test passed end-to-end.** Need determine whether the UI test ran against a different app data container, whether the second answer is lost, or whether UI counters are updated before failed persistence. Keep this discrepancy as a blocking investigation before claiming full session completion. No physical device accessed.

### 2026-10-22 — Two-answer discrepancy resolved: stale XCTest method execution

Investigation showed the previous xcodebuild log executed the **old single-answer method body** despite source changes: only one `Tap "ОТВЕТИЛ ЛЕГКО"` was present in the XCTest action trace, and the expected accessibility-marker checks were absent. The apparent mismatch between source and SQLite was a **test execution artifact**, not demonstrated application data loss. Renamed the test to a new unique selector `testChemistryTwoAnswersPersistAfterRelaunch` and reran with `-only-testing` matching that name. The fresh XCTest trace confirms **two separate rating taps** and successful waits for both `study-answered-1` and `study-answered-2`; the test passed (`/tmp/botai_chemistry_new_test_identity.log`). Inspection of the **current** simulator app data container after execution: attempt count **4 → 6**, latest study session **answered=2, correct=2**. Therefore two persisted answers and session counters agree. Future test edits must confirm the XCTest trace includes the new assertions, not merely rely on `TEST SUCCEEDED`. This remains a partial-session recall test, not full course completion or cloud sync.

### 2026-10-22 — Home-screen concept restored (first compact implementation)

Reviewed `docs/PRODUCT.md`: original UX requires mission→challenge→feedback→reward→development; motivational context is dynamic (yesterday, weekly average, personal record, mastery pace, deadline risk). The current `GameHomeView` retained streak, daily ring, goal progress and forecast snapshots but moved forecast visualization to PDF. Implemented a compact full-width **55pt plot** for the first active goal's historical known-count snapshots, with deadline drift label only when a forecast exists. Standard Dynamic Type dashboard now has no `ScrollView`; accessibility sizes retain scrolling. Kept daily plan, mastery/review/time, study button, courses and PDF access. Simulator build passed `/tmp/botai_compact_home_build.log`. **Not yet visually validated on all simulator sizes; screen fit is pending and must be checked before release.** The chart is a first iteration; future versions should display a time-normalized planned-vs-actual trajectory rather than a raw snapshot sequence, and offer a goal selector. Session-mode chooser and pause/resume remain pending.

### 2026-10-22 — Home palette alignment

`docs/UI_SPEC.md` specifies white/neutral surfaces, one primary blue action, green for success and restrained orange/red for semantic warnings, while Learn keeps its dark digital game surface. Applied home-only `HomePalette` with system grouped backgrounds and dynamic primary/secondary text; retained shared `HomeTheme` for Learn/Library/Courses to avoid unintended regressions. Removed multicolor home CTA gradient. Simulator build `BUILD SUCCEEDED` (`/tmp/botai_light_home_build.log`). Physical-device acceptance and visual screen-fit remain pending; no iPhone install.

### 2026-10-22 — Session launch decision correction and verification

**Source of truth:** `docs/UI_SPEC.md` (accepted): one primary `БОТАТЬ` action, or `ПРОДОЛЖИТЬ` for a resumable local session; Learn retains its dark game language. The earlier proposed launch flow further separates session scope (topic/subject/mixed), format (cards/test/mixed) and strategy (learn/review). Do not replace that with three competing home shortcuts.

**Implemented:** `GameHomeView.swift` now has a single primary `БОТАТЬ` button opening `SessionLaunchPicker`; topic, subject, mixed-all-subjects and due-review choices exist as first-stage options. Removed the temporary `Вперемешку`/`Повторить`/`Выбрать` home shortcuts. No schema migration.

**Verification:** branch `feature/v0.3.0-chemistry-pilot`, commit `d269aab`; `xcodebuild` on iPhone 16e iOS 18.6 Simulator, `CODE_SIGNING_ALLOWED=NO`, serial UI test `LaunchSmokeTests.testPrimaryStudyLaunchOpensSubjectPicker`: **1/1 passed**, log `/tmp/botai_agreed_launch_ui_retry.log`. Initial test failed because the primary composite SwiftUI button was not exposed under its visible text; added a stable `primary-study-launch` accessibility identifier and reran successfully. Prior `testQuickStartModesOpenSubjectPicker` passed before correction but tested the now-rejected design. Earlier light-home build passed (`/tmp/botai_light_home_build.log`), motivation build passed (`/tmp/botai_motivation_build.log`). **No full regression suite on current HEAD, no manual small/large-screen layout QA, no real-device install.**

**Not done:** format/strategy selection at launch; persist last configuration; interrupted-session restoration at the same question; genuine time-normalized goal plot; visual verification that all standard-size home content fits without scrolling. Existing test for the picker verifies opening and dismissal only, not a full subject/topic launch. Next executable step: implement format/strategy and persisted launch preferences with unit/UI coverage; then durable session resume and its relaunch test.

**Data safety:** user-owned `ios/BOTAI.xcodeproj/project.pbxproj` remains modified and unstaged; do not reset or commit. Physical iPhone untouched. No push performed.

### 2026-10-22 — Full regression exposed test drift (OPEN)

Ran complete `xcodebuild test` on iPhone 16e simulator (serial, code signing disabled), `/tmp/botai_post_launch_full_regression.log`: **TEST FAILED**, 14 UI tests, 7 XCTest assertion failures across 5 tests. Chemistry two-answer test still searched for removed `УЧИТЬСЯ СЕГОДНЯ` CTA. Updated its source to use stable `primary-study-launch` and the chemistry subject picker; this revised chemistry test is **not yet verified against a seeded isolated chemistry database**. The second chemistry test could not open its expected seeded course (fixture state must be re-established before attributing to app behavior). Other failures: create-course-section-topic-goal, extended PDF share, BOTAI file import. These require isolated reruns/triage; do not mark the regression green or dismiss failures as flaky. The primary launch picker test and several baseline tests passed in the failed full run. This regression was launched before the chemistry test-source update.

**Next:** rerun focused primary-launch test after source update; re-seed only disposable simulator UI-test database via documented guarded chemistry fixture script; rerun both chemistry tests; investigate remaining 3 UI failures individually; rerun full regression. Physical phone remains untouched.

### 2026-10-22 — Regression recovery completed (green)

Updated two outdated UI assertions after the accepted single-button study launch: PDF share now locates `Отчёт PDF`; course/topic/goal test opens `primary-study-launch`, chooses `Тема проверки` in `Что будем учить?`, and then checks the study card. Focused rerun of the course/topic/goal test passed (`/tmp/botai_course_ui_fixed_20261022.log`).

**Verified on disposable iPhone 16e simulator:** complete serial `LaunchSmokeTests` suite **12/12 passed, 0 failures**, `** TEST SUCCEEDED **`, `/tmp/botai_launch_clean_20261022.log` (200.764 s). This final run had no XCTest runner restarts. Chemistry tests ran separately with isolated SQLite fixture/backup using `tools/chemistry_pilot/run_simulator_smoke.sh`: **2/2 passed**, `/tmp/botai_chem_ui_20261022.log`. Chemistry Python tests: **5/5 passed**, `/tmp/botai_chem_python_20261022.log`.

An earlier attempted full run was invalidated by two concurrent xcodebuild processes targeting the same simulator, causing runner restarts; it was discarded and replaced with the clean serial run above. This confirms current UI smoke regression and seeded chemistry smoke tests, **not** full device release acceptance, small/large-screen visual fit, complete course exhaustion, cloud sync, or unfinished session configuration/resume work.

**Data safety:** `ios/BOTAI.xcodeproj/project.pbxproj` contains pre-existing user changes; deliberately excluded from this checkpoint. No physical iPhone touched. No push.
