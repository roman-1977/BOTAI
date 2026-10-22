# BOTAI implementation status

Snapshot: 2026-10-21. This describes the `refactor/v0.2.0` branch, not a released App Store build. The feature scope is frozen for v0.2.0: refactoring, reliability, UI consistency and regression testing only.

## Implemented

- SwiftUI iOS app built with XcodeGen (`ios/project.yml`), GRDB/SQLite local-first storage and migrations v1–v7.
- Material library: CSV/TSV import, BOTAI Package v1 import/export, generated cards and single/multiple-choice questions.
- Persistent attempts, learning states, study sessions, course/section/topic/goal hierarchy and study schedule.
- Local daily planner, learning session, course and material management, progress views.
- Account-scoped local database switching and an attempt-upload outbox through Supabase. This is **not** full bidirectional sync.
- Refactor branch: storage errors surfaced to users rather than silently accepted; failed answers do not advance the session; failed final session saves keep the session open; deletion and reference cleanup errors are reported.
- Shared dark palette across home, learning, courses, materials and profile; nonfunctional speed/mode and demo-material controls removed or clearly marked unavailable.

## Partial / not production-complete

- The learning algorithm is an MVP scheduling heuristic.
- Supabase attempt upload exists, but complete pull, reconciliation, sync cursors/tombstones, cross-device learning state and content sync are not complete.
- Course data is stored as a JSON aggregate; migration compatibility needs more old-database fixtures.
- Some demo fixtures and placeholder group/library content remain visible. They must not be mistaken for user data.
- The root navigation is a home view with modal sections, not the four-tab information architecture described in `UI_SPEC.md`.
- UI still contains tightly coupled views and hardcoded dimensions; Dynamic Type, VoiceOver, contrast and reduced-motion audits are outstanding.
- Public library/classroom acquisition, Course Package v2 and AI exam are outside the current release scope.

## v0.2.0 verification

- Full iPhone 16 Pro Max / iOS 18.6 simulator regressions on commits `786e520`, `0a5584e` and `8f4c9bd` each passed **87 tests, 0 failures**, including UI tests.
- The full regression on code commit `c4d07b0` passed **87 tests, 0 failures**, including UI tests. The full regression on `0e867a3` also passed **87 tests, 0 failures**, including UI tests; subsequent commit `5314bd1` changed documentation only.
- Full regression on `290fe1f` passed **88 tests, 0 failures** on iPhone 16 Pro Max / iOS 18.6, including the new `testPrimaryScreensVisualBaseline` UI test. The test captured home, courses, materials and profile screens; exported screenshots were manually reviewed and confirmed the formerly black navigation titles are now legible in white on dark backgrounds. Screenshots cover the default font size on this device, not every accessibility configuration.
- On iPhone 16e with Accessibility Medium text, `testPrimaryScreensVisualBaseline` passed (1 test, 0 failures) and exported four screenshots. Manual inspection confirmed the courses empty state and profile metrics reflow without text clipping; materials remain vertically scrollable and the horizontally scrolling filter row does not display all choices simultaneously. The profile lower sections also require vertical scrolling. These are accessibility usability follow-ups, not test failures.
- Full regression on code commit `d8152bd` passed **91 tests, 0 failures** on iPhone 16 Pro Max / iOS 18.6, including UI tests. Added failure-path coverage for corrupt SQLite files, missing storage parent directories and absent `.botai` imports. This is the latest full-suite result; the subsequent documentation-only commit does not change app code.
- Full regression after the Reduce Motion change on code commit `7cfd92f` passed **91 tests, 0 failures** on iPhone 16 Pro Max / iOS 18.6, including UI tests. This is the validated release-candidate code revision.
- Debug simulator builds and installs succeeded. The home screen was visually reviewed at standard and Accessibility Medium text sizes.
- A large-text layout issue was reproduced (truncated study button and crowded metric labels), fixed in `c4d07b0`, and the corrected screen was captured and reviewed at Accessibility Medium.
- The home screen was also inspected on the smaller iPhone 16e at default and Accessibility Medium sizes. A clipped daily-plan heading was found and fixed in `0e867a3`; the updated compact-device screenshot confirmed the complete heading and repositioned progress ring. At accessibility sizes, the goal selection control is below the fold but remains reachable by scrolling.
- VoiceOver descriptions were added for session progress rings, but a full screen-reader walkthrough has not been performed.
- UI review is **partial**, not final: other sections, compact devices, further accessibility sizes and contrast/reduced-motion settings remain to be examined.

## Release candidate scope and known limitations

`v0.2.0-rc1` is a tested refactor candidate, **not** an App Store release or production-complete backend. The full VoiceOver screen-reader walkthrough and manual physical-device validation have not been completed. Live network failure/recovery and end-to-end cross-device synchronization are not certified; a mocked backend retry test verifies that failed uploads preserve the local outbox. Demo/placeholder content remains visible, and the four-tab navigation specified in `UI_SPEC.md` is not implemented. These items require separate acceptance before public distribution.

## Remaining acceptance gates

