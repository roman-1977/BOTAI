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

## Current architecture status

MVP scope and core architecture are approved. The repository contains a working SwiftUI/GRDB iOS client: learning flow, local material library, CSV/TSV/ZIP import, media handling, question-set authoring and material preview. Course/package architecture is the next design milestone.

Core stack: Swift/SwiftUI, GRDB/SQLite local-first persistence, Supabase/PostgreSQL/Auth/Storage, and trusted server functions for privileged workflows.

Architecture decisions are recorded in `docs/decisions/`; accepted ADRs take precedence over older working notes.

Next milestone: separate Material from Course. Table import remains a Material workflow; the `.botai` transport evolves into a Course package containing materials, structure and methodology. Account/class/public-library surfaces remain intentionally shallow until that model is fixed.

Product UX drafts: `docs/GOALS_PROGRESS.md` and `docs/SCREEN_FLOW.md`.

### Для пользователей
- [Подготовка CSV/TSV и ZIP с изображениями](docs/USER_IMPORT_GUIDE.md)
- В инструкции также есть готовые промпты для подготовки материалов с помощью ИИ.
