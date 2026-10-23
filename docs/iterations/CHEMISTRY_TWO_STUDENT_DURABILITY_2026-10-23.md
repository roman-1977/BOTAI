# Chemistry: independent student persistence — 2026-10-23

## Contract and implementation under test

Each authenticated Supabase user UUID selects a distinct account-local SQLite directory. Fresh first-install provisioning imports the same bundled chemistry course (323 questions, 102 material sets, 70% staged route) into each database without copying another student's progress. The course's stable marker makes re-provisioning idempotent. Detailed attempts and learning states remain local and are not part of server summary sync.

## Regression scenario

An automated real-file SQLite integration test opens **two different authenticated account directories**, provisions chemistry independently, answers the **same actual generated chemistry question** for each student using distinct attempt IDs and different learning streaks, closes the DB scope, reopens both files in reverse account order, repeats the first-install provisioner (simulating relaunch/update), and verifies attempts, learning states, exactly one course and 102 materials remain intact and separate. No server access, credentials or production data involved.

## Acceptance boundary

This is a deterministic disk-backed integration test, not an iOS UI login, a physical iPhone restart, a multi-day user journey or a hosted Supabase verification. Those release blockers remain open in `CHEMISTRY_LEARNER_PRE_RELEASE_GATE_2026-10-23.md`. In particular, do not claim automatic transfer of detailed per-question history to a second device: it is intentionally local by accepted contract.

## Verification

- **PASS**: 184/184 unit tests, `xcodebuild` exit 0, `/tmp/botai_two_student_units_verified_20261023.log`. The new test uses an actual question generated from the bundled chemistry material.
- **PASS**: full serial simulator regression **184/184 unit + 28/28 UI**, `xcodebuild` exit 0, `** TEST SUCCEEDED **`, `/tmp/botai_two_student_full_verified_20261023.log`.
