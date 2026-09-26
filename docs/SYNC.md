# BOTAI Sync Architecture

Status: Data/Sync v1.

## Principles

BOTAI is local-first.

Core study functionality must continue without network access.

The backend is authoritative for published content.

User learning activity is recorded locally first and synchronized when possible.

## IDs

All synchronized entities use UUID identifiers.

UUIDs may be created offline on the device.

This avoids local/server numeric-ID mapping.

## Content ownership

Published content is controlled by its author/editorial lifecycle.

Learning history belongs to the learner.

Updating published content must not overwrite or destroy personal learning history.

## Attempts are events

Attempts are append-oriented learning events.

Example fields:

- id
- user_id
- question_id
- question_version_id
- direction
- result
- confidence
- answered_at
- device_id

After creation, normal application behavior should not rewrite an Attempt.

This makes multi-device and offline synchronization substantially safer.

## LearningState is derived

LearningState represents the current calculated learning condition of a question/direction.

It is derived from learning events rather than being the sole historical source of truth.

Conceptually:

Attempts
↓
Learning Engine
↓
LearningState

The device maintains a local LearningState for immediate operation.

The server may maintain/recalculate canonical state using synchronized Attempts.

## Pair directions

For bidirectional pairs, A→B and B→A may have independent LearningState records.

Example:

H₂SO₄ → Серная кислота: strong

Серная кислота → H₂SO₄: weak

## Question versioning

Question has a stable identity.

QuestionVersion contains a particular published representation.

An Attempt records both:

- question_id
- question_version_id

Minor corrections therefore do not necessarily destroy learning history.

A materially different learning item should normally receive a new Question identity.

## Offline write flow

When the learner answers a question offline:

1. create Attempt locally;
2. update local LearningState;
3. update current StudySession;
4. add required synchronization operation;
5. continue immediately without waiting for network.

## Sync queue

The local database contains a durable synchronization queue.

Conceptual fields:

- id
- entity_type
- entity_id
- operation
- created_at
- attempt_count
- last_error

Synchronization operations must be idempotent.

Retrying upload of an Attempt with the same UUID must not create duplicates.

## Content download

The complete public library is not stored on every device.

The device downloads content selected by the user plus required metadata/media.

## Remote content updates

Example:

A learner downloaded Quiz version 1.0.

While the learner is offline, the author:

- edits 5 questions;
- archives 2 questions;
- adds 15 questions.

The learner also creates 47 Attempts.

After reconnecting:

1. the 47 Attempts are uploaded;
2. new content metadata is downloaded;
3. changed QuestionVersions replace local presentation data;
4. archived questions stop appearing in future study queues;
5. historical Attempts remain valid;
6. new questions become available;
7. compatible LearningState remains associated with stable Question IDs.

## Conflicts

The initial conflict philosophy is domain-specific rather than universal last-write-wins.

Published content:
server publication/version state wins.

Attempts:
merge by unique event UUID.

LearningState:
reconcile/recalculate from merged learning evidence.

Goals and other mutable personal records:
conflict rules will be specified separately.

## Deletion

Soft deletion/tombstones should be used only where synchronization semantics require them.

Do not automatically add deleted_at to every table.

Historical learning events should not disappear merely because published content is later archived.

## Future BOLDAI

BOLDAI may later create additional learning evidence or knowledge-gap signals.

The existing synchronization model must allow those signals to influence LearningState without changing the identity of existing content.

## Canonical LearningState

Canonical server LearningState is not directly writable by normal clients.

iOS calculates and stores a local LearningState for immediate offline operation.

Devices synchronize Attempts rather than competing LearningState updates.

After Attempts from multiple devices are merged, trusted server-side logic calculates canonical LearningState.

This prevents last-write-wins loss when several devices study offline concurrently.

## Publication synchronization

Only published and currently available QuizVersions are exposed through the
public library.

Drafts and submissions are not public synchronization sources.

If a publication is suspended or withdrawn, future synchronization must stop
offering it as available public content.

Historical learning events are not automatically deleted merely because a
publication becomes unavailable.

Exact removal of cached UGC from devices during account deletion or content
withdrawal will be defined in the local sync implementation.
