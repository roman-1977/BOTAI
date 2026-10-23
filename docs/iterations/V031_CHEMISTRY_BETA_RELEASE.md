# BOTAI 0.3.1 — chemistry learner beta for user testing (2026-10-23)

## Decision and data safety

Owner approved release for learner testing and required **learning data to persist going forward**. The pre-release `resetPilotLearning()` call has been removed from application launch and account switches. Attempts, knowledge states, study sessions, daily progress and history remain in the account-local SQLite database across cold launches and updates; curriculum and course records are retained as before. Test-fixture reset (`-botai-reset-ui-test-data`) remains confined to isolated UI-test storage.

**Important limitation:** cloud learning sync is intentionally suspended in this beta to avoid silently restoring legacy remote pilot progress or uploading data that was previously treated as disposable. Learning progress is persisted **on the current device, per account**, but is **not yet backed up/synchronized to a second device**. Do not uninstall the app, clear its data or change bundle ID if progress must be preserved. Account sign-in may require live Supabase configuration; Apple ID has not been verified end-to-end on a physical device. Restoring safe cloud sync requires an explicit reconciliation/migration plan and tests; never replace local progress with old remote records automatically.

## Release scope

Chemistry learner beta includes bundled curriculum, teacher-defined staged course, recommended graded-choice tests, optional cards via manual setup, progress/motivation, local persistence and existing auth UI. Two physical learner devices, actual Apple/email sign-in, multi-day progression and offline/online recovery still require acceptance testing. Do not claim App Store/TestFlight distribution unless the upload actually succeeds.

## Verification

Pre-change checkpoint: 189/189 unit tests passed; all 28 UI scenarios passed across a full 26/28 run plus two targeted reruns. After persistence change, full unit/UI simulator run: `/tmp/botai_042_release_full.log` (fill in final outcome). Xcode project has unrelated user edits and must not be committed. Release build should override version/build using `MARKETING_VERSION=0.3.1 CURRENT_PROJECT_VERSION=3` rather than rewriting the project file.

## Transfer package

See `docs/iterations/FINAL_HANDOFF_2026-10-23.md`. Every primary GPT entry point (`AGENTS.md`, `docs/CHATGPT_REPOSITORY_GUIDE.md`, `README.md`, status/plan, QA plan and current handoff) now points to the authoritative beta handoff. Historical notes remain for traceability and must not be mistaken for the current release status.

## Confirmed release outcome — 2026-10-23

- Fresh complete post-persistence simulator run `/tmp/botai_042_release_full.log`: **TEST SUCCEEDED**; **28/28 UI tests PASS, 0 failed, 0 remaining**. Earlier unit evidence **189/189 PASS** from `/tmp/botai_037_units.log`; the fresh combined xcodebuild log's visible summary confirms 28 UI tests, not an independently re-counted 189 unit tests.
- Signed Debug generic iPhoneOS build `/tmp/botai_043_beta_device_build.log`: **BUILD SUCCEEDED**, using `MARKETING_VERSION=0.3.1 CURRENT_PROJECT_VERSION=3`.
- Release gate `/tmp/botai_044_beta_release_gate.log`: **TESTS_PASS**, **SIGNED_BUILD_PASS**, branch and annotated tag pushed, **GITHUB_PRERELEASE_PUBLISHED**.
- Tag: `v0.3.1-chemistry-beta`; GitHub prerelease: https://github.com/roman-1977/BOTAI/releases/tag/v0.3.1-chemistry-beta ; tagged source commit `13cda23`. This status addendum is a later documentation-only commit, so it is not contained in the release tag.
- Distribution is a GitHub prerelease and signed Xcode device build, **not** TestFlight or App Store; physical device installation, real sign-in and long-term cloud persistence remain unverified.
- Local learner progress is preserved in SQLite; cloud learning sync deliberately disabled. Do not delete/reinstall the app after learners start, and do not claim cloud backup.
