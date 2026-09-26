# ADR-008: Attempts are authoritative learning evidence

Status: Accepted

## Decision

Learning Attempts are durable learning events.

Canonical server LearningState is derived from synchronized Attempts.

Client devices must not directly overwrite canonical server LearningState.

## Local operation

Each iOS device maintains its own calculated LearningState in SQLite.

This allows:

- instant response after answering;
- offline learning;
- local scheduling of repetitions.

## Synchronization

Devices upload Attempts with stable UUID identifiers.

The server merges Attempts from all devices.

Trusted server-side learning logic calculates canonical LearningState from the merged evidence.

Clients may then receive the canonical state during synchronization.

## Multi-device consequence

If iPhone and iPad both operate offline, neither device's calculated state overwrites the other.

Their Attempts are merged first.

Canonical state is calculated from the combined history.

## Algorithm changes

Because Attempts remain historical evidence, LearningState can be recalculated when the learning algorithm changes.

## Time

Attempts store both:

- answered_at — device-reported event time;
- received_at — server receipt time.

Scheduling logic must not blindly trust device clocks when timestamps appear inconsistent.
