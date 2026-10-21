-- BOTAI Stage 6: RLS test for a privileged psql connection.
-- Requires psql (\gset), authenticated role, and a disposable test database.
-- All fixtures are rolled back, including auth.users. Never run in production.
\set ON_ERROR_STOP on
BEGIN;
SELECT gen_random_uuid() AS a, gen_random_uuid() AS b,
       gen_random_uuid() AS q, gen_random_uuid() AS v \gset
INSERT INTO auth.users(id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at)
VALUES
  (:'a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'botai-rls-a-' || :'a' || '@example.invalid', '', now(), now(), now()),
  (:'b', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'botai-rls-b-' || :'b' || '@example.invalid', '', now(), now(), now());
INSERT INTO public.questions(id, creator_user_id, question_type)
VALUES (:'q', :'a', 'self_check');
INSERT INTO public.question_versions(id, question_id, version_number, prompt_text, created_by)
VALUES (:'v', :'q', 1, 'RLS disposable fixture', :'a');

SELECT set_config('botai.fixture.q', :'q', true);
SELECT set_config('botai.fixture.v', :'v', true);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', :'b', true);
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM public.questions WHERE id = current_setting('botai.fixture.q')::uuid)
  THEN RAISE EXCEPTION 'B can read A private question'; END IF;
  IF EXISTS (SELECT 1 FROM public.question_versions WHERE id = current_setting('botai.fixture.v')::uuid)
  THEN RAISE EXCEPTION 'B can read A private version'; END IF;
END $$;
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', :'a', true);
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.questions WHERE id = current_setting('botai.fixture.q')::uuid)
  THEN RAISE EXCEPTION 'A cannot read own question'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.question_versions WHERE id = current_setting('botai.fixture.v')::uuid)
  THEN RAISE EXCEPTION 'A cannot read own version'; END IF;
END $$;
RESET ROLE;
ROLLBACK;
