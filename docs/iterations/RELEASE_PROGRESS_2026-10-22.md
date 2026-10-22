# BOTAI — release progress and work blocks (2026-10-22)

**Status: NOT RC.** Work in blocks, not one test per user update. A block is done only with implementation, full relevant tests, documentation and scoped commit. Do not push, deploy backend migrations, sign, distribute or publish without explicit approval.

## Overall readiness

The previously communicated **70%** was a *subjective estimate*, not a verified completion ratio. Do **not** use it as a precise burn-down metric. Source of truth is `docs/releases/RC_0.3.0_READINESS.md` (RC-01…RC-10). Ten gates are not equal-sized; a count of passed gates is not equivalent to percentage of remaining work. Report both evidence and blockers, and revise percentage only after weighting remaining tasks.

| Work block | Scope | Status | Evidence / remaining |
| --- | --- | --- | --- |
| 1. MVP functional acceptance | Session launch modes, shared questionnaires, persistence, completed-session reporting, motivation | IN PROGRESS | 143/143 unit PASS; shared two-topic UI PASS, now extended through answer/finish/relaunch; full UI regression running; complete scope×format×strategy matrix and teacher-guided policy still open |
| 2. Reliability & backend | Offline/reconnect, isolated migrations, summary-only sync, RLS, retries, no duplicate uploads | OPEN | SQLite local regressions exist; disposable PostgreSQL migrations `0025`/`0026` and RLS fixtures not yet accepted |
| 3. UI & device acceptance | Small/standard/large screens, home without scroll, light/dark, Dynamic Type, VoiceOver, physical iPhone | OPEN | Some screenshots and UI smoke tests exist, but no complete visual/accessibility sign-off |
| 4. Release readiness | Privacy, moderation, App Review, signing, metadata, TestFlight, RC audit | OPEN | RC checklist exists; no signing/upload/release authorized |

### Functional acceptance — shared questionnaire

- One stable `knowledgeID` is learned once across all referencing topics.
- Both topics can contain that knowledge; whole-subject unique coverage uses union, not sum.
- Completed sessions report the *selected* topic; reporting does not fork mastery.
- Unit tests: 143/143 PASS (`/tmp/botai_shared_topic_summary_units_20261022.log`).
- Two-topic UI test originally 1/1 PASS (`/tmp/botai_shared_two_topics_ui_20261022.log`). Extended UI now answers in topic B, completes, relaunches, starts topic A, 1/1 PASS (`/tmp/botai_shared_two_topics_answer_finish_20261022.log`). This does **not** directly inspect durable mastery in the UI or remote upload.
- Full standard UI regression **24/24 PASS**, and 143/143 unit PASS (run started before latest unit-only changes), `xcodebuild` exit 0: `/tmp/botai_block1_full_regression_20261022.log`. **Caveat:** Xcode emitted a result-bundle saving error (`mkstemp: No such file or directory`) despite test success; preserve raw log and rerun before RC if xcresult bundle required. Post-change 145/145 unit PASS (`/tmp/botai_block1_matrix_units_20261022.log`).

## Reporting format after each block

1. Block completion and accepted functionality (with test log and commit).
2. Overall release readiness: current RC gates, P0 blockers and evidence, with estimate clearly labelled.
3. Next block and outstanding decisions/permissions. Do not announce release or 100% before all mandatory gates are closed.

### Goal mastery denominator fix (in progress)

Audit found `GoalProgressService.reconcile` counted repeated questions in the denominator when a goal references shared knowledge through multiple question sets. Changed the calculation to a union of `knowledgeID` and added a regression covering 50% versus an erroneous 67%, 100%, and empty input. **Post-change 144/144 unit PASS** in 46 suites (`/tmp/botai_goal_unique_mastery_units_20261022.log`). No claim that this resolves teacher-guided adaptivity.

### Scope × format × strategy matrix (unit checkpoint)

Added `StudyQuestionSelectionMatrixTests.allFormatsAndStrategiesPreserveUniqueQuestionIdentity` covering **mixed/cards/tests × automatic/all** with repeated question references. All six combinations return expected kinds and unique question IDs. **145/145 unit PASS** in 46 suites, `/tmp/botai_block1_matrix_units_20261022.log`. This is a unit matrix, **not** yet the full subject/topic/mixed UI matrix.

### Cross-format shared mastery regression

A card and a choice question with different question IDs but the same knowledgeID share due priority and mastery while remaining separately selectable in their formats. Goal mastery counts their shared knowledge once. **146/146 unit PASS**, `/tmp/botai_shared_format_mastery_units_20261022.log`. Full mixed-format UI fixture remains pending.

### Opposite format fixture (choice-only) UI matrix

Extended the real single-choice fixture to verify the opposite 18 availability states: topic/subject/all-subject × mixed/cards/tests × automatic/all. Mixed/tests enabled, cards disabled; launches choice and validates correct-answer feedback. **1/1 focused UI PASS**, `/tmp/botai_choice_scope_matrix_ui_20261022.log`. Together with card-only fixture this covers **36 states**, but not distinct subjects or a mixed-format catalog.

