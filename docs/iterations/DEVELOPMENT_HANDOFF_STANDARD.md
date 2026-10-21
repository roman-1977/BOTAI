# BOTAI — Mandatory iteration and handoff standard

Status: ACCEPTED by project owner, 2026-10-22. Applies to every development iteration, including v0.3.0.

## Definition of Done (mandatory for every iteration)

1. **Implementation**: explain what actually changed, affected files and data/migrations; no claims of completion without verification.
2. **Documentation**: update architecture, data model, product/UX, sync and user instructions **where impacted**; keep `docs/IMPLEMENTATION_STATUS.md` and active iteration log current.
3. **Progress**: record completed work, remaining work, blockers, assumptions, risks and exact next executable step in `docs/iterations/<iteration>.md`. Date each entry; link commits and test evidence.
4. **Tests**: add or revise unit/integration/UI/regression tests for every behavior change, including failures, offline and migration cases as relevant. Do not remove failing tests to make a release green.
5. **Verification**: run relevant test suites and build; log commands, environment, pass/fail counts and artifacts. If tests cannot run, document why and mark status unverified.
6. **Data safety**: preserve user work, document destructive operations and their authorized scope; avoid secrets in code, fixtures, logs or commits.
7. **Git**: use a feature branch, coherent commits and clean staged scope. Do not include unrelated pre-existing changes. Record branch, baseline, commit IDs and push status.
8. **Handoff**: ensure a new developer can start from the repository without chat history: environment setup, source of truth, decisions, current status, exact commands to reproduce, next tasks and known limitations.

## Handoff checklist

- [ ] Current branch and baseline identified
- [ ] Product/architecture decisions reflected in docs and ADRs
- [ ] Schema, migrations, fixture provenance and seed instructions documented
- [ ] Tests created/updated and results recorded
- [ ] Known bugs and unresolved questions recorded
- [ ] Progress and next concrete action recorded
- [ ] No secrets, no unrelated changes in commit
- [ ] Build and runtime state described accurately

## Rule

A code change without corresponding progress documentation and relevant test coverage is **not a completed iteration**. Update the handoff record at each meaningful checkpoint, not only at release time.
