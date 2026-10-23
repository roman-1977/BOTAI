# BOTAI — актуальная передача проекта и готовый промпт

> **CURRENT AUTHORITATIVE SNAPSHOT (2026-10-23; baseline commit `6bce16f`).** Branch `feature/v0.3.0-chemistry-pilot`. Complete sequential iPhone 16e simulator run: **177/177 unit and 25/25 UI PASS**, exit 0, `/tmp/botai_rc04_full_final_20261023.log`. Separately seeded chemistry UI: **2/2 PASS** at an earlier checkpoint, not included in the full run. RC-08 PASS for this baseline, but **overall NOT RC**. RC-04 P0 OPEN: `.botai` one-material coursePlan imports goals/sections/topics/guidance, SQLite persistence and Today recommendation sheet work; teacher priority breaks observed-urgency ties and suggested pace is compared without overriding profile minutes. Difficulty is informational only; multi-material course transport and full teacher-guided acceptance remain OPEN. RC-05 multi-size/accessibility/device OPEN; RC-06 local aggregate-sync and disposable SQL gates PASS, hosted/device checks deferred by owner; RC-07 partial; RC-09 distribution deferred. User-owned `ios/BOTAI.xcodeproj/project.pbxproj` must never be staged, overwritten or reverted. Older dated checkpoints below are historical, not the current status.

Обновлено 2026-10-23. Этот документ заменяет устаревший снимок `NEXT_CHAT_HANDOFF_2026-10-22.md` в части статуса, принятых решений и следующих шагов. Не полагаться на историю чата как на единственный источник.

> **АКТУАЛЬНЫЙ СРЕЗ — 2026-10-23, после `95cd330`.** Старые числа и списки «не готово» ниже — исторический снимок, не текущий статус. Актуальные таблицы: `docs/IMPLEMENTATION_PLAN.md` (Active execution plan) и `docs/releases/RC_0.3.0_READINESS.md` (RC-01…RC-10). Подтверждено 159/159 unit + 25/25 UI PASS (`/tmp/botai_rc06_consolidated_full_20261023.log`), SQL security replay 3/3 PASS, отдельно seeded chemistry 2/2 PASS на более раннем checkpoint. RC-01/02/03 функционально реализованы и широко протестированы, но некоторые исчерпывающие E2E сценарии не подтверждены. RC-04 teacher-guided scoring и RC-05 визуальная/accessibility приёмка остаются реальными пробелами. RC-06 локально проверен; владелец согласился отложить hosted Supabase и физические сетевые испытания. RC-07 операционная приёмка частична; RC-09 распространение отложено по решению владельца. Следующий шаг — **RC-04 по утверждённым правилам**, параллельно точечно закрывать реальные недостающие E2E сценарии, не повторять уже пройденные 54 проверки доступности. Не трогать пользовательский `ios/BOTAI.xcodeproj/project.pbxproj`.

> **RC-04 аудит 2026-10-23:** базовый планировщик (цели, сроки, освоение, дневной бюджет, due/new/future) реализован. Teacher-guided модель не согласована полностью: роль преподавателя, право управления последовательностью и политика распределения времени остаются открытыми. Не придумывать коэффициенты. См. `docs/iterations/RC04_ADAPTIVE_CONTRACT_AUDIT_2026-10-23.md`.

> **RC-04 граница MVP:** пользовательский план по целям/срокам/темпу обязателен (`docs/REQUIREMENTS.md`), расширенные инструменты преподавателя после MVP (`docs/ROADMAP.md`), но принятые концептуальные назначения преподавателя (ADR-023) нельзя самовольно исключать. Следующее без новых продуктовых решений: тестировать и исправлять доказанные дефекты multi-goal планирования.

> **ПОСЛЕДНЕЕ РЕШЕНИЕ ВЛАДЕЛЬЦА (2026-10-23):** RC-04 полный цикл рекомендаций преподавателя **обязателен в MVP ученика**. Источник — импорт курса или прямой seed химии; хранение офлайн, обработка и влияние на план, визуализация и тесты обязательны. Только кабинет преподавателя отложен. Старые записи ниже о неопределённости/пост-MVP заменены этим решением. См. `docs/iterations/RC04_STUDENT_RECOMMENDATIONS_DECISION_2026-10-23.md`.

> **RC-04 implementation checkpoint:** `LearningGoal.guidance` optional Codable + chemistry local seed + compatibility unit test in progress; full import/adaptation/UI **not** done. Do not mark RC-04 PASS. Test log `/tmp/botai_rc04_guidance_units_20261023.log`.

> **RC-04 UI checkpoint:** Today goal card shows optional teacher priority and rationale from local course goals; simulator build PASS `/tmp/botai_rc04_guidance_ui_build_20261023.log`. Full adaptive effect, general import, difficulty/pace and visual/UI acceptance still pending.

