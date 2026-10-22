# RC-06 — offline logout must revoke local access

## Finding

`AuthStore.signOut()` previously cleared the local identity and Keychain binding only if the Supabase remote logout call succeeded. An offline request could throw and leave the account's learning UI unlocked even after the learner selected Sign out.

## Fix

Use `defer` to unconditionally clear `OfflineAccountBinding`, `userID`, `isAuthenticated`, and `isOfflineLocalSession` on every sign-out outcome. Supabase Swift's `AuthClient.signOut(scope:)` implementation was inspected in the pinned local package: it calls `sessionManager.remove()` before the network logout request, so an offline failure still removes the persisted SDK session. If remote revocation fails, display an explicit warning that local logout succeeded but remote session termination could not be confirmed. The per-account database remains intact and cannot be accessed as guest.

## Verification / limitations

Run the signed simulator unit suite and UI regression on the modified app. No live backend token-revocation claim: remote revocation cannot be confirmed without a real authenticated test identity and server checks. RC-06 remains open until that acceptance test is performed.

Signed final build: unit suite PASS `/tmp/botai_rc06_signout_20261023.log`; 25/25 UI PASS `/tmp/botai_rc06_signout_ui_20261023.log`.

## Follow-up: storage errors take precedence over the study interface

The root view previously selected `RootTabView` when initial identity resolution was complete, even if a subsequent account database reopen failed. The guard now requires `storageFailure == nil`, ensuring that a failed per-account storage rebind cannot expose a stale study view. The existing storage-error retry screen is shown instead. This is a fail-closed UI guard, not a substitute for live backend isolation tests.

Signed simulator unit suite and 25/25 UI tests PASS. Logs: `/tmp/botai_rc06_storage_guard_unit_20261023.log`, `/tmp/botai_rc06_storage_guard_ui_20261023.log`.
