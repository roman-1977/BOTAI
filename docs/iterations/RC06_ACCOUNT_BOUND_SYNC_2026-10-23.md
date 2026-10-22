# RC-06 — account-bound aggregate synchronization (2026-10-23)

## Scope and security finding

A `SyncService` instance retains the local `LearningRepository` from the account that created it. Previously it read whichever Supabase account was currently authenticated at flush start. An asynchronous task retained across a sign-out/account switch could therefore attempt to upload the old account's pending aggregate summaries as the newly authenticated account.

## Change

- `SyncService` now requires an immutable `boundAccountID` on construction.
- A flush is rejected unless the current authenticated user matches the bound account.
- The account guard is repeated at coordinator checkpoints to prevent continuing after a switch.
- Both app service-construction paths and the live integration test explicitly supply the account identity.
- Added a unit policy regression for same-account, switched-account and signed-out cases.

## Acceptance and limitations

This addresses the stale-service cross-account upload entry point. It does **not** establish that the full offline authorization/reconnect acceptance matrix is complete. Outstanding: end-to-end cold offline launch, reconnect while app remains active, revoked-session handling, real network disruption, multi-account UI and live hosted backend verification. Do not mark RC-06 closed or publish.

## Verification

See `/tmp/botai_rc06_account_binding_20261023.log` for the first local unit build and `/tmp/botai_rc06_account_binding_full_20261023.log` for the signed simulator suite. Record final counts and failures in the handoff after completion.


## Verified simulator results

- Unsigned baseline unit run: **154/154 PASS** (`/tmp/botai_rc06_account_binding_20261023.log`), executed before the new policy test was added.
- Final signed full run: **155/155 Swift Testing PASS** and **25/25 UI PASS**, zero failures, Xcode `** TEST SUCCEEDED **` (`/tmp/botai_rc06_account_binding_full_20261023.log`). Two seeded chemistry UI tests require their separate disposable fixture run and are not included in the 25 standard UI tests.
- The full offline cold-start → study → reconnect integration scenario has **not** been executed; RC-06 remains open.
