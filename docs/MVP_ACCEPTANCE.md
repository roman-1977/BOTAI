# BOTAI MVP acceptance

Implemented verticals: account/Apple auth; local-first learning with GRDB and outbox; Supabase sync; reveal/pair/single/multiple question model; text/LaTeX/media rendering hooks; public library; own quiz authoring; publication submission/moderation schema; goals; adaptive daily plan; attempts/LearningState; week comparison and streak; friends/shared-result backend; challenges backend; reports/blocking; account deletion request; privacy manifest.

Release gates that require owner accounts/infrastructure rather than source code: Apple Developer signing/capability provisioning, configuring Apple provider in Supabase, App Store Connect privacy questionnaire/screenshots/metadata, moderator operations, and real-device TestFlight acceptance.

## Personal library acceptance

- Library opens the user's learning library first; shared discovery is a separate navigation step.
- Saving a created/imported quiz keeps it private and never submits it for moderation.
- An owned quiz can be opened, started and edited.
- A published quiz added from the shared library can be opened and started but not edited in place.
- `Create my copy` is the path for modifying shared content.
- Publication is an explicit workflow with catalog placement before moderation submission.
- Import provenance is administrative; learning runs from saved concrete question-answer items.
