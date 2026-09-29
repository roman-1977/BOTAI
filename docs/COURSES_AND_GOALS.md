# BOTAI Courses and Goals — v1

## Product boundary
BOTAI has one learning engine and three sources of learning goals.

- **Auto-course** — an author designs a sequence for a typical learner. Completing one goal activates the next automatically.
- **Teacher/class** — a teacher assigns the next goal to a specific learner based on observed progress. BOTAI does not advance the teacher's sequence on its own.
- **Self-directed** — the learner creates, pauses, resumes, completes and replaces personal goals.

These sources may coexist. A learner can have an active auto-course goal, a teacher assignment and a paused personal goal at the same time.

## Goal is the executable unit
A Goal answers: what to learn, which material/question sets are in scope, the completion criterion, and who controls progression. Daily workload (minutes/questions today) is separate from the learning Goal.

Initial lifecycle: `waiting → active ↔ paused → completed`, with cancellation/archive added when persistence is implemented.

## Auto-course v1
An AutoCourse is an ordered sequence of goals. It targets a typical learner and is intentionally simple in v1: no branching graph. Each step has a mastery/completion criterion. On completion, the next step unlocks. Later versions may add diagnostic skipping or remediation branches without changing Goal identity.

## Class v1
Teacher goals use the same Goal execution model, but completion returns control to the teacher. A future Assignment adds learner/class, due date and teacher context around the Goal.

## Self-directed v1
The learner owns sequencing. Personal goals can be paused and resumed independently. Creating a new goal does not destroy paused goals or their learning state.

## Course package
`.botai` Course Package v2 will carry course metadata, reusable materials, ordered auto-course goals, completion criteria, and portable media. Teacher assignments and learner progress are user-specific state and do not belong in a distributable course package.

## Personal course authoring UX
The first authoring workflow is learner-owned: `MyCourse → Section → Topic → existing QuestionSets`, plus an independent ordered list of Goals. Course structure organizes knowledge; goals organize the learner's intended progression. Question sets remain reusable library objects and are referenced, not copied. Goal order is a plan for self-study and does not lock navigation. The first editor supports course creation, reorderable sections/topics, linking existing personal quizzes, and reorderable goals with a mastery threshold.
