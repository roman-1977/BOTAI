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
