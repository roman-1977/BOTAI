# Chemistry 2027 pilot — developer fixture (NOT .botai import format)

`build_seed.py` converts the two 2027 chemistry CSVs into `chemistry_seed.json` and validates source pairs. `seed_local_sqlite.py` seeds an **already migrated** `learning.sqlite` from that JSON; it does not initialize a database or connect to Supabase.

Run tests: `python3 -m unittest discover -v` from this directory.

Dry run: `python3 seed_local_sqlite.py --db /path/to/learning.sqlite`.

**Destructive**: only on a disposable local account store, after closing the app and backing up the database: `python3 seed_local_sqlite.py --db /path/to/learning.sqlite --apply --reset-learning-data`.

The seeder deletes local learning attempts, sessions, states, outbox, course, materials and profile in the selected SQLite file. Never point it at an unrelated account. The current pilot exposes **card/reveal questions only**; the multiple-choice source values are preserved but cannot be assessed correctly until row-specific choice keys are supported by the Swift learning model. See `docs/iterations/V030_CHEMISTRY_PILOT.md`.
