# ADR-016: Daily targets and progress motivation

Status: Accepted

## Decision

Separate long-lived Goals, a small Minimum Day, and the adaptive BOTAI Daily Plan. The learner controls the destination and preferred intensity; BOTAI calculates the actual workload. The primary completion unit is questions completed.

Daily-plan progress is visible during learning and compares primarily with the learner's own historical baseline. Completing the BOTAI plan is a checkpoint, not a forced session end. Missed targets do not create debt.

Social comparison is explicit and secondary. Raw Attempts, Goals and weak-topic data remain private unless a future feature has an explicit sharing contract.

Streaks and personal bests are derived from authoritative learning history rather than mutable client counters.

## Consequences

The current `goals` table is not sufficient for minimum/plan history. Do not overload it. Add the daily-target persistence model only after this product flow is accepted, so schema follows UX rather than guessing it.
