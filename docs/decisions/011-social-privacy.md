# ADR-011: Social features are explicit and privacy-first

Status: Accepted

## Decision

BOTAI social features are based on explicit relationships and invitations.

The MVP does not require a global public leaderboard.

## Friendship

Friendship is a two-party relationship.

A request must be explicitly accepted.

Blocking takes precedence over friendship and social visibility.

## Sharing

Learning results are private by default.

Sharing creates an explicit result snapshot.

BOTAI does not automatically expose a learner's LearningState, complete
Attempt history or goals to friends.

## Challenges

Challenges use explicit participants.

Participants are invited and must accept.

Challenge results are calculated from authoritative learning Attempts rather
than values supplied by clients.

## Minors

Because BOTAI is intended to be useful to school-age learners, social
discovery should minimize unnecessary exposure of personal information.

Public ranking/discovery features require a separate privacy and safety review
before implementation.
