# BOTAI 0.3.0 — Chemistry Pilot (direct Xcode installation)

**Owner decision 2026-10-23:** approve a bounded private chemistry pilot release, installed directly from Xcode. This is **not** an App Store/TestFlight release, and it is **not** a declaration that every broad MVP RC-01…RC-10 gate has passed. The owner accepts starting physical learner acceptance after the release candidate is assembled.

## Scope

- Two separate student accounts, independent on-device SQLite progress and learning history.
- 323 bundled chemistry questions, 323 four-choice representations, 102 materials, 25 topics, 5 sections; inorganic → organic → review, 70% section mastery, due/weak before new.
- Cards, pairs, single/multiple-choice where content supports them; launch by subject/topic/mixed, offline resume, local streak/progress, teacher-guidance seed and Today summary.
- Native Apple ID plus email/password/reset; Supabase email confirmation remains required. Only completed-session and topic aggregates sync; individual attempts remain on device.

## Verified before release

- Last completed full simulator regression: 184/184 unit + 28/28 UI PASS (2026-10-23, `/tmp/botai_two_student_full_verified_20261023.log`).
- Signed Debug iPhoneOS device build PASS with Apple Development certificate, correct Team ID, bundle, embedded profile and Apple Sign In entitlement. Build and entitlement evidence: `docs/iterations/DEVICE_SIGNING_DIAGNOSTIC_2026-10-23.md`.
- Live Supabase Apple provider enabled, native Client ID `com.roman1977.botai`; two aggregate tables deployed, ownership RLS and authenticated-only access verified; `tools/release/check_live_auth_and_schema.sh` exits 0.
- Production migrations 0025/0026 have **remote-generated** ledger versions `20261023145228` and `20261023145243`; reconcile history before any future migration push. No repeated migration application.

## Versioned build (important)

The locally modified `project.pbxproj` still sets `MARKETING_VERSION=0.1.0` and `CURRENT_PROJECT_VERSION=1`, overriding values in `Info.plist` during Xcode build. To produce the versioned pilot **without editing or staging that user-owned file**, run `tools/release/build_signed_chemistry_pilot.sh` (explicit `MARKETING_VERSION=0.3.0 CURRENT_PROJECT_VERSION=2` overrides). An ordinary Xcode Run currently produces 0.1.0 (1) despite the source Info.plist update; resolve this in Xcode project settings separately if persistent 0.3.0 display is desired.

## Installation and first-run acceptance

1. Connect/unlock the intended iPhone, trust the Mac, enable Developer Mode if Xcode prompts. In Xcode open `ios/BOTAI.xcodeproj`, scheme `BOTAI`, choose the actual device and Run. Automatic signing should select Team `RW79ZHJQP2`. Do **not** delete the existing app or local database when upgrading.
2. Create/sign into each student's **own** account (Apple ID first; email/password alternative with email confirmation). Never share a login. Confirm first-run chemistry, subject/topic launch, cards and choices, inorganic route and 70% transition.
3. Study offline, force-close, relaunch offline, confirm session/progress survives. Restore network, complete a session, check no duplicate upload on retry. Sign out/change account and confirm local isolation. Confirm server-side session/topic aggregate counts under each authenticated user and absence of cross-user visibility.
4. Report device model, iOS version, authentication path and any error messages; never send passwords or tokens.

## Explicit residual risks / follow-up

- Real native Apple credential exchange, email delivery, multi-account hosted sync/RLS and two-device end-to-end are **not yet validated**. Physical pilot is the planned acceptance stage, not already completed.
- No final accessibility/VoiceOver, Dynamic Type and no-scroll physical sign-off; broad RC-04 teacher workflow and RC-07 UGC operations remain outside the bounded chemistry pilot and in the implementation plan.
- Distribution via App Store or TestFlight needs separate approval and release hardening.
- Do not stage, revert or overwrite the user's local changes to `ios/BOTAI.xcodeproj/project.pbxproj`.

## Final versioned signing evidence

`xcodebuild ... -configuration Debug -destination generic/platform=iOS -derivedDataPath /tmp/BOTAI-0.3.0-Pilot-Final CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=RW79ZHJQP2 MARKETING_VERSION=0.3.0 CURRENT_PROJECT_VERSION=2 build` returned **BUILD SUCCEEDED, exit 0**. Built app `/tmp/BOTAI-0.3.0-Pilot-Final/Build/Products/Debug-iphoneos/BOTAI.app` reports **0.3.0 (2)**; `codesign --verify --deep --strict` exit 0, Apple entitlement `[Default]`, embedded profile, 35 MB. This is a **signed Debug device build**, not an App Store IPA.

## Final simulator acceptance (2026-10-23)

**184/184 Swift unit tests + 28/28 UI tests PASS**, exit 0, `** TEST SUCCEEDED **` (iPhone 16e simulator, `/tmp/botai_chemistry_release_final_20261023.log`). Two seeded chemistry UI tests included in the 28. This is the final pre-pilot automated regression. Versioned signed build 0.3.0 (2) PASS; `codesign --verify --deep --strict` exit 0. **Owner-approved private chemistry pilot candidate is READY FOR DIRECT XCODE DEVICE INSTALLATION**, with physical/hosted acceptance explicitly pending.

## Release evidence

See `docs/releases/RC_0.3.0_READINESS.md`, `docs/iterations/CURRENT_HANDOFF_AND_PROMPT.md` and the final verification record in this file. No physical installation is claimed until actually observed.
