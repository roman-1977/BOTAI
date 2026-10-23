# Live backend release gate — confirmed blockers (2026-10-23)

**Important: this is the first direct read-only check against the configured real Supabase project, not a simulator/mock assertion.** Checked the public endpoints using the app's existing publishable key. No accounts created, rows changed, migrations executed, or secret credentials exposed. Reproduce with `tools/release/check_live_auth_and_schema.sh`. **Release gate returns exit 1 (`RELEASE_BACKEND_GATE=BLOCKED`)** for the observed provider/schema blockers; a future public-check PASS would still require actual hosted two-account/RLS tests.

## Observed results

| Check | Result | Meaning |
| --- | --- | --- |
| Supabase Auth health with publishable key | HTTP 200 | Configured hosted Auth service responds |
| `/auth/v1/settings` | HTTP 200 | Public provider configuration accessible |
| Email provider | **ENABLED** | Email/password API enabled; not proof that email confirmation delivery works |
| Email confirmation | **REQUIRED** | Must verify actual confirmation mail and login with disposable test account |
| Apple provider | **DISABLED** | **Apple ID sign-in will not work** despite iOS UI and entitlement until provider is enabled/configured in Supabase Auth |
| `completed_session_summaries` via REST | **HTTP 404 PGRST205** | Table not found in exposed `public` schema cache; aggregate sync cannot work as configured |
| `completed_session_topic_aggregates` via REST | **HTTP 404 PGRST205** | Same for topic aggregate sync |
| `supabase migration list --linked` | **IPv6 unsupported** | CLI couldn't inspect remote migration history from current network; no migration applied |
| Local Supabase | **Docker/Podman absent** | Disposable local Supabase backend cannot be started in this environment without additional runtime |

The REST 404s are **not proof of physical table absence**: the tables may be missing, in a different schema, or not exposed to PostgREST. The two relevant SQL migrations are `backend/supabase/migrations/0025_completed_session_summaries.sql` and `0026_completed_session_topic_aggregates.sql`. Inspect remote schema/migration history and RLS/grants before applying changes; do not blindly run migrations on a production project.

## Required external configuration

1. In Supabase Dashboard → Authentication → Providers → Apple, configure/enable the Apple provider for the app's bundle identifier `com.roman1977.botai` with correct Apple Developer credentials/redirect settings. Confirm iOS signing entitlements and provider setup together. **No provider settings changed in this audit.**
2. Inspect remote Supabase database schema and migrations 0025/0026; ensure tables, grants, RLS, PostgREST schema exposure, and idempotent keys match the checked-in migrations. **No production migration applied in this audit.**
3. Provide/approve a disposable staging Supabase environment or controlled test accounts for end-to-end email/Apple login and two-user aggregate sync. Existing live integration test deliberately refuses the configured production project; this safety boundary must remain.
4. Re-run the read-only probe, then controlled real-account/hosted RLS integration, followed by signed release archive. Physical iPhone installation remains a separate later phase.

## Client-side safety correction

`AuthStore.signOut()` previously cleared local account binding in a `defer` **after** awaiting the remote logout. It now clears local identity, authentication and cached offline-session flags **before** network suspension, so a slow/offline server cannot keep the previous learner's account locally accessible. The remote logout still runs, with explicit error on failure. This is a real account-isolation fix, not just an additional test.

## Final regression

**PASS:** 184/184 unit and 28/28 UI on iPhone 16e simulator, `xcodebuild` exit 0, `/tmp/botai_auth_logout_full_20261023.log`. This includes the immediate-local-lockout logout code change. Hosted provider/schema blockers remain OPEN.
