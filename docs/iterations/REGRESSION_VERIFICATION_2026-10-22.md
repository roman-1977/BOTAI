# UI regression verification — 2026-10-22

Branch: `feature/v0.3.0-chemistry-pilot`.
Simulator: iPhone 16e, iOS 18.6, UDID `33176212-1247-4722-B8F4-4E53438502E4`. No physical device was used.

## Changes

- Updated PDF share UI smoke assertion to the current home button label `Отчёт PDF`.
- Updated course/topic/goal UI smoke to use the accepted single `primary-study-launch` button, navigate through `Что будем учить?`, explicitly select `Тема проверки`, then answer the chemistry question.
- Application behavior was not changed; these are tests adjusted to the accepted launch flow.

## Verified

- **LaunchSmokeTests:** 12 tests, 0 failures; `** TEST SUCCEEDED **`, exit 0. Log: `/tmp/botai_launch_clean_20261022.log`. Serial execution with no competing xcodebuild processes; total test execution 200.764 seconds.
- **ChemistryPilotSmokeTests:** 2 tests, 0 failures; `** TEST SUCCEEDED **`. Log: `/tmp/botai_chem_ui_20261022.log`. Run through `tools/chemistry_pilot/run_simulator_smoke.sh` with backup and seeding of isolated simulator UI-test database.
- **Chemistry Python unittest:** 5 tests, 0 failures. Log: `/tmp/botai_chem_python_20261022.log`.
- `git diff --check` on the changed UI test source: clean.

## Prior failures and test hygiene

An initial 12-test regression failed because the course flow test did not choose a topic in the new picker. Its focused rerun passed, followed by the successful clean 12-test regression. A subsequent overlapping simulator test invocation produced XCTest runner restarts; those results were rejected and the extra xcodebuild was terminated before the final clean run. Do not run two xcodebuild UI test jobs against the same simulator simultaneously.

## Scope and remaining work

This verification covers the existing UI tests, not the unfinished session format/strategy picker, persisted last launch configuration, same-question resume, time-normalized goal chart, or manual layout QA across device sizes. The full 14-test combined suite was not run as one job; the 12 general and 2 seeded chemistry tests were run separately to preserve their distinct fixture requirements.

User-owned `ios/BOTAI.xcodeproj/project.pbxproj` remains modified and must not be staged, reverted, or committed. No physical iPhone installation and no push were performed.
