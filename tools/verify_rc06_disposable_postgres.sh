#!/usr/bin/env bash
# Replay RC-06 SQL security fixtures against the pre-existing isolated test cluster.
# Never starts, migrates, or connects to a non-loopback/production database.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PG_BIN=/opt/homebrew/opt/postgresql@17/bin
CLUSTER=/tmp/botai_pg17_rls_20261022/data
PORT=55439
DB=botai_rls_disposable
if [[ ! -f "$CLUSTER/PG_VERSION" || ! -x "$PG_BIN/pg_ctl" || ! -x "$PG_BIN/psql" ]]; then
  echo 'Disposable PostgreSQL 17 cluster unavailable; no external fallback' >&2
  exit 2
fi
if "$PG_BIN/pg_ctl" -D "$CLUSTER" status >/dev/null 2>&1; then
  echo 'Refusing to operate on an already running cluster' >&2
  exit 2
fi
cleanup() { "$PG_BIN/pg_ctl" -D "$CLUSTER" -m immediate stop >/dev/null 2>&1 || true; }
trap cleanup EXIT
"$PG_BIN/pg_ctl" -D "$CLUSTER" -o "-h 127.0.0.1 -p $PORT" -w start >/dev/null
for fixture in \
  completed_session_summary_rls.sql \
  completed_session_topic_aggregate_rls.sql \
  completed_session_negative_permissions.sql; do
  echo "Running $fixture"
  "$PG_BIN/psql" -X -v ON_ERROR_STOP=1 -h 127.0.0.1 -p "$PORT" -d "$DB" -f "$ROOT/backend/tests/$fixture" >/dev/null
  echo "PASS $fixture"
done
