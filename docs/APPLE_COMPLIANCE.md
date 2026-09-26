# Apple / App Store Compliance

BOTAI follows an App-Store-first development principle.

This document is a development checklist, not legal advice.

## User Generated Content

BOTAI will contain user-generated learning materials.

Architecture must support:

- moderation;
- reporting;
- blocking;
- suspension/removal of problematic content;
- suspension of abusive accounts;
- developer contact/support mechanism.

Public submission must not necessarily become immediately public.

Suggested lifecycle:

draft
→ submitted
→ in_review
→ published

## Account deletion

If users can create accounts, the app must provide an in-app path to initiate account deletion.

Personal data and learning data must be handled according to applicable requirements.

Published educational content is a separate lifecycle concern and must not be implemented using automatic database cascade deletion from User.

## Authentication

Sign in with Apple is planned as the primary iOS authentication mechanism.

## Children and teenagers

BOTAI is expected to be useful to school-age users, including minors.

The product is not currently planned specifically for Apple's Kids Category.

Privacy and data processing requirements for minors must nevertheless be considered separately.

## Privacy

Minimize collection of personal data.

Avoid unnecessary third-party SDKs.

Initial MVP should avoid advertising SDKs and unnecessary third-party analytics.

## AI

BOLDAI is post-MVP.

Before personal information, voice data or user content is sent to an external AI provider:

- the data flow must be documented;
- privacy implications must be reviewed;
- required user disclosure/consent must be implemented;
- AI credentials must remain server-side.

## Secrets

Never commit:

- API keys;
- service-role keys;
- Apple credentials;
- signing certificates;
- private keys;
- passwords;
- production secrets.

## Release checklist

Before App Store submission, review at minimum:

- current App Review Guidelines;
- privacy disclosures;
- account deletion;
- UGC moderation/report/block flows;
- authentication;
- age rating;
- permissions;
- subscription/payment rules if monetization is implemented.

## UGC publication and moderation

Public quizzes are user-generated content.

BOTAI must provide, before App Store submission:

- a method for filtering objectionable material;
- reporting of offensive/problematic content;
- timely handling of reports;
- user blocking;
- published developer/support contact information;
- moderation and removal procedures.

BOTAI uses a moderated publication lifecycle rather than automatically making
submitted user content public.

## Account deletion and UGC

The earlier concept that ordinary published UGC automatically survives author
account deletion has been rejected.

For ordinary UGC, account deletion must include associated user-created
content except where applicable law requires retention.

Collaboratively authored content requires separately defined rights and
deletion behavior.

## Sign in with Apple deletion

When an account using Sign in with Apple is deleted, the backend deletion
workflow must revoke the associated Apple credentials/tokens as required.

## Intellectual property

BOTAI editorial content and user-generated content must have distinct
provenance.

Deleting UGC must not be bypassed by silently relabeling a retained copy as
BOTAI editorial content.

Equivalent educational facts or curriculum may be independently authored,
subject to applicable intellectual-property rules.

## Social features and minors

BOTAI social functionality should minimize unnecessary exposure of school-age
users.

MVP social design uses:

- explicit friendship requests;
- explicit challenge invitations;
- private-by-default learning data;
- explicit sharing of result snapshots;
- blocking;
- reporting where public UGC is involved.

A global public learner leaderboard is not part of the MVP and would require
a separate privacy/safety review.
