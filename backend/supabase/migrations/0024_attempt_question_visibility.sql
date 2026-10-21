-- An attempt may only reference a question version visible to the current user.
-- The foreign key alone does not enforce RLS visibility of referenced rows.
begin;
create policy "attempts visible question version insert"
on public.attempts
as restrictive
for insert
to authenticated
with check (
    exists (
        select 1
        from public.question_versions v
        where v.id = question_version_id
          and v.question_id = question_id
    )
);
commit;
