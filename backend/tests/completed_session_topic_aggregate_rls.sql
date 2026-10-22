-- Privileged psql only, disposable database after migrations 0025/0026.
\set ON_ERROR_STOP on
BEGIN;
SELECT gen_random_uuid() AS a, gen_random_uuid() AS b,
       gen_random_uuid() AS session_id, gen_random_uuid() AS course_id,
       gen_random_uuid() AS section_id, gen_random_uuid() AS topic_id \gset
INSERT INTO auth.users(id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at)
VALUES
  (:'a', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'botai-topic-a-' || :'a' || '@example.invalid', '', now(), now(), now()),
  (:'b', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'botai-topic-b-' || :'b' || '@example.invalid', '', now(), now(), now());
SELECT set_config('botai.topic.a', :'a', true);
SELECT set_config('botai.topic.session', :'session_id', true);
SELECT set_config('botai.topic.course', :'course_id', true);
SELECT set_config('botai.topic.section', :'section_id', true);
SELECT set_config('botai.topic.topic', :'topic_id', true);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', :'a', true);
INSERT INTO public.completed_session_summaries
  (user_id, session_id, started_at, ended_at, active_seconds, answered, correct)
VALUES (:'a', :'session_id', now() - interval '5 minutes', now(), 120, 4, 3);
INSERT INTO public.completed_session_topic_aggregates
  (user_id, session_id, course_id, section_id, topic_id, answered, correct)
VALUES (:'a', :'session_id', :'course_id', :'section_id', :'topic_id', 3, 2);
DO $$ BEGIN
  IF (SELECT count(*) FROM public.completed_session_topic_aggregates) <> 1
  THEN RAISE EXCEPTION 'A cannot read own topic aggregate'; END IF;
  BEGIN
    UPDATE public.completed_session_topic_aggregates SET answered = 9;
    RAISE EXCEPTION 'Client was allowed to change aggregate';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    INSERT INTO public.completed_session_topic_aggregates
      (user_id, session_id, course_id, section_id, topic_id, answered, correct)
    VALUES (current_setting('botai.topic.a')::uuid,
      current_setting('botai.topic.session')::uuid,
      current_setting('botai.topic.course')::uuid,
      current_setting('botai.topic.section')::uuid,
      current_setting('botai.topic.topic')::uuid, 1, 1);
    RAISE EXCEPTION 'Duplicate topic aggregate accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
END $$;
SELECT set_config('request.jwt.claim.sub', :'b', true);
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM public.completed_session_topic_aggregates)
  THEN RAISE EXCEPTION 'B can read A topic aggregate'; END IF;
  BEGIN
    INSERT INTO public.completed_session_topic_aggregates
      (user_id, session_id, course_id, section_id, topic_id, answered, correct)
    VALUES (current_setting('botai.topic.a')::uuid,
      current_setting('botai.topic.session')::uuid,
      current_setting('botai.topic.course')::uuid,
      current_setting('botai.topic.section')::uuid,
      current_setting('botai.topic.topic')::uuid, 1, 1);
    RAISE EXCEPTION 'B was allowed to forge A aggregate';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $$;
RESET ROLE;
ROLLBACK;
