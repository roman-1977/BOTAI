# Xcode device signing diagnostic — 2026-10-23

Pilot distribution is **direct Xcode installation**, not TestFlight/App Store. Do not require an Apple Distribution identity or App Store profile for the pilot.

Command: `xcodebuild -project ios/BOTAI.xcodeproj -scheme BOTAI -configuration Debug -destination 'platform=iOS,id=201AC996-019D-5C5B-B50C-FB35547DBA82' -derivedDataPath /tmp/BOTAI-Device-Signing-Diagnostic CODE_SIGN_STYLE=Automatic build`.

**BUILD SUCCEEDED**, exit 0, 49.69 s. Signed app `/tmp/BOTAI-Device-Signing-Diagnostic/Build/Products/Debug-iphoneos/BOTAI.app`. Verified `codesign`: identifier `com.roman1977.botai`, **Apple Development: Roman Arzumanov**, Team `RW79ZHJQP2`; embedded provisioning profile exists; entitlement `com.apple.developer.applesignin = [Default]`; application identifier `RW79ZHJQP2.com.roman1977.botai`.

Connected device `My Precious` (iPhone 17 Pro Max, ID `201AC996-019D-5C5B-B50C-FB35547DBA82`) was passcode-locked during build, causing benign `notification_proxy` warnings; **the build and signing succeeded**, but installation, launch and real Apple login were **not performed**. Additional paired devices: `Liza iPhone` iPhone 17 Pro Max, `iPhone 💘🎀` iPhone 15 Pro Max. Confirm the actual pilot device mapping before installing.

Supabase Apple native provider enabled for `com.roman1977.botai`; public backend checks pass. Remaining pilot gates: installation and real Apple ID login on device(s), email login, offline/restart/reconnect, two-account hosted aggregate sync and RLS isolation, regression after any changes. Avoid modifying/staging the user-owned `ios/BOTAI.xcodeproj/project.pbxproj`.
