# BOTAI implementation status

Snapshot: 2026-10-01. This file distinguishes code that exists now from accepted target architecture.

## Implemented now

- SwiftUI iOS app generated from ios/project.yml with XcodeGen.
- GRDB/SQLite migrations v1-v7.
- Offline Material library with CSV/TSV and BOTAI Package v1 import/export.
- Card, single-choice and multiple-choice generation with stable question IDs.
- Attempts, LearningState, StudySessions and transactional Attempt sync outbox.
- Persistent Courses, Sections, Topics, Learning Goals and StudyProfile.
- Local DailyPlanner and study-session UI.
- Material/Course/Goal deletion retains learning history; material deletion cleans live course references.
- Partial Supabase auth, public-library/social/account-safety and Attempt-upload services.

## Partial / prototype

- Repetition scheduling is a simple MVP heuristic, not the final scheduler.
- Sync uploads Attempts but lacks full pull/reconciliation/cursor handling.
- Course persistence is a JSON aggregate; schema evolution needs compatibility tests.
- BOTAI Package v1 is a Material format; Course Package v2 is not implemented.
- History retains stable question IDs but not display snapshots of deleted/renamed material/course/goal names.

## Not implemented yet

- Per-account private local database isolation and account-switch cleanup.
- Complete multi-device sync and canonical LearningState reconciliation.
- Sync cursors/tombstones and server-content cache lifecycle.
- Course Package v2 and complete class/group acquisition.
- Release-grade migration fixtures, package fuzz/size-limit tests, accessibility/localization hardening.
- BOLDAI / AI exam.

## Current technical-debt priorities

1. Surface persistence failures instead of swallowing them with try? in user-visible write paths.
2. Split LearnSessionView (541 lines at this snapshot) into smaller presentation components and a testable session model.
3. Add migration-upgrade fixtures and malformed/oversized package security tests.
4. Define retained historical metadata snapshots for long-term statistics after content deletion/rename.
5. Finish account isolation before treating authentication as production-ready.
6. Keep XcodeGen generation deterministic and avoid accidental generated-project diffs.

## Validation baseline

git diff --check must be clean. A generic iOS Simulator build must compile. Unit tests cover learning state, repositories, material cascade deletion, deletion/history invariants, table parsing, daily plan and study profile.