> **RC-04 latest 2026-10-23:** guidance priority breaks exact goal urgency ties only (no fabricated weights); 161/161 signed unit PASS `/tmp/botai_rc04_guidance_order_units_20261023.log`. Full student recommendation pipeline still P0 OPEN.

> **RC-04 rest-day fix:** zero-minute days no longer allocate phantom mandatory minute; optional study still available. 161/161 unit PASS `/tmp/botai_rc04_restday_units_20261023.log`.

> **RC-04 latest 2026-10-23:** multi-goal budget allocation fixed (no starvation when budget covers goals, proportional remainder, stable tie, no phantom minutes). 164/164 simulator units PASS `/tmp/botai_rc04_multigoal_units_20261023.log`. Teacher recommendation pipeline still incomplete.

> **RC-04 persistence 2026-10-23:** imported-source goal guidance round-trips through SQLite and survives course update; 165/165 simulator units PASS `/tmp/botai_rc04_guidance_persistence_units_20261023.log`. Not yet tested through full app relaunch/import UI.

> **RC-04 latest:** teacher difficulty (1–5) and suggested daily minutes (1–240) supported in optional course goal guidance, shown in Today, invalid ranges normalized, 167/167 simulator unit PASS `/tmp/botai_rc04_difficulty_pace_units_20261023.log`. Adaptive difficulty/pace use, general import and UI tests P0 OPEN.

> **RC-04 pace comparison 2026-10-23:** chemistry direct seed includes teacher difficulty 4 and 25-minute suggestion; Today compares it against actual goal allocation, never silently changes profile. 168/168 simulator units PASS `/tmp/botai_rc04_pace_assessment_units_20261023.log`. General course import/adaptive difficulty/full UI acceptance open.

## Подтверждённое состояние

- Репозиторий Mac: `/Users/romanarzumanov/Desktop/Личное/Develop/BOTAI`; ветка `feature/v0.3.0-chemistry-pilot`; последний подтверждённый коммит перед этим документом `33f9f20`. Проверять фактический HEAD при входе.
- Устройство Remote Desktop Commander: `bbdafaf9-b83c-4dcd-9e84-96d3bf7f61fd`; симулятор iPhone 16e: `33176212-1247-4722-B8F4-4E53438502E4`.
- Последняя полная общая регрессия `/tmp/botai_full_regression_20261022.log`: 140/140 Swift Testing unit (45 suites), 23/23 standard UI, 0 failures, `TEST SUCCEEDED`, exit 0. После неё отдельный **полный unit-target прогон 143/143 PASS** (`/tmp/botai_shared_topic_summary_units_20261022.log`) с новым тестом общей mastery по темам; новый focused two-topic shared-set UI **1/1 PASS** (`/tmp/botai_shared_two_topics_ui_20261022.log`); полный 23 UI suite после новых тестов не перезапускался. Изолированные химические seeded UI **2/2 PASS после последних изменений** на disposable simulator `62B01BED-4A72-43B9-A02D-351D9E82EE7A`, `/tmp/botai_chemistry_disposable_seeded_20261022.log`, exit 0.
- Утверждено владельцем: один опросник в нескольких темах = единое состояние освоения по `knowledgeID`, без повторного изучения и без двойного счёта уникальных знаний по предмету. Атрибуция занятия влияет на отчётность, а не на mastery.
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

> Продолжай разработку BOTAI в проекте «iOS разработка». Не начинай заново и не меняй принятые решения. Подключись к Mac через Remote Desktop Commander, открой репозиторий `/Users/romanarzumanov/Desktop/Личное/Develop/BOTAI` и **сначала прочитай `AGENTS.md`, `docs/CHATGPT_REPOSITORY_GUIDE.md` и `docs/iterations/CURRENT_HANDOFF_AND_PROMPT.md`**, затем перечисленные там источники истины. Проверь текущие ветку, HEAD, git status и тестовые результаты, не доверяй устаревшим handoff-файлам. Последний общий baseline: 140/140 unit + 23/23 UI PASS; позднее 143/143 unit PASS с shared mastery, unique coverage и completed-session attribution tests; проверяй актуальный HEAD, ветка `feature/v0.3.0-chemistry-pilot`; сверяй с более новыми коммитами. Chemistry seeded регрессия уже 2/2 PASS; продолжай с закрытия матрицы учебных сценариев и последующие P0 задачи из плана. Для каждого законченного этапа обязательно реализуй код, добавь/обнови тесты, реально запусти проверки, обнови документацию, статус и план, создай аккуратный git-коммит и укажи следующий шаг. Не включай в коммиты чужой изменённый `ios/BOTAI.xcodeproj/project.pbxproj`; не уничтожай пользовательские данные. Не выгружай детальные попытки на сервер — только агрегаты завершённых сессий. Не отправляй TestFlight/App Store без отдельного согласия. Сообщение «+» означает продолжать самостоятельно, без повторных согласований. Предпочитай законченные значимые этапы вместо частых сообщений «жду тесты». В конце подготовки релиза обнови этот handoff и предоставь готовый актуальный промпт для следующего чата.

