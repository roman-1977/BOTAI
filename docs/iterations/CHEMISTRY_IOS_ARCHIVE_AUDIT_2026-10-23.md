# Chemistry iOS device archive — 2026-10-23

**Owner order: release candidate first, physical installation only later.** This record concerns a local pre-release archive, **not** a release-ready signed artifact, TestFlight submission or installable IPA.

## Verified archive

- Xcode Release / `generic/platform=iOS` / **arm64**: `xcodebuild archive` exit 0, `** ARCHIVE SUCCEEDED **` (`/tmp/botai_030_prerc_archive_20261023.log`).
- Local output: `/tmp/BOTAI-Chemistry-0.3.0-PreRC.xcarchive` (on development Mac only).
- App bundle `com.roman1977.botai`, version **0.3.0 (1)**, minimum iOS **18.0** (original archive settings inspected; version overridden to 0.3.0 for final audit).
- Compiled `Assets.car` includes the `ChemistryPilot` dataset; executable is `arm64`.
- **Unsigned** by deliberate `CODE_SIGNING_ALLOWED=NO`; `codesign --verify` rejects it as expected. The archive is not installable and must not be represented as a finished release.
- Reproducible audit script: `tools/release/archive_chemistry_prerc.sh`; use `BOTAI_VERIFY_ONLY=1 bash tools/release/archive_chemistry_prerc.sh` to verify the existing archive without rebuilding. Audit PASS.

## Distribution blockers

1. The project currently defaults to `MARKETING_VERSION=0.1.0`, build 1. The 0.3.0 archive explicitly overrides the version on the command line, **without touching the user-owned modified `ios/BOTAI.xcodeproj/project.pbxproj`**. Agree and finalize canonical release version/build before signing.
2. Local signing audit found Apple Development and macOS Developer ID identities but no Apple Distribution identity; confirm Apple Developer team, provisioning and the Sign in with Apple entitlement before producing a signed archive/IPA.
3. Real hosted Apple/email registration, RLS, account isolation, aggregate sync and offline/reconnect acceptance remain unverified. The opt-in live test explicitly rejects the configured production Supabase host; it cannot be treated as a PASS against a real disposable backend without explicit environment configuration.
4. No physical iPhone installation or external distribution has been performed or authorized.

## Automated test baseline

Full serial simulator regression: **184/184 unit + 28/28 UI PASS** at `886b2a9` (`/tmp/botai_two_student_full_verified_20261023.log`). This archive is built from the same code with only release version overrides. No source code changed in this archive-audit block.
