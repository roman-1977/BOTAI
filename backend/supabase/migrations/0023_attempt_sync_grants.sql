-- Attempt RLS already enforces auth.uid() = user_id on SELECT and INSERT.
-- Allow only these operations; no UPDATE or DELETE grant.
begin;
grant select, insert on table public.attempts to authenticated;
commit;
