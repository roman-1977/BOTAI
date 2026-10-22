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

## Recommendation engine v1 (2026-10-22)

The PDF compares average weekly **actual minutes** over the last 14 calendar days against `StudyProfile.weeklyMinutes`. When behind, it prints the weekly minute shortfall and a suggested number of additional 15-minute sessions (or redistributing those minutes among preferred days). When ahead, it recognizes the lead and does **not** suggest more mandatory workload. For a zero-minute weekly plan, voluntary activity is described as optional. This is a **time-budget** comparison only, not a knowledge-readiness forecast. For goals with deadlines the PDF explicitly discloses that readiness projection needs a historical mastery series.

Tests `ForecastRecommendationPDFTests` extract real PDF text using PDFKit and assert under-plan and ahead-of-plan recommendations; 2/2 passed on simulator. The earlier `RestDayAndPDFReportTests` also passed 2/2 after reconnection.

## Knowledge history — v13 (2026-10-22)

The app now writes immutable `knowledgeProgressEvents` on every successful attempt, atomically with the learning state and outbox. Each event identifies the canonical knowledge, its mastery outcome and time. These observations support future per-goal knowledge mastery trajectories and deadline projections without equating practice time with learning. Historical attempts created before v13 have no reliable mastery-attempt snapshots; they are deliberately not backfilled with guessed values. Local chemistry fixture reset includes this table. `KnowledgeProgressHistoryTests` 2/2 passed; Python fixture tests 5/5 passed.

## Goal-specific deadline forecast v1 (2026-10-22)

The PDF now includes a section for each active goal, resolving a **set of canonical knowledge IDs** from its material rules. It reports current known/total, target count `ceil(total × target%)`, remaining items, observed mastery-growth rate (knowledge/day), approximate date of reaching target and lead/lag in days against the goal's deadline. If projected late, it reports the knowledge/day pace needed and the factor by which observed progress would need to increase, and recommends increasing frequency/duration gradually. If projected early, it encourages maintaining the current pace. If already mastered, it celebrates completion. If there are fewer than three calendar days between the first and last observed event or no positive growth, it does not invent an ETA. The calculation is explicitly **an approximate linear forecast**, not a guaranteed outcome or a prediction based on study minutes. Historical mastery data begins with v13; pre-migration history is not invented.

Verified `KnowledgeDeadlineForecastTests` 4/4 on simulator; PDF recommendation regression 2/2. Remaining: rolling windows, minimum evidence, confidence intervals, plan revision history, visual PDF QA and full UI integration.

## Forecast v1.1 — rolling history and regressions

The ETA now considers only the last 28 calendar days of knowledge-progress events and requires observations on at least **three distinct days**. The baseline includes last-known observations before the window, and changes inside the window are replayed per canonical knowledge ID. A negative or flat net change yields no projected completion date. Ancient activity is not extrapolated into the current rate. Six targeted Swift forecast tests passed. This is a conservative linear estimate, not a confidence-bounded forecast; sparse samples, plan revisions and PDF visual QA remain outstanding.
