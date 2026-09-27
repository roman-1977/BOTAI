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

`Session start/resume → Question card → answer/reveal → result/self-rating → next card → ... → Pause`

The learning surface is continuous rather than round-based. Daily goals span multiple launches. The persistent header shows four compact daily indicators: questions vs goal, active study minutes vs goal, correct/incorrect mix, and unique-question coverage of the active material. The section title reserves up to two lines; the card keeps a stable maximum height; space for up to six answers and the Pause action is reserved below it.

Recall cards flip and then ask for self-rating. Single-choice tests reveal correctness on selection; multiple-choice tests reveal it after **Answer**. After correctness is shown, tapping the card or any part of the answer region advances with the card transition.

Pause preserves progress. Active study time is accumulated only while the app is active and a question is being worked on, and the displayed total updates at question boundaries. See ADR-019 for session lifecycle and mode behavior.

## Pause and day boundary

**Pause** leaves the learning surface and preserves the current day's progress; it is not a destructive Finish action. Reopening learning can resume the last selection/session without rebuilding it. A logical StudySession is finalized when a new session is explicitly started or when a later launch determines that the previous study day has ended.

Exhausting the currently selected question pool may show a lightweight completion state, but reaching a daily goal does not end learning automatically. Daily summaries and longer-term comparisons belong to Home/Progress rather than forcing a result screen after every pause.

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

## Personal library and publication — MVP correction

The Library tab opens the user's own learning library first, not the public catalog.

`Library → My learning library → Quiz detail → Start quiz`

Owned quiz: `Quiz detail → Start / Edit / More`.

Published quiz added to the user's library: `Quiz detail → Start / Remove from library / Create my copy`. It is not directly editable.

Discovery is secondary: `Library → Shared library → Search/categories → Published quiz detail → Add to my library`.

Creation is private by default: `My learning library → Create/import → Preview generated question-answer pairs → Save → Quiz detail`.

Publication is explicit and separate: `Owned quiz → More → Propose publication → choose catalog placement → Preview submission → Submit for moderation`.

## Student game loop

`Сегодня → Миссия дня → Испытания → Награда/XP → Мой путь → следующая миссия`.

Главный экран ученика показывает уровень, XP, серию и доступные миссии. Экран прохождения концентрируется на одном испытании. После завершения показывается игровая награда. Ученический прогресс представлен уровнями, достижениями и освоенными мирами; подробная аналитика вынесена из этого flow.

Служебные экраны (`Профиль`, настройки, управление собственными материалами) могут использовать стандартный системный UI без игровой оболочки.

## Single-screen student shell

У ученика нет табличной/tab-bar навигации как основного интерфейса. После входа он попадает на один игровой home-screen: визуальный уровень/XP, текущий маршрут, цели с графическим прогрессом и достижения. С этого экрана доступны только естественные ответвления: начать/продолжить прохождение, открыть цель/маршрут и открыть настройки/профиль. Подробная аналитика остаётся административной функцией.
