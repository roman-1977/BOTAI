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
