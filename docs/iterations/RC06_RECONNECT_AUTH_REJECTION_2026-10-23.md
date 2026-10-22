# RC-06 — lock offline study on failed account revalidation

## Finding

On a cold offline launch, the account UUID is accepted only when the Keychain binding matches the persisted Supabase session and the session request fails with a network transport error. However, after local study has been unlocked, `reconnectOfflineSession()` previously returned false on non-transport auth errors or account mismatch while leaving `userID` and `isOfflineLocalSession` unchanged. The local study UI could remain available even after a server-side rejection.

## Fix

- Preserve offline study access when reconnection fails due to a transport outage.
- On a non-transport revalidation error (including rejected/revoked auth, TLS errors and unexpected server errors), clear the active offline identity, stop offline mode and set `didFailBootstrap` so the application hides the study UI until a successful retry.
- Apply the same fail-closed behavior when the server reports a different account UUID.
- Do not delete any local learning data, overwrite Keychain binding, or fall back to a guest learning database as an authorization bypass.
- Keep existing account-bound aggregate sync checks from `3cb14ff`.

## Tests and scope

The policy regression tests cover transport outage, timeout, TLS rejection, auth failure and server error. The signed simulator unit suite is in `/tmp/botai_rc06_revalidation_20261023.log`; standard UI regression is in `/tmp/botai_rc06_revalidation_ui_20261023.log`.

**RC-06 remains OPEN:** this change does not substitute for a real offline cold-start → completed study → network restoration → backend ACK integration run, actual revoked-session backend test, account-switch UI fixture, or device testing. No TestFlight/App Store publication.


### Final verification

Signed unit tests: 156/156 passed. Signed UI tests: 25/25 passed. Evidence: `/tmp/botai_rc06_revalidation_20261023.log`, `/tmp/botai_rc06_revalidation_ui_20261023.log`. This does not close RC-06 end-to-end acceptance.
