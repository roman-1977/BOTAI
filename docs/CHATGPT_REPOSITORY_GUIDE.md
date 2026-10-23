# BOTAI — инструкция для ChatGPT: где искать правду о проекте

**Обязательно прочитать перед началом работы в новом чате или после передачи задачи.** Дата актуализации: 2026-10-23. Репозиторий — первичный источник контекста; история чатов может быть неполной. Текущая рабочая ветка: `feature/v0.3.0-chemistry-pilot`. Проверять фактическую ветку через `git branch --show-current`.

## 1. Порядок чтения при старте

1. **`AGENTS.md`** — обязательные правила для AI, архитектурные ограничения и безопасность.
2. **`docs/CHATGPT_REPOSITORY_GUIDE.md`** — эта карта документов и алгоритм работы.
3. **`docs/iterations/DEVELOPMENT_HANDOFF_STANDARD.md`** — обязательный Definition of Done: код + тесты + документация + прогресс + Git + передача контекста.
4. **`docs/IMPLEMENTATION_STATUS.md`** — текущая сводка; исторический блок v0.2.0 не принимать за статус v0.3.0.
5. **`docs/IMPLEMENTATION_PLAN.md`**, раздел **Active execution plan — v0.3.0** — задачи в порядке приоритетов и критерии готовности.
6. **`docs/releases/RC_0.3.0_READINESS.md`** — проверяемые критерии RC, риски, подтверждённые тесты и незакрытые требования.
7. **`docs/iterations/CURRENT_HANDOFF_AND_PROMPT.md`** — актуальный снимок состояния, точные команды и готовый промпт для нового чата. Старый `NEXT_CHAT_HANDOFF_2026-10-22.md` — исторический и содержит устаревшие решения.
8. `git status --short`, `git log -5 --oneline`, текущие исходники и тесты — проверить реальность относительно документации.

**При противоречиях:** явно принятые новые решения владельца и принятые ADR имеют приоритет над старым описанием. Проверенный код и результаты тестов показывают фактическую реализацию, но не отменяют продуктовые требования. Если документ устарел, обновить его с указанием, что заменено; не восстанавливать отменённую функциональность.

## 2. Где искать информацию по вопросу

| Вопрос | Смотреть в первую очередь |
|---|---|
| Что делаем сейчас и что дальше? | `docs/IMPLEMENTATION_PLAN.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/releases/RC_0.3.0_READINESS.md` |
| Принятые решения по запуску занятий | `docs/iterations/SESSION_LAUNCH_DECISIONS_2026-10-22.md`, `docs/iterations/SESSION_MODE_MATRIX_2026-10-22.md` |
| Возобновление занятия, сохранение ответа | `docs/iterations/RESUMABLE_SESSION_2026-10-22.md`, iOS persistence и UI-тесты |
| Синхронизация и что хранится на сервере | `docs/iterations/SESSION_SUMMARY_SYNC_DECISION_2026-10-22.md`, `docs/iterations/SESSION_SUMMARY_SERVER_CHECKPOINT_2026-10-22.md`, `docs/SYNC.md` |
| Предметы, темы, цели, мотивация | `docs/COURSES_AND_GOALS.md`, `docs/GOALS_PROGRESS.md`, `docs/REPORTING_AND_MOTIVATION.md` |
| Экран, навигация, темы оформления | `docs/UI_SPEC.md`, `docs/SCREEN_FLOW.md`, `docs/USER_FLOW.md`; сверять с текущими SwiftUI-экранами |
| Форматы карточек, импорт | `docs/MATERIAL_FILE_FORMATS.md`, `docs/DATA_MODEL.md`, `docs/USER_IMPORT_GUIDE.md` |
| Архитектура и БД | `docs/ARCHITECTURE.md`, `docs/CLIENT_ARCHITECTURE.md`, `docs/LOCAL_DATABASE.md`, `docs/decisions/` |
| Требования MVP и границы | `docs/ROADMAP.md`, `docs/REQUIREMENTS.md`, `docs/MVP_ACCEPTANCE.md`, `docs/OPEN_QUESTIONS.md` |
| Публикация и модерация | `docs/APPLE_REVIEW_CHECKLIST.md`, `docs/APPLE_COMPLIANCE.md`, соответствующие ADR |
| Как тестировать | `docs/iterations/REGRESSION_VERIFICATION_2026-10-22.md`, `docs/qa/`, `ios/BOTAITests/`, `ios/BOTAIUITests/`, `tools/chemistry_pilot/` |

