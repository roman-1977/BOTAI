# Stage 6 — Sync/Auth/Security verification

- iOS stores attempts and original text snapshots transactionally in account-scoped SQLite.
- Server question/version mappings are verified under the authenticated user's RLS session.
- Publication uses deterministic IDs (user + local ID + content) and conflict-ignore inserts to make retries idempotent.
- Edited/deleted materials cannot redirect historical attempts to the new question version.
- Pending text-only historical attempts can publish their original snapshot and upload after restart.
- Uploads are acknowledged only after the server returns the matching stored attempt; retry preserves history.
- Flush runs on login/bootstrap, new attempt, and app foreground activation.
- Choice and media/LaTeX cards are not yet supported by this text publication path; their attempts stay local.

## Verification

- `BOTAI_SUPABASE_URL=https://gdkjcfrzxrjdscutxffc.supabase.co python3 backend/tests/live_rls_probe.py` — 11/11 RLS checks passed on 2026-10-21.
- `LiveSupabaseSyncTests` was run explicitly against the development Supabase project on 2026-10-21 and passed: publish, publish retry, attempt upload/ACK retry, recovery from an answer-time snapshot without the current card.
- To rerun the live Swift test, set `BOTAI_RUN_LIVE_SYNC=1` in the Xcode test scheme environment and select `LiveSupabaseSyncTests`. It creates temporary anonymous accounts and data in the development project.
- Unit/UI tests use the iPhone 16 Pro Max iOS 18.6 simulator; a transient accessibility connection failure in the full UI suite passed when the failed case was rerun alone.