1. Complete full regression on the final commit, including UI tests and launch/relaunch paths.
2. Review rendered UI on compact and large devices, large text, accessibility and navigation.
3. Exercise fresh install, failed storage, offline use, import/export, delete, account switch and sync recovery.
4. Document residual limitations, freeze and tag the validated candidate; keep `main` unchanged until sign-off.

See `docs/PRE_REFACTOR_AUDIT_2026-10-21.md` for the original audit and proposed architecture; its snapshot predates the branch changes above.

### v0.3.0 chemistry pilot (2026-10-22, in progress)

See `docs/iterations/V030_CHEMISTRY_PILOT.md` for authoritative milestones, verification and handoff. A deterministic 323-question developer fixture and guarded local SQLite seed exist (not yet installed into running app). `StudyQuestion.knowledgeID` now links both assessment modes at the presentation model level; persistence/mastery remain keyed by mode-specific IDs and need migration. Targeted simulator tests: 2/2 passed; fixture tests: 5/5 passed. No live account reset or production Supabase changes.

2026-10-22 checkpoint: v12 `knowledgeStates` migration and durable knowledge-level attempt recording implemented; adaptive planner/goal mastery read canonical knowledge progress. Targeted Swift simulator tests 2/2 passed, chemistry fixture tests 5/5 passed. Legacy mode-specific states remain for compatibility; dashboard and full simulator integration pending. Details: `docs/iterations/V030_CHEMISTRY_PILOT.md`.

2026-10-22: fixed rest-day study restriction (schedule is motivational plan, not access control), switched home knowledge metrics to canonical knowledge states, and added a locally generated 28-day plan-vs-actual PDF report with share sheet. Targeted iOS simulator tests: 4/4 passed. PDF visual QA, full regression, historical schedule snapshots and topic-level analytics pending. See iteration log.

2026-10-22: PDF now contains weekly pace lead/lag and concrete 15-minute-session recommendations; distinguishes time-plan projections from unavailable knowledge-readiness forecasts. Verified by 2 new PDFKit extraction tests (passed) plus 2 rest-day/PDF tests (passed). See `docs/REPORTING_AND_MOTIVATION.md`.

2026-10-22: v13 immutable canonical knowledge-progress event history now persists atomically and survives app restart. 2 new Swift tests + 2 existing PDF forecast tests passed; 5 chemistry Python tests passed. Per-goal deadline ETA calculation and historical schedule snapshots still pending. See iteration log.

2026-10-22: active-goal knowledge deadline projections now appear in the PDF: canonical unique knowledge denominator, observed mastery rate, approximate completion date, days ahead/behind deadline, required pace and study-frequency/duration recommendations. 4 new Swift forecast tests passed and 2 PDF regression tests passed. Forecast is explicitly preliminary; history starts at v13. See reporting spec and iteration log.

2026-10-22: deadline forecast tightened to rolling 28-day observed mastery, three distinct activity days and net regression-aware growth. Six targeted simulator tests passed. Full regression attempt encountered Xcode device-service/passcode error and remains unverified; see iteration log.

2026-10-22: v14 study-plan and forecast snapshots, PDF textual trend, historical plan lookup. Tests 2 snapshot + 2 PDF + 5 Python passed. Automatic daily capture and PDF graph pending.

2026-10-22: post-session forecast capture added, UI test verifies PDF share sheet. Four selected UI tests passed on iPhone 16 Pro Max simulator (fresh home, baseline screens, isolated relaunch, PDF share). Full suite pending.

2026-10-22: PDF forecast-history vector chart implemented and tested (2/2); full UI run revealed an existing Edit Course navigation assertion failure, triage pending.

2026-10-22: complete 11-test UI suite passed on serial retry, 0 failures (192s). Previously failing Edit Course test passed both in isolation and full retry. Potential intermittent timing issue, not reproduced; see iteration log.

2026-10-22: added second PDF history chart for predicted deadline deviation (+late/-early), with missing-ETA gaps. 101/101 full Swift tests passed before new chart test; updated chart tests 3/3 passed.

2026-10-22: Joint regression on commit 89d8192: Swift tests 102/102, UI tests 11/11, 0 failures, 205.28s; log `/tmp/botai_final_joint_oct22.log`. Manual multi-goal PDF visual inspection pending.

2026-10-22: added PDF stress regression: eight goals, 480 daily snapshots, page-bound checks. ForecastChartPDFTests 4/4 passed. Human visual review of PDF chart strokes still pending.

2026-10-22: PDF visual QA completed using a rendered 6-page, 8-goal/480-snapshot fixture. Pages 3–6 inspected: no clipping/overlap, chart lines and labels readable. PDF tests 4/4 passed after temporary QA code removal. Reporting milestone complete for tested scenarios.

2026-10-22: chemistry pilot seeded into a copy of a real v14 simulator SQLite schema (323 rows, 102 materials, 204 rules, 5 sections, 1 goal; integrity ok). Isolated simulator UI smoke test passed for course and goal visibility. Reproducible script added; end-to-end session and cloud sync remain open.