## 3. Текущие решения, которые нельзя незаметно менять

- Новая сессия: быстрый запуск по **теме / предмету / смешанно**, дополнительные настройки необязательны и действуют только на эту сессию.
- Форматы: **смешанный / карточки / тесты**; стратегия: **автоматически / все вопросы**. **Отдельной стратегии «Повторение» и быстрого старта «Повторить изученное» нет.** Повторение встроено в автоматический приоритет: просроченные/слабые → новые → изученные, ещё не просроченные. При равном приоритете сохранять исходный порядок. Не запускать пустые занятия; удалять дубликаты вопросов.
- Возобновление сохраняет исходный порядок, позицию и уже записанные ответы; не пересчитывает выборку после перезапуска.
- Обучение работает offline-first; попытки и LearningState остаются локальными. На сервер отправляются **только агрегаты завершённых сессий** согласно принятому контракту. Не возобновлять отменённый план публикации подробных попыток.
- AI-экзамен / BOLDAI исключён из MVP. **App Store и TestFlight не запускать без отдельного согласия владельца.**
- Учитель задаёт рекомендации/ориентиры, а систему выбора определяет алгоритм; **полноценная teacher-guided адаптация пока не реализована**, не объявлять её готовой.

## 4. Подтверждённое состояние и ограничения

- 2026-10-22: полный пост-изменений запуск на iPhone 16e simulator: **137/137 unit + 16/16 standard UI PASS**, `xcodebuild` exit 0, журнал `/tmp/botai_final_session_gate_20261022.log` на рабочем Mac.
- Отдельный chemistry seeded UI ранее: **2/2 PASS**; не считать его частью последнего полного запуска. Chemistry UI требует отдельной подготовленной БД.
- Полная матрица scope × format × strategy, teacher-guided адаптация, миграции `0025`/`0026` и RLS в disposable Postgres, offline/reconnect, визуальная/accessibility-приёмка и Apple compliance остаются незакрытыми. **Статус NOT RC**.
- Пользовательские изменения в `ios/BOTAI.xcodeproj/project.pbxproj` существуют отдельно: **не добавлять в коммит, не откатывать и не перезаписывать** без отдельного разрешения.

### Актуальное состояние RC-06 на 2026-10-23 (заменяет исторические данные выше)

- HEAD на момент сверки: `353f603` (SQLite cold-restart → offline upload failure → reconnect → one ACK). Предыдущий `820f07b` блокирует учебный экран при отказе account storage. Проверять HEAD заново, не полагаться на статический SHA.
- **Подтверждено:** signed simulator full unit suite и 25/25 UI PASS для `820f07b`, логи `/tmp/botai_rc06_storage_guard_unit_20261023.log`, `/tmp/botai_rc06_storage_guard_ui_20261023.log`; последующий focused `SessionSummarySyncCoordinatorTests` 11/11 PASS для `353f603`, лог `/tmp/botai_rc06_reconnect_focused_20261023.log`.
- **Подтверждено ранее:** миграции 0025/0026 и rollback-only RLS fixtures в изолированном PostgreSQL 17 с тестовым auth-uid shim; это НЕ hosted Supabase/PostgREST и НЕ доказательство реальной авторизации. Не повторять устаревшее утверждение выше, что PostgreSQL не тестировался.
- **Открыто:** hosted development Supabase two-account RLS и серверные ACK, реальное отключение/восстановление сети с холодным запуском, expired/revoked session, проверка на физическом устройстве. RC-06 PARTIAL. Не применять миграции к production и не отключать сеть Mac без согласования.
- **Тестовая дисциплина:** адресные проверки для локальных изменений; полный signed unit/UI на границе этапа. Пользовательский `ios/BOTAI.xcodeproj/project.pbxproj` не добавлять в коммит.

