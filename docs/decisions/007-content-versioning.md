# ADR-007: Stable content identity with explicit versions

Status: Accepted

## Decision

Quiz, Question and AnswerOption have stable identities.

Published representations are versioned separately.

Examples:

- Quiz → QuizVersion
- Question → QuestionVersion
- AnswerOption → AnswerOptionVersion

## Reason

A formatting correction or reordered answer option should not automatically destroy a learner's history.

Attempts can reference both the stable Question and the exact QuestionVersion shown at the time.

## Material changes

A change that creates a fundamentally different learning item should normally create a new Question rather than reuse the old identity.

Exact learning-impact rules will be specified later.