### Block-oriented execution and release progress — 2026-10-22

Owner requested work in **substantial blocks** with overall release progress, not per-test updates. Current release ledger: `docs/iterations/RELEASE_PROGRESS_2026-10-22.md`; authoritative gates `docs/releases/RC_0.3.0_READINESS.md`. Previous 70% is subjective, not measured; always report blockers and verified gates. Two-topic UI extended through answer/finish/relaunch PASS (`/tmp/botai_shared_two_topics_answer_finish_20261022.log`); full post-change regression started (`/tmp/botai_block1_full_regression_20261022.log`).

- Goal mastery calculation now uses unique knowledge IDs in both `DailyPlanner.make` and `GoalProgressService.reconcile`, test `SharedGoalMasteryTests`; **144/144 unit PASS**, `/tmp/botai_goal_unique_mastery_units_20261022.log`. Full standard UI regression started before this fix; if needed rerun UI affected flows after commit.

- **Latest 2026-10-22:** standard 24/24 UI PASS (run 614 sec), previous 143/143 unit PASS, log `/tmp/botai_block1_full_regression_20261022.log`; xcresult bundle failed to save due to mkstemp missing directory even though tests and xcodebuild exit succeeded. New six-case format×strategy unit matrix plus shared mastery fix: **145/145 unit PASS**, `/tmp/botai_block1_matrix_units_20261022.log`. Full scope×format×strategy UI, teacher-guided adaptivity and backend acceptance still open. Work in blocks, report gates not unsupported precision.

- Expanded shared questionnaire UI coverage: both topics, subject, all-subject mixed show equal unique counts; answer/finish/relaunch still pass, 1/1 focused UI `/tmp/botai_scope_matrix_ui_20261022.log`, exit 0. This is not complete cross-product.

### Consolidated regression checkpoint — 2026-10-22

Complete clean full test suite **146/146 unit + 25/25 standard UI PASS** with two intentionally skipped chemistry tests on unseeded standard simulator, exit 0: `/tmp/botai_full_clean_regression_20261022.log`. Independently **2/2 seeded chemistry UI PASS** on disposable simulator, exit 0: `/tmp/botai_seeded_chemistry_acceptance_20261022.log`. Five chemistry fixture Python tests PASS: `/tmp/botai_chemistry_seed_python_20261022.log`. RC-08 PASS for tested revision; still NOT RC. Next work in meaningful blocks: offline/reconnect + backend migration 0025/0026 RLS on disposable Postgres, adaptive teacher guidance policy, visual/accessibility/device gates. Preserve user-owned pbxproj and never deploy without approval.

### Offline/reconnect checkpoint — 2026-10-22

Two disk-backed, restart-persistent fake-network integration tests now cover summary retry/ACK and parent-first topic aggregate upload/ACK, including duplicate-completion idempotency. **148/148 BOTAITests PASS**, `/tmp/botai_offline_reopen_sync_units_20261022.log`. Disposable Postgres migration 0025/0026 RLS fixtures remain unexecuted: `docker`, `psql`, `pg_ctl` unavailable on Mac PATH; do NOT use linked/live Supabase as a substitute. Real network drop, hardware, migration and RLS acceptance remain open. Continue work in batches and preserve user-owned pbxproj.

### Duplicate ACK security regression — 2026-10-22

Added duplicate-ACK rejection in both completed session and topic aggregate upload coordinators; malicious fake-backend tests confirm no local ACK on duplicate IDs. **150/150 BOTAITests PASS** `/tmp/botai_duplicate_ack_tests_20261022.log`. Still pending isolated PostgreSQL RLS migrations 0025/0026 and real network disruption tests.

### Disposable PostgreSQL RLS checkpoint — 2026-10-22

Homebrew PostgreSQL 17 installed; isolated cluster at `/tmp/botai_pg17_rls_20261022/data`, port 55439, **stopped after tests**. Exact migrations 0025/0026 and both rollback-only RLS fixtures executed successfully on genuine PostgreSQL using minimal local auth schema/uid shim. No live Supabase changes. This covers DB SQL and basic role-based isolation, NOT hosted Supabase Auth/PostgREST. Do not mistake shim for full Supabase. Next: real network disruptions, remaining RC gates. Preserve user-owned `ios/BOTAI.xcodeproj/project.pbxproj`.

### Additional PostgreSQL negative-permission tests — 2026-10-22

