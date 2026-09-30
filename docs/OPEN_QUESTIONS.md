# Open Questions

Вопросы, которые намеренно пока не считаются решёнными. Принятые решения фиксируются в ADR и не должны оставаться в этом списке.

## Product

- Нужен ли родительский режим после MVP.
- Нужна ли отдельная роль преподавателя / профессионального автора.
- Как измерять «понимание» темы помимо запоминания.
- Как пользователь задаёт желаемый уровень освоения.
- Как приложение распределяет время между несколькими целями.

## Learning

- Какой production-алгоритм интервального повторения должен заменить текущую простую MVP-эвристику (Again=сразу, Hard=текущий/1 день, Good=удвоение интервала).
- Как учитывать самооценку и какая шкала оптимальна.
- Как объединять автоматическую и ручную оценку.
- Когда тема считается готовой к будущему BOLDAI.
- Как будущие результаты BOLDAI влияют на очередь BOTAI.

## Content

- Нужна ли отдельная сущность Knowledge Item после проверки текущей модели на реальном контенте.
- Какие типы заданий нужны сверх MVP-набора.
- Как юридически оформить права на совместно созданный публичный контент.

## Business

- Бесплатное или платное приложение.
- Подписка / разовая покупка / freemium.
- Возможна ли монетизация авторских курсов.

## Technical

- Минимальная версия iOS.
- Analytics provider и политика аналитики.
- Push notifications: какие события действительно требуют push.
- Конкретная реализация trusted RPC / Edge Functions для social/moderation/account deletion.

BOLDAI и AI Content Generation являются post-MVP; выбор AI-моделей и стоимость AI не блокируют MVP.

## Sync semantics to decide with features

- Conflict policy for offline edits to Goals.
- Conflict policy for profile changes.
- Conflict policy for collaborative content editing if/when offline authoring is enabled.

- Exact iOS file-protection class for the private GRDB store versus desired background sync behavior.
