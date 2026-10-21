# BOTAI — pre-refactor architecture and UX audit

Date: 2026-10-21. Scope: current implementation, no new features. Evidence: repository source, existing architecture/UI documents and stage-6 tests. This is a **static code/design review**, not a visual audit on multiple device sizes. Screenshots, VoiceOver and Dynamic Type require a separate hands-on pass before visual sign-off.

## Executive assessment

The local-first separation of domain models, GRDB repositories, observable stores and an actor-based sync service is a good foundation. The main issues are *consistency and observability*, not a need for a new framework. Existing UI contains a recognizable dark/cyan visual direction, but screens do not share a coherent tokenized design system. `docs/UI_SPEC.md` calls for a neutral, serious-learning home with four tabs, while the actual `RootTabView` displays only `GameHomeView` (no tabs), with dark digital/game styling. Resolve the product direction **before** restructuring view code.

## Findings, prioritized

| Priority | Area | Verified evidence | Risk | Refactor direction |
|---|---|---|---|---|
| P0 | Persistence errors | `BOTAIApp.swift` can fall back to nil repository if opening `learning.sqlite` fails; `CourseStore.swift`, `StudyProfileStore.swift`, `LearningStore.saveSession` use `try?` for writes | UI can appear functional with unsaved data; silent data loss | Typed `StorageState` (loading/ready/recoverableFailure), throwing repository operations and explicit UI error feedback; never silently switch to ephemeral learning |
| P0 | UI/document mismatch | `RootTabView.swift` is a single-line wrapper around `GameHomeView`; `docs/UI_SPEC.md` specifies Today/Library/Progress/Profile tabs and a light neutral home | Inconsistent information architecture; costly refactor if direction unclear | Decide navigation and home identity; retain existing features, no new tabs unless already agreed as the intended navigation |
| P1 | Sync observability | `SyncService.flush` swallows publication, mapping, and upload errors using `try?` | Users cannot distinguish offline, queued, failed, synced | `SyncStatus` state machine and typed outcomes, unobtrusive account/sync status in existing profile surface; retry policy and diagnostics |
| P1 | Learning view complexity | `LearnSessionView.swift` ~543 lines, 20+ `@State` fields; timer, answer selection, progress, layout and mode controls co-located | Difficult testing, regressions when changing layout | `StudySessionModel` with explicit state transitions; extract QuestionCard, AnswerArea, SessionHUD, ModeSheet, CompletionView; preserve behavior |
| P1 | Visual inconsistency | `GameHomeView.swift`, `LearnSessionView.swift`, `AddMaterialView.swift` hard-code cyan/white/black and gradients; other screens use system Form/List | Fragmented look; light/dark and contrast inconsistencies | Semantic color/spacing/typography tokens, shared buttons/cards/empty states; one design system |
| P1 | Accessibility | `LearnSessionView` hardcodes card heights, ring widths 68pt and labels at 9–10pt; home metrics 8pt; many fixed 42–54pt targets | Text clipping with Dynamic Type, VoiceOver comprehension, minimum touch targets | Dynamic Type-aware metrics, scalable layout, accessibility labels/values, 44pt+ hit areas, reduced motion; automated plus manual audits |
| P1 | Demo/production boundary | `LearningStore` defaults to `DemoContent.questions`; `TodayView`, `PlansView` reference `MVPDemoData` and `GameDemo` | Sample data can be mistaken for user data; confusing onboarding and statistics | Explicit preview/demo fixtures, real empty state, test-only seed injection; avoid implicit demo fallback |
| P1 | Test coverage | 73 unit tests, 9 UI tests, live sync and RLS probe verified at stage 6; full suite previously saw transient accessibility snapshot errors | Good logic confidence, incomplete visual/device coverage | Screenshot baselines for small/large iPhone, dark/light, large text; VoiceOver and offline/account-switch exploratory matrix |
| P2 | Dependency wiring | `BOTAIApp.swift` creates multiple repositories/stores and manages account switching, sync and test fixtures | Root composition too coupled to infrastructure | `AppContainer`/composition root and explicit account-scoped `SessionContext`; dependency injection via initializers/environment |
| P2 | File readability | Several feature views use highly compressed single-line Swift declarations (`GameHomeView`, `TodayView`, library screens) | High review cost and fragile diffs | SwiftFormat conventions, one declaration per line, modular components, naming consistency |
| P2 | Source of truth | `docs/IMPLEMENTATION_STATUS.md` snapshot 2026-10-01 is stale after stage 6 | Decisions based on outdated implementation status | Refresh implementation status and link to stage 6 verification; separate current vs target capabilities |
| P2 | Security / long-term history | Attempt snapshots and account isolation exist; migration history and multi-device pull are still distinct concerns | Overclaiming complete sync or production readiness | Keep stage-6 scope explicit; test migrations with real old DB fixtures, verify historical deletion cases |

