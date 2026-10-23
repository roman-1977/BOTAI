> **2026-10-22 choice UI:** incorrect single-choice and two-correct-answer multi-select UI scenarios PASS; full regression pending.

> **2026-10-22 choice-format UI:** populated single-choice chemistry fixture, `Тесты` launch, correct selection and feedback PASS; wrong/multi-select paths pending.

> **2026-10-22 strategy UI:** populated topic All→Automatic switching and launch PASS; actual prioritization unit-tested; multiple-choice UI pending.

> **2026-10-22 format UI:** populated card-only catalog Tests→Cards filtering PASS; strategy UI and choice fixture pending.

> **2026-10-22 populated UI:** topic/subject/mixed launch enablement and topic question display PASS in new isolated UI test; cross-product pending.

> **2026-10-22 scope fix:** explicit topic attribution for shared question sets implemented; 140/140 unit PASS (`/tmp/botai_scope_attribution_unit_20261022.log`). Full regression 140/140 unit + 17/17 UI PASS (`/tmp/botai_topic_attribution_full_20261022.log`); **NOT RC**.

> **2026-10-22 additional focused UI:** empty-library launch disabled/no accidental session **PASS** (`/tmp/botai_empty_catalog_ui_20261022.log`); full regression after this UI-only change pending.

> **Latest v0.3.0 verification (2026-10-22):** Shared format/strategy selection for launcher and daily planner, deterministic matrix unit tests, **139/139 unit + 16/16 standard UI PASS** (`/tmp/botai_selection_full_20261022.log`, exit 0). Full cross-product UI matrix and seeded chemistry rerun remain outstanding; **NOT RC**.

> **Current v0.3.0 status (2026-10-22):** This file's original v0.2.0 snapshot below is historical, not the current implementation status. For the active branch `feature/v0.3.0-chemistry-pilot`, consult `docs/releases/RC_0.3.0_READINESS.md` and `docs/iterations/SESSION_LAUNCH_DECISIONS_2026-10-22.md`. Current simulator verification: **137/137 unit + 16/16 standard UI PASS** (exit 0, `/tmp/botai_final_session_gate_20261022.log`). Durable session resume, scoped launch and due-first automatic priority are implemented. Teacher-guided adaptive policy, complete mode matrix, backend migration/RLS acceptance, device-wide visual/accessibility and release signing remain open. **NOT RC; no TestFlight/App Store distribution authorized.**

---

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

2026-10-22: chemistry pilot end-to-end UI recall smoke passed: open session, flip card, rate answer, finish, terminate/relaunch; isolated simulator SQLite inspection after first run found 1 attempt, 1 session and 1 knowledge history event. Multi-choice/full-session/sync remain pending.

2026-10-22: WARNING: chemistry UI reported two answered questions and XCTest passed, but inspected simulator SQLite increased attempts only 3→4 and newest session answered=1. Possible test container mismatch or real persistence bug. Blocker: reconcile test target container and on-disk DB before accepting multi-question session.

2026-10-22: resolved apparent two-answer SQLite discrepancy: xcodebuild was executing old single-answer XCTest body (confirmed by action trace). Renamed test selector; fresh action trace confirms two answer taps and both UI counters, SQLite attempts 4→6 and latest session answered=2/correct=2. New strict test passed.

2026-10-22: UI launch correction on `feature/v0.3.0-chemistry-pilot` commit `d269aab`: one primary `БОТАТЬ` button opens scope selection (topic/subject/mixed/review); temporary three-button home shortcuts removed. Focused iPhone 16e Simulator UI test `testPrimaryStudyLaunchOpensSubjectPicker` **1/1 passed** (`/tmp/botai_agreed_launch_ui_retry.log`). Full suite and visual screen-fit unverified. Accepted design still requires format/strategy configuration, saved preferences, durable same-question session resume. See iteration log.

2026-10-22: full serial iPhone 16e simulator regression after launch changes **FAILED**: 14 UI tests, 7 assertion failures in 5 tests (`/tmp/botai_post_launch_full_regression.log`). Chemistry smoke used obsolete study CTA; test source updated but seeded chemistry integration must be rerun. Course creation, PDF share and BOTAI import UI failures need isolated triage. Release gate remains blocked; see iteration log.

