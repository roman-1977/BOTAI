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

Question content has priority. Header contains exit, compact daily progress and only essential session state. Feedback explains why an answer is correct/incorrect and may offer expandable detail. Motivation messages occur at checkpoints, not after every tap.

## Session result

Show questions completed, accuracy/result mix, time, plan completion and one meaningful comparison. Offer Finish and Continue (+5) without implying that extra work is required.

## Progress

Period selector: Week / Month / 3 Months / All Time. First row shows a small set of comparable metrics (questions, accuracy, studied days, time). Follow with a period chart and explicit comparison to the previous equivalent period.

Detailed views include activity calendar, subject/topic strength, due/weak material, streaks, personal records and Goal pace. Numbers must remain understandable without charts.

## Motivation safeguards

Do not use shame copy, red failure states for missed voluntary goals, fake readiness percentages, excessive confetti, or loss threats. A missed day does not erase learned material. Streak and plan completion are separate facts.

## Accessibility and iOS behavior

Support Dynamic Type, VoiceOver labels, sufficient contrast, Reduce Motion, light/dark appearance, and meaningful state without color alone. Interactive targets should follow Apple platform conventions. Offline and pending-sync states should be subtle and actionable only when user intervention is actually needed.
