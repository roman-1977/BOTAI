# ADR-020: Offline-first unified material library

Status: Accepted

BOTAI Client accepts material from package import, CSV authoring, class/group assignment and the public library. These sources must not create four incompatible runtime models.

All installed content is normalized into one local SQLite model: material metadata, fields, knowledge rows and question-generation rules. Learning history references stable generated question identities derived from material/row/rule identity. Provenance is stored separately as source metadata.

A future BOTAI Studio produces and consumes the same `.botai` package format. Studio is optional tooling, not a runtime dependency.

The first package format is ZIP-based and versioned. Version 1 contains `manifest.json`, CSV content and optional `images/`. Import is validated and transactional. No external AI or paid per-user API is required for basic creation, import or learning.
