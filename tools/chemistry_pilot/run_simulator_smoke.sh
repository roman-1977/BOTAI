#!/usr/bin/env bash
# Run ONLY on a disposable iOS simulator. Never target a physical device.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SIMULATOR_ID="${1:?Usage: run_simulator_smoke.sh DISPOSABLE_SIMULATOR_UDID}"
APP_ID=com.roman1977.botai
APP_DATA="$(xcrun simctl get_app_container "$SIMULATOR_ID" "$APP_ID" data)"
DB="$APP_DATA/Library/Application Support/BOTAI-UITests/learning.sqlite"
[[ -f "$DB" ]] || { echo "Missing migrated BOTAI-UITests database: $DB" >&2; exit 1; }
# Only modify the UI-test database in the explicitly chosen simulator.
xcrun simctl terminate "$SIMULATOR_ID" "$APP_ID" >/dev/null 2>&1 || true
mkdir -p "$ROOT/.build/chemistry-pilot"
BACKUP="$ROOT/.build/chemistry-pilot/ui-test-before-seed-$(date +%Y%m%d-%H%M%S).sqlite"
sqlite3 "$DB" ".backup '$BACKUP'"
echo "UI-test DB backup: $BACKUP"
python3 "$ROOT/tools/chemistry_pilot/seed_local_sqlite.py" --db "$DB" --apply --reset-learning-data
xcodebuild -project "$ROOT/ios/BOTAI.xcodeproj" -scheme BOTAI \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -only-testing:BOTAIUITests/ChemistryPilotSmokeTests \
  -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO
