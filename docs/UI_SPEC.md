# BOTAI UI Specification v1

Status: Accepted direction from UX storyboard; component details remain iterative.

## Visual hierarchy

BOTAI should feel like a serious learning tool with light motivational feedback, not a game dashboard. White/neutral surfaces, system typography, one primary blue action color, semantic green for success and restrained orange/red only when they carry meaning.

Home answers one question first: **what should I do now?** The order is Goal/pace, streak as a compact signal, today's BOTAI plan, habit minimum, due/weak/new mix, primary action, then one personal insight. Weekly/monthly analytics do not compete with the primary action.

## Navigation

Primary tabs: Today, Library, Progress, Profile. Friends/challenges are reached contextually from Progress/Profile/Home cards in v1 rather than requiring a permanent fifth tab.

## Today

The Goal card may show a dated goal and pace. A readiness percentage must not be shown until its algorithm and evidence are defined; use pace/status language instead.

Today's plan uses completed / recommended questions and a progress bar. The habit minimum is a separate completed/not-completed row. Due, weak and new counts explain the plan. The primary button is BOTАТЬ or ПРОДОЛЖИТЬ when a local session exists.

One contextual insight may appear below the action, e.g. accuracy vs recent personal baseline. Social comparison is never the dominant Home signal.

## Learn

The learner-facing Learn screen uses the project's dark digital/game language. The top HUD contains four equally weighted daily rings — Questions, Minutes, Answers and Coverage — plus a narrow full-height Mode control visually separated from the rings.

The section/topic label is left aligned and reserves two lines. Below it, the question/answer remains a physical card with a fixed height for the current device layout. The bottom of the screen always reserves the maximum six vertically stacked answer choices and a persistent Pause button; fewer answers must not make the card jump.

The Mode console is part of the game surface, not a system settings sheet. Its centered groups are Strategy (Learn / Review / AI), Format (Card / Test / AI), and Pace (Calm / Speed / AI). Selecting Speed on an already-selected tile cycles the configured seconds. Runtime direction reversal is intentionally absent because pair/table direction belongs to content creation.

Question content has visual priority. Correctness uses semantic feedback, but advancement remains spatially forgiving: after a test is checked, the card, answer buttons and empty answer region all advance. Accessibility must preserve the same actions without relying on color alone.

## Pause and completion

Pause is the persistent bottom action and must read as resumable, not as failure or final completion. Meeting or exceeding a daily goal changes progress/motivation state but does not force navigation. If the selected material is exhausted, a compact completion state may summarize today's questions and active minutes and offer a clear return action.

## Progress

Period selector: Week / Month / 3 Months / All Time. First row shows a small set of comparable metrics (questions, accuracy, studied days, time). Follow with a period chart and explicit comparison to the previous equivalent period.

Detailed views include activity calendar, subject/topic strength, due/weak material, streaks, personal records and Goal pace. Numbers must remain understandable without charts.

## Motivation safeguards

Do not use shame copy, red failure states for missed voluntary goals, fake readiness percentages, excessive confetti, or loss threats. A missed day does not erase learned material. Streak and plan completion are separate facts.

## Accessibility and iOS behavior

Support Dynamic Type, VoiceOver labels, sufficient contrast, Reduce Motion, light/dark appearance, and meaningful state without color alone. Interactive targets should follow Apple platform conventions. Offline and pending-sync states should be subtle and actionable only when user intervention is actually needed.

### RC-04 learner-facing recommendation access — 2026-10-23

Found that `GameHomeView.goalsCard` existed but was **never inserted into the rendered view hierarchy**. Teacher priority, difficulty, suggested daily minutes, pace comparison, rationale, mastery and target were therefore invisible despite previous UI implementation claims. Added a compact `Рекомендации и цели` action in Today when actionable goals exist, opening a scrollable accessible goal-details sheet. The standard-size home remains one-screen and without scrolling. Existing active-goal UI scenario now checks the recommendations button, sheet title, goal name and actual mastery after app relaunch. This verifies access to persisted student guidance UI, not a new difficulty-scoring policy.

Verification pending: full sequential simulator suite `/tmp/botai_rc04_full_sequential_20261023.log` was launched **before** these UI edits and cannot verify them; run the focused changed UI scenario and unit suite after the full run exits. Do not report a green UI run before the final summary. Teacher difficulty still informational; an unapproved numeric weight must not be invented. RC-04 OPEN.

### RC-04 visible recommendations verification — 2026-10-23

Confirmed a product defect: `goalsCard` was defined but unreachable in the rendered Today hierarchy. Now a compact `Рекомендации и цели` button opens a scrollable sheet showing the real per-goal mastery/target, minutes, deadline and available teacher guidance without introducing scrolling on standard-size Today. The persisted-goal cold-relaunch UI test now opens the sheet and asserts the goal and `Освоено 0%`. **Focused simulator UI PASS** (`testCreateCourseSectionTopicAndGoal`, 75.867 s, `/tmp/botai_rc04_recommendations_ui_20261023.log`); **176/176 unit PASS** (`/tmp/botai_rc04_visible_guidance_units_20261023.log`). A full UI suite started before this fix was intentionally stopped so the updated UI could be verified; it is NOT a completed full UI regression. Full sequential regression remains required at RC closure. No change to teacher difficulty scoring or profile minute budget.
