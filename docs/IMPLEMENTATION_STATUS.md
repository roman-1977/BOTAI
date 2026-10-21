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
- Debug simulator builds and installs succeeded. The home screen was visually reviewed at standard and Accessibility Medium text sizes.
- A large-text layout issue was reproduced (truncated study button and crowded metric labels), fixed in `c4d07b0`, and the corrected screen was captured and reviewed at Accessibility Medium.
- The home screen was also inspected on the smaller iPhone 16e at default and Accessibility Medium sizes. A clipped daily-plan heading was found and fixed in `0e867a3`; the updated compact-device screenshot confirmed the complete heading and repositioned progress ring. At accessibility sizes, the goal selection control is below the fold but remains reachable by scrolling.
- VoiceOver descriptions were added for session progress rings, but a full screen-reader walkthrough has not been performed.
- UI review is **partial**, not final: other sections, compact devices, further accessibility sizes and contrast/reduced-motion settings remain to be examined.

## Remaining acceptance gates

1. Complete full regression on the final commit, including UI tests and launch/relaunch paths.
2. Review rendered UI on compact and large devices, large text, accessibility and navigation.
3. Exercise fresh install, failed storage, offline use, import/export, delete, account switch and sync recovery.
4. Document residual limitations, freeze and tag the validated candidate; keep `main` unchanged until sign-off.

See `docs/PRE_REFACTOR_AUDIT_2026-10-21.md` for the original audit and proposed architecture; its snapshot predates the branch changes above.
