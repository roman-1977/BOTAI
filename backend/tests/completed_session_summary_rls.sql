-- Execute with privileged psql on a disposable Supabase database after migration 0025.
-- Entire fixture is rolled back; never run against production.
\set ON_ERROR_STOP on
BEGIN;
SELECT gen_random_uuid() AS a, gen_random_uuid() AS b,
       gen_random_uuid() AS s, gen_random_uuid() AS t \gset
INSERT INTO auth.users(id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at)
VALUES
  (:'a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'botai-summary-a-' || :'a' || '@example.invalid', '', now(), now(), now()),
  (:'b', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'botai-summary-b-' || :'b' || '@example.invalid', '', now(), now(), now());
SELECT set_config('botai.summary.a', :'a', true);
SELECT set_config('botai.summary.b', :'b', true);
SELECT set_config('botai.summary.s', :'s', true);
SELECT set_config('botai.summary.t', :'t', true);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', :'a', true);
INSERT INTO public.completed_session_summaries
  (session_id, user_id, started_at, ended_at, active_seconds, answered, correct)
VALUES (:'s', :'a', now() - interval '5 minutes', now(), 120, 7, 5);
DO $$ BEGIN
  IF (SELECT count(*) FROM public.completed_session_summaries) <> 1
  THEN RAISE EXCEPTION 'A cannot read own summary'; END IF;
  BEGIN
    INSERT INTO public.completed_session_summaries
      (session_id, user_id, started_at, ended_at, active_seconds, answered, correct)
    VALUES (current_setting('botai.summary.s')::uuid,
      current_setting('botai.summary.a')::uuid, now(), now(), 0, 0, 0);
    RAISE EXCEPTION 'Duplicate session accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO public.completed_session_summaries
      (session_id, user_id, started_at, ended_at, active_seconds, answered, correct)
    VALUES (current_setting('botai.summary.t')::uuid,
      current_setting('botai.summary.a')::uuid, now(), now(), 1, 1, 2);
    RAISE EXCEPTION 'Invalid correct count accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    UPDATE public.completed_session_summaries SET answered = 999;
    RAISE EXCEPTION 'Client was allowed to update summary';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $$;
SELECT set_config('request.jwt.claim.sub', :'b', true);
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM public.completed_session_summaries)
  THEN RAISE EXCEPTION 'B can read A summary'; END IF;
  BEGIN
    INSERT INTO public.completed_session_summaries
      (session_id, user_id, started_at, ended_at, active_seconds, answered, correct)
    VALUES (current_setting('botai.summary.t')::uuid,
      current_setting('botai.summary.a')::uuid, now(), now(), 0, 0, 0);
    RAISE EXCEPTION 'B was allowed to forge A summary';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $$;
RESET ROLE;
ROLLBACK;
