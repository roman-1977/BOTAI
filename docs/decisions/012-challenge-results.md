# ADR-012: Challenge results are server-derived

Status: Accepted

## Decision

Challenge scores are calculated by trusted backend logic from synchronized
Attempts.

Normal clients cannot directly write ChallengeResult.

## Reason

Client-provided scores would make challenges trivial to manipulate and could
diverge between devices.

Attempts already provide the authoritative learning evidence needed to
calculate:

- questions answered;
- correct answers;
- accuracy.

## Offline participation

A learner may continue studying offline during a challenge.

Results may remain provisional until relevant Attempts have synchronized.

The UI must not imply that an offline provisional result is final.
