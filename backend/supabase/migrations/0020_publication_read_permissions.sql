-- Published question and quiz RLS policies query publications.
-- Grant table-level SELECT while retaining publications RLS filtering.
begin;
grant select on table public.publications to authenticated;
commit;
