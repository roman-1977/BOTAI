# BOTAI Roadmap

## MVP

MVP BOTAI должен быть полноценным продуктом для реального обучения, а не только техническим прототипом.

### Входит в MVP

- iOS-приложение;
- аккаунт пользователя;
- Sign in with Apple;
- синхронизация между устройствами;
- local-first работа;
- предметы, разделы, темы и опросники;
- собственные опросники пользователя;
- публичная библиотека;
- публикация пользовательских опросников;
- модерация публичного контента;
- версии и обновления опубликованного материала;
- текст;
- LaTeX/формулы;
- изображения и схемы;
- двусторонние пары;
- вопрос → ответ;
- single choice;
- multiple choice;
- интервальные повторения;
- история попыток;
- персональный LearningState;
- автоматическая ежедневная программа;
- слабые / забываемые / новые элементы;
- цели и даты экзаменов;
- несколько предметов и целей;
- статистика;
- недельные отчёты;
- мотивационные механики;
- друзья;
- обмен результатами;
- челленджи;
- жалобы;
- блокировка пользователей;
- удаление аккаунта и персональных данных.

## Не входит в MVP

### BOLDAI

AI-экзамен остаётся частью продуктовой концепции и учитывается в архитектуре, но не реализуется в MVP.

### AI Content Generation

Не входят в MVP:

- PDF → опросник;
- фото → опросник;
- документ → опросник;
- автоматическая AI-генерация учебного материала.

## После MVP

Основные крупные направления:

1. BOLDAI / AI Exam.
2. AI Content Generation.
3. Расширение типов заданий.
4. Авторские и преподавательские инструменты.
5. Родительские функции.
6. Web / Android — при подтверждённой необходимости.

## Принцип

Архитектура MVP должна позволять добавить BOLDAI без переписывания учебного ядра.

## Current implementation sequence

1. Harden and validate backend schema design.
2. Define GRDB/local-first sync contract.
3. Create iOS project skeleton and local database migrations.
4. Implement authentication/bootstrap.
5. Implement core Learn loop offline-first.
6. Connect synchronization and public library.
7. Add content authoring/publication, goals/statistics, then social features.
8. Complete App Store privacy/moderation/account-deletion operational checks before release.

The first executable milestone is an offline Learn vertical slice with durable Attempt/outbox behavior, not a full set of empty screens.
