#!/usr/bin/env bash
# Read-only pre-release gate. Does not create accounts, write database rows,
# run migrations, alter Supabase configuration, or print the public API key.
set -euo pipefail
cd "$(dirname "$0")/../.."
config=ios/BOTAI/Infrastructure/SupabaseConfiguration.swift
project_url=$(sed -n 's/.*static let projectURL = URL(string: "\([^"]*\)".*/\1/p' "$config")
key=$(sed -n 's/.*static let publishableKey = "\([^"]*\)".*/\1/p' "$config")
[[ "$project_url" == https://*.supabase.co && -n "$key" ]] || { echo 'Invalid app backend config' >&2; exit 2; }
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
failed=0
settings_status=$(curl -fsS --connect-timeout 8 --max-time 20 -o "$work/settings.json" -w '%{http_code}' -H "apikey: $key" "$project_url/auth/v1/settings")
python3 - "$work/settings.json" <<'PY' || failed=1
import json,sys
settings=json.load(open(sys.argv[1]));providers=settings.get('external',{})
print('EMAIL_PROVIDER', 'ENABLED' if providers.get('email') else 'DISABLED')
print('APPLE_PROVIDER', 'ENABLED' if providers.get('apple') else 'DISABLED')
print('EMAIL_CONFIRMATION', 'REQUIRED' if not settings.get('mailer_autoconfirm') else 'AUTO')
if not providers.get('email') or not providers.get('apple'): sys.exit(1)
PY
for table in completed_session_summaries completed_session_topic_aggregates; do
  status=$(curl -sS --connect-timeout 8 --max-time 20 -o "$work/$table.json" -w '%{http_code}' \
    -H "apikey: $key" -H "Authorization: Bearer $key" \
    "$project_url/rest/v1/$table?select=session_id&limit=1")
  python3 - "$table" "$status" "$work/$table.json" <<'PY' || failed=1
import json,sys
name,status,path=sys.argv[1:]
try: data=json.load(open(path))
except (OSError,ValueError): data={}
if status=='404' and isinstance(data,dict) and data.get('code')=='PGRST205':
    print(name, 'NOT_EXPOSED_IN_PUBLIC_SCHEMA_CACHE')
    sys.exit(1)
elif status in ('401','403') and isinstance(data,dict) and data.get('code') in ('42501','PGRST301'):
    print(name, 'EXISTS_AUTH_REQUIRED_RLS', 'http='+status)
elif status=='200' and isinstance(data,list):
    print(name, 'VISIBLE_TO_ANON', 'rows='+str(len(data)))
else:
    print(name, 'HTTP_'+status, 'code='+str(data.get('code') if isinstance(data,dict) else 'unknown'))
    sys.exit(1)
PY
done
if [[ "$failed" != 0 ]]; then
  echo "RELEASE_BACKEND_GATE=BLOCKED" >&2
  exit 1
fi
echo "RELEASE_BACKEND_GATE=PUBLIC_CHECKS_PASS"