2026-10-22: resumable study session implementation in progress: v15 local SQLite snapshot, exact ordered questions and cursor, home `ПРОДОЛЖИТЬ`/`Новое занятие`, relaunch restore. Complete pre-atomic 14/14 LaunchSmokeTests PASS (`/tmp/botai_resume_regression_20261022.log`). Atomic answer+cursor transaction added afterwards and is under verification (`/tmp/botai_resume_atomic_ui_20261022.log`). Do not claim final green until post-atomic tests finish. Details: `docs/iterations/RESUMABLE_SESSION_2026-10-22.md`.
2026-10-22: post-atomic focused UI regression **2/2 PASS** (`/tmp/botai_resume_atomic_ui_20261022.log`). New resumable-session unit tests added, awaiting execution.
2026-10-22: resumable-session atomic persistence tests **2/2 PASS** (`/tmp/botai_resume_unit_20261022.log`); post-atomic UI **2/2 PASS**. Full 14/14 UI regression was run before atomic hardening, not after. Physical-device/visual checks outstanding.

2026-10-22: RC 0.3.0 readiness audit created at `docs/releases/RC_0.3.0_READINESS.md`. Ten acceptance gates, evidence, risks and next executable steps; **NOT RC**. No release build or TestFlight verification.

2026-10-22: owner directed autonomous **large-batch delivery to user-testable v0.3.0**, no repeated micro-approvals. Execution plan: `docs/iterations/USER_TESTING_READINESS_2026-10-22.md`.
2026-10-22: full serial combined regression **105/105 unit + 14/14 UI PASS** (`/tmp/botai_user_testing_full_regression_20261022.log`), before new two-question fixture/test. New mid-session relaunch UI test running.

- 2026-10-22: Fixed multi-question interrupted-session resume: SwiftUI `.sheet(item:)` carries immutable resume mode; new end-to-end UI test confirms the second question survives process relaunch (focused 1/1 PASS). Full regression pending.
- 2026-10-22: Post-fix full simulator regression: 105 Swift Testing cases and all 15 standard UI tests PASS; combined run exit 65 because 2 chemistry-pilot UI tests require separately seeded data. Seeded chemistry test run pending.
- 2026-10-22: Chemistry pilot verified separately on seeded disposable simulator DB: 2/2 UI tests PASS. Total verified: 105 Swift Testing + 15 standard UI + 2 seeded chemistry UI. Seed script now clears resumable session and pilot UI test handles mixed question formats.
- 2026-10-22 product decision (not yet implemented): server sync of aggregate learning-session results **after completion only**; per-question history/repetition remains local. Supersedes choice-question publication work. See `docs/iterations/SESSION_SUMMARY_SYNC_DECISION_2026-10-22.md`.
- 2026-10-22: First session-summary sync implementation checkpoint: additive SQLite v16 and idempotent durable completed-session aggregates, with explicit finish/result-screen completion wiring. Focused local tests passed. Network sync, server RLS, and topic breakdowns remain pending; see `docs/iterations/SESSION_SUMMARY_SYNC_DECISION_2026-10-22.md`.
- 2026-10-22: Session-summary server migration `0025_completed_session_summaries.sql` prepared (not applied), local ACK idempotency implemented and 9/9 focused tests passed. End-to-end upload, server RLS verification, legacy outbox transition and detailed breakdowns still outstanding.
- 2026-10-22: Summary network transport and account-guarded coordinator implemented; focused Xcode tests pass. Backend migration not deployed, no live E2E, and legacy attempt upload remains active; RC-06 not accepted.
- 2026-10-22: Sync trigger switched from per-answer to session-completion signal (plus foreground/login retries); seven summary coordinator regression tests added. Combined legacy+summary suites 16/16 PASS. No live server deployment.
- 2026-10-22: Disabled all active legacy per-question server uploads without deleting local attempt history/outbox; completed-session persistence now atomically clears resume checkpoint. Focused 17/17 tests passed. Server migration remains unapplied.
- 2026-10-22: Prepared rollback-only two-user SQL fixture `backend/tests/completed_session_summary_rls.sql` (not executed); audited mixed-session attribution and confirmed existing `StudyQuestion` lacks stable subject/topic IDs. No inferred breakdowns sent. Full regression run started; see test log before marking passed.
- 2026-10-22: Added stable local course/section/topic attribution resolver with explicit ambiguity handling and tests; 115/115 unit tests passed. Not yet connected to session lifecycle or uploaded breakdowns. Full UI regression still pending.
- 2026-10-22: Implemented and tested local mixed-session aggregate accumulator with explicit unattributed bucket and Codable checkpoint compatibility; not wired to live session flow. Full UI regression failed and requires triage.
- 2026-10-22: Main picker now passes stable unique topic attribution into sessions; local per-answer aggregate and attribution map checkpoint atomically with answer/cursor; backward-compatible old checkpoints. 4/4 focused tests passed. Completed-summary upload still overall-only; other launch paths unattributed.
- 2026-10-22: Completed-session local outbox now retains optional topic aggregates and unknown bucket atomically, with count validation and backward-compatible JSON; 10/10 focused tests passed. Server upload intentionally still overall-only; targeted UI screenshot retry started.
- 2026-10-22: Visual-baseline UI test retry PASS (1/1); prior full-run failure was a snapshot acquisition error. Drafted unapplied migration 0026 and rollback-only two-user topic RLS fixture; no live deployment or topic upload.
- 2026-10-22: Implemented local v17 independent topic ACK queue and authenticated topic aggregate transport with verified readback, retry-safe parent-before-topic ordering, and 7/7 new coordinator tests. Supabase 0025/0026 still unapplied; no live server validation.

- 2026-10-22: Duplicate-key guards added; 131/131 unit tests PASS; full UI regression pending.

- 2026-10-22: Added topic-sync concurrency regression tests (account switch, duplicate flush, backend failure); execution pending completion of UI suite.

- 2026-10-22: 15 general UI tests PASS; 2 chemistry UI tests require separate seeded fixture. Topic concurrency 3/3 PASS after stabilizing async test polling. Seeded chemistry rerun pending.

- 2026-10-22: General UI 15/15 PASS, isolated seeded chemistry UI 2/2 PASS; terminal answer checkpoint survives until completed-session transaction; targeted recovery tests 2/2 PASS.

- 2026-10-22: Restored Mac access, strengthened atomic final-answer crash test, aligned existing checkpoint expectations with retained terminal cursor. Full unit regression 136/136 PASS (44 suites). Targeted UI resume verification in progress.

- **Corrected owner decision 2026-10-22:** Defer only App Store publication and TestFlight upload until separately authorized. Continue development/testing. No new GitHub, Supabase or physical-device restrictions are implied; their existing safeguards and permissions remain unchanged.

- **2026-10-22 regression checkpoint:** full simulator run **140/140 unit PASS (45 suites) + 23/23 general UI PASS**, 0 failures, exit 0 (`/tmp/botai_full_regression_20261022.log`). New populated-catalog and choice-feedback UI paths passed. Isolated chemistry seeded suite and remaining RC checks are separate; **not RC-ready**.

- **2026-10-22 isolated chemistry gate:** disposable iPhone 16e simulator seeded via guarded script; 323 knowledge rows/102 materials/5 sections/1 goal; **2/2 chemistry UI PASS**, exit 0 (`/tmp/botai_chemistry_disposable_seeded_20261022.log`). Previous standard **140 unit + 23 UI PASS**. RC remains OPEN for other gates.

- **2026-10-22 shared mastery regression:** one questionnaire referenced by multiple topics shares one durable `knowledgeID` mastery state; test confirms reopen/answer/reopen across topic contexts. **141/141 unit PASS** (`/tmp/botai_shared_knowledge_all_units_20261022.log`). General UI last 23/23 PASS; chemistry seeded 2/2 PASS (separate runs). UI E2E shared-topic flow remains pending.

- **2026-10-22 unique coverage gate:** shared knowledge counted in each topic but once in combined subject forecast; **142/142 unit PASS** (`/tmp/botai_shared_goal_all_units_20261022.log`). Two-topic UI E2E remains OPEN.

