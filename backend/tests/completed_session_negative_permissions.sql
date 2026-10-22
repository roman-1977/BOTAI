-- Disposable PostgreSQL after migrations 0025/0026, with Supabase auth roles.
-- Verify client privilege boundaries and parent FK. Entire fixture rolls back.
\set ON_ERROR_STOP on
BEGIN;
SELECT gen_random_uuid() AS owner, gen_random_uuid() AS stranger,
       gen_random_uuid() AS session_id, gen_random_uuid() AS course_id,
       gen_random_uuid() AS section_id, gen_random_uuid() AS topic_id \gset
INSERT INTO auth.users(id) VALUES (:'owner'), (:'stranger');
SELECT set_config('botai.negative.session', :'session_id', true);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', :'owner', true);
INSERT INTO public.completed_session_summaries
 (user_id,session_id,started_at,ended_at,active_seconds,answered,correct)
 VALUES (:'owner',:'session_id',now(),now(),0,1,1);
DO $$ BEGIN
  BEGIN
    DELETE FROM public.completed_session_summaries;
    RAISE EXCEPTION 'Client delete on summary was permitted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    DELETE FROM public.completed_session_topic_aggregates;
    RAISE EXCEPTION 'Client delete on topic was permitted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    INSERT INTO public.completed_session_topic_aggregates
      (user_id,session_id,course_id,section_id,topic_id,answered,correct)
    VALUES (current_setting('request.jwt.claim.sub')::uuid, gen_random_uuid(),
      gen_random_uuid(),gen_random_uuid(),gen_random_uuid(),1,1);
    RAISE EXCEPTION 'Orphan topic aggregate accepted';
  EXCEPTION WHEN foreign_key_violation THEN NULL; END;
  BEGIN
    INSERT INTO public.completed_session_topic_aggregates
      (user_id,session_id,course_id,section_id,topic_id,answered,correct)
    VALUES (current_setting('request.jwt.claim.sub')::uuid,
      current_setting('botai.negative.session')::uuid,
      gen_random_uuid(),gen_random_uuid(),gen_random_uuid(),1,2);
    RAISE EXCEPTION 'Invalid topic correct count accepted';
  EXCEPTION WHEN check_violation THEN NULL; END;
END $$;
RESET ROLE;
CREATE ROLE botai_unauthenticated_fixture NOLOGIN;
GRANT USAGE ON SCHEMA public TO botai_unauthenticated_fixture;
SET LOCAL ROLE botai_unauthenticated_fixture;
DO $$ BEGIN
  BEGIN
    PERFORM count(*) FROM public.completed_session_summaries;
    RAISE EXCEPTION 'Unauthenticated summary read was permitted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM count(*) FROM public.completed_session_topic_aggregates;
    RAISE EXCEPTION 'Unauthenticated topic read was permitted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;
ROLLBACK;
