# ADR-018 — Personal library, ownership and publication

Status: Accepted — 2026-09-26.

## Decision

The Library tab is personal-first. It contains owned quizzes and shared published quizzes explicitly added/downloaded by the user.

Owned quizzes are editable. Added published quizzes are read-only; editing requires `Create my copy`, producing a new owned quiz with independent identity.

Creation/import saves privately. It never implies moderation. Publication is a separate explicit command and requires proposed catalog placement before submission.

Imported source data and generation settings are retained only as administrative provenance/export material. Runtime learning uses the concrete question-answer items saved in the quiz; existing quizzes are never regenerated from their import source.

## Consequences

Ownership/membership must be represented explicitly in storage/API. UI edit controls are driven by that relationship. Shared-library discovery is secondary to the user's learning library. Publication moderation operates on an explicit submission, not on quiz creation.