- **2026-10-22 two-topic UI:** actual course/section/two topics referencing one seeded set; topic counts equal whole-subject unique count; second topic launches real question. **Focused 1/1 UI PASS**, `/tmp/botai_shared_two_topics_ui_20261022.log`. Full standard UI suite not rerun after this addition. Completed-session shared attribution still OPEN.

- **2026-10-22 shared completed-session topic attribution:** two sessions sharing one question persist separate selected-topic breakdowns; **143/143 unit PASS** (`/tmp/botai_shared_topic_summary_units_20261022.log`). UI end-to-end answer-to-summary remains open.

- **2026-10-22 shared-goal mastery bugfix:** both daily plan and goal completion reconcile now calculate unique `knowledgeID` denominator rather than duplicated question occurrences; regression verifies 50%/100%/empty. **144/144 unit PASS**, `/tmp/botai_goal_unique_mastery_units_20261022.log`. Full UI regression still running at this checkpoint.

- **2026-10-22 block 1 regression:** standard **24/24 UI PASS** and previous **143/143 unit PASS**, `/tmp/botai_block1_full_regression_20261022.log`; Xcode xcresult save warning, raw test log authoritative. Latest post-change **145/145 unit PASS** `/tmp/botai_block1_matrix_units_20261022.log`; six format×strategy matrix cases covered in unit test, full scope×format×strategy UI remains pending.


### RC-06 account-bound sync hardening — 2026-10-23

Bound every `SyncService` instance to its originating authenticated UUID. A stale task may no longer start aggregate uploads from an old account database under a newly signed-in account; identity is rechecked at coordinator checkpoints. See `docs/iterations/RC06_ACCOUNT_BOUND_SYNC_2026-10-23.md`. Added regression coverage for account match, switch and sign-out. RC-06 remains OPEN pending end-to-end offline cold launch, reconnect, revoked-session and multi-account acceptance tests; no release approval.


### RC-06 offline revalidation fail-closed — 2026-10-23

`AuthStore.reconnectOfflineSession()` now locks local study on non-transport authorization failures and account mismatch, instead of leaving the offline identity active. Network outages still preserve local study access. See `docs/iterations/RC06_RECONNECT_AUTH_REJECTION_2026-10-23.md`. Signed unit suite: **156/156 PASS** (`/tmp/botai_rc06_revalidation_20261023.log`). Full offline/reconnect/ACK acceptance remains OPEN; never treat this regression as RC-06 closure.


### RC-06 foreground network restoration — 2026-10-23

Added `NWPathMonitor`-driven retry on offline→online transition even while the app stays foregrounded. Supabase account revalidation and existing account-bound aggregate sync are still required. Unit suite **157/157 PASS** (`/tmp/botai_rc06_connectivity_20261023.log`); UI regression log `/tmp/botai_rc06_connectivity_ui_20261023.log`. See `docs/iterations/RC06_FOREGROUND_CONNECTIVITY_RETRY_2026-10-23.md`. Full controlled network/hosted backend acceptance remains OPEN.


### RC-06 offline logout fail-closed — 2026-10-23

Local identity and offline binding are now always cleared on sign-out even when Supabase remote logout fails. The pinned Supabase SDK clears its persisted session before the remote call; remote token revocation is not claimed on network failure. See `docs/iterations/RC06_OFFLINE_LOGOUT_2026-10-23.md`. Signed regression evidence: `/tmp/botai_rc06_signout_20261023.log` (pending), UI regression `/tmp/botai_rc06_connectivity_ui_20261023.log` (earlier build). Full hosted backend acceptance remains open.

RC-06 follow-up (2026-10-23): root study UI now fails closed if per-account storage reopen fails after initial bootstrap; signed simulator regression pending. See `docs/iterations/RC06_OFFLINE_LOGOUT_2026-10-23.md`.

RC-06 readiness ledger reconciled 2026-10-23: `353f603` focused SQLite reconnect 11/11 PASS; `820f07b` full signed unit + 25/25 UI PASS; disposable PostgreSQL RLS previously PASS (auth shim). Hosted Supabase and real network/device gates remain OPEN. See `docs/releases/RC_0.3.0_READINESS.md`.

