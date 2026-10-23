# BOTAI 0.3.1 — chemistry learner beta for user testing (2026-10-23)

## Decision and data safety

Owner approved release for learner testing and required **learning data to persist going forward**. The pre-release `resetPilotLearning()` call has been removed from application launch and account switches. Attempts, knowledge states, study sessions, daily progress and history remain in the account-local SQLite database across cold launches and updates; curriculum and course records are retained as before. Test-fixture reset (`-botai-reset-ui-test-data`) remains confined to isolated UI-test storage.

**Important limitation:** cloud learning sync is intentionally suspended in this beta to avoid silently restoring legacy remote pilot progress or uploading data that was previously treated as disposable. Learning progress is persisted **on the current device, per account**, but is **not yet backed up/synchronized to a second device**. Do not uninstall the app, clear its data or change bundle ID if progress must be preserved. Account sign-in may require live Supabase configuration; Apple ID has not been verified end-to-end on a physical device. Restoring safe cloud sync requires an explicit reconciliation/migration plan and tests; never replace local progress with old remote records automatically.

## Release scope

Chemistry learner beta includes bundled curriculum, teacher-defined staged course, recommended graded-choice tests, optional cards via manual setup, progress/motivation, local persistence and existing auth UI. Two physical learner devices, actual Apple/email sign-in, multi-day progression and offline/online recovery still require acceptance testing. Do not claim App Store/TestFlight distribution unless the upload actually succeeds.

## Verification

Pre-change checkpoint: 189/189 unit tests passed; all 28 UI scenarios passed across a full 26/28 run plus two targeted reruns. After persistence change, full unit/UI simulator run: `/tmp/botai_042_release_full.log` (fill in final outcome). Xcode project has unrelated user edits and must not be committed. Release build should override version/build using `MARKETING_VERSION=0.3.1 CURRENT_PROJECT_VERSION=3` rather than rewriting the project file.
