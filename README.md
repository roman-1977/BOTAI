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

Architecture approved; implementation preparation.

См. документацию в `/docs`.

## Current architecture status

MVP scope and the core architecture are approved. The repository currently contains the backend data-model design (`0001`–`0004`) and accepted architecture decisions. iOS implementation has not started yet.

Core stack: Swift/SwiftUI, GRDB/SQLite local-first persistence, Supabase/PostgreSQL/Auth/Storage, and trusted server functions for privileged workflows.

Architecture decisions are recorded in `docs/decisions/`; accepted ADRs take precedence over older working notes.

Next executable milestone: offline Learn vertical slice backed by GRDB with durable idempotent sync outbox.

Product UX drafts: `docs/GOALS_PROGRESS.md` and `docs/SCREEN_FLOW.md`.

### Для пользователей
- [Подготовка CSV/TSV и ZIP с изображениями](docs/USER_IMPORT_GUIDE.md)
- В инструкции также есть готовые промпты для подготовки материалов с помощью ИИ.