2026-10-23 RC-06: obsolete opt-in live test that assumed legacy per-attempt uploads replaced with aggregate-only, two-anonymous-account, duplicate-ACK and cross-account read-isolation hosted Supabase fixture. Requires BOTH BOTAI_RUN_LIVE_SYNC=1 and BOTAI_DISPOSABLE_SUPABASE_CONFIRMED=1; never run without owner-confirmed disposable backend. This is test scaffolding, not evidence of hosted verification.

RC-06 hosted opt-in fixture expanded: verifies parent-first topic aggregate upload, attributed counts, idempotent topic ACK and cross-account topic RLS reads. It remains disabled until a confirmed disposable Supabase environment is available.

RC-06 safety: hosted test now requires a separate explicit BOTAI_TEST_SUPABASE_URL and BOTAI_TEST_SUPABASE_PUBLISHABLE_KEY, refuses the app-configured Supabase URL/key, and refuses insecure non-loopback HTTP. Added deterministic negative configuration test; no hosted requests in routine suite.

RC-06 live backend fixture now includes negative cross-account INSERT tests for both parent and topic aggregates (RLS WITH CHECK), in addition to SELECT isolation. These hosted assertions remain unexecuted until disposable Supabase is configured; local compilation only validates the fixture.

RC-06 consolidated SQL replay (2026-10-23): added `tools/verify_rc06_disposable_postgres.sh`, a fail-closed runner for the previously created isolated PostgreSQL 17 cluster at `/tmp/botai_pg17_rls_20261022/data`, bound only to 127.0.0.1:55439. All three existing RLS/negative-permission fixtures PASS (`/tmp/botai_rc06_sql_replay_20261023.log`); runner stops server on exit. It does not migrate production or replace hosted Auth/PostgREST testing. Full signed regression initiated after the hosted test-harness changes; see subsequent checkpoint for results.

RC-06 signed simulator consolidated unit/UI suite PASS after SQL replay and hosted harness additions: `/tmp/botai_rc06_consolidated_full_20261023.log`. Hosted integration test is disabled by default, so its live assertions were NOT executed.

### Reconciled release state — 2026-10-23 (`95cd330`)

Authoritative current-state tables were corrected in `docs/IMPLEMENTATION_PLAN.md` and `docs/releases/RC_0.3.0_READINESS.md`. Session matrix: 18 card-only + 18 choice-only + 18 mixed-catalog availability states tested; broad launch/resume/shared knowledge PASS, exhaustive distinct-subject E2E not claimed. RC-04 teacher-guided adaptation and RC-05 visual/accessibility remain open. RC-06 local acceptance passed (159 unit + 25 UI, 3 SQL security fixtures); hosted Supabase and physical network checks explicitly deferred by owner. RC-07 operational UGC/privacy acceptance partial, distribution deferred. Old progress entries remain historical, not live status.

RC-04 accepted-contract audit 2026-10-23: inspected `DailyPlanner`, goal/profile models, accepted goal and motivation specifications and `OPEN_QUESTIONS`. Baseline planning is implemented; teacher guidance, authority and scoring are not. Explicitly recorded unresolved policy rather than inventing weights. See `docs/iterations/RC04_ADAPTIVE_CONTRACT_AUDIT_2026-10-23.md`. Documentation-only; no tests run.

RC-04 scope check 2026-10-23: learner-side adaptive daily planning is an explicit MVP requirement, while expanded teacher authoring tools are post-MVP. Teacher/class assignment semantics remain accepted conceptually and are not scoped out; implementation policy remains unresolved. Next: deterministic learner-side multi-goal acceptance tests without inventing teacher weights.

2026-10-23 OWNER DECISION: student-side teacher recommendations are mandatory in MVP (course import/direct chemistry-style seeding → offline persistence → adaptive planning → student UI). Only teacher authoring/admin is deferred. RC-04 P0 OPEN; prior interpretation superseded. Contract: `docs/iterations/RC04_STUDENT_RECOMMENDATIONS_DECISION_2026-10-23.md`.

