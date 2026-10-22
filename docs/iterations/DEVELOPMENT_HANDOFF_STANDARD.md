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

## Verification tiers — accepted 2026-10-23

The owner superseded the previous practice of running the entire signed simulator UI suite after each small edit. **Do not weaken the requirement to test each behavior change.** Choose the smallest defensible test scope, and document the exact command and results:

- **Documentation-only**: check affected references and `git diff --check`; no simulator run unless documentation changes executable setup.
- **Localized implementation**: compile the app and run targeted unit tests plus the directly affected UI tests if behavior is visible. Add/update regression coverage for the changed behavior.
- **Auth, persistence, account isolation, migrations, sync**: run the relevant security/data unit and integration suites and focused UI paths, including failure/offline cases. Broaden to full regression if a change affects shared bootstrap, navigation, or multiple stores.
- **Completed milestone / release candidate / before release**: run the complete signed unit and UI regression suites, plus required live-backend and device acceptance separately. A simulator green result does not imply live backend acceptance.

Prefer **one substantial, coherent implementation batch** followed by its verification and one self-contained commit. Avoid multiple background test queues, overlapping `xcodebuild` processes, and repetitive full regressions. If a full regression is already running, allow it to finish rather than starting a duplicate. Each commit still requires current documentation, changed-behavior tests, build evidence, and explicit limitations. Record deferred full-regression debt in the active milestone log; never describe it as passed.

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
