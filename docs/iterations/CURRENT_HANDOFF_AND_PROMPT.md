# BOTAI — актуальная передача проекта и готовый промпт

Обновлено 2026-10-22. Этот документ заменяет устаревший снимок `NEXT_CHAT_HANDOFF_2026-10-22.md` в части статуса, принятых решений и следующих шагов. Не полагаться на историю чата как на единственный источник.

## Подтверждённое состояние

- Репозиторий Mac: `/Users/romanarzumanov/Desktop/Личное/Develop/BOTAI`; ветка `feature/v0.3.0-chemistry-pilot`; последний подтверждённый коммит перед этим документом `33f9f20`. Проверять фактический HEAD при входе.
- Устройство Remote Desktop Commander: `bbdafaf9-b83c-4dcd-9e84-96d3bf7f61fd`; симулятор iPhone 16e: `33176212-1247-4722-B8F4-4E53438502E4`.
- Последняя полная регрессия `/tmp/botai_full_regression_20261022.log`: 140/140 Swift Testing unit (45 suites), 23/23 standard UI, 0 failures, `TEST SUCCEEDED`, exit 0. Изолированные химические seeded UI **2/2 PASS после последних изменений** на disposable simulator `62B01BED-4A72-43B9-A02D-351D9E82EE7A`, `/tmp/botai_chemistry_disposable_seeded_20261022.log`, exit 0.
- Готовы: старт по теме/предмету/вперемешку; формат mixed/cards/tests; стратегия automatic/all; приоритет due/new/not due; дедупликация; сохранение ответов и курсора после перезапуска; UI-проверки correct/incorrect/multiselect; явная атрибуция выбранной темы. Это не подтверждает полный cross-product или teacher-guided адаптацию.
- Не готово к RC: полная матрица scope × format × strategy, end-to-end shared-set attribution, teacher-guided scoring, офлайн/reconnect, disposable Postgres миграции 0025/0026 + RLS/idempotency, multi-device визуальная/accessibility приёмка, модерация/удаление/Apple compliance, финальный seeded chemistry прогон и устройство.
- Локальные Attempts и LearningState НЕ выгружать; серверу только агрегаты завершённых сессий. AI-экзамен вне MVP. TestFlight и App Store публикация только после отдельного разрешения владельца.
- **НЕ трогать и НЕ добавлять в коммит** чужое локальное изменение `ios/BOTAI.xcodeproj/project.pbxproj`. Не сбрасывать пользовательские БД. Seed химии только в disposable изолированной тестовой среде.

## Источники истины

Читать `AGENTS.md`, `docs/CHATGPT_REPOSITORY_GUIDE.md`, `docs/iterations/DEVELOPMENT_HANDOFF_STANDARD.md`, `docs/iterations/SESSION_LAUNCH_DECISIONS_2026-10-22.md`, `docs/iterations/SESSION_MODE_MATRIX_2026-10-22.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/releases/RC_0.3.0_READINESS.md`, `docs/iterations/SESSION_SUMMARY_SYNC_DECISION_2026-10-22.md`, `docs/UI_SPEC.md`. Старые отчёты не должны отменять более новые решения.

## Воспроизведение

```sh
cd '/Users/romanarzumanov/Desktop/Личное/Develop/BOTAI'
git status --short && git log -5 --oneline
xcodebuild -project ios/BOTAI.xcodeproj -scheme BOTAI -destination 'platform=iOS Simulator,id=33176212-1247-4722-B8F4-4E53438502E4' -only-testing:BOTAITests -only-testing:BOTAIUITests/LaunchSmokeTests -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO
```

Для chemistry seeded smoke использовать `tools/chemistry_pilot/run_simulator_smoke.sh` строго по инструкции скрипта, с отдельной disposable БД. Полная регрессия ~9 минут; не запускать параллельные Xcode UI-сборки на одном симуляторе.

## Приоритет следующих действий

1. **Выполнено:** 2/2 seeded chemistry UI PASS на отдельном disposable simulator, лог указан выше.
2. Довести матрицу выбора режимов, включая shared-set attribution и persisted attempts, с тестами.
3. Зафиксировать teacher-guided правила и детерминированные тесты; реализовать без незапрошенного изменения UX.
4. Прогнать миграции 0025/0026 и RLS в disposable Postgres, offline/reconnect и идемпотентные retry.
5. Провести проверку экранов/доступности и затем Apple compliance и финальный RC checklist.

Каждый законченный блок = код + тесты + запуск + документация + статус + коммит. Не считать готовым то, что не проверено. Не публиковать сборку без отдельного согласия.

## ГОТОВЫЙ ПРОМПТ ДЛЯ НОВОГО ЧАТА (копировать целиком)

> Продолжай разработку BOTAI в проекте «iOS разработка». Не начинай заново и не меняй принятые решения. Подключись к Mac через Remote Desktop Commander, открой репозиторий `/Users/romanarzumanov/Desktop/Личное/Develop/BOTAI` и **сначала прочитай `AGENTS.md`, `docs/CHATGPT_REPOSITORY_GUIDE.md` и `docs/iterations/CURRENT_HANDOFF_AND_PROMPT.md`**, затем перечисленные там источники истины. Проверь текущие ветку, HEAD, git status и тестовые результаты, не доверяй устаревшим handoff-файлам. Последний подтверждённый baseline до передачи: 140/140 unit + 23/23 UI PASS, коммит `33f9f20`, ветка `feature/v0.3.0-chemistry-pilot`; сверяй с более новыми коммитами. Chemistry seeded регрессия уже 2/2 PASS; продолжай с закрытия матрицы учебных сценариев и последующие P0 задачи из плана. Для каждого законченного этапа обязательно реализуй код, добавь/обнови тесты, реально запусти проверки, обнови документацию, статус и план, создай аккуратный git-коммит и укажи следующий шаг. Не включай в коммиты чужой изменённый `ios/BOTAI.xcodeproj/project.pbxproj`; не уничтожай пользовательские данные. Не выгружай детальные попытки на сервер — только агрегаты завершённых сессий. Не отправляй TestFlight/App Store без отдельного согласия. Сообщение «+» означает продолжать самостоятельно, без повторных согласований. Предпочитай законченные значимые этапы вместо частых сообщений «жду тесты». В конце подготовки релиза обнови этот handoff и предоставь готовый актуальный промпт для следующего чата.
