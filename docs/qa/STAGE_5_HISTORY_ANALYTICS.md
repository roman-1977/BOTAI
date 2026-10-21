# Stage 5 — History, analytics and integrity

Status: accepted and closed (simulator).

## Baseline
- Study sessions, attempts and learning states persist in SQLite.
- Existing `DeletionHistoryTests` cover retention of learning history after deleting materials or courses.
- `StudentProgressView` already reads live `LearningStore` analytics.

## Changes
- Removed static `GameDemo`/`MVPDemoData` metrics and fabricated achievements from `ProgressDashboardView`.
- The dashboard now displays actual mastery, answer totals, accuracy, study time and recent persisted sessions, including an empty state.
- Simulator Debug build: **BUILD SUCCEEDED** (`/tmp/botai_stage5_dashboard_build.log`).

## Acceptance results
- Added `LearningAnalyticsRegressionTests` for aggregate counts, accuracy, UTC calendar-day grouping and empty-state zero metrics. **2/2 passed** (`Test-BOTAI-2026.10.21_17-37-05-+0300.xcresult`).
- Added `repeatedSessionUpdatesAndMaterialDeletionPreserveTotals`: session upsert remains one record, persisted counters survive reload and linked material deletion does not erase attempts. **3/3 DeletionHistoryTests passed** (`Test-BOTAI-2026.10.21_17-38-10-+0300.xcresult`).
- Note: SQLite date round-trips can differ in subsecond precision; assert stable IDs and durable integer counters rather than exact Date equality.
- Full iPhone 16 Pro Max iOS 18.6 simulator suite: **45/45 passed** (36 unit + 9 UI, zero failures/skips), verified using `xcresulttool get test-results summary` for `Test-BOTAI-2026.10.21_17-38-44-+0300.xcresult`.

## Stage decision
**Stage 5 accepted and closed** for simulator coverage. Physical-device E2E and release acceptance are later stages.
