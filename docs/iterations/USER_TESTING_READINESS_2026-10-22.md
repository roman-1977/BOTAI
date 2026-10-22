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
