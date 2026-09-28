# ЕГЭ import fixtures

Набор реальных по содержанию тренировочных материалов для проверки BOTAI Client. Каждый файл — самостоятельный материал без встроенной структуры курса. Структуру пользователь создаёт позже в клиенте.

## Химия
- `chemistry/01_atomic_structure.csv` — простой формат «Вопрос / Ответ».
- `chemistry/02_inorganic_classes.csv` — справочник с тремя полями. При импорте удобно проверить несколько направлений: Название ↔ Формула, Название ↔ Класс, Формула → Класс.

## Математика, профильный ЕГЭ
- `math/01_probability.csv` — простой «Вопрос / Ответ» по вероятности.
- `math/02_formulas.tsv` — TSV-справочник: Название / Формула / Назначение.

Темы выбраны по навигаторам самостоятельной подготовки ФИПИ к ЕГЭ-2026. Формулировки текущей первой партии составлены как самостоятельные тренировочные вопросы по проверяемому содержанию; следующие fixtures добавят варианты ответа и `.botai` с изображениями.

## Current realistic-volume fixtures

- Chemistry atomic structure: 36 knowledge rows × 6 fields; intended to generate many bidirectional cards.
- Chemistry inorganic classes: 30 knowledge rows × 3 fields.
- Mathematics probability: 120 independent question/answer rows.
- Mathematics formulas: 32 knowledge rows × 3 fields.

These are intentionally large enough to exercise scrolling, parsing, rule expansion and SQLite persistence. Further fixtures will target 300–1000 rows and BOTAI packages with images.
