# Chemistry 2027 pilot — developer fixture (NOT .botai import format)

`build_seed.py` converts the two 2027 chemistry CSVs into `chemistry_seed.json` and validates source pairs. `seed_local_sqlite.py` seeds an **already migrated** `learning.sqlite` from that JSON; it does not initialize a database or connect to Supabase.

Run tests: `python3 -m unittest discover -v` from this directory.

Dry run: `python3 seed_local_sqlite.py --db /path/to/learning.sqlite`.

**Destructive**: only on a disposable local account store, after closing the app and backing up the database: `python3 seed_local_sqlite.py --db /path/to/learning.sqlite --apply --reset-learning-data`.

The seeder deletes local learning attempts, sessions, states, outbox, course, materials and profile in the selected SQLite file. Never point it at an unrelated account. The pilot seeds **both card/reveal and single-choice rules**. Because existing Swift rules have one correct-choice configuration per rule, materials are partitioned by correct answer letter (102 material groups, 204 rules, 323 knowledge rows). This is a temporary fixture workaround, NOT the intended canonical knowledge model. The goal references only reveal rules to avoid double-counting mastery; choice rules are available in the course sections. A future learning-engine change must unify progress for both assessment modes. See `docs/iterations/V030_CHEMISTRY_PILOT.md`.