New `backend/tests/completed_session_negative_permissions.sql` fixture PASS on disposable PostgreSQL 17; verifies forbidden DELETE, unauthenticated SELECT, orphan topic FK, invalid counts. `/tmp/botai_rls_negative_permissions_20261022.log`. Cluster stopped, no live database touched. Full hosted Supabase and physical offline/online tests still outstanding.

### Offline auth cold-launch blocker — 2026-10-22

Source audit found `AuthStore.bootstrap()` non-missing-session error -> `didFailBootstrap`, and `BOTAIApp` blocks RootTabView. This prevents reliable offline cold launch for previously authenticated users when session refresh requires network. Preserve strict account separation; do not replace identity with guest on network error. Design secure cached local identity and test offline cold launch, expired token, sign-out and switching before RC. Also 151/151 unit tests PASS including partial ACK retry, `/tmp/botai_partial_summary_retry_20261022.log`.

### Offline account binding prototype — 2026-10-23

`AuthStore.swift` adds Keychain-backed last verified UUID; only transport failure with cached UUID allows local-only access to exact account database; no cloud sync, no guest fallback. Binding cleared on confirmed missing session/successful sign-out, replaced on verified sign-in. 152/152 units PASS `/tmp/botai_offline_auth_guard_tests_20261023.log`. MUST test actual offline cold start, token expiration/revocation, account switching, Keychain behavior, and reconnect before release; this is not fully accepted. Do not touch user-owned project.pbxproj.

### Offline error allowlist — 2026-10-23

`AuthStore.isTransportFailure` now accepts only connectivity-related URL error codes; TLS trust/authentication/bad URL fail closed. Negative tests PASS (152/152 total), `/tmp/botai_offline_auth_allowlist_20261023.log`. Still test end-to-end offline Keychain cold launch and reconnect.

### Keychain entitlement blocker — 2026-10-23

Isolated Keychain integration test found `SecItemAdd` -34018 in unsigned simulator (`CODE_SIGNING_ALLOWED=NO`). Test reports `KEYCHAIN_INTEGRATION_NOT_VERIFIED` and does not assert persistence in that environment. 153/153 remaining unit tests PASS `/tmp/botai_keychain_unsigned_20261023.log`. Signed simulator or physical-device Keychain acceptance is a **release blocker**. Do not misreport 153 PASS as verified Keychain functionality.

### Signed simulator Keychain acceptance — 2026-10-23

Signed simulator test run succeeded with `GENERATE_INFOPLIST_FILE=YES CODE_SIGN_IDENTITY='-'` build overrides: 153/153 PASS, isolated Keychain persistence test PASS, `/tmp/botai_keychain_signed_sim2_20261023.log`. Previous -34018 was due to unsigned test host. No pbxproj modifications. Next verify app cold start with network loss/reconnect and account switching; device gate still open.

### Reconnect fix — 2026-10-23

`AuthStore.reconnectOfflineSession` requires restored Supabase user UUID to equal cached offline user. `BOTAIApp` on scene activation revalidates then restores sync service to the same isolated SQLite database. Signed-simulator 153/153 units PASS `/tmp/botai_offline_reconnect_20261023.log`. Add actual offline→online UI/integration coverage, including mismatched account and revoked session; do not call gate closed yet.

### Secure offline binding matrix — 2026-10-23

Offline cold-start requires Keychain account UUID **and** matching Supabase SDK `auth.currentSession?.user.id`, on recognized transport error only; no guest fallback. Same-account reconnection policy tested. 154/154 signed-simulator units PASS `/tmp/botai_offline_policy_matrix_20261023.log`. Full signed regression running in `/tmp/botai_signed_full_regression_20261023.log` (process 74148 at last check); check exit/status before claiming UI pass. Full offline→online cold-launch UI acceptance remains outstanding.

### Full signed UI regression completed — 2026-10-23

`/tmp/botai_signed_full_regression_20261023.log`: exit 0, 25/25 UI PASS, 2 chemistry UI SKIP on unseeded standard simulator, runtime ~731s. This run started before persisted-session match hardening; latest change has 154/154 signed unit PASS. Still need end-to-end offline cold start/reconnect test and hosted integration. No pbxproj edits.


### RC-06 account-bound sync hardening — 2026-10-23

Bound every `SyncService` instance to its originating authenticated UUID. A stale task may no longer start aggregate uploads from an old account database under a newly signed-in account; identity is rechecked at coordinator checkpoints. See `docs/iterations/RC06_ACCOUNT_BOUND_SYNC_2026-10-23.md`. Added regression coverage for account match, switch and sign-out. RC-06 remains OPEN pending end-to-end offline cold launch, reconnect, revoked-session and multi-account acceptance tests; no release approval.


### Verification for account-bound sync change

