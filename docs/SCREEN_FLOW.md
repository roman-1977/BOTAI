# BOTAI Screen Flow v1

Status: Accepted v1 information architecture — visual design in iteration

## Navigation model

Primary tabs for the first product design pass: **Сегодня**, **Библиотека**, **Прогресс**, **Профиль**. Creation and social/challenges are entered from the relevant tab rather than occupying permanent navigation initially.

## First launch

`Launch → Welcome → Sign in / continue with supported auth → What do you want to learn? → Library selection → Goal setup → Study intensity/minimum proposal → Home`

Goal setup can create a dated goal (for example an exam) or `Learn without a date`. BOTAI proposes a sustainable minimum/intensity; the actual daily study plan is calculated from learning state and may vary by day. The user must be able to get to useful learning without configuring social features.

## Today / Home

Home shows active Goal, today's `done / BOTAI plan`, minimum/streak state, estimated study mix and one primary action.

`Home → БОТАТЬ → Study session`

`Home → plan/minimum → Study goal settings`

`Home → goal card → Goal detail`

`Home → comparison insight → Progress detail`

If there is an unfinished local StudySession, primary action becomes **ПРОДОЛЖИТЬ**. Offline state does not remove the action.

## Study session

`Session start → Question → Answer/reveal → self/result input → next question → ... → checkpoint → completion`

Persistent compact header: today's adaptive-plan progress (`18/27`) and session exit. Question content has visual priority.

At selected checkpoints BOTAI may show a small progress message; not after every answer. At BOTAI-plan completion: `Target reached → Finish | Continue`.

Exiting early saves the local session and today's completed work. There is no failure state for stopping before the target.

## Session result

Shows completed questions, result mix/accuracy, time, target status, change vs own recent baseline when statistically meaningful, and weak/due material discovered.

Actions: **Готово**, **Ещё 5**, or continue a relevant challenge when applicable.

## Goals

`Home/Profile → Goals → Goal detail → Edit goal`

Goal detail shows target date, connected quizzes, pace, recent consistency and BOTAI recommendation. Editing a Goal and editing the Daily Target are separate actions.

BOTAI can propose `Your recent activity supports 15/day instead of 10/day`; applying it always requires user confirmation.

## Progress

`Progress overview → Today / Week / Month / Longer period → Quiz/topic detail`

Overview starts with a plain-language trend, then plan/minimum history, activity/accuracy, memory/due state, streaks/personal bests, and goal pace. Week and Month explicitly compare with the previous equivalent period. Charts support those answers rather than becoming the information architecture themselves.

## Library

`Library → Search/categories → Quiz detail → Add to learning → choose Goal (optional) → Home`

Own content: `Library/Profile → My quizzes → Create/Edit → Preview → Submit for publication`. Moderation/publication states stay visible to the author.

## Friends and challenges

Entry points: Progress/Profile and optional Home card.

`Friends → requests/list → friend summary`

`Challenges → challenge detail → accept/decline → study normally → challenge result`

Only explicitly shared snapshots/challenge metrics are visible. Blocking is available from the relevant person surface. No global public learner leaderboard in v1.

## Profile and settings

Profile contains account, learning preferences, Goals, daily-target defaults, notifications, privacy/social settings, support, moderation/report history where relevant, and account deletion.

## Offline and sync states

Home/Learn/Progress use local data and remain usable offline for downloaded/enrolled content. A subtle sync state may appear when needed. Pending upload is not an error. Conflicts that require user choice are surfaced at the owning feature, not as a generic sync dashboard.

## Deferred flow

BOLDAI / AI exam is intentionally excluded from this v1 screen flow. The architecture reserves it, but its UX is designed separately before implementation.