2026-10-23 RC-04 work in progress: optional Codable goal guidance and chemistry seed metadata added with compatibility test; no general import, planner integration or visualization yet. Do not mark RC-04 complete.

RC-04 student UI partial 2026-10-23: Today goal card displays stored recommendation priority and rationale, VoiceOver priority label. Simulator build PASS (`/tmp/botai_rc04_guidance_ui_build_20261023.log`); UI behavior not yet independently tested. RC-04 remains P0 OPEN.

RC-04 2026-10-23: teacher priority now breaks equal-urgency goal ties in DailyPlanner, without overriding actual mastery/deadline or due-first question order. Signed simulator unit 161/161 PASS. This is partial recommendation use, not RC-04 completion.

2026-10-23 RC-04 rest-day fix: no phantom mandatory minute for zero budget; voluntary questions still available. 161/161 signed simulator unit PASS. Full recommendation pipeline P0 OPEN.

2026-10-23 RC-04 multi-goal fairness: deterministic 1-minute minimum per goal when budget allows, urgency-weighted remainder, no overbudget or phantom rest-day minute. 164/164 signed simulator unit PASS. General recommendation pipeline/UI still open.

2026-10-23 RC-04 SQLite persistence: guidance survives CourseRepository save/new repository reload/update, verified by signed simulator unit 165/165 PASS. Full process relaunch, course import, difficulty/pace and UI acceptance still open.

2026-10-23 RC-04: optional difficulty (1–5) and teacher suggested daily minutes (1–240) in local course guidance; invalid values ignored, shown on Today without modifying learner budget. 167/167 simulator unit PASS. Planner integration/general import/UI acceptance open.

2026-10-23 RC-04: chemistry direct seed includes difficulty 4 and suggested 25 min/day; Today compares teacher pace to BOTAI allocated goal minutes without changing profile budget. 168/168 simulator units PASS, Python seed syntax PASS. RC-04 P0 OPEN.

### Cross-goal question deduplication — 2026-10-23

Repeated StudyQuestion IDs are scheduled once across active goals. Later goals fill from next eligible unique question; goals with no remaining unique questions are omitted. Allocated minutes for such empty goals are not yet redistributed (open). Mastery still deduplicates knowledge IDs separately. Simulator 169/169 unit PASS (`/tmp/botai_rc04_dedup_units_20261023.log`). Full import/adaptive difficulty/UI acceptance open.

### RC-04 consolidated planner regression (2026-10-23)

Planner now removes overlapping question IDs **before** assigning shared study minutes, so goals with no remaining unique work do not consume time and the budget is reallocated to actionable goals. Due/new/not-due ordering and deterministic teacher-priority tie-break remain unchanged. Deadline urgency now counts calendar days (not truncated 24-hour intervals), including overdue deadlines. Added midnight/next-day/overdue/no-deadline regression. Full simulator unit + standard UI run: `/tmp/botai_rc04_batch_full_20261023.log` (check final result before claiming PASS). Outstanding: full teacher course import, adaptive difficulty policy, end-to-end UI guidance acceptance, physical device. RC-04 stays OPEN.

### RC-04 overlap integration verification — 2026-10-23

Added real in-memory SQLite material + two active goals referencing the exact same question set. DailyPlanner now demonstrably emits one goal, one question, and assigns the full 20-minute learner budget to that actionable goal rather than reserving time for an empty overlapping goal. Simulator unit suite **171/171 PASS** (`/tmp/botai_rc04_overlap_integration_20261023.log`). A separate full UI suite is still running (`/tmp/botai_rc04_batch_full_20261023.log`); do not mark UI PASS before its final summary. The `.botai` format currently represents individual materials rather than courses; a separate agreed course transport is still required to ingest full teacher plans. Difficulty guidance remains informational, not a verified adaptive input. RC-04 OPEN.

### RC-04 bundled course import (2026-10-23)