Signed simulator: 155/155 unit, 25/25 standard UI, zero failures (`/tmp/botai_rc06_account_binding_full_20261023.log`). Remaining RC-06 end-to-end offline/reconnect/revocation and hosted backend gates OPEN. Continue in large completed blocks; never stage the user-modified Xcode project file.


### RC-06 offline revalidation fail-closed — 2026-10-23

`AuthStore.reconnectOfflineSession()` now locks local study on non-transport authorization failures and account mismatch, instead of leaving the offline identity active. Network outages still preserve local study access. See `docs/iterations/RC06_RECONNECT_AUTH_REJECTION_2026-10-23.md`. Signed unit suite: **156/156 PASS** (`/tmp/botai_rc06_revalidation_20261023.log`). Full offline/reconnect/ACK acceptance remains OPEN; never treat this regression as RC-06 closure.


### RC-06 foreground network restoration — 2026-10-23

Added `NWPathMonitor`-driven retry on offline→online transition even while the app stays foregrounded. Supabase account revalidation and existing account-bound aggregate sync are still required. Unit suite **157/157 PASS** (`/tmp/botai_rc06_connectivity_20261023.log`); UI regression log `/tmp/botai_rc06_connectivity_ui_20261023.log`. See `docs/iterations/RC06_FOREGROUND_CONNECTIVITY_RETRY_2026-10-23.md`. Full controlled network/hosted backend acceptance remains OPEN.


### RC-06 offline logout fail-closed — 2026-10-23

Local identity and offline binding are now always cleared on sign-out even when Supabase remote logout fails. The pinned Supabase SDK clears its persisted session before the remote call; remote token revocation is not claimed on network failure. See `docs/iterations/RC06_OFFLINE_LOGOUT_2026-10-23.md`. Signed regression evidence: `/tmp/botai_rc06_signout_20261023.log` (pending), UI regression `/tmp/botai_rc06_connectivity_ui_20261023.log` (earlier build). Full hosted backend acceptance remains open.

RC-06 storage failure guard (2026-10-23): `BOTAIApp` now requires `storageFailure == nil` before showing `RootTabView` after identity resolution. Validate signed unit/UI suites; do not treat this as real backend ACK/revocation acceptance. Do not stage the user's `ios/BOTAI.xcodeproj/project.pbxproj`.

RC-06 reconnection integration regression (2026-10-23): `SessionSummarySyncCoordinatorTests.offlineRestartReconnectAndRepeatedRetryNeverDuplicateSession` uses a mutable fake transport and a persistent SQLite file to verify failed offline upload, cold restart, eventual ACK and idempotent retries. Run focused `xcodebuild ... -only-testing:BOTAITests/SessionSummarySyncCoordinatorTests`; do not claim live Supabase coverage. Current user-owned `project.pbxproj` must stay unstaged.

RC-06 authoritative handoff refresh 2026-10-23: latest verified `353f603` 11/11 focused PASS; prior `820f07b` signed unit and 25/25 UI PASS. Historical running PID 82041 has completed; do not wait for it. Disposable PostgreSQL migrations/RLS were tested with an auth shim, hosted Supabase not tested. Read updated `docs/CHATGPT_REPOSITORY_GUIDE.md` and RC readiness ledger.

RC-06 live acceptance harness updated: `ios/BOTAITests/LiveSupabaseSyncTests.swift` no longer tests obsolete legacy attempt publishing. Hosted aggregate-only fixture is gated by BOTH `BOTAI_RUN_LIVE_SYNC=1` and `BOTAI_DISPOSABLE_SUPABASE_CONFIRMED=1`; do not enable without disposable backend approval and 0025/0026 migration. Local compile-only run must not be represented as hosted PASS.

RC-06 hosted fixture now checks both completed-session parent and topic aggregate rows with two-account read isolation; remains explicitly opt-in. See `LiveSupabaseSyncTests.swift` and its two required environment guards.

Hosted RC-06 harness security: four environment variables required (BOTAI_RUN_LIVE_SYNC, BOTAI_DISPOSABLE_SUPABASE_CONFIRMED, BOTAI_TEST_SUPABASE_URL, BOTAI_TEST_SUPABASE_PUBLISHABLE_KEY). Rejects app-configured production backend. Never run on a non-disposable project; confirm migrations and anonymous auth before enabling.

RC-06 hosted acceptance now tests forbidden foreign-owner INSERT for both tables. A live run must verify both denial paths; local test PASS with opt-in disabled does not count as server acceptance.

RC-06 consolidated verification: `tools/verify_rc06_disposable_postgres.sh` replays all three rollback-only SQL security fixtures on pre-existing disposable PostgreSQL cluster, PASS `/tmp/botai_rc06_sql_replay_20261023.log`. It refuses running clusters and stops its own server. Next required: hosted Supabase and real network/device acceptance; no production changes authorized.

