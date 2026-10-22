# BOTAI v0.3.0 — Release Candidate readiness audit

Date: 2026-10-22. Branch: `feature/v0.3.0-chemistry-pilot`. Baseline implementation: `a19a376`. Status: **NOT RC / audit only**. No release tag, archive, TestFlight upload or push.

## Evidence and boundaries

- Local-first learning, account-scoped GRDB, v15 resumable-session snapshot, atomic answer+cursor: implemented. Last full `LaunchSmokeTests` before atomic change: **14/14 PASS** (`/tmp/botai_resume_regression_20261022.log`). After atomic change: focused UI **2/2 PASS** (`/tmp/botai_resume_atomic_ui_20261022.log`), focused unit **2/2 PASS** (`/tmp/botai_resume_unit_20261022.log`). Full subsequent verification: **105/105 Swift Testing, 15/15 standard UI, 2/2 separately seeded chemistry UI PASS** (2026-10-22; `docs/iterations/USER_TESTING_READINESS_2026-10-22.md`).
- Live Supabase development checks dated 2026-10-21: 11/11 RLS checks and explicitly enabled `LiveSupabaseSyncTests` passed per `docs/STAGE6_SYNC_VERIFICATION.md`. Coverage limited to supported text publishing/attempts. Choice and media/LaTeX attempts currently stay local. Do not claim all modes cloud-synced.
- `docs/MVP_ACCEPTANCE.md` describes implemented verticals but is not a signed-off acceptance test report. Product decisions in `docs/UI_SPEC.md` and iteration logs take precedence over outdated status prose.
- No real iPhone/TestFlight/Apple review acceptance has been verified in this audit. User-owned `ios/BOTAI.xcodeproj/project.pbxproj` is modified independently and must not be staged or reverted.

## Mandatory RC gates (all must be PASS or explicitly scoped out by owner)

| ID | Gate / measurable acceptance | Current state | Next executable verification |
|---|---|---|---|
| RC-01 | Starting session defaults to system strategy; manual subject/topic/mixed, format and review overrides work without persisting transient choices; resume preserves original settings | PARTIAL | UI test each launch path and resume with different formats; inspect session strategy implementation |
| RC-02 | Multi-question restart resumes exact ordered next question, counts each answer once; background and explicit finish semantics are clear | PARTIAL | End-to-end 2+ question relaunch test, finish/discard test, crash/rollback and account-isolation tests |
| RC-03 | Reveal, pair, single and multiple choice, empty-column card generation and imported chemistry content behave correctly | PARTIAL | Run existing card-generation and chemistry fixtures; test full session in all four modes |
| RC-04 | Adaptive selection, due scheduling, goal priorities, teacher guidance and difficulty follow agreed product rules | OPEN — spec/implementation gap | Compare code to accepted rules, define deterministic scenario tests; do not imply full teacher-guided algorithm exists |
| RC-05 | Home light theme fits one standard iPhone screen without scrolling; full-width half-height chart, pace/lag and CTA correct; Learn dark; VoiceOver/Dynamic Type adequate | UNVERIFIED visually | Screenshot/measure on small/standard/large simulators and actual device; accessibility audit |
| RC-06 | Offline launch, answers, relaunch, migration, reconnect and no duplicated attempts; sync support explicitly documented for every MVP format | PARTIAL | Offline/reconnect integration tests, schema migration upgrade, RLS, unsupported format policy |
| RC-07 | Import/author/edit/private/public and moderation/report/block/deletion workflows satisfy App Review constraints | PARTIAL | Test user flows and moderator operations; review `docs/APPLE_REVIEW_CHECKLIST.md` |
| RC-08 | Full post-change unit/integration/UI and chemistry smoke suite green, no test-fixture contamination | PASS for committed resume changes (`b09f6ea`): 105 unit + 15 standard UI + 2 seeded chemistry UI | Rerun after any further code changes; chemistry requires separate seeded DB |
| RC-09 | Signing, bundle/version/build, privacy policy, data disclosures, age rating, screenshots, App Store metadata and TestFlight install | NOT VERIFIED | Apple Developer/App Store Connect setup and physical-device acceptance |
| RC-10 | Documentation, migration/rollback and handoff reproducible; no secrets or unrelated edits in RC commit | PARTIAL | Update affected specs, review clean diff, handoff and release notes; tag only after gates |

## Prioritization

**P0 before internal RC:** RC-01, RC-02, RC-03, RC-04 (or explicit bounded MVP policy), RC-05, RC-06, RC-08. **P0 before external TestFlight/App Store:** RC-07, RC-09, RC-10. Some gates overlap; do not treat this table as independent day estimates.

**Post-MVP unless owner reopens:** AI exam/BOLDAI, richer social features, advanced multimedia beyond agreed MVP. Existing moderation/account/privacy obligations are **not** deferrable if their corresponding features are exposed.

## Risk register

1. **High:** server publication currently excludes choice and media/LaTeX attempt paths; offline and multi-device behavior may diverge.
2. **High:** teacher-guided adaptive strategy not fully implemented; product behavior must be specified before claiming learning quality acceptance.
3. **High:** public UGC/moderation/account deletion and Apple compliance require operational checks, not just schema presence.
4. **Resolved for tested paths:** two-question resume and unanswered-question resume both passed end-to-end UI tests.
5. **Medium:** home screen no-scroll visual gate and accessibility unverified across devices.

## Handoff / exact next action

1. Implement an isolated UI test that answers question 1 of 2+, terminates the app, relaunches, verifies question 2, completes and verifies exactly two persisted attempts.
2. Run serial full UI regression and existing BOTAITests on iPhone 16e simulator (`33176212-1247-4722-B8F4-4E53438502E4`) with `CODE_SIGNING_ALLOWED=NO`; separately run guarded chemistry fixture script `tools/chemistry_pilot/run_simulator_smoke.sh` on disposable simulator only.
3. Audit format/strategy selection and adaptive planning against accepted decisions; turn findings into concrete tests and fix plan.
4. Keep `docs/IMPLEMENTATION_STATUS.md` and active iteration log synchronized. Preserve user-owned `project.pbxproj`. Do not touch physical iPhone or production data without authorization.

### RC-06 product decision update (2026-10-22)

The accepted sync contract is now **completed-session aggregates only**; detailed question attempts and spaced repetition stay local. The previously proposed expansion of server choice-question publication is **cancelled**. RC-06 remains PARTIAL until durable completion-only summary sync, migration, RLS, retries, and tests are implemented. Authoritative plan: `docs/iterations/SESSION_SUMMARY_SYNC_DECISION_2026-10-22.md`.
