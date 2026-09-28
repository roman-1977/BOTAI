# BOTAI material file formats — Client v1

## CSV / TSV creation

The client accepts UTF-8 text tables. The first non-empty row is the header. Every following non-empty row must have the same number of columns. Supported delimiters are comma (`,`), semicolon (`;`) and tab; tab is preferred when copying from Numbers/Excel.

Example `acids.csv`:

```csv
Название,Формула,Остаток,Заряд
Серная кислота,H2SO4,SO4,2-
Азотная кислота,HNO3,NO3,1-
```

After opening the file the user supplies a material title, optional subject/topic, previews the parsed rows, and enables question directions such as `Название → Формула`. A direction creates one card per usable row. The source file is transport only: after confirmation BOTAI stores normalized fields, rows and rules in its local SQLite database.

## BOTAI package (`.botai`)

A `.botai` file is a ZIP container. Client v1 reserves this structure:

```text
manifest.json
content.csv
images/          # optional
```

`manifest.json` contains `formatVersion`, title, optional subject/topic, material kind, data filename and question rules. Paths must remain inside the archive. Unknown future format versions must be rejected rather than guessed. Images are optional and will be referenced by data fields in a later implementation step.

See `samples/acids.csv` and `samples/acids.botai` for test fixtures. Do not silently change this format: update the manifest version, ADR and compatibility tests together.

## User-facing guide
Практическая инструкция по подготовке CSV/TSV и ZIP с изображениями находится в `docs/USER_IMPORT_GUIDE.md`. Текущая реализация поддерживает несколько media-колонок и сохраняет media локально вместе с материалом.
