# BOTAI Data Model

Status: conceptual model.

SQL schema is not yet frozen.

## Domains

The system is divided into five main domains.

### Identity

- User
- Profile
- PrivacySettings
- Consent

### Content

- Course
- Subject
- Section
- Topic
- Quiz
- QuizVersion
- Question
- AnswerOption
- Media
- ContentBlock

### Learning

- Enrollment
- LearningState
- Attempt
- StudySession
- Goal
- GoalContent

### Publication

- Draft
- Submission
- Publication
- ModerationCase
- Report

### Social

- Friendship
- Challenge
- ChallengeParticipant
- SharedResult
- Block

## Content hierarchy

Typical hierarchy:

Course
└── Subject
    └── Section
        └── Topic
            └── Quiz
                └── Question

The hierarchy must not require every level.

A personal Quiz may exist without Course, Subject, Section or Topic.

## Question identity

Questions require stable identifiers.

Minor edits must not automatically destroy the user's learning history.

## Question types

Initial types:

- pair;
- self-check;
- single choice;
- multiple choice.

The model must allow additional types later.

## Pair direction

A pair may allow:

A → B

B → A

or both.

Learning progress may differ by direction.

Therefore LearningState must be capable of representing direction-specific memory.

Example:

H₂SO₄ → Серная кислота: strong

Серная кислота → H₂SO₄: weak

## Answer options

Multiple-choice options require stable identifiers.

Reordering answer options must not change their identity.

## Content blocks

Questions should not be designed around only question_text / answer_text.

Content may contain:

- text;
- LaTeX;
- image.

The same content model should eventually be usable in prompts, answers and answer options.

## LearningState

LearningState represents the current calculated state of learning.

Possible data includes:

- user;
- question;
- direction when applicable;
- strength;
- state;
- last reviewed;
- next review;
- review count;
- success count;
- failure count.

Exact fields depend on the selected repetition algorithm.

## Attempt

Attempt represents an individual interaction with a question.

LearningState is current state.

Attempt is historical evidence.

These concepts must remain separate.

## Goals

A Goal may cover multiple content areas.

Example:

ЕГЭ 2027
├── Mathematics
├── Physics
└── Chemistry

This allows BOTAI to allocate daily study time between subjects.

## Versioning

Quiz is a persistent identity.

QuizVersion represents published revisions.

Users subscribe to the Quiz and may receive later versions without losing compatible learning history.

## Published content lifecycle

Public UGC uses the moderated lifecycle defined by ADR-004 and ADR-009.

Typical states:

draft
→ submitted
→ in_review
→ published
→ suspended / withdrawn

Ordinary user-generated publications are withdrawn/removed during responsible account deletion. Collaborative ownership and legally required retention are handled explicitly by the trusted deletion workflow.

## Data/Sync v1 decisions

### UUID

All synchronized domain entities use stable UUID identifiers.

### Question versions

Question is the stable learning identity.

QuestionVersion represents a concrete revision of that question.

Attempts retain the QuestionVersion used when the answer occurred.

### Attempts as historical evidence

Attempt is an append-oriented learning event.

Attempts are the durable evidence from which learning state can be reconstructed.

### LearningState as calculated state

LearningState is optimized current state, not the only source of truth.

It may be recalculated from Attempts when algorithms or synchronized history change.

### Multi-device learning

Attempts created on different devices are merged by UUID rather than resolving progress using simple last-write-wins.

### Local storage scope

The device stores subscribed/downloaded content rather than the entire public library.

### Sync support

Local persistence includes durable synchronization state and a pending-operation queue.

## Superseding lifecycle note

The earlier statement in this document that accepted published UGC survives author account deletion is superseded by **ADR-004**. Ordinary user-generated publications are withdrawn/removed as part of the responsible account deletion workflow, subject to collaborative ownership, legal retention requirements and the detailed deletion policy.

Accepted ADRs take precedence over older working notes in this document.

## Personal quiz ownership and library membership (MVP clarification)

A user's learning library is the primary content surface. A quiz shown there has an explicit relationship type; the UI must never infer edit rights from titles, publication state, or download state.

- `owned`: created or imported by the current user. Fully editable.
- `library`: added/downloaded from published shared content. The published original is read-only for the learner.
- To modify a `library` quiz, the user explicitly creates an independent owned copy.

Import source is administrative provenance, not runtime quiz content. The original uploaded table/file and import-generation parameters may be retained for administrator inspection/export/reuse. It is not used to regenerate an existing quiz.

A saved quiz contains the resulting concrete question-answer items used by learning. Personal creation does not submit anything for moderation.

Publication is a separate explicit workflow. A submission identifies the proposed catalog placement (course/subject/section/topic as applicable) and the quiz/version being proposed. Approval creates/updates shared published content; the author's owned quiz remains their own content.
