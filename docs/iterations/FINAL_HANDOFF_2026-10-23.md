# BOTAI — complete engineering handoff, 2026-10-23

## 0. READ THIS FIRST / authoritative current state

This document supersedes historical 0.3.0 pilot-release readiness claims for the **0.3.1 chemistry learner beta**. Owner authorized release for user testing and explicitly required **preserving all future learning data**. Never infer publication or real-device acceptance from successful simulator tests. Cross-check the release gate log, remote tag, and GitHub release before reporting published status. Old checkpoint banners elsewhere are historical, not current authority.

## 1. Source and release identification

- Repository: `roman-1977/BOTAI`, `https://github.com/roman-1977/BOTAI`.
- Working branch: `feature/v0.3.0-chemistry-pilot`; latest persistence commit `1e7c689`; preceding UI/default correction `a68de39`.
- Intended beta: `0.3.1 (3)`, Git tag `v0.3.1-chemistry-beta`, **GitHub prerelease**, signed Debug iPhoneOS build installed via Xcode. NOT TestFlight/App Store.
- Release script outside repo: `/tmp/botai_beta_release_gate.sh`; status `/tmp/botai_044_beta_release_gate.log`. Simulator full run `/tmp/botai_042_release_full.log`; signed build `/tmp/botai_043_beta_device_build.log`.
- **Release gates:** 1) full tests `TEST SUCCEEDED`; 2) signed device `BUILD SUCCEEDED`; 3) git push branch/tag succeeds; 4) GitHub prerelease exists. A partial result is not a published release. Confirm each step, record hash and remote URL.
- `ios/BOTAI.xcodeproj/project.pbxproj` has **pre-existing user modifications**: do not overwrite, stage or commit them. Set `MARKETING_VERSION=0.3.1 CURRENT_PROJECT_VERSION=3` as xcodebuild overrides. Verify actual built Info.plist, signing team, entitlement and embedded profile.

## 2. Product scope and current behavior

- iOS 18+ SwiftUI, offline SQLite, Supabase authentication/backend behind API abstraction. Goal: structured memorization, chemistry first, broader EGE MVP remains in scope.
- Bundled chemistry: 323 knowledge questions, 102 materials, 25 topics, 5 sections, deterministic idempotent per-account install; staged inorganic → organic at 70% then reinforcement. Curriculum correctness/completeness belongs to teacher and is not certified by engineering tests.
- Learning: recommended/daily goal defaults to objectively graded multiple-choice; cards selectable manually. Question order randomized within due/new/not-due priority; deduplicate knowledge. Study indicators compacted.
- **CRITICAL DATA POLICY:** no progress reset on cold launch or account switch. Preserve attempts, knowledge states, session checkpoints, stats, daily plan and course data across restarts. Local account data are isolated. UI fixtures may reset their own isolated storage via `-botai-reset-ui-test-data`; never invoke destructive reset on a learner device.
- **CRITICAL SYNC LIMITATION:** beta disables remote learning sync (`BOTAIApp.betaLearningSyncEnabled = false`) to prevent stale pre-release remote data being restored. This means no cloud backup or cross-device learning sync; do not promise either. Do not uninstall or change bundle ID after testing begins. Account login remains implemented but must be verified live on physical devices.

## 3. Quality evidence and open acceptance

- Prior 0.3.1 correction: 189/189 unit PASS (`/tmp/botai_037_units.log`); 28 distinct UI cases PASS across full 26/28 and targeted corrections (`/tmp/botai_038_ui.log`, `039`, `041`); not a clean single full run.
- Current full run after persistence correction: `/tmp/botai_042_release_full.log`, **outcome must be read and updated**; do not predeclare success. Physical iPhone installation and real-world two-user learning NOT YET VERIFIED.
- Remaining physical tests: install/update without wiping existing app data; sign in with Apple and email; logout/account switch, guest isolation; airplane mode, relaunch, interruption, next-day progress and 70% transition; reconnect without stale remote data; content and accessibility checks on intended iPhone 15 Pro Max and iPhone 16 Pro Max.
- On `My Precious` an older BOTAI 0.1.0 app with existing local database was found. A point-in-time SQLite backup exists outside Git at `~/BOTAI-device-backups/2026-10-22-My-Precious/learning.sqlite`; it is **not a full encrypted iPhone backup**. Never uninstall/replace without checking owner intent and backups.

## 4. Immediate next work after this handoff

1. Verify current full tests and release gate logs; fix any failure, rerun and update evidence; only then publish/tag.
2. Record actual remote commit/tag/GitHub release link and signed build metadata; update release notes and all top-level status banners with confirmed result, not projections.
3. Install on intended devices safely and conduct independent two-learner acceptance, capturing bugs and crash logs. Do not wipe existing user data.
4. Restore safe cloud progress persistence: inventory existing remote rows, define explicit migration/reconciliation (legacy pilot remote state vs authoritative local beta state), implement idempotent account-bound upload/download, conflict rules, offline queue and retry, RLS isolation; add unit/integration/UI and multi-device tests before enabling sync. No silent reset, overwrite or rehydration.
5. Finish outstanding broader MVP/teacher requirements without weakening approved decisions. Keep documentation, plan, test evidence and commits self-contained.

## 5. Mandatory rules for any new GPT/developer

- Start from `AGENTS.md`, `docs/CHATGPT_REPOSITORY_GUIDE.md`, `docs/iterations/CURRENT_HANDOFF_AND_PROMPT.md`, this handoff and `docs/iterations/V031_CHEMISTRY_BETA_RELEASE.md`; consult historical decisions before changing UX/architecture.
- No repeated micro-approvals: deliver complete functional blocks with code, regression, docs, plan, reproducible logs and commit.
- Explicitly report **unit passed/total, UI passed/total and remaining**; distinguish simulator from physical phone, build from install, local persistence from cloud sync, GitHub prerelease from App Store/TestFlight.
- Protect existing project-file edits and local user data. Never put credentials, auth tokens, personal databases or private backups in Git.
- Do not call an asynchronous background task successful until its completion and exit status are verified.

## 6. Suggested next-chat kickoff prompt

Continue BOTAI from `docs/iterations/FINAL_HANDOFF_2026-10-23.md`. First verify `/tmp/botai_042_release_full.log`, `/tmp/botai_044_beta_release_gate.log`, signed build, GitHub tag/release and current git status; finish any incomplete release gate. Never erase learner progress or touch preexisting `ios/BOTAI.xcodeproj/project.pbxproj` changes. Beta must preserve local SQLite progress; remote learning sync stays disabled until safe migration is implemented and tested. Report exact test counts and outstanding physical-device acceptance. Then prepare safe installation and a concrete cloud-persistence follow-up plan.
