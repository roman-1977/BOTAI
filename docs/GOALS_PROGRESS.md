# Goals, Daily Progress and Motivation

Status: Accepted for UX prototyping

## Product principle

BOTAI owns the study plan; the learner owns the ambition. A Goal describes **why / by when** the learner studies. A Daily Target describes **how much today**. They are separate concepts.

BOTAI proposes a daily target from the active goal, due material and recent sustainable activity. The learner may accept it, choose a lighter/intensive preset, or set it manually. BOTAI may later suggest a change but never silently raises the target.

Missing a day does not create debt and does not punish the learner. The next day's plan is recalculated.

## Three motivation layers

BOTAI separates three things that other products often mix together.

**Minimum day** is a small meaningful threshold that keeps the daily study streak. It is intentionally easier than the full plan.

**Today's BOTAI plan** is the adaptive workload: due + weak + new material. Its size may change each day. Questions completed are the primary progress unit; time is a supporting statistic.

**Long-term Goal pace** answers whether the learner is moving fast enough toward a dated destination. Do not display a generic readiness percentage until its algorithm has a defensible definition.

The learner controls the long-term Goal and preferred intensity/minimum. BOTAI calculates and recalculates the actual daily plan. Historical targets/results are never rewritten by later settings changes.

## During a study session

The Learn HUD keeps daily progress visible without a live ticking clock. Four indicators answer different questions: **Questions** = completed answers against the user's daily question goal; **Minutes** = accumulated active study time against the daily time goal; **Answers** = correct vs incorrect result mix; **Coverage** = unique questions encountered today as a percentage of the active material.

Question and minute goals may exceed 100%; over-performance remains visible instead of being capped away. Coverage counts unique question IDs so repetition cannot inflate it. Accuracy/result mix and coverage are descriptive statistics, not substitutes for long-term mastery.

Daily progress survives pausing and resuming during the same study day. Only active work between question presentation and completion contributes to study time. Background/inactive time does not. The displayed minute value updates when moving to a new question rather than every second.

## Completing the target

Completing today’s BOTAI plan is a positive checkpoint, not a forced end of session. The learner can finish or continue. Extra work counts in today's actual progress but does not retroactively enlarge the target.

The completion card should answer: what was done, how today compares with the learner's baseline, what improved, and what BOTAI recommends next.

## Statistics

Statistics support Today, Week, Month, 3 Months and All Time comparisons and answer decisions, not merely display charts:

- Am I becoming more reliable?
- What material is weak or becoming due?
- How consistent is my study?
- How does today/week compare with my own recent period?
- Am I on pace for a dated Goal?

Core measures: completed questions, correct/hard/incorrect distribution, accuracy, due backlog, studied days, minimum-day completion, current/best streak, time spent, week/month comparisons, personal records, and goal pace. Memory strength remains distinct from future AI-exam understanding.

## Streaks and personal bests

A studied day is a day with meaningful learning activity. A target-complete day is tracked separately. The UI must not imply that an incomplete day erased learning progress.

Personal bests can include most questions in a day, best sustained accuracy above a minimum sample, and longest consistency streak. Historical facts are derived from Attempts/StudySessions rather than trusted client counters.

## Friends and challenges

Private by default. A learner may explicitly share a daily/weekly result snapshot or join a Challenge. Friends do not receive raw Attempt history, Goals or detailed weak-topic data.

Friend comparison uses the same declared metric and period for everybody. It is never required to complete the daily target. Blocking overrides all social visibility.

## Home

Home answers `What should I do today?` in this order:

1. active Goal and date/pace when relevant;
2. today’s BOTAI plan and progress ring/bar;
3. minimum-day / streak state;
4. BOTAI’s prepared mix: due / weak / new;
5. primary action **БОТАТЬ** / Continue;
6. one useful self-comparison insight;
7. optional friends/challenge card below personal progress.

## Non-goals

No shame copy, loss-aversion threats, automatic public leaderboard, automatic sharing, or silent target increases. AI exam mode is not required for this motivation loop.
