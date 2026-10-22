# BOTAI 0.3.0 — local simulator release build checkpoint

- Source commit: `944a12b` (`feature/v0.3.0-chemistry-pilot`).
- Release configuration, iOS Simulator arm64: **BUILD SUCCEEDED**, `/tmp/botai_rc_build_20261022.log`.
- App bundle: `/tmp/botai_rc_030_20261022/Build/Products/Release-iphonesimulator/BOTAI.app` (local Mac only; simulator binary, not signed iPhone IPA).
- Installed and launched successfully on disposable simulator `33176212-1247-4722-B8F4-4E53438502E4` (`simctl install` and `simctl launch` both exit 0).
- Unit tests: **137/137 PASS**, `/tmp/botai_adaptive_verified_20261022.log`.
- Standard UI: **15/15 PASS** in `/tmp/botai_release_ui_20261022.log`; overall combined xcodebuild exited 65 because it also ran two chemistry tests without seeding. Do not claim that combined invocation passed.
- Seeded chemistry UI: **2/2 PASS**, `/tmp/botai_chemistry_rc_20261022.log` after running `tools/chemistry_pilot/run_simulator_smoke.sh` on disposable simulator.
- Known blockers for calling this a fully accepted MVP release: RC-04 teacher-guided adaptive selection unverified/incomplete; RC-05 physical visual/accessibility acceptance missing; RC-06 Supabase migrations 0025/0026 and RLS not applied/validated against a disposable database, live reconnect not validated; RC-07 public moderation/UGC review incomplete. Device-signed IPA not built.
- Existing user-owned uncommitted `ios/BOTAI.xcodeproj/project.pbxproj` deliberately left untouched.
- App Store and TestFlight publication explicitly deferred by user; neither was attempted.

**Status:** local simulator Release build available for inspection; **NOT** a signed distributable release or completed RC acceptance.
