# BOTAI chemistry pilot — learner feedback corrections (2026-10-23)

Owner reports from real-device manual testing: repeated underlying knowledge in one 10-question session, mixing reveal cards and multiple-choice; overloaded launch picker on primary «БОТАТЬ»; no visible Apple account identity; active session should be unique and resumable only on the same calendar day. Midnight during an open study screen must not interrupt it, but after leaving it the previous-day snapshot must not resume.

Implemented changes: primary «БОТАТЬ» launches system recommendation immediately; manual picker is a separate «Настроить занятие» action; if today's snapshot exists, explicit continue/new recommended/new manual options; previous-day snapshot excluded from resume; default answer mode cards and knowledge-ID deduplication, explicit test mode available in manual picker; profile shows available authenticated email, otherwise a shortened per-account identifier. Apple private relay address is acceptable; Apple full name is saved on its first available authorization, keyed by account UUID, and restored on subsequent logins; offline fallback does not invent identity. The recommendation is the existing due-first teacher-guided daily plan, not a newly invented strategy. No published release until manual acceptance.

Regression: `PilotFeedbackRegressionTests` cover unique knowledge, one response mode and calendar-day resume. Simulator regression passed; physical iPhone acceptance remains pending. Local user-modified Xcode project file must remain untouched.

## Verification checkpoint

The latest unit regression passed **187/187** tests (59 suites), `/tmp/botai_031_units_with_apple.log`, `** TEST SUCCEEDED **`. Simulator build succeeded (`/tmp/botai_031_build.log`). The initial full UI run used an older compiled test bundle and failed in tests expecting the removed mixed format and in course-to-manual-launch navigation (`/tmp/botai_031_ui.log`). Both previously failing UI scenarios passed in targeted rerun (`/tmp/botai_031_ui_targeted_retry.log`, `** TEST SUCCEEDED **`). The final full UI regression passed **26/26 executed** UI tests with zero failures (`/tmp/botai_031_ui_final.log`, `** TEST SUCCEEDED **`). There are 28 `func test` declarations in the source, but the executed suite reported 26 tests; do not represent the two unmatched declarations as executed. One earlier targeted attempt failed before running any tests due to an Xcode device-service/passcode issue; do not treat this as an app regression. Only physical-device manual acceptance and subsequent distribution remain open.

## Post-install feedback (pending acceptance)

The learner observed five consecutive sulfuric-acid questions. Session selection now randomizes questions **within** due/new/not-due priority tiers, retaining the teacher's due-first strategy and one knowledge item per session. It does not attempt semantic similarity grouping. Added a regression checking priority ordering, knowledge uniqueness, and varied order. Awaiting new unit/UI regression and real-device acceptance; not yet a release. Further requests: use objective multiple-choice by default, fix cramped labels beneath four study rings, and reset learning progress at each pre-release app launch while retaining account, curriculum and courses (including guarding against cloud rehydration). These three requests remain open.

### Implementation update — pilot defaults

- Recommended and goal launches now use choice tests; manual picker defaults to tests and still offers cards explicitly. Empty test sets route to the picker, never silently fall back to self-rated cards.
- Study rings now use equal-width header columns with smaller labels and additional bottom padding.
- `AppDatabase.resetPilotLearning()` clears only learning tables (attempts, state, sessions, history, snapshots and outbox). Course definitions, imported materials, study profile and authentication are not deleted. Reset is performed at cold start and when the authenticated account database is opened. UI-test launches bypass this temporary policy to preserve persistence tests.
- Aggregate-statistics sync is disabled during this pre-release pilot to avoid uploading discarded progress. No remote learning records are deleted; remote progress must be reconciled explicitly when pilot reset is removed.
- Session selection shuffles within due/new/not-due priority tiers, retaining one question per knowledge item. This does not attempt semantic grouping of similar acids.
- **Release acceptance pending**: verify full simulator suite and device behavior; do not tag or publish a release.

### Final simulator verification — pilot-default correction

- Unit regression: **189/189 passed**, 59 suites, `/tmp/botai_037_units.log` (`TEST SUCCEEDED`). Includes pilot reset and question-order regressions.
- Full UI regression: **26/28 passed** initially, `/tmp/botai_038_ui.log`. Two old UI assertions assumed the prior fixed card order and retained card-format selection across launches.
- Updated both tests to explicitly select card format when required and accept shuffled/reversible card prompts. `testSharedQuestionSetInTwoTopicsIsNotDuplicatedForSubject` passed in `/tmp/botai_039_ui_targeted.log`; `testResumeSecondQuestionAfterFirstAnswerAndRelaunch` passed in `/tmp/botai_041_ui_targeted.log` (`TEST SUCCEEDED`). Thus **all 28 distinct UI scenarios passed across full run and targeted reruns**; a new single uninterrupted 28/28 full run has not been performed after the test-only corrections.
- The previous targeted attempt `/tmp/botai_040_ui_targeted.log` failed during course creation with intermittent simulator/device-service errors; rerun passed. Do not describe it as a product fix.
- User-edited `ios/BOTAI.xcodeproj/project.pbxproj` is intentionally excluded from this commit.
- Remaining acceptance: manual test on the physical iPhone, explicit user release approval, and subsequent restoration of persistent learning progress before general release. Do not publish/tag yet.
