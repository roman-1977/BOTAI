-- The quizzes SELECT/UPDATE policies reference quiz_collaborators.
-- PostgreSQL evaluates these expressions with the caller's privileges;
-- without SELECT, even unrelated question INSERTs can fail with 42501.
-- RLS remains enabled on quiz_collaborators. Do not expose its rows:
-- there is intentionally no SELECT policy for the authenticated role.
begin;
grant select on table public.quiz_collaborators to authenticated;
commit;
