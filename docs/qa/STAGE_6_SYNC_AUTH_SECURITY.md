# Stage 6 — Sync, authorization and data security

Status: active. Server integration and account isolation are not accepted.

## Findings
- The sync actor is not called by the application; offline outbox records are not currently uploaded.
- Local study question UUIDs are not authoritative server QuestionVersion IDs. The backend enforces a foreign key. Uploading fabricated IDs would fail.
- Previous grade mapping incorrectly converted `hard` to `correct`.
- Local SQLite database is not partitioned by authenticated user. Account switching is not yet safe.
- Migration `0002_learning.sql` defines per-user RLS for attempts with INSERT/SELECT only; deployment and cross-user denial require server integration tests.

## Implemented safety changes
- SyncService explicitly retains the local outbox instead of attempting uploads with invented server question/version IDs. No remote uploads are claimed.
- Added correct mapping for all three grades (again → incorrect, hard → hard, good → correct).
- Added two focused `SyncSafetyTests`: mapping and durable local pending attempt. **2/2 passed**, `Test-BOTAI-2026.10.21_17-48-47-+0300.xcresult`.

## Remaining
1. Map local question IDs to real server Question and QuestionVersion IDs; then implement idempotent uploads, bounded retries and a durable cursor.
2. Partition private local state by user identity and define guest-to-account migration.
3. Validate auth bootstrap, sign-out, account switching, and cross-user RLS with an actual backend.
4. Run full regression suite and physical-device checks.