## Recommended design approach

**Positioning:** serious, modern educational utility with gentle motivation. Keep the engaging dark study mode as a focused *learning surface*; simplify surrounding navigation and forms. Avoid making every screen look like a neon game. One primary action per screen, secondary content lower in hierarchy.

**Recommended palette A — Calm Indigo (preferred):** light canvas `#F7F9FC`, surface `#FFFFFF`, ink `#182338`, secondary `#64748B`, primary `#3455D1`, primary pressed `#2843AA`, success `#16856B`, warning `#B66B13`, destructive `#C43E4B`, separator `#E3E9F2`. Dark learning canvas `#10192E`, card `#192640`, ink `#F4F7FD`, primary accent `#72B7FF`, success `#5AD5AF`. Preserve semantic meanings, not arbitrary green/red correctness alone.

**Alternative B — Teal Slate:** light canvas `#F5F8F8`, ink `#172A32`, primary `#087F83`, surface `#FFFFFF`, dark canvas `#0E2028`, dark card `#18343E`, accent `#65D2CE`. Quieter, more scientific; risk of overly low distinction between secondary and primary actions.

**Alternative C — Warm Academic:** light canvas `#FAF8F3`, ink `#282B36`, primary `#4E5EC7`, warm accent `#D78D43`, dark canvas `#171B2C`, dark card `#252C43`. Friendly, but warm accent must be reserved for meaningful emphasis.

These are **proposed tokens**, not measured WCAG-compliant pairings. Validate contrast per foreground/background pairing and state. Prefer SF system text styles and Dynamic Type over fixed 8–10pt labels. Use SF Symbols consistently. Use restrained elevation/borders; gradients only for the principal call to action or session atmosphere, not every card. Avoid relying on color to indicate correctness.

## Navigation and key journeys to review

1. First launch with no material: show an honest empty state, single next action, no fictional learning progress.
2. Material import/create: clear step sequence, preview, actionable validation errors, cancellation without residue.
3. Set course/goal: separate hierarchy from study action, maintain orientation/back navigation.
4. Daily home: primary next action, concise goal progress, optional streak; no misleading mastery or readiness.
5. Study session: readable question, obvious answer action, clear paused/completed states, no unexpected card movement; large text and landscape testing.
6. History/progress: labels with clear denominator/time period, no ambiguous mastery percentages.
7. Offline/auth/sync: queued changes must remain usable, user can understand sync state without alarming banners.

## Target architecture (evolution, not rewrite)

`AppContainer` (account-scoped dependencies) → `Feature View` + `@Observable Feature Model` → `Use Case` (study session, material import, sync) → `Repository protocol` → GRDB implementation. `SyncCoordinator` actor works through typed interfaces; Supabase adapter remains outside views. Domain scheduling and question generation stay pure/testable. Introduce abstractions at real boundaries only; avoid protocol-for-every-type and wholesale MVVM conversion.

**Design system:** `DesignSystem/{ColorTokens,Typography,Spacing,Components}`. Use semantic tokens and reusable controls; keep learning mode's dark theme as a scoped variant rather than globally forcing `.preferredColorScheme(.dark)` for unrelated screens.

## Refactor sequence with acceptance gates

1. **Baseline and design decision:** capture current screens and journeys; approve navigation + palette + light/dark behavior; save screenshot baseline. No functional changes.
2. **Safety first:** explicit database/bootstrap/write errors and account-scoped dependency container. Gate: migration/identity/outbox tests and no silent fallback.
3. **Study state extraction:** separate session model and UI components. Gate: existing 73 unit + 9 UI tests, answer/timeout/background/finish behavior parity.
4. **Design system:** implement tokens and components; apply to home, study, library, profile without changing features. Gate: screenshot comparison and accessibility review.
5. **Consistency cleanup:** demo boundaries, code formatting, docs, error/empty/loading states. Gate: fresh-install/offline/relaunch/account-switch/import/export matrix.
6. **Final validation:** simulator matrix (compact + large iPhone, large text, dark/light), VoiceOver, Reduce Motion, contrast, UI snapshots, live Supabase smoke; report known limitations explicitly.

## What NOT to do

No new learning modes, AI examination, social features, cloud media sync or public-content workflows in this refactor. Do not swap GRDB, SwiftUI, or Supabase merely for architectural fashion. Do not redesign the learning algorithm while refactoring presentation. Do not conflate visual acceptance with passing unit tests.

## Review status

**Code/architecture audit:** completed against current files. **UX recommendations and candidate palettes:** prepared. **Rendered-screen audit:** pending capture on actual simulator/device; therefore visual issues beyond source-evident problems remain hypotheses. **Implementation:** not started, awaiting selection of visual direction and navigation treatment.
