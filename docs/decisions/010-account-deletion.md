# ADR-010: Account deletion is a trusted server workflow

Status: Accepted

## Decision

Account deletion is not implemented as deleting the Profile row.

The user initiates deletion from the app.

A trusted backend workflow performs the deletion process.

## Conceptual flow

1. Authenticate and confirm the deletion request.
2. Stop or withdraw affected public UGC.
3. Resolve collaboratively authored content.
4. Remove user-owned drafts and personal media.
5. Remove personal learning/social data according to retention rules.
6. Revoke Sign in with Apple credentials/tokens when applicable.
7. Delete the authentication account.
8. Confirm completion to the user.

## Requirements

The flow must be easy to find in the app.

The app must offer deletion of the account, not merely deactivation.

If deletion requires processing time, the user should be informed.

## Server responsibility

Clients may request account deletion.

Clients do not directly execute destructive multi-table deletion.

Trusted server-side code owns the workflow so that partial deletion cannot
leave inconsistent public content or authentication state.
