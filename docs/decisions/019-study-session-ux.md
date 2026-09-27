# ADR-019: Study session interaction model

Status: Accepted

## Context

The learner UI targets children and teenagers and must keep the question card visually stable while still exposing daily progress and optional study modes. A study day may contain several app launches; leaving the screen is a pause, not necessarily the end of the day's learning.

## Decision

The Learn screen is a single game surface. Its header shows four daily indicators: question-goal progress, study-time-goal progress, correct/incorrect result mix, and daily coverage (unique questions seen / questions in the active material). Goal rings may visibly exceed 100% rather than hiding over-performance.

Below the header, reserve up to two lines for the section title. Reserve a fixed answer area large enough for six vertically stacked choices and a persistent Pause action at the bottom. The question card occupies all remaining height and therefore does not resize when the question type or number of answers changes.

Question interaction is card-based. Recall cards flip on card tap and then offer self-rating. Single-choice tests reveal correctness immediately after selection. Multiple-choice tests require Answer before revealing correctness. Once a test is checked, tapping the card, a choice, or any empty part of the answer region advances with the same card-transition animation.

Pause leaves the learning surface while preserving daily work. Daily goals and counters span launches during the same study day. A future durable StudySession implementation closes the prior session when a new session is explicitly started or when a later launch establishes that the study day has ended. More than five minutes of inactivity pauses active question timing. Only active time between presenting a question and completing it counts as study time; the UI updates the displayed accumulated time at question boundaries rather than running a visible second-by-second clock.

The in-game mode control opens a game-styled console rather than system Settings. It has three independent dimensions: Strategy = Learn / Review / AI; Format = Card / Test / AI; Pace = Calm / Speed / AI. Speed uses a compact cycling time limit (prototype values 10/20/30/60 seconds). These controls change question delivery, not the selected quiz/material. Pair/table direction is defined when content is created and is not a runtime study-mode setting.

## Current implementation boundary

`LearnSessionView` implements the accepted interaction prototype and visual states. Several counters, goals, mode selections and timing values are still view-local/demo state. ADR-019 defines the intended product behavior; persistence, day-boundary reconciliation, inactivity handling and AI scheduling must move into domain/session services before production release. Do not mistake prototype state for the final data model.

## Follow-up engineering work

Before this prototype is production-ready:

- persist the daily counters, coverage set, active selection and mode choices instead of seeding demo values in the view;
- move session/day lifecycle and the five-minute inactivity rule into a testable domain service with an injectable clock;
- make Learn / Review / AI, Card / Test / AI and Pace modes drive the scheduler/question renderer (the current console is primarily interaction/UI state);
- implement timed-question expiry semantics and AI-selected timing; the current speed tile only chooses a limit;
- derive the section/topic label from selected content instead of prototype copy;
- add focused tests for session timing, day rollover, pause/resume, coverage uniqueness, mode behavior and question-state transitions;
- verify Dynamic Type, VoiceOver, Reduce Motion and compact/small-device layouts before release.
