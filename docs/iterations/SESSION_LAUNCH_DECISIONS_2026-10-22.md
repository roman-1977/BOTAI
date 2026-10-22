# Session launch decisions — 2026-10-22

Approved product decisions:

1. New session launch is frictionless: choose a scope (topic, subject, mixed, or quick-start) and start directly. Do not force a configuration or confirmation step.
2. Fine controls are hidden in a collapsed `Дополнительные настройки` disclosure. They can override question format (cards/tests/mixed) and strategy (automatic/all) for **one new session only**.
3. Every **new** session uses system defaults again; manual overrides must not persist as defaults. Continuing an unfinished session must restore its original configuration, question order, current question, and recorded answers rather than recompute.
4. Teacher supplies guidance (priorities, targets, difficulty, pace); the **system** decides an adaptive strategy using that guidance and current student performance. Teacher guidance is an input, not a rigid override.
5. Present implementation is a limited automatic baseline: due questions first, then other questions. Full adaptive strategy and teacher recommendation storage/priority integration remain **pending**; do not represent baseline as completed adaptive learning.

Implementation checkpoint: `GameHomeView.swift` uses `@State` instead of `@AppStorage` for format and strategy, collapsed advanced options, and due-first ordering without a shuffle at the call site. UI smoke `testNewSessionResetsAdvancedLaunchSettings` passed on simulator (`/tmp/botai_launch_reset_ui_20261022.log`). The persistence/resume workflow is not yet implemented; the existing `LearnSessionView` resets its question index to zero on construction and saves aggregate sessions, not a durable question cursor.

Next work: design durable session snapshot keyed by stable question identifiers and store/retrieve it through the existing repository; make the primary button say `ПРОДОЛЖИТЬ` when resumable; add restart/resume UI tests and crash-safe checkpoints, including correct cleanup on completion. Respect user-owned Xcode project changes.

## Release and testing boundary — accepted 2026-10-22

**Current decision: no App Store publication and no TestFlight upload until separate owner approval.** Continue normal development, local testing and other project workflows under their existing permissions and safeguards. This decision imposes no new restrictions on GitHub, Supabase, or physical-device testing. Release-readiness documentation is informational, not authorization to publish.

2026-10-22 scope audit: fixed `SessionLaunchPicker.launchRow` attribution resolution to consider **all** course references rather than only the selected topic/subject. A question reused by another topic must remain unattributed, even when the user launches a single topic; otherwise its aggregate could be falsely assigned. Existing shared-question and unique-question resolver tests exercise this invariant. Full unit suite 137/137 PASS (`/tmp/botai_full_attribution_scope_20261022.log`). Adaptive teacher-guidance integration is still pending; do not label due-first baseline as full adaptive strategy.

Adaptive planner hardening (2026-10-22): removed random shuffling from goal question-set selection and used a stable question-ID tie-breaker. Due-date comparison now uses the planning date passed to DailyPlanner.make instead of the wall clock. This improves reproducibility of a plan for a given snapshot; it does not complete teacher-guided adaptive prioritization. Full unit regression 137/137 PASS (`/tmp/botai_adaptive_verified_20261022.log`).

## Superseding accepted decisions and verified implementation — 2026-10-22

This section supersedes the outdated review-only strategy, non-resumable status, and next-work statements above. **There is no separate review strategy or review quick-start.** A session always covers the selected topic, subject, or mixed scope. Automatic mode orders due/weak questions before new questions and not-yet-due reinforcement, without excluding new questions when no review is due. All mode retains all eligible questions. The collapsed format settings select mixed/cards/tests for this session only. Duplicate question IDs are included once. Equal-priority questions preserve authored order.

A durable local resumable-session snapshot and atomic answer/cursor persistence are implemented. Focused answered-question restart and unanswered-question restart both pass. Full post-change simulator regression: **137/137 unit and 16/16 standard UI PASS** (`/tmp/botai_final_session_gate_20261022.log`, exit 0). Full teacher-guided adaptive selection remains **not implemented**. See `docs/iterations/SESSION_MODE_MATRIX_2026-10-22.md` for missing acceptance coverage and `docs/releases/RC_0.3.0_READINESS.md` for release gates.