Consolidated signed simulator full unit/UI regression PASS: `/tmp/botai_rc06_consolidated_full_20261023.log`. Live Supabase test runs in safe disabled mode; do not call it hosted PASS.

### Cross-goal question deduplication — 2026-10-23

Repeated StudyQuestion IDs are scheduled once across active goals. Later goals fill from next eligible unique question; goals with no remaining unique questions are omitted. Allocated minutes for such empty goals are not yet redistributed (open). Mastery still deduplicates knowledge IDs separately. Simulator 169/169 unit PASS (`/tmp/botai_rc04_dedup_units_20261023.log`). Full import/adaptive difficulty/UI acceptance open.

### RC-04 consolidated planner regression (2026-10-23)

Planner now removes overlapping question IDs **before** assigning shared study minutes, so goals with no remaining unique work do not consume time and the budget is reallocated to actionable goals. Due/new/not-due ordering and deterministic teacher-priority tie-break remain unchanged. Deadline urgency now counts calendar days (not truncated 24-hour intervals), including overdue deadlines. Added midnight/next-day/overdue/no-deadline regression. Full simulator unit + standard UI run: `/tmp/botai_rc04_batch_full_20261023.log` (check final result before claiming PASS). Outstanding: full teacher course import, adaptive difficulty policy, end-to-end UI guidance acceptance, physical device. RC-04 stays OPEN.

### RC-04 overlap integration verification — 2026-10-23

Added real in-memory SQLite material + two active goals referencing the exact same question set. DailyPlanner now demonstrably emits one goal, one question, and assigns the full 20-minute learner budget to that actionable goal rather than reserving time for an empty overlapping goal. Simulator unit suite **171/171 PASS** (`/tmp/botai_rc04_overlap_integration_20261023.log`). A separate full UI suite is still running (`/tmp/botai_rc04_batch_full_20261023.log`); do not mark UI PASS before its final summary. The `.botai` format currently represents individual materials rather than courses; a separate agreed course transport is still required to ingest full teacher plans. Difficulty guidance remains informational, not a verified adaptive input. RC-04 OPEN.

### RC-04 bundled course import (2026-10-23)

Added an **optional `coursePlan` field to version-1 `.botai` material packages**: course title/subject and one or more goals with question-set indexes, mastery target, deadline and optional teacher guidance (priority, rationale, difficulty, suggested minutes). Old material-only archives decode unchanged. The import preview identifies bundled courses. Import saves material, maps package question-set indexes to newly generated persistent material/rule IDs, then saves an active learner course with its goals/guidance. If course persistence fails, it attempts to delete the just-imported material. Manifest validation rejects empty goal/title, out-of-range targets and invalid/disabled question-set references. The contract currently supports **one bundled material and its goals**; multi-material course archives and section/topic structure are not implemented.

Verification: simulator build PASS (`/tmp/botai_rc04_course_import_final_build_20261023.log`); **173/173 unit PASS** (`/tmp/botai_rc04_course_import_units_20261023.log`), including JSON compatibility, invalid references and SQLite material/course persistence. Full UI regression `/tmp/botai_rc04_batch_full_20261023.log` has at least one failing existing UI test (`testMixedCardAndChoiceFormatsAvailableForEveryScope` at line 562, course title not found); this is **not a passing UI suite**. End-to-end document picker, process restart and adaptive difficulty remain open. RC-04 OPEN.

### RC-04 import archive and UI triage — 2026-10-23

Added integration test that creates an actual `.botai` ZIP with a `coursePlan`, opens it through `BOTAIPackageService.read`, and verifies that teacher guidance and question-set mapping survive the archive boundary. Simulator **174/174 unit PASS** (`/tmp/botai_rc04_zip_course_units_20261023.log`). The earlier full UI run (`/tmp/botai_rc04_batch_full_20261023.log`) is **NOT PASS**: `testMixedCardAndChoiceFormatsAvailableForEveryScope` fails at `LaunchSmokeTests.swift:562` while waiting for the newly created course title; `testPopulatedChoiceOnlyTestsFormatAndAnswer` fails at line 518 while waiting for the session scope screen after launch. Do not relabel these as passed or delete tests; investigate simulator state and navigation persistence and rerun. Course import currently only supports one bundled material and goals, not full multi-material/section/topic course; teacher difficulty is not yet an adaptive signal. RC-04 OPEN.

### RC-04 course section/topic import and simulator isolation (2026-10-23)

Extended optional `.botai` `coursePlan` with `sections[]` and `topics[]`, each topic referring to validated enabled question-set indexes within the bundled material. The importer maps them to persistent `CourseSection`/`CourseTopic` and newly assigned rule IDs. Missing `sections` decodes as empty for backward compatibility. Empty sections/topics and invalid/disabled indexes reject before saving. Multi-material packages remain unsupported; do not describe this as a complete multi-material course importer.

