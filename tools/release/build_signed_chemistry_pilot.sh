#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
# Explicit overrides: do not modify/stage the owner's local project.pbxproj edits.
DERIVED_DATA="${BOTAI_PILOT_DERIVED_DATA:-/tmp/BOTAI-0.3.0-Pilot-Final}"
xcodebuild -project ios/BOTAI.xcodeproj -scheme BOTAI -configuration Debug \
  -destination 'generic/platform=iOS' -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=RW79ZHJQP2 \
  MARKETING_VERSION=0.3.0 CURRENT_PROJECT_VERSION=2 build
APP="$DERIVED_DATA/Build/Products/Debug-iphoneos/BOTAI.app"
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Info.plist" | grep -qx '0.3.0'
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Info.plist" | grep -qx '2'
codesign --verify --deep --strict "$APP"
test -f "$APP/embedded.mobileprovision"
printf 'PILOT_SIGNED_BUILD_PASS app=%s version=0.3.0(2)\n' "$APP"
