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
- Full post-change unit + standard UI regression: `/tmp/botai_block1_full_regression_20261022.log` — pending outcome at document creation; update after completion.

## Reporting format after each block

1. Block completion and accepted functionality (with test log and commit).
2. Overall release readiness: current RC gates, P0 blockers and evidence, with estimate clearly labelled.
3. Next block and outstanding decisions/permissions. Do not announce release or 100% before all mandatory gates are closed.
