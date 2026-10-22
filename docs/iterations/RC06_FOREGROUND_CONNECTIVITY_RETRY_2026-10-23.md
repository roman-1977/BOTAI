# RC-06 — foreground connectivity restoration

## Finding

Previously the application retried offline account revalidation and aggregate synchronization only when the scene transitioned to `.active`. A learner who remained in the foreground while Wi-Fi/mobile connectivity was restored could keep studying offline without triggering a sync until backgrounding and reopening the app.

## Change

`ConnectivityRetrySignal` uses Apple's `NWPathMonitor` to emit a retry event when an observed unavailable path becomes available. `BOTAIApp` starts it at bootstrap and listens for the transition. On restoration, an offline identity is revalidated with Supabase, the exact local account database is rebound to sync, and pending completed-session aggregates are flushed. An already online account can retry a failed upload as well. `NWPathMonitor` is **not** treated as proof of authorization; all existing account-bound checks and fail-closed policy remain enforced. No new attempt-level upload is introduced.

## Regression coverage

- New policy test checks initial online, continuing offline and offline-to-online transitions.
- Existing `SessionSummarySyncCoordinatorTests.offlineCompletionSurvivesDatabaseReopenAndUploadsExactlyOnce` verifies durable offline completion, database reopen, failed upload, ACK on retry, idempotent second flush, and persisted history.
- Existing coordinator tests check account change during suspended upload, overlapping flush, partial/foreign/duplicate acknowledgements, and topic aggregate retry.
- Signed simulator unit suite: **157/157 PASS** (`/tmp/botai_rc06_connectivity_20261023.log`).
- Signed UI regression: `/tmp/botai_rc06_connectivity_ui_20261023.log` (record final result after completion).

## Not yet verified

A controlled real network interruption and reconnection in the running simulator, a hosted backend ACK, revoked remote sessions, and device testing remain unverified. RC-06 remains OPEN; no release approval.

## Final signed UI result

25/25 standard UI PASS; zero failures; see `/tmp/botai_rc06_connectivity_ui_20261023.log`. RC-06 remains open pending real-network/backend acceptance.
