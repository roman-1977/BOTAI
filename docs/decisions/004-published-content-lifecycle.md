# ADR-004: Published UGC lifecycle and account deletion

Status: Accepted

## Context

BOTAI allows users to create quizzes and submit them to a public library.

Earlier architecture considered allowing published content to survive deletion
of the author's account.

That model has been rejected for ordinary user-generated content.

## Decision

Publishing a user-created quiz does not transfer permanent ownership of that
UGC to BOTAI.

When the responsible user account is deleted, BOTAI must remove that user's
UGC from public distribution and delete associated user content according to
the account-deletion policy, except where retention is legally required.

Historical learning evidence belonging to other users is a separate domain.

Attempts and derived statistics do not become ownership of the deleted UGC
and may be retained only to the extent allowed by the applicable privacy and
data-retention policy.

## Shared authorship

Collaborative content requires special handling.

Deletion of one collaborator must not blindly delete content that is also
owned or maintained by remaining collaborators.

Before release, Terms of Service must define rights and responsibilities for
collaboratively authored content.

## BOTAI editorial content

BOTAI may independently create editorial learning material covering the same
facts or curriculum.

Editorial/system content must have its own provenance and must not be
implemented as a hidden retained copy of deleted UGC.

## Forks

A user-created fork is an independent Quiz with its own identity.

Deleting the original does not automatically delete independently authored
forks, subject to intellectual-property and content-policy requirements.
