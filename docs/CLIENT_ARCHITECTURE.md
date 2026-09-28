# BOTAI Client architecture

## Product boundary

BOTAI Client is the complete learner application. A future BOTAI Studio may make authoring faster, but the client must remain able to import and create study material without Studio.

Material can enter the client through exactly four first-class sources: a prepared `.botai` package, local CSV creation, a class/group assignment, or the public library. Once installed, all four sources use the same local material model; provenance is metadata, not a different runtime type.

## Offline-first storage

SQLite/GRDB is the source of truth for installed materials, question rules, learning state, attempts, goals and session state. Network services synchronize or deliver material but are never required to open an already installed material or continue learning.

`StudyMaterialRecord` describes the material. `MaterialField` describes its columns. `KnowledgeRow` stores source facts. `QuestionRule` describes how facts become cards/tests. Generated study questions are views of those facts/rules, not duplicated canonical content.

Media belongs to the material and is stored under Application Support using stable relative paths. Database rows must never depend on temporary import URLs.

## Package format v1

A `.botai` file is a ZIP container with `manifest.json`, one CSV data file, and an optional `images/` directory. `manifest.json` declares format version, metadata and question-generation rules. Import must validate paths, version, CSV shape and media references before committing anything to the library.

Package import is transactional: stage → validate → preview → commit. Failed/cancelled imports leave no partial material. Export uses the same format so future Studio and Client remain interoperable.

## Client navigation

Home answers “what should I study now?”. My Materials answers “what can I study?”. Add Material exposes four routes: Open BOTAI package, Create from CSV, Join class/group, Public Library. Profile contains account/sync/privacy/app preferences. Runtime learning modes stay inside Learn and are not global settings.

## Future sync

Supabase IDs map to local UUIDs and synchronize metadata/content revisions. Assigned/library materials may be read-only locally while created/imported materials are owned by the user. The local database remains usable while signed out; account connection adds sync rather than unlocking basic study.
