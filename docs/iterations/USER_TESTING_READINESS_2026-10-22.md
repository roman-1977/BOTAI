# BOTAI 0.3.0 — user-testing readiness execution

Date: 2026-10-22. Branch: `feature/v0.3.0-chemistry-pilot`. Baseline: `f123a89`.

## Owner directive

Deliver an installable, user-testable build in **large autonomous batches**. Do not request approvals for minor changes or report every small edit. Escalate only genuinely blocking choices, permissions, Apple credentials/signing, production-impacting operations, or changes to accepted scope. Do not silently downgrade agreed functionality to pass tests.

## Delivery batches

1. **Study core (P0):** verify and finish multi-question resume/finish, every MVP question mode, topic/subject/mixed/review launch, adaptive scheduling and goal/teacher guidance within agreed scope; robust local migrations and offline continuity. Run focused and broad tests.
2. **Content and sync (P0):** imports, own/shared library and authoring, unsupported choice/media attempt sync, retry/idempotency, migration and account isolation. Complete security and moderation flows needed for features exposed to users.
3. **UX and acceptance (P0):** no-scroll light home, compact chart, dark learning view, small/standard/large screen, accessibility, progress/report correctness. End-to-end regression and seeded chemistry pilot.
4. **Test distribution:** release configuration, signing, privacy/age/UGC requirements, installation and test checklist. Use TestFlight if signing/App Store Connect credentials and permissions are available; otherwise produce a verified simulator/dev-device build and list exact external blocker. No invented TestFlight delivery.

## Definition of user-testable

- Reproducible install on target iPhone/TestFlight or clearly documented blocked distribution step.
- Real user can import/create material, start each agreed mode, learn offline, restart and resume, view progress, reconnect without data loss, and understand errors.
- Automated unit/integration/UI/chemistry tests green, with full post-change regression; no ignored failing tests.
- Accepted product/UX behavior checked against source of truth; outstanding known limitations explicitly documented.
- Docs, version, release notes, user testing script and handoff complete; no user-owned Xcode project changes included.

## First executable work

Inspect existing UI fixture and study flow, implement two-question interrupted-session UI coverage and run full regression; then proceed through batches without asking for step-by-step confirmation. Log each batch with commit IDs, tests and blockers in this file.

### Batch 1 — regression and interrupted two-question scenario

- Started serial combined `BOTAITests` + `LaunchSmokeTests` on disposable iPhone 16e simulator; log `/tmp/botai_user_testing_full_regression_20261022.log`. Unit subset: **105/105 PASS**; UI suite still running at this checkpoint. This run was compiled before the new two-question UI test, which must be run separately.
- Added isolated opt-in `-botai-seed-two-course-questions` UI fixture and `testResumeSecondQuestionAfterFirstAnswerAndRelaunch`: answer question 1, terminate, resume at question 2, complete and clear CTA. **Not yet run.**
- Do not count test as passed before execution; do not start concurrent xcodebuild against same simulator.

- Combined pre-two-question-fixture regression **PASS**: 105/105 Swift Testing cases and 14/14 UI cases, `/tmp/botai_user_testing_full_regression_20261022.log` (273.75s). New two-question UI test running separately `/tmp/botai_two_question_resume_20261022.log`.
- New two-question UI test **FAILED** on first run: after resume, expected `Основание` not visible (line 345; `/tmp/botai_two_question_resume_20261022.log`). Prior 119-test suite remains green. Added accessibility diagnostic for next run; do not mark gate passed.

### Multi-question resume regression (2026-10-22)

The new two-question course UI scenario exposed a real SwiftUI sheet presentation race: `GameHomeView` used separate `learn` and `resumeSession` state, so the resume sheet was constructed with `resume=false`, showing question 1 and counters 0/2 despite a persisted cursor 1/2. Replaced those independent flags with an identifiable `StudyPresentation(resume:)` item bound to `.sheet(item:)`; the presentation's mode is now immutable per sheet instance. `LearnSessionView` additionally guards initial restoration against premature scene-phase checkpointing. The focused test **passed** after this fix (1/1, `/tmp/botai_resume_presentation_fix_20261022.log`). A full regression after the fix is still required; the earlier 119/119 pass predates this scenario.

### Full simulator regression after resume fix

- Full `xcodebuild test` run: **105/105 Swift Testing cases passed** (reported by Xcode's Swift Testing runner); **15/15 LaunchSmokeTests passed** (including both interrupted-session resume scenarios). `/tmp/botai_full_regression_resume_fix_20261022.log`.
- The combined invocation returned exit 65 solely because **2 ChemistryPilotSmokeTests failed without their required preseeded chemistry database**. They are deliberately documented to run separately with `tools/chemistry_pilot/run_simulator_smoke.sh`; this was a fixture/precondition failure, not evidence that chemistry functionality regressed. A properly seeded pilot run has been started and must be reported separately.
- Chemistry pilot rerun with the dedicated seeded fixture: **2/2 UI tests PASS**, exit 0, `/tmp/botai_chemistry_seed_snapshot_fix_20261022.log`. Two harness fixes were required: support randomized recall/choice questions, and clear `resumableStudySession` during the explicit disposable-DB reset. Both are test-only fixes.
