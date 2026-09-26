# ADR-006: SQLite + GRDB for local persistence

Status: Accepted

## Decision

BOTAI will use SQLite through GRDB for local persistence on iOS.

## Reasons

BOTAI is local-first. The local database is not merely a UI cache.

It must support:

- offline learning;
- large question collections;
- learning state;
- append-only attempt history;
- study sessions;
- goals;
- downloaded content;
- pending synchronization;
- explicit migrations;
- efficient Learning Engine queries.

GRDB provides direct and predictable access to SQLite while allowing the rest of the application to remain independent from the persistence implementation.

## Architecture

SwiftUI
↓
Features
↓
Repositories
↓
GRDB / SQLite

SwiftUI views must not access GRDB directly.

## Server relationship

Server: PostgreSQL / Supabase.

Device: SQLite / GRDB.

The schemas do not need to be identical, but stable UUID identifiers and compatible domain models should make synchronization explicit and predictable.

## Migrations

Local database migrations must be explicit and version-controlled in Git.

## Consequence

The Sync Engine is a first-class architectural component.
