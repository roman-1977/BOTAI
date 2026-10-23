> **CONFIRMED 0.3.1 BETA RELEASE (2026-10-23):** 28/28 UI PASS, signed iPhoneOS BUILD SUCCEEDED, branch/tag pushed and GitHub prerelease published: https://github.com/roman-1977/BOTAI/releases/tag/v0.3.1-chemistry-beta . See `docs/iterations/FINAL_HANDOFF_2026-10-23.md` for authoritative limitations: local SQLite learning progress retained, cloud learning sync OFF, physical device acceptance pending. Previous in-progress notices are historical.

> **CURRENT HANDOFF — 2026-10-23, BOTAI 0.3.1 CHEMISTRY BETA:** Owner authorized learner testing and mandated durable progress. Current implementation removes pilot launch/account-switch learning reset; SQLite progress survives restarts, per device/account. Remote learning sync remains deliberately OFF pending reconciliation of stale cloud pilot progress; it is **not** cloud-backed. Full new regression is running in `/tmp/botai_042_release_full.log`; signed iPhoneOS build and GitHub prerelease are gated on its success in `/tmp/botai_044_beta_release_gate.log`. **Do not claim release published until logs and remote tag/release are verified.** User-edited `ios/BOTAI.xcodeproj/project.pbxproj` must remain untouched and uncommitted. Authoritative current state: `docs/iterations/V031_CHEMISTRY_BETA_RELEASE.md` and `docs/iterations/FINAL_HANDOFF_2026-10-23.md`. Prior 0.3.0 release notes are historical. Physical iPhone acceptance, account sign-in, and safe cloud synchronization remain OPEN.

# BOTAI

BOTAI — приложение для запоминания больших объёмов структурированной информации и подготовки к проверке знаний.

## Концепция

**БОТАЙ → БОЛТАЙ → ЗНАЙ**

- **БОТАЙ** — запоминание и повторение утверждённого учебного материала.
- **БОЛТАЙ (BOLDAI)** — AI-экзамен по уже изученному материалу.
- **ЗНАЙ** — цель: не просто увидеть правильный ответ, а устойчиво помнить и понимать материал.

Первый основной сценарий — подготовка школьника к ЕГЭ по нескольким предметам.

Архитектура продукта не должна быть жёстко привязана к ЕГЭ: тот же механизм должен впоследствии подходить для языков, медицины, профессионального обучения и других областей.

## Status

Active iOS MVP development. Offline learning and material import are implemented and under iterative testing.

См. документацию в `/docs`.

## Current implementation status

Working SwiftUI/GRDB local-first iOS client. Implemented now: persistent Materials and Courses/Goals, CSV/TSV and BOTAI Package v1 material import/export, generated card/choice questions, stable question IDs, Attempts/LearningState/StudySessions, local daily planning, and deletion that retains learning history.

Supabase auth/publication/social and Attempt-upload scaffolding exist, but full multi-device sync, account-scoped local stores, public-library/class acquisition and Course Package v2 are not complete.

See docs/IMPLEMENTATION_STATUS.md for the implementation-vs-target snapshot. Accepted ADRs remain authoritative for target architecture.

### Для пользователей
- [Подготовка CSV/TSV и ZIP с изображениями](docs/USER_IMPORT_GUIDE.md)
- В инструкции также есть готовые промпты для подготовки материалов с помощью ИИ.