## 5. Рабочий цикл ChatGPT

1. Прочитать источники выше, проверить `git status`, последние коммиты и существующие тесты. Сформулировать конкретный следующий **значимый блок работы**, не разбивать на десятки пустых промежуточных отчётов.
2. Реализовать и проверить поведение, включая граничные случаи, офлайн и сохранение данных, где применимо. Не удалять падающие тесты ради зелёного результата.
3. Запустить соответствующие unit/UI/integration проверки. Фиксировать команду, окружение, число тестов, лог и честный результат. Не называть частичный прогон полным.
4. Обновить **в одном цикле** спецификацию принятого решения, `IMPLEMENTATION_STATUS`, `IMPLEMENTATION_PLAN`, RC-чеклист и соответствующий `docs/iterations/` журнал **если затронуты**. Отмечать завершённые пункты, новые риски и следующий исполнимый шаг.
5. Проверить `git diff --check`, состав `git diff --cached`, отсутствие секретов и чужих изменений. Коммитить только свои файлы. Push/tag/публикация — отдельные действия, не выдавать локальный коммит за удалённый.
6. В конце сообщить пользователю **что реально сделано**, тесты (pass/fail), коммит, незакрытые вопросы и следующий этап. Если операция выполняется долго, не утверждать, что она завершилась.

## 6. Быстрый старт команд

```sh
cd '/Users/romanarzumanov/Desktop/Личное/Develop/BOTAI'
git branch --show-current
git status --short
git log -5 --oneline
# Проверять актуальную конфигурацию scheme/destination перед тестами.
# Стандартные unit + UI на доступном iPhone 16e simulator:
xcodebuild -project ios/BOTAI.xcodeproj -scheme BOTAI \
  -destination 'platform=iOS Simulator,id=33176212-1247-4722-B8F4-4E53438502E4' \
  -only-testing:BOTAITests -only-testing:BOTAIUITests/LaunchSmokeTests \
  -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO
```

**Правило передачи:** новый чат должен начать с этого файла, плана, статуса, RC-чеклиста и `git status`, а не с реконструкции истории по памяти. При расхождении документации и реализации создать явную задачу на устранение расхождения.

### RC-04 bundled import mapping consolidation — 2026-10-23

Extracted a single `BundledCourseImporter.course(plan:manifest:references:)` mapping contract from the SwiftUI file importer. It validates the package before indexing, verifies the generated rule-reference count, constructs section/topic and goal links from the same mapped UUIDs, and preserves imported teacher guidance. The UI now calls this mapper rather than duplicating mapping logic. Added repository-level regression covering the actual built `StudyCourse` saved and reloaded from SQLite, section/topic references, goal references, guidance, and invalid reference-count rejection. Existing material-only packages remain supported. No multi-material archive support yet.

Verification logs: `/tmp/botai_rc04_import_mapping_units_20261023.log` (unit tests), `/tmp/botai_rc04_choice_ui_clean_20261023.log` (sequential choice UI regression). **Do not mark either PASS until the corresponding final test summary is confirmed.** Earlier isolated UI `testMixedCardAndChoiceFormatsAvailableForEveryScope` passed, while `testPopulatedChoiceOnlyTestsFormatAndAnswer` suffered a simulator helper disconnect; these are separate outcomes. RC-04 OPEN: adaptive difficulty policy, multi-material import, complete sequential UI acceptance and physical device.

RC-04 import mapper verification (2026-10-23): 176/176 simulator unit PASS, `/tmp/botai_rc04_import_mapping_units_20261023.log`; isolated choice UI PASS, `/tmp/botai_rc04_choice_ui_clean_20261023.log`. Full UI regression and adaptive difficulty remain OPEN.