Added an **optional `coursePlan` field to version-1 `.botai` material packages**: course title/subject and one or more goals with question-set indexes, mastery target, deadline and optional teacher guidance (priority, rationale, difficulty, suggested minutes). Old material-only archives decode unchanged. The import preview identifies bundled courses. Import saves material, maps package question-set indexes to newly generated persistent material/rule IDs, then saves an active learner course with its goals/guidance. If course persistence fails, it attempts to delete the just-imported material. Manifest validation rejects empty goal/title, out-of-range targets and invalid/disabled question-set references. The contract currently supports **one bundled material and its goals**; multi-material course archives and section/topic structure are not implemented.

Verification: simulator build PASS (`/tmp/botai_rc04_course_import_final_build_20261023.log`); **173/173 unit PASS** (`/tmp/botai_rc04_course_import_units_20261023.log`), including JSON compatibility, invalid references and SQLite material/course persistence. Full UI regression `/tmp/botai_rc04_batch_full_20261023.log` has at least one failing existing UI test (`testMixedCardAndChoiceFormatsAvailableForEveryScope` at line 562, course title not found); this is **not a passing UI suite**. End-to-end document picker, process restart and adaptive difficulty remain open. RC-04 OPEN.

### RC-04 import archive and UI triage — 2026-10-23

Added integration test that creates an actual `.botai` ZIP with a `coursePlan`, opens it through `BOTAIPackageService.read`, and verifies that teacher guidance and question-set mapping survive the archive boundary. Simulator **174/174 unit PASS** (`/tmp/botai_rc04_zip_course_units_20261023.log`). The earlier full UI run (`/tmp/botai_rc04_batch_full_20261023.log`) is **NOT PASS**: `testMixedCardAndChoiceFormatsAvailableForEveryScope` fails at `LaunchSmokeTests.swift:562` while waiting for the newly created course title; `testPopulatedChoiceOnlyTestsFormatAndAnswer` fails at line 518 while waiting for the session scope screen after launch. Do not relabel these as passed or delete tests; investigate simulator state and navigation persistence and rerun. Course import currently only supports one bundled material and goals, not full multi-material/section/topic course; teacher difficulty is not yet an adaptive signal. RC-04 OPEN.

### RC-04 course section/topic import and simulator isolation (2026-10-23)

Extended optional `.botai` `coursePlan` with `sections[]` and `topics[]`, each topic referring to validated enabled question-set indexes within the bundled material. The importer maps them to persistent `CourseSection`/`CourseTopic` and newly assigned rule IDs. Missing `sections` decodes as empty for backward compatibility. Empty sections/topics and invalid/disabled indexes reject before saving. Multi-material packages remain unsupported; do not describe this as a complete multi-material course importer.

Simulator build PASS (`/tmp/botai_rc04_section_import_build_20261023.log`); **175/175 unit PASS** (`/tmp/botai_rc04_section_import_units_20261023.log`), including section/topic JSON roundtrip and invalid-index rejection. Full UI suite started earlier was not isolated: subsequent test invocations targeted the same simulator while it was running, so its failures cannot be confidently attributed to the app. After stopping the long suite, isolated rerun showed `testMixedCardAndChoiceFormatsAvailableForEveryScope` PASS (48.408s), but `testPopulatedChoiceOnlyTestsFormatAndAnswer` failed with XCTest `Lost connection to the application` / simulator helper, not an assertion. Need a clean, **nonconcurrent** simulator UI run; never mark full UI PASS yet. RC-04 OPEN: adaptive difficulty, full course multi-material transport, complete UI acceptance and real-device checks.

### RC-04 bundled import mapping consolidation — 2026-10-23

Extracted a single `BundledCourseImporter.course(plan:manifest:references:)` mapping contract from the SwiftUI file importer. It validates the package before indexing, verifies the generated rule-reference count, constructs section/topic and goal links from the same mapped UUIDs, and preserves imported teacher guidance. The UI now calls this mapper rather than duplicating mapping logic. Added repository-level regression covering the actual built `StudyCourse` saved and reloaded from SQLite, section/topic references, goal references, guidance, and invalid reference-count rejection. Existing material-only packages remain supported. No multi-material archive support yet.