Simulator build PASS (`/tmp/botai_rc04_section_import_build_20261023.log`); **175/175 unit PASS** (`/tmp/botai_rc04_section_import_units_20261023.log`), including section/topic JSON roundtrip and invalid-index rejection. Full UI suite started earlier was not isolated: subsequent test invocations targeted the same simulator while it was running, so its failures cannot be confidently attributed to the app. After stopping the long suite, isolated rerun showed `testMixedCardAndChoiceFormatsAvailableForEveryScope` PASS (48.408s), but `testPopulatedChoiceOnlyTestsFormatAndAnswer` failed with XCTest `Lost connection to the application` / simulator helper, not an assertion. Need a clean, **nonconcurrent** simulator UI run; never mark full UI PASS yet. RC-04 OPEN: adaptive difficulty, full course multi-material transport, complete UI acceptance and real-device checks.

### RC-04 bundled import mapping consolidation — 2026-10-23

Extracted a single `BundledCourseImporter.course(plan:manifest:references:)` mapping contract from the SwiftUI file importer. It validates the package before indexing, verifies the generated rule-reference count, constructs section/topic and goal links from the same mapped UUIDs, and preserves imported teacher guidance. The UI now calls this mapper rather than duplicating mapping logic. Added repository-level regression covering the actual built `StudyCourse` saved and reloaded from SQLite, section/topic references, goal references, guidance, and invalid reference-count rejection. Existing material-only packages remain supported. No multi-material archive support yet.

Verification logs: `/tmp/botai_rc04_import_mapping_units_20261023.log` (unit tests), `/tmp/botai_rc04_choice_ui_clean_20261023.log` (sequential choice UI regression). **Do not mark either PASS until the corresponding final test summary is confirmed.** Earlier isolated UI `testMixedCardAndChoiceFormatsAvailableForEveryScope` passed, while `testPopulatedChoiceOnlyTestsFormatAndAnswer` suffered a simulator helper disconnect; these are separate outcomes. RC-04 OPEN: adaptive difficulty policy, multi-material import, complete sequential UI acceptance and physical device.

RC-04 import mapper verification (2026-10-23): 176/176 simulator unit PASS, `/tmp/botai_rc04_import_mapping_units_20261023.log`; isolated choice UI PASS, `/tmp/botai_rc04_choice_ui_clean_20261023.log`. Full UI regression and adaptive difficulty remain OPEN.

### RC-04 learner-facing recommendation access — 2026-10-23

Found that `GameHomeView.goalsCard` existed but was **never inserted into the rendered view hierarchy**. Teacher priority, difficulty, suggested daily minutes, pace comparison, rationale, mastery and target were therefore invisible despite previous UI implementation claims. Added a compact `Рекомендации и цели` action in Today when actionable goals exist, opening a scrollable accessible goal-details sheet. The standard-size home remains one-screen and without scrolling. Existing active-goal UI scenario now checks the recommendations button, sheet title, goal name and actual mastery after app relaunch. This verifies access to persisted student guidance UI, not a new difficulty-scoring policy.

Verification pending: full sequential simulator suite `/tmp/botai_rc04_full_sequential_20261023.log` was launched **before** these UI edits and cannot verify them; run the focused changed UI scenario and unit suite after the full run exits. Do not report a green UI run before the final summary. Teacher difficulty still informational; an unapproved numeric weight must not be invented. RC-04 OPEN.

### RC-04 visible recommendations verification — 2026-10-23

Confirmed a product defect: `goalsCard` was defined but unreachable in the rendered Today hierarchy. Now a compact `Рекомендации и цели` button opens a scrollable sheet showing the real per-goal mastery/target, minutes, deadline and available teacher guidance without introducing scrolling on standard-size Today. The persisted-goal cold-relaunch UI test now opens the sheet and asserts the goal and `Освоено 0%`. **Focused simulator UI PASS** (`testCreateCourseSectionTopicAndGoal`, 75.867 s, `/tmp/botai_rc04_recommendations_ui_20261023.log`); **176/176 unit PASS** (`/tmp/botai_rc04_visible_guidance_units_20261023.log`). A full UI suite started before this fix was intentionally stopped so the updated UI could be verified; it is NOT a completed full UI regression. Full sequential regression remains required at RC closure. No change to teacher difficulty scoring or profile minute budget.

### Deterministic generated choice order — 2026-10-23

Fixed nonreproducible `StudyQuestionBuilder` distractor selection and answer ordering: SHA-256 ranking derived from stable rule ID, row ID and candidate text now gives the same answer list and correct indexes for a given material snapshot, including when a question is rebuilt after restart. This does **not** change the persisted snapshot for an in-progress session, or the automatic due/weak/new study priority. New regression covers repeated builds of six four-choice questions. **177/177 simulator unit PASS**, `/tmp/botai_rc04_stable_choice_units_20261023.log` (`TEST_EXIT:0`); targeted UI not run for this pure question builder change. Full signed UI regression remains OPEN.

