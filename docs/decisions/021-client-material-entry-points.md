# ADR-021: Client material entry points

Status: Accepted

The learner client presents one common **My Materials** hub. Material can enter through exactly four visible routes: open a prepared BOTAI package, create/import from CSV, join a class/group, or download from the public library.

Client v1 implements CSV creation first and BOTAI package import next. Class/group and public library remain visible disabled/preview entry points until their flows are implemented. Account/profile remains accessible from Home but is not required for local materials or learning.

All routes ultimately produce the same local material model. Source (`created`, `importedPackage`, `assigned`, `library`) records provenance but must not create four incompatible study engines. Future BOTAI Studio must emit the same package/model rather than introducing a Studio-only format.
