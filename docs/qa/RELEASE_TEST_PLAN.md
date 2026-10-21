# BOTAI release verification — execution plan

Baseline date: 2026-10-21. Source revision at start: `69eb56d` (`main`).

## Execution rules

1. Work in nine sequential stages. Do not mark a stage complete without artifacts and reproducible verification.
2. Record PASS, FAIL, BLOCKED or NOT RUN for each case. A successful build is not a test pass.
3. Reproduce defects, add regression coverage where feasible, fix, then rerun impacted cases.
4. Preserve local user data; never run destructive tests against real personal accounts or databases.
5. Simulator and physical-iPhone outcomes must be recorded separately with OS/device/build.
6. Commit stage results with evidence; distinguish code-complete from externally blocked release steps.

## Baseline inventory

- Xcode 26.4; iOS minimum 18.0; app identifier `com.roman1977.botai`; app version 0.1.0 (build 1).
- SwiftUI app; GRDB, Supabase, ZIPFoundation; XcodeGen project at `ios/project.yml`.
- 63 Swift application files, including 22 files in `Features` and 16 in `Services`.
- Seven unit-test source files, 15 `@Test` cases detected; **no UI-test target** declared in `ios/project.yml`.
- 30 `try?` occurrences in application Swift files require write-path review (not all necessarily bugs).
- Simulators installed for iOS 18.4, 18.6 and 26.4. Two iPhone 17 Pro Max devices appear paired; execution on hardware NOT YET VERIFIED.
- Current product/implementation gap inventory: `docs/IMPLEMENTATION_STATUS.md` (2026-10-01 snapshot).

## Stage gates

| Stage | Scope | Evidence required |
| --- | --- | --- |
| 1 | Inventory and baseline | Source/test inventory, build result, feature matrix, risk register |
| 2 | Test harness | Deterministic isolated database, XCTest and XCUITest target, repeatable simulator run |
| 3 | Materials/cards | Import/export, parsing, missing fields, distractors, delete, malformed archive regression |
| 4 | Courses/study | Course/goal CRUD, all learning modes, scheduling, interruptions, end-to-end UI |
| 5 | Persistence/history | Migrations, restart, transactions, statistics, delete/history invariants |
| 6 | Auth/sync/security | Offline, auth/account separation, retries, server sync, privacy and data isolation |
| 7 | Refactor/performance | Error propagation, modular session logic, profiling, full regression |
| 8 | Physical iPhone | Install, real-device workflows, backgrounding, network loss, performance |
| 9 | Release | Release archive, final simulator/device regression, compliance and TestFlight readiness |

## Functional test matrix (initial)

| Area | Critical scenarios | Current evidence |
| --- | --- | --- |
| App launch/navigation | Fresh install, relaunch, tabs, empty states, offline launch | NOT RUN |
| Material library | Create/edit/delete, CSV/TSV, `.botai` round-trip, invalid/oversized archives | Unit coverage partial; UI NOT RUN |
| Card generation | Bidirectional synonym, Q&A, single/multi-choice, empty columns, four choices | Unit coverage partial; UI NOT RUN |
| Courses/goals | Create/edit/delete, references, goal planning, cascading behavior | Deletion unit coverage partial; UI NOT RUN |
| Study | All modes, correct/incorrect, interruption, session persistence, due scheduling | Unit coverage partial; UI NOT RUN |
| Progress | Attempts, mastery, streak, daily goals, history after content deletion | Unit coverage partial; UI NOT RUN |
| Local storage | GRDB migration v1–v7, corruption, atomic writes, reinstall/relaunch | Unit coverage partial; upgrades NOT RUN |
| Accounts/sync | Login/logout, offline outbox, retries, multi-account isolation, conflict | NOT RUN; known implementation gaps |
| Accessibility | Dynamic Type, VoiceOver labels, touch targets, contrast | NOT RUN |
| Release | Release build/archive, signing, entitlements, privacy, App Store checklist | NOT RUN |

## Known release blockers / risks

- No UI-test target; UI automation cannot run until stage 2.
- User-visible persistence write paths may suppress failures via `try?`.
- Material-reference cleanup and deletion must be made atomic or failure-safe.
- Multi-device sync and private per-account database isolation are incomplete according to implementation status; do not label these features release-ready.
- `.botai` archive extraction needs resource and path validation.
- Historical labels after content deletion are not retained.
- Physical-device provisioning warning observed during device discovery; paired status alone is not a passing install/test.

## Execution log

- 2026-10-21: Confirmed clean `main` at `69eb56d`, source/test inventory and available simulator/device list. Baseline Debug build for generic iOS Simulator PASSED (`xcodebuild -project ios/BOTAI.xcodeproj -scheme BOTAI -configuration Debug -destination "generic/platform=iOS Simulator" -derivedDataPath /tmp/botai_release_audit_derived CODE_SIGNING_ALLOWED=NO build`); 44.85 s, exit 0. AppIntents metadata warning is non-blocking. No test execution claimed.

## Stage 1 acceptance

- PASS: Repository status and baseline revision recorded.
- PASS: Application/service and test-source inventory, dependencies and deployment target recorded.
- PASS: Simulator and paired-device discovery recorded.
- PASS: Baseline Debug simulator compilation verified.
- PASS: Feature coverage matrix, release risks and stage gates documented.
- NOT RUN: Unit/UI tests and real-device deployment; scheduled for stages 2 and 8 respectively.
- Stage 1 is an inventory/diagnostic gate only; a green build is not a release approval.
