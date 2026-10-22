# BOTAI v0.3.0 — iPhone installation readiness (2026-10-22)

## Confirmed

- `xcodebuild -project ios/BOTAI.xcodeproj -scheme BOTAI -configuration Debug -destination 'generic/platform=iOS' -allowProvisioningUpdates build` succeeded (log `/tmp/botai_device_build_oct22.log`).
- The resulting Debug-iphoneos/BOTAI.app is signed with Apple Development certificate for team `RW79ZHJQP2`, bundle ID `com.roman1977.botai`.
- iOS deployment target is 18.0. Xcode reported an interface-orientation warning; not a build failure.
- CoreDevice sees `My Precious` (iPhone 17 Pro Max) connected, `Liza iPhone` paired/available and a third iPhone unavailable. A provider warning also appears in `devicectl` output; device installation is not yet verified.
- Most recent joint simulator regression before PDF stress test: 102 Swift tests and 11 UI tests passed. PDF stress tests 4/4 passed after visual QA.

## Installation decision / safety

Do not automatically install over `com.roman1977.botai` on a physical device: an existing installation may contain valuable local/offline study data. Before installation, verify whether BOTAI is already installed on the selected phone, back up its data if present, and confirm the target device. Installing or replacing an app can trigger migration; uninstalling deletes local container data. No physical-device installation or account sign-in has been performed in this checkpoint.

## Remaining gates before beta

1. Confirm target iPhone and backup state; install signed Debug build and test launch/relaunch and database migrations without wiping user data.
2. Test offline learning, `.botai` import/export, storage pressure/failure, app relaunch, sync recovery and account switch on a real phone.
3. Review compact/large text, VoiceOver and reduced motion on device.
4. Decide whether demo/placeholder content should be hidden for beta, and complete Apple privacy/App Store release checks.
5. Run final full regression and tag candidate only after physical-device acceptance.

The app is **buildable and signed for iPhone**, not yet validated as installed or ready for App Store distribution.