### Full sequential simulator regression — 2026-10-23

**PASS:** signed iPhone 16e simulator `xcodebuild test -parallel-testing-enabled NO`, `/tmp/botai_rc04_full_final_20261023.log`, `TEST_EXIT:0`, `** TEST SUCCEEDED **`, **177/177 unit and 25/25 UI**. All UI tests ran sequentially without competing test sessions, including populated choice and mixed-scope launch, course/goal/recommendation cold relaunch, resume, import, shared-question dedup and visual smoke. This validates the current simulator baseline after commit `6a2a5d7`; it does **not** prove full RC-04 feature acceptance. Remaining: approved adaptive treatment of difficulty, multi-material course transport, complete teacher recommendation scenarios and real-device acceptance. User-owned Xcode project settings remain untouched.

### RC-04 ordinal difficulty adaptation — 2026-10-23

Teacher difficulty (1...5) now participates in actual goal scheduling **only after** observed mastery/deadline urgency and explicit teacher priority are equal. Higher difficulty wins that tie, and global question dedup assigns overlapping material to the selected goal once. No arbitrary numeric weights, no change to user-owned daily minutes, no invented extra questions, and no override of stronger actual urgency or critical priority. Missing/invalid difficulty is treated as unspecified. Added one ordinal boundary unit and one real SQLite/material/goal end-to-end planner integration test, including overlapping references and priority precedence. **179/179 unit PASS** on iPhone 16e simulator, `/tmp/botai_rc04_difficulty_units_20261023.log`, `TEST_EXIT:0`. Last complete UI baseline remains **25/25 PASS** at `6a2a5d7` before this code change; UI not rerun for this checkpoint. **RC-04 remains PARTIAL**: multi-material archive and full adaptive/teacher authority acceptance pending.

### RC-04 real archive to daily plan acceptance — 2026-10-23

Added `actualBotaiArchiveImportPersistsTeacherPlanAndSchedulesQuestions`: actual `.botai` ZIP -> manifest read/validation -> imported material and generated rule IDs -> section/topic/goal mapping -> persisted and reloaded course in SQLite -> learner DailyPlanner -> two concrete chemistry questions and pace shortfall (teacher 25 vs profile 15 minutes). The student budget remains capped at 15 minutes. **180/180 unit PASS**, `TEST_EXIT:0`, `/tmp/botai_archive_test.log`. Last complete sequential UI suite remains **25/25 PASS before this change**; no claim of a new full UI run. This test covers the existing single-material archive format; **multi-material course archive remains NOT IMPLEMENTED** and must not be implied by this checkpoint. RC-04 remains OPEN; teacher authority/advanced adaptation and full acceptance pending.

### RC-04 course import consistency checkpoint — 2026-10-23

Refactored UI `.botai` import into `LearnerPackageImport.run`: validate manifest and course mapping before writing; import material, then persist the learner course via new throwing `CourseStore.saveOrThrow`; if course persistence fails, remove only the just-imported material and its media, preserving unrelated library data. Rollback failures are surfaced explicitly rather than swallowed. Once a course write commits, a later UI refresh failure cannot be misreported as a failed write and cause dangling course references. Added real SQLite tests for failure rollback and successful linked import. **181/181 unit PASS**, `/tmp/botai_atomic_import_units_final.log`, exit 0. Focused import-browser UI **1/1 PASS**, `/tmp/botai_atomic_import_ui.log`, exit 0. Last full sequential UI suite **25/25 PASS before these code changes**; no new full-suite claim. This is a compensating rollback across two repository writes, **not an ACID cross-store transaction**; multi-material course packages and full teacher acceptance remain OPEN.

### Full sequential simulator regression — 2026-10-23 (current baseline)

**181/181 unit PASS; 25/25 UI PASS; zero failed UI cases; `xcodebuild` exit 0; `** TEST SUCCEEDED **`.** iPhone 16e simulator `33176212-1247-4722-B8F4-4E53438502E4`, `-parallel-testing-enabled NO`, complete serial suite, 730.46 seconds. Log `/tmp/botai_rc04_full_181_20261023.log`. This run includes latest learner-course import rollback, ordinal teacher difficulty, ZIP -> SQLite -> planner tests, importer UI, recommendations after relaunch, resume, and session strategies. This is the **new authoritative simulator regression baseline** superseding the 177+25 snapshot at `6bce16f` and all older intermediate test notes. **Not a release candidate yet**: RC-04 multi-material course packaging/teacher authority and complete adaptive acceptance, RC-05 device/accessibility, hosted acceptance and distribution gates remain open. User-owned pbxproj not touched.
