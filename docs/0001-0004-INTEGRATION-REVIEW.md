# Integration review: migrations 0001–0004

Status: Completed 2026-09-26

## Scope

Reviewed Identity/Content, Learning, Publication/Moderation and Social/Challenges as one PostgreSQL schema.

## Blocking findings

1. `0003` uses composite foreign keys to `quiz_versions(quiz_id, id)`, but `0001` did not expose that pair as a unique key. A clean migration run would fail.
2. Enrollment stored both `quiz_id` and `quiz_version_id` without enforcing that the version belongs to the quiz.
3. Attempts could similarly associate a quiz with a version from another quiz.
4. Answer option versions did not enforce that an option and QuestionVersion belong to the same Question.

## Security / lifecycle findings

- Canonical `LearningState` is correctly read-only to normal clients.
- Attempts are append-oriented and have no client UPDATE policy.
- Publication/moderation state is server-controlled.
- Challenge results are server-controlled.
- Friendship and challenge state transitions still require trusted RPC/Edge Functions before implementation.
- Account deletion is intentionally a trusted workflow rather than a SQL cascade.

## Documentation drift

`DATA_MODEL.md`, `OPEN_QUESTIONS.md`, `README.md` and `AGENTS.md` contained decisions superseded by accepted ADRs. They must not be used to override accepted decisions.

## Outcome

The blocking relational-integrity issues are fixed in the design migrations before first deployment. The next architecture layer is the local GRDB schema and synchronization contract.

## Remaining implementation gates

Before connecting a real iOS client, add trusted operations for friendship responses, challenge invitations/responses, publication transitions, moderation actions, canonical learning-state recalculation, challenge-result calculation, and account deletion. Their absence is intentional at schema-design stage, but direct client writes must not be opened as a shortcut.

## RLS note

The current content-authoring child tables remain intentionally closed to normal clients because their complete collaborator-aware write policy is not yet implemented. This is safe-by-default but means the content editor cannot be connected directly to these tables yet. Authoring access must be completed before ContentEditor implementation rather than by adding permissive blanket policies.

## Next step

Create the iOS skeleton with GRDB and implement the first local migration around the offline Learn vertical slice. Do not attempt to implement every backend table locally on day one.

The review is architectural/static. A clean PostgreSQL/Supabase migration execution test remains required before the schema is treated as deployable.

Accepted ADRs created by this review: ADR-013 (local sync contract), ADR-014 (composite identity/version integrity), ADR-015 (local account isolation).

No production database exists according to the migration headers; if that assumption changes, do not deploy the edited historical migrations over an existing environment without reconciliation.

A later pre-deployment review should also exercise RLS with real authenticated Supabase sessions; static SQL review cannot prove all policy interactions.

Review did not introduce a universal mutable-record conflict rule; goals/profile/editor drafts still need explicit sync semantics when their offline editing UI is implemented.

The review intentionally favors database-enforced invariants and safe-by-default RLS over convenience shortcuts.


