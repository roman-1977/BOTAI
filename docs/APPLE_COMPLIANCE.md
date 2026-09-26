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
