# Session mode/settings acceptance matrix — 2026-10-22

All scenarios are mandatory for MVP; this is a verification plan, not evidence of passing tests.

## Dimensions
- Scope: all subjects mixed; one subject; one topic; review quick start; user daily-goal quick start.
- Format: mixed (reveal/pair/single-choice/multiple-choice), cards only (reveal/pair), tests only (single/multiple choice).
- Strategy: automatic, all, review; review quick start overrides selected strategy.
- Data: populated, no eligible format, no due items, some due items, duplicate references across topics, offline, resumed session.

## Expected invariants
1. Fresh session picker defaults to mixed format and automatic strategy; reopening resets temporary overrides.
2. Changing format filters out ineligible kinds; zero eligible questions disables the launch row; no empty session is created.
3. Review includes only due questions and disables launch when none are due; quick review does not silently include new cards.
4. All includes all eligible questions, regardless of due date. Automatic puts due before non-due; full teacher-guided adaptive policy is still pending.
5. Topic scope must not leak questions from other topics; subject scope contains only that subject's topics; all-subject scope covers the catalog.
6. An existing session resumes with its original ordered questions, answers and format; no new picker setting changes an in-progress session.
7. Multiple-choice requires exact correct set; single-choice one correct answer; reveal/pair record answers once, including relaunch after answering.
8. A question reused across topics must not be falsely attributed to one topic in aggregate sync.
9. Repeat each essential scenario with airplane-mode/offline storage and after app relaunch.

## Coverage audit (as of start)
- Existing UI: fresh picker, advanced-settings reset, two-question resume, chemistry two-answer persistence, importer.
- Existing unit: card generation, local learning persistence, attribution and sync queue.
- Missing automated matrix: format x strategy x scope with due/no-due, all four answer UIs, disabled empty-state rows, resumed mixed-format session.
- Gate: RC-01/03/04/06 remain PARTIAL/OPEN until missing scenarios are implemented and executed.