Verification logs: `/tmp/botai_rc04_import_mapping_units_20261023.log` (unit tests), `/tmp/botai_rc04_choice_ui_clean_20261023.log` (sequential choice UI regression). **Do not mark either PASS until the corresponding final test summary is confirmed.** Earlier isolated UI `testMixedCardAndChoiceFormatsAvailableForEveryScope` passed, while `testPopulatedChoiceOnlyTestsFormatAndAnswer` suffered a simulator helper disconnect; these are separate outcomes. RC-04 OPEN: adaptive difficulty policy, multi-material import, complete sequential UI acceptance and physical device.

RC-04 import mapper verification (2026-10-23): 176/176 simulator unit PASS, `/tmp/botai_rc04_import_mapping_units_20261023.log`; isolated choice UI PASS, `/tmp/botai_rc04_choice_ui_clean_20261023.log`. Full UI regression and adaptive difficulty remain OPEN.

### RC-04 learner-facing recommendation access — 2026-10-23

Found that `GameHomeView.goalsCard` existed but was **never inserted into the rendered view hierarchy**. Teacher priority, difficulty, suggested daily minutes, pace comparison, rationale, mastery and target were therefore invisible despite previous UI implementation claims. Added a compact `Рекомендации и цели` action in Today when actionable goals exist, opening a scrollable accessible goal-details sheet. The standard-size home remains one-screen and without scrolling. Existing active-goal UI scenario now checks the recommendations button, sheet title, goal name and actual mastery after app relaunch. This verifies access to persisted student guidance UI, not a new difficulty-scoring policy.

Verification pending: full sequential simulator suite `/tmp/botai_rc04_full_sequential_20261023.log` was launched **before** these UI edits and cannot verify them; run the focused changed UI scenario and unit suite after the full run exits. Do not report a green UI run before the final summary. Teacher difficulty still informational; an unapproved numeric weight must not be invented. RC-04 OPEN.

### RC-04 visible recommendations verification — 2026-10-23

Confirmed a product defect: `goalsCard` was defined but unreachable in the rendered Today hierarchy. Now a compact `Рекомендации и цели` button opens a scrollable sheet showing the real per-goal mastery/target, minutes, deadline and available teacher guidance without introducing scrolling on standard-size Today. The persisted-goal cold-relaunch UI test now opens the sheet and asserts the goal and `Освоено 0%`. **Focused simulator UI PASS** (`testCreateCourseSectionTopicAndGoal`, 75.867 s, `/tmp/botai_rc04_recommendations_ui_20261023.log`); **176/176 unit PASS** (`/tmp/botai_rc04_visible_guidance_units_20261023.log`). A full UI suite started before this fix was intentionally stopped so the updated UI could be verified; it is NOT a completed full UI regression. Full sequential regression remains required at RC closure. No change to teacher difficulty scoring or profile minute budget.

### Deterministic generated choice order — 2026-10-23

Fixed nonreproducible `StudyQuestionBuilder` distractor selection and answer ordering: SHA-256 ranking derived from stable rule ID, row ID and candidate text now gives the same answer list and correct indexes for a given material snapshot, including when a question is rebuilt after restart. This does **not** change the persisted snapshot for an in-progress session, or the automatic due/weak/new study priority. New regression covers repeated builds of six four-choice questions. **177/177 simulator unit PASS**, `/tmp/botai_rc04_stable_choice_units_20261023.log` (`TEST_EXIT:0`); targeted UI not run for this pure question builder change. Full signed UI regression remains OPEN.

### Full sequential simulator regression — 2026-10-23

**PASS:** signed iPhone 16e simulator `xcodebuild test -parallel-testing-enabled NO`, `/tmp/botai_rc04_full_final_20261023.log`, `TEST_EXIT:0`, `** TEST SUCCEEDED **`, **177/177 unit and 25/25 UI**. All UI tests ran sequentially without competing test sessions, including populated choice and mixed-scope launch, course/goal/recommendation cold relaunch, resume, import, shared-question dedup and visual smoke. This validates the current simulator baseline after commit `6a2a5d7`; it does **not** prove full RC-04 feature acceptance. Remaining: approved adaptive treatment of difficulty, multi-material course transport, complete teacher recommendation scenarios and real-device acceptance. User-owned Xcode project settings remain untouched.