### Scope × format × strategy populated availability matrix

Expanded a real populated card-only UI flow to assert **18 states** (3 scopes × 3 formats × 2 strategies): mixed/cards enabled, tests disabled; launched actual card. **1/1 UI PASS**, xcodebuild exit 0, `/tmp/botai_scope_format_strategy_ui_20261022.log`. Still pending distinct subjects and mixed choice/card catalog, offline, and complete E2E.

### Shared questionnaire — three launch scopes UI checkpoint

The existing real two-topic UI E2E now checks **topic A = topic B = whole subject = all subjects mixed** question counts for the shared set; then answers, completes, relaunches, and opens the other topic. **Focused 1/1 UI PASS**, exit 0, `/tmp/botai_scope_matrix_ui_20261022.log`. This covers shared-set scope invariants, **not** a complete 3 scopes × 3 formats × 2 strategies E2E cross-product. Remaining: distinct subject fixtures, offline/reconnect, adaptive policy.

### Mixed catalog UI checkpoint

Added isolated mixed card and choice fixture. Real topic attaches both sets; all 18 scope x format x strategy combinations enabled, and test question feedback succeeds. Focused 1/1 UI PASS: /tmp/botai_mixed_catalog_ui_20261022.log. Distinct subject fixture and full mixed session still pending.

### Full-suite regression audit (2026-10-22)

A complete xcodebuild test run on standard isolated simulator is underway; raw log: /tmp/botai_all_scenarios_regression_20261022.log. It initially revealed that two chemistry-pilot UI tests assumed preseeded content and failed on a standard empty simulator. Those tests now skip only when the external chemistry fixture is absent, and still execute assertions when seeded. A clean rerun is required after the current run finishes. Do not count skipped pilot tests as verified.

### Full automated regression result

Complete standard-simulator sweep: 146/146 unit PASS; 25/25 general UI PASS; two chemistry-pilot UI tests initially FAIL because this simulator has no external chemistry seed (full log /tmp/botai_all_scenarios_regression_20261022.log, exit 65). Fixed the pilot precondition handling, then isolated recheck of both chemistry tests on unseeded simulator exits 0 with two SKIPS (/tmp/botai_pilot_unseeded_skip_fixed_20261022.log). This does NOT establish seeded chemistry acceptance; keep separate seeded run required. General UI tests all passed in the first sweep, but a post-fix complete clean full-suite rerun has not yet occurred.

### Clean comprehensive automated regression — 2026-10-22

**PASS**: serial full xcodebuild run on isolated standard iPhone 16e simulator: **146/146 unit**, **25/25 standard UI PASS**, **2 chemistry-pilot UI SKIP** (fixture intentionally absent), exit **0**, `** TEST SUCCEEDED **`. Evidence: `/tmp/botai_full_clean_regression_20261022.log` (724 s). The earlier red run with 2 chemistry fixture failures was superseded by this post-fix green run; skipped tests are not counted as passes.

**PASS separately**: prepared the dedicated disposable chemistry simulator (`62B01BED-4A72-43B9-A02D-351D9E82EE7A`) using local-only fixture script after backing up its UI-test SQLite database. Chemistry fixture validates 323 knowledge questions, 102 materials and 5 sections. **2/2 seeded chemistry UI PASS**, exit **0**, `/tmp/botai_seeded_chemistry_acceptance_20261022.log`. The five Python seed/integrity tests also **5/5 PASS**, `/tmp/botai_chemistry_seed_python_20261022.log`.

**RC-08 standard and seeded chemistry automated regression: PASS for this revision.** This is not a claim that all manual, hardware, security, accessibility or offline/reconnect acceptance scenarios passed. RC-04 teacher guidance and RC-06 disposable Postgres RLS remain open. No production deployment, release tag, TestFlight upload, or push.

### Block 2 — offline/restart/reconnect durable summary verification (2026-10-22)

Added two disk-backed SQLite integration tests (temporary disposable DB paths, no user data touched). First test completes an aggregate-only session offline, verifies duplicate completion does not duplicate the outbox, closes and reopens the database, simulates a failed upload, retries after reconnect, verifies one ACK and zero further uploads, then reopens again to verify durable ACK. Second test completes a topic-attributed session offline, reopens, confirms topic uploads are blocked until the parent session summary is acknowledged, then uploads exactly once and confirms both ACKs survive another restart. **148/148 unit tests PASS**, `/tmp/botai_offline_reopen_sync_units_20261022.log`, xcodebuild exit 0.

**Boundary:** these are integration tests with fake network backends, not live transport or actual airplane-mode/reconnect on hardware. Migrations `0025`/`0026` have rollback-only RLS fixture scripts (`backend/tests/completed_session_summary_rls.sql` and `backend/tests/completed_session_topic_aggregate_rls.sql`) but are **NOT executed against disposable Postgres**: this Mac has `supabase` CLI but no `docker`, `psql` or `pg_ctl` in PATH. No live database migration or production backend access attempted. RC-06 remains PARTIAL, release NOT RC.
