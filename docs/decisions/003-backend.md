# ADR-003: Supabase / PostgreSQL backend

Status: Accepted as working architecture

## Decision

BOTAI will use Supabase as the initial backend platform.

Core technologies:

- PostgreSQL;
- Supabase Auth;
- Storage;
- Row Level Security;
- Edge Functions.

## Reasons

BOTAI has strongly relational data:

- content hierarchy;
- users and enrollments;
- question learning states;
- authors and publications;
- versions;
- friendships;
- challenges;
- moderation.

PostgreSQL is a natural fit for these relationships.

Supabase also provides the backend primitives required for MVP without requiring a custom server platform from day one.

## Constraint

The iOS UI must not become tightly coupled to Supabase.

Local persistence and repository/sync layers isolate the application from the backend implementation.
