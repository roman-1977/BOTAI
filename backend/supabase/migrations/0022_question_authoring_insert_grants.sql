-- Authoring RLS INSERT policies existed, but authenticated lacked table privileges.
-- Grant only INSERT on questions and versions; WITH CHECK RLS still enforces ownership.
begin;
grant insert on table public.questions, public.question_versions to authenticated;
commit;
