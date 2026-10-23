# Chemistry learner release gate — release first, installation later
> **IOS DEVICE ARCHIVE AUDIT 2026-10-23:** unsigned Release **arm64 iOS archive 0.3.0 (1) PASS**, compiled ChemistryPilot asset verified; `/tmp/BOTAI-Chemistry-0.3.0-PreRC.xcarchive`. Reproducible read-only audit `tools/release/archive_chemistry_prerc.sh`. **Not signed/installable**; hosted auth/sync and distribution signing remain blockers. See `docs/iterations/CHEMISTRY_IOS_ARCHIVE_AUDIT_2026-10-23.md`.


Owner decision 2026-10-23: **complete a verifiable release candidate before any installation on either physical phone**. Installation/physical-device acceptance is a subsequent stage, not a prerequisite for finishing the release build. No physical installation, TestFlight upload, App Store submission, or production migration is authorized by this decision.

## Scope of the first release

Two separate students, independent accounts on iPhone 15 Pro Max and iPhone 16 Pro Max, fresh start, chemistry course immediately available, staged inorganic → organic → full review at 70%, durable offline SQLite learning from the first answer, account login/logout/relogin, aggregate-only server sync. The teacher owns educational completeness and correctness. Existing broader public MVP requirements remain on the later roadmap.

## Release build evidence

- **PASS:** Release configuration, generic iOS Simulator, unsigned, `xcodebuild` exit 0, `** BUILD SUCCEEDED **`: `/tmp/botai_chemistry_release_build_20261023.log`. This is not a signed iOS archive or installable IPA.
- **PASS:** iPhone 16e simulator 183/183 unit and 27/27 UI before the new auth-entry UI test: `/tmp/botai_chemistry_install_full_final.log`.
- **PASS:** new auth-entry UI test: Apple button, email login/registration/recovery sheet, invalid empty credentials disabled, no network account creation attempted. `/tmp/botai_release_auth_ui_20261023.log`. Does **not** verify real provider authentication.
- **PASS:** bundled chemistry smoke on iPhone 15 Pro Max and iPhone 16 Pro Max simulators; two chemistry UI tests on iPhone 16e. See `docs/iterations/RELEASE_TARGET_DECISION_2026-10-23.md`.
- **PASS:** final complete serial iPhone 16e simulator regression including the new auth-entry test: **183/183 unit + 28/28 UI PASS**, `xcodebuild` exit 0, `** TEST SUCCEEDED **`, 747.96 seconds, `/tmp/botai_pre_rc_full_20261023.log`.

## Release blockers — not waived

1. **Hosted auth:** real disposable Supabase Apple and email registration, email verification/recovery, logout/relogin and account isolation have not been end-to-end tested. Developer capability and Supabase Apple provider settings must be verified. Do not fabricate a login result or use a production user account without permission.
2. **Durability:** test a multi-day chemistry sequence, completed sessions, app restart, offline learning, reconnect, updates, switching between two distinct accounts; assert zero lost or cross-account answers.
3. **Sync:** validate aggregate-only summary/topic ACK against a controlled hosted development backend for both users, RLS and idempotency; detailed attempts stay local by design.
4. **Distribution:** validate signed Release archive, entitlement/provisioning profile, version/build numbers, release notes, privacy/account handling and installation method. No TestFlight/App Store upload without separate approval.
5. **UI/accessibility:** review final no-scroll home, Dynamic Type/VoiceOver/Reduce Motion and error paths. Simulator smoke is not physical-device acceptance.

## Stop condition

Mark `RELEASE CANDIDATE READY` only when all pre-install release gates are satisfied with evidence. Then request authorization for the **separate** physical installation phase. Do not equate unsigned simulator Release build with release completion. The independently edited `ios/BOTAI.xcodeproj/project.pbxproj` remains untouched and unstaged.

## Signing audit (read-only)

Xcode project settings report `DEVELOPMENT_TEAM = RW79ZHJQP2`, app bundle `com.roman1977.botai`, `MARKETING_VERSION = 0.1.0`, build `CURRENT_PROJECT_VERSION = 1` (settings may differ by target). Local keychain contains `Apple Development: Roman Arzumanov (KF45J6CD3W)` and `Developer ID Application: Roman Arzumanov (RW79ZHJQP2)`; **no Apple Distribution certificate appeared** in the read-only `security find-identity -v -p codesigning` result. Do not conflate Developer ID (macOS) with iOS distribution. Signing profile/entitlement verification and archive remain blocked pending an authorized Apple Developer configuration check. The user-owned project file is not changed automatically.
