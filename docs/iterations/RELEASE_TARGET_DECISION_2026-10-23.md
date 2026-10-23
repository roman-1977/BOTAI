# BOTAI v0.3.0 — утверждённая цель релиза (2026-10-23)

## Решение владельца

**Довести весь согласованный MVP до релиза, без урезания требований и без замены релиза одним химическим пилотом.** Первая практическая приёмка — ежедневное обучение химии двумя **разными учениками** на **iPhone 15 Pro Max и iPhone 16 Pro Max**. Это независимые профили/прогресс; межустройственное объединение одного ученика не требуется для первой установки, но согласованная архитектура авторизации и синхронизации остаётся обязательной частью продукта и не удаляется.

**Граница ответственности:** преподаватель отвечает за полноту программы ЕГЭ, содержание и правильность учебных материалов. BOTAI отвечает за корректный импорт, отображение, генерацию вопросов, цели, рекомендованный темп, адаптацию, сохранение, офлайн и надёжность обучения. Не заявлять о полном покрытии ЕГЭ без подтверждения преподавателя.

## Приёмка перед установкой

1. Проверить и довести учебную последовательность неорганическая химия → органическая химия → повторение, включая утверждённый порог 70%, назначение материала, переходы и поведение при изменении прогресса. Не считать это реализованным без end-to-end тестов.
2. Проверить несколько учебных дней: новый/повторяемый материал, ответы, статистику, рекомендации, сроки, выход/перезапуск, прерванную сессию, офлайн и восстановление сети. Отдельные ученики не должны смешивать данные.
3. Проверить экраны и доступность на обоих целевых размерах, затем на обоих физических телефонах. Предыдущая чистая регрессия 181 unit + 25 UI на iPhone 16e **не** является проверкой iPhone 15/16 Pro Max.
4. Завершить открытые RC-01…RC-10 по существующим требованиям, включая UGC/модерацию, синхронизацию и документацию. Не отменять ранее утверждённые функции ради пилота.
5. Повторить полную регрессию после исправлений, собрать подписанный кандидат, установить и принять на двух устройствах. Для TestFlight/App Store требуются отдельные полномочия, настройки подписи и явное подтверждение фактической отправки; это решение разрешает **подготовку**, но не утверждает, что публикация уже выполнена.

## Текущие доказательства и статус

Последний полный последовательный симуляторный прогон: **181/181 unit и 25/25 UI PASS**, `/tmp/botai_rc04_full_181_20261023.log`, `xcodebuild` exit 0. **NOT RC** до завершения открытых проверок. `.botai` coursePlan поддерживает один материал; multi-material курс и проверка полной химической последовательности открыты. Не изменять/не включать в коммит пользовательский `ios/BOTAI.xcodeproj/project.pbxproj`.

## Правила исполнения

Работать крупными завершёнными блоками: сверить принятые решения → код и тесты → сборка и регрессия → документация/план/статус → самодостаточный коммит. Не подменять функциональную приёмку количеством тестов.

## Уточнение ближайшего релиза: Chemistry Learner Release 1

Владелец уточнил приоритет: **ближайший релиз — допуск реальных пользователей к изучению химии**. Это не означает отмену общего MVP и не означает, что кабинет преподавателя/публичная модерация обязаны задерживать частный химический релиз, если эти функции не доступны ученикам. Их обязательства и приёмка остаются в общем плане. Два независимых ученика, iPhone 15 Pro Max и iPhone 16 Pro Max.

**Блокирующие условия:** доступная химия без ручной перезаписи пользовательской базы; работающие карточки и тесты; план на следующий день с прогрессом и повторением; сохранение результатов после закрытия и офлайн; разделение аккаунтов; визуальная приёмка обеих моделей; подписанная устанавливаемая сборка и безопасный путь обновления.

**Выявленный конкретный разрыв:** существующий `tools/chemistry_pilot/seed_local_sqlite.py` требует `--reset-learning-data` и удаляет учебные записи выбранной БД. Это **только disposable тестовый seed**, не путь первичной загрузки на телефон ребёнка. Для релиза нужен недеструктивный импорт/предустановка химии через обычное приложение, с повторным запуском без дубликатов и без потери прогресса. Запрещено запускать destructive seed на реальном устройстве.

**Выявленный конкретный разрыв:** seed создаёт один общий goal с `masteryTarget=90`, пять разделов и 25 тем, но не кодирует поэтапное продвижение «неорганическая → органическая → повторение» при 70%. Нельзя считать такой маршрут реализованным только потому, что все разделы присутствуют. Требуется реализовать и проверить автоматические переходы и условия завершения.

**Проверка данных 2026-10-23:** `python3 -m unittest discover -s tools/chemistry_pilot -p 'test_*.py' -v` — **5/5 PASS**, `/tmp/botai_chemistry_pilot_python_20261023.log`. Недеструктивный preview `seed_local_sqlite.py` — **323 вопросов, 102 набора**, `/tmp/botai_chemistry_seed_preview_20261023.log`, `EXIT 0`; распределение: неорганическая 200, органическая 86, общая 23, качественные реакции 12, химия и жизнь 2. **Это валидация структуры, а не проверка полноты/качества преподавателем.** Последняя общая iOS регрессия 181/181 unit + 25/25 UI PASS, но на iPhone 16e simulator, не на двух целевых Pro Max.

**Порядок работ:** (1) недеструктивная доставка и полноценный курс/70% маршрут; (2) E2E ежедневного обучения, офлайн, изоляция учеников и регрессия; (3) два целевых экрана и физических устройства, подпись и установка; (4) отдельное решение о TestFlight/App Store отправке. Не выдавать завершённость ни одного пункта без доказательств.

## Apple ID — implemented UI checkpoint (2026-10-23)

`ProfileView` now exposes a native `SignInWithAppleButton` for unauthenticated users, generates a fresh cryptographically secure nonce, sends its SHA256 digest in the Apple request, and exchanges the returned ID token + raw nonce using existing `AuthStore.signInWithApple` / Supabase Auth. The existing `BOTAI.entitlements` already declares `com.apple.developer.applesignin`. On failure, the user sees an auth error and is not marked signed in. Existing DEBUG anonymous test login is retained separately. **181/181 unit PASS**, `/tmp/botai_apple_auth_units_20261023.log`; this is build and existing unit regression, NOT a successful real Apple ID authentication. Pending: Apple Developer App ID/capability and Supabase provider configuration, physical-device sign-in/sign-out/relogin/account isolation, UI acceptance, email/password alternative and recovery. Do not claim these are complete.

## Email/password learner accounts checkpoint — 2026-10-23

Implemented Profile -> email account sheet with sign-in, sign-up and password reset modes; secure password entry, basic email validation, busy/disabled state and visible errors. `AuthStore` calls Supabase Auth `signIn(email:password:)`, `signUp(email:password:)`, and `resetPasswordForEmail`. Successful sessions bind to verified UUID and existing account-local storage; sign-up without a session **does not unlock** learning and prompts email confirmation. **181/181 simulator unit PASS**, `/tmp/botai_email_auth_units_20261023.log`. Not yet verified against hosted Supabase email provider, email delivery/redirect, Apple provider, physical devices or account switching UI. No full UI suite rerun after this change; last full UI baseline 25/25 from `02cfb0f`.
