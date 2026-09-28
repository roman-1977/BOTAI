# ADR-022: Library, courses and assignments

Status: Accepted

The Materials screen is a library first and an import surface second. Its primary split is **Personal / Group**.

Personal materials are owned by the learner regardless of provenance (created locally, imported from a file, or added from the public library). They can be filtered by provenance and removed from the learner's library.

Personal organization uses **Course → Section** rather than filesystem folders. A course is optional. Sections may be nested. A material is stored once and may be linked to several sections/courses without duplication; learning history follows the material/knowledge, not the link.

An **Assignment** defines what the learner intends or is required to study. It can select one or more materials (later, subsets of material) and has zero or more measurable goals such as questions/day, active minutes/day, mastery target, or deadline. Assignments are what the start/resume flow will offer to the learner.

Group/class libraries use the same conceptual material/course/section/assignment model, but ownership and edit rights belong to a teacher/parent. Learners may study and view their progress but cannot change group structure, assigned material, or imposed goals.

The `+` action is secondary and opens sources: import file, public library, manual creation, or join group. Public library and group connectivity remain UI placeholders until their implementation stage.
