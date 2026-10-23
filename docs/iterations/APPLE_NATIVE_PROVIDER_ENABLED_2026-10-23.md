# Native Apple Sign In provider enabled — 2026-10-23

User opened an authenticated Apple Developer portal tab on the development Mac and previously authorized Supabase configuration changes.

## Verified configuration

- Apple Developer team **RW79ZHJQP2** contains existing explicit universal App ID **`com.roman1977.botai`**, identifier `393A465W3J`. Its **Sign In with Apple** capability was **already enabled** and marked **primary App ID**. No Apple Developer portal changes were required or made.
- Supabase project `gdkjcfrzxrjdscutxffc` → Authentication → Sign In / Providers → Apple: **enabled**, with native Client IDs **`com.roman1977.botai`**. Saved in the authenticated dashboard. OAuth secret left empty because the iOS client uses native Apple identity tokens, not web OAuth. No private Apple keys generated, copied, or exposed.
- Verified via dashboard after save: **Apple ENABLED**. Independently verified via `/auth/v1/settings`: **`external.apple=true`**; email still enabled with confirmation required.
- `tools/release/check_live_auth_and_schema.sh`: **`RELEASE_BACKEND_GATE=PUBLIC_CHECKS_PASS` (exit 0)**. Both aggregate tables respond **401/42501** to anonymous REST queries, as expected; previously missing tables are available behind authentication.

## What this does and does not prove

The server-side Apple provider blocker is **resolved**. The app already contains the native Apple button, SHA256 nonce exchange and Apple entitlement. This check **does not** prove a real Apple credential exchange: native Sign in with Apple requires a signed app on an Apple device with a matching provisioning profile. The only existing local profile is expired and belongs to a different bundle ID. Signed distribution and real Apple/email login, session refresh, hosted two-user RLS and aggregate upload remain release gates.

Do not claim an unsigned simulator archive is installable, or mark the full release ready. No source changes or regression test reruns were required for this configuration-only change.
