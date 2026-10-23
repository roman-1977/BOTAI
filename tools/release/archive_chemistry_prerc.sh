#!/usr/bin/env bash
# Creates an UNSIGNED, non-installable iOS device archive for pre-release audit.
# Deliberately never exports an IPA, uploads, signs or changes the Xcode project.
set -euo pipefail
cd "$(dirname "$0")/../.."
version="${BOTAI_RELEASE_VERSION:-0.3.0}"
build="${BOTAI_RELEASE_BUILD:-1}"
archive="${BOTAI_ARCHIVE_PATH:-/tmp/BOTAI-Chemistry-${version}-PreRC.xcarchive}"
log="${BOTAI_ARCHIVE_LOG:-/tmp/botai_chemistry_prerc_archive.log}"
case "$version" in *[!0-9.]*|'') echo 'Invalid version' >&2; exit 2;; esac
case "$build" in *[!0-9]*|'') echo 'Invalid build' >&2; exit 2;; esac
if [[ "${BOTAI_VERIFY_ONLY:-0}" == 1 ]]; then
  [[ -d "$archive" ]] || { echo "Missing archive: $archive" >&2; exit 2; }
else
  if [[ -e "$archive" ]]; then
    echo "Archive already exists; choose a new BOTAI_ARCHIVE_PATH: $archive" >&2
    exit 2
  fi
  xcodebuild -project ios/BOTAI.xcodeproj -scheme BOTAI -configuration Release \
    -destination 'generic/platform=iOS' -archivePath "$archive" archive \
    CODE_SIGNING_ALLOWED=NO GENERATE_INFOPLIST_FILE=YES \
    MARKETING_VERSION="$version" CURRENT_PROJECT_VERSION="$build" > "$log" 2>&1 || {
      tail -40 "$log" >&2; exit 1;
    }
fi
app="$archive/Products/Applications/BOTAI.app"
plist="$app/Info.plist"
[[ -f "$plist" && -f "$app/BOTAI" && -f "$app/Assets.car" ]]
read_plist() { /usr/libexec/PlistBuddy -c "Print :$1" "$plist"; }
[[ "$(read_plist CFBundleIdentifier)" == 'com.roman1977.botai' ]]
[[ "$(read_plist CFBundleShortVersionString)" == "$version" ]]
[[ "$(read_plist CFBundleVersion)" == "$build" ]]
xcrun --sdk iphoneos assetutil --info "$app/Assets.car" | grep -m 1 '"Name" : "ChemistryPilot"' >/dev/null
if codesign --verify "$app" >/dev/null 2>&1; then
  echo 'Unexpected signature: this script is for unsigned pre-release audit only' >&2
  exit 1
fi
printf 'PASS unsigned iOS archive: %s\nBundle: %s; version: %s (%s); ChemistryPilot asset present\nNot installable; signing and distribution still required.\n' "$archive" "$(read_plist CFBundleIdentifier)" "$version" "$build"
