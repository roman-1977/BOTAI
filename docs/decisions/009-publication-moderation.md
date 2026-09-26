# ADR-009: Publication and moderation pipeline

Status: Accepted

## Decision

Public user-generated quizzes do not become publicly visible merely because
their author requests publication.

The publication lifecycle is:

draft
→ submitted
→ in review
→ approved/rejected
→ published

A published item may later become:

published
→ suspended
→ restored or withdrawn

## Separation of concerns

Submission represents the author's request to publish a specific QuizVersion.

Publication represents public availability.

ModerationCase represents review/enforcement work.

Report represents a user's complaint about published content.

These concepts remain separate rather than being represented by a single
is_approved flag.

## Moderation authority

Moderator and administrator roles are server-controlled.

Users cannot grant themselves moderation privileges by editing their profile
or other client-writable data.

## Public versions

A Publication points to a concrete QuizVersion.

This means users see a known immutable version of the learning material rather
than an author's partially edited draft.

## Reports

Users can report published content.

Initial report reasons include:

- inappropriate;
- incorrect;
- copyright;
- spam;
- harassment;
- other.

Reports require a moderation workflow and timely operational response.

## Blocking

Users can block other users.

Blocking must affect relevant discovery/social surfaces.

The exact UI behavior will be specified during product design.
