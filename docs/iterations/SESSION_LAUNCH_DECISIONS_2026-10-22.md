# Session launch decisions — 2026-10-22

Approved product decisions:

1. New session launch is frictionless: choose a scope (topic, subject, mixed, or quick-start) and start directly. Do not force a configuration or confirmation step.
2. Fine controls are hidden in a collapsed `Дополнительные настройки` disclosure. They can override question format (cards/tests/mixed) and strategy (automatic/all/review) for **one new session only**.
3. Every **new** session uses system defaults again; manual overrides must not persist as defaults. Continuing an unfinished session must restore its original configuration, question order, current question, and recorded answers rather than recompute.
4. Teacher supplies guidance (priorities, targets, difficulty, pace); the **system** decides an adaptive strategy using that guidance and current student performance. Teacher guidance is an input, not a rigid override.
5. Present implementation is a limited automatic baseline: due questions first, then other questions. Full adaptive strategy and teacher recommendation storage/priority integration remain **pending**; do not represent baseline as completed adaptive learning.

Implementation checkpoint: `GameHomeView.swift` uses `@State` instead of `@AppStorage` for format and strategy, collapsed advanced options, and due-first ordering without a shuffle at the call site. UI smoke `testNewSessionResetsAdvancedLaunchSettings` passed on simulator (`/tmp/botai_launch_reset_ui_20261022.log`). The persistence/resume workflow is not yet implemented; the existing `LearnSessionView` resets its question index to zero on construction and saves aggregate sessions, not a durable question cursor.

Next work: design durable session snapshot keyed by stable question identifiers and store/retrieve it through the existing repository; make the primary button say `ПРОДОЛЖИТЬ` when resumable; add restart/resume UI tests and crash-safe checkpoints, including correct cleanup on completion. Respect user-owned Xcode project changes.

## Release and testing boundary — accepted 2026-10-22

**Current project phase: LOCAL DEVELOPMENT AND TESTING ONLY.** Do not publish BOTAI to the App Store, upload builds to TestFlight, create a public release, push to remote GitHub, deploy Supabase migrations, or touch the physical iPhone unless the owner explicitly authorizes the particular action. Run tests locally on the Mac and disposable iOS simulators; use isolated test databases and preserve user data. Release-readiness documentation is for future planning, not authorization to publish. Continue implementing and testing the accepted MVP without treating App Store submission as the current milestone.
