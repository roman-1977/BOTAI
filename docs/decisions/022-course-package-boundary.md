# ADR-022: Material import and Course package boundary

Status: Accepted

## Decision
CSV/TSV/ZIP import creates a **Material**: source knowledge, media and rules that generate questions/answers.

A **Course** is a separate aggregate. It organizes one or more Materials into reusable sections/directions and adds learning methodology: sequencing, assignment/goal context, repetition/training policy and other course-level behavior. A Material may belong to multiple Courses.

`.botai` is the transport format for a ready learning product at Course level. The existing single-material Package v1 remains a tested compatibility prototype; it must not define the future UX. Course Package v2 will contain package metadata/author, `materials[]`, course structure/relationships, methodology and portable media.

## Consequences
The Material screen offers table import, not `.botai` as a peer source. Course import owns `.botai`. Account, class/group and public-library buttons may remain placeholders until their domain flows are implemented. Manual material creation is removed from the current client surface.
