# ADR-004: Published content survives author account deletion

Status: Accepted conceptually

## Context

Users may create learning material and submit it to the public BOTAI library.

Other users may depend on published material and accumulate learning history against it.

## Decision

Private drafts belong to the user's personal workspace.

Accepted published learning content has an independent lifecycle.

Deleting the original author's account must not automatically delete published educational material.

## Consequences

Database relationships must not use destructive cascade deletion from User to published content.

Author identity may need to be anonymized or otherwise handled according to publication terms, privacy requirements and applicable law.

Publication terms and licensing require separate legal/product specification.
