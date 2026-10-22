# Reporting and motivation — BOTAI v0.3.0

## Product rules

1. Schedule defines **intended** study time, never whether a learner is allowed to practice. A day with 0 planned minutes is a rest day, **not a lockout**.
2. Actual study time is derived from persisted `StudySession.activeSeconds`; attempts are separately counted and never treated as minutes.
3. On rest days, voluntary study is a **bonus**, not an unmet goal. A day of planned rest without practice must not be described as failure.
4. Compare plan and actual transparently. Encourage learners who are behind without guilt, penalties, or deceptive mastery claims.
5. Mastery is based on canonical `knowledgeID`; attempts retain mode-specific question IDs for audit and sync. Do not conflate number of answered questions with number of mastered knowledge items.

## Current PDF v1

Home screen → **Расширенный отчёт · PDF** → native share sheet. Generated locally using `UIGraphicsPDFRenderer`. Includes 28-day plan/fact daily ledger, answers per day, aggregate plan/fact, total attempts, session minutes, due knowledge, known knowledge, active goals and encouraging summary. No cloud transmission by the export code.

**Important limitation:** historical daily plans are currently reconstructed from today's `StudyProfile`, not from schedule snapshots. When the learner edits their schedule, the retrospective comparison may change. Until historical plan snapshots exist, the report is a helpful approximation, not an immutable adherence record. Study sessions are recorded independently and represent actuals. A richer v2 should include coverage/accuracy/mastery by course and topic, progress forecasts, due-backlog distribution, weekly/monthly trend charts, changes to study plans and PDF visual QA.

## Verification

2026-10-22: `RestDayAndPDFReportTests` (2 tests) and `SharedKnowledgeProgressTests` (2 tests) passed on iPhone 16 Pro Max simulator. Full UI/export and visual QA pending. See `docs/iterations/V030_CHEMISTRY_PILOT.md`.
