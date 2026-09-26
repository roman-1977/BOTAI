# BOTAI iOS Engineering Standards

Status: Accepted baseline before creation of the iOS target.

## Apple submission baseline

Use the current stable Xcode/toolchain for release builds. As of September 2026 App Store Connect requires Xcode 26+ and an iOS 26+ SDK; re-check Apple's Upcoming Requirements before every release. Deployment target is a product decision and must also satisfy Apple's current minimum target rules.

`CFBundleShortVersionString` uses three numeric components (`Major.Minor.Patch`). `CFBundleVersion` is a machine build identifier and must advance for distributed builds. Release automation owns build-number increments; developers do not hand-edit scattered version values.

## Swift and project structure

Use Swift 6 language mode and SwiftUI for new UI. Concurrency warnings are treated as design issues: prefer value types and `Sendable`, isolate mutable shared state, and keep UI state on `@MainActor`. Do not suppress concurrency diagnostics globally.

Use feature-oriented modules/folders with explicit dependency direction: App -> Features -> Domain -> Data/Infrastructure. Views do not call Supabase/HTTP/GRDB directly. Business rules live outside SwiftUI views and are unit-testable.

Use `.xcconfig` for build configuration and environment-specific non-secret values. Secrets, service-role credentials and private signing material never enter the repository or client bundle.

## Dependencies

Prefer Apple frameworks first. Add a third-party package only when it materially reduces risk or maintenance. Use Swift Package Manager by default and pin dependencies through the resolved package graph committed to source control for reproducible application builds.

Every dependency needs an owner/reason, license check, maintenance/security review, and privacy review. We are responsible for third-party code shipped in the app. SDK privacy manifests/signatures and required-reason API declarations must be valid for release.

## Privacy manifests and APIs

Keep an app `PrivacyInfo.xcprivacy` from the beginning, not as a release-week task. Declare app data collection and any required-reason API use accurately. Generate and review Xcode's privacy report before TestFlight/App Store submissions.

No private APIs, hidden review-only behavior, executable-code downloading, or deprecated API knowingly introduced into new code. Warnings from the current release Xcode are triaged before distribution.

## Formatting, naming and comments

Use Swift API Design Guidelines and Xcode formatting as the semantic baseline. Add SwiftFormat/SwiftLint only with a small repository-owned configuration; style tooling must not create noisy churn or override idiomatic Swift.

Names describe intent rather than implementation. Avoid unexplained abbreviations and giant `Manager` types. Files normally contain one primary type plus tightly related helpers.

Comments explain **why**, invariants, non-obvious tradeoffs and external constraints. Do not narrate obvious code. Public/shared APIs and non-obvious protocols use `///` documentation where it improves correct use. TODO/FIXME includes a concrete reason or tracked work item; dead commented-out code is deleted and recovered from Git if needed.

## Testing and quality gates

Domain rules, scheduling/reconciliation, persistence migrations and sync conflict behavior require unit/integration coverage. Critical user journeys receive UI tests once stable. Tests must be deterministic; clocks, UUID generation and network boundaries are injectable where needed.

Before merge/release: build with warnings reviewed, tests pass, formatter/linter pass when enabled, `git diff --check` passes, no secrets are detected, migrations are forward-tested, and offline behavior is exercised for local-first features.

Accessibility is implementation quality: Dynamic Type, VoiceOver semantics, sufficient contrast, Reduce Motion where relevant, and controls with platform-appropriate hit targets. User-visible strings live in localization resources rather than being scattered as literals through feature code.

## Git and schema discipline

`main` stays releasable. Changes are small enough to review and use descriptive commits. Database migrations already applied outside disposable development environments are immutable; corrections are new migrations. Local SQLite/GRDB migrations are versioned and tested against representative previous stores.

Generated files are either reproducibly generated and documented or intentionally committed; never maintain two manual sources of truth. Architecture decisions that constrain future work get an ADR before implementation diverges.

## Release discipline

Debug/staging/release configuration is explicit. Release builds use production endpoints and production entitlements without runtime secret switches. Archive validation, privacy report review, TestFlight smoke testing and App Store metadata/privacy-label review are part of the release checklist.

Apple requirements change. `docs/APPLE_REVIEW_CHECKLIST.md` governs product/review policy; this file governs engineering. Both are revalidated against current Apple documentation before a public submission.
