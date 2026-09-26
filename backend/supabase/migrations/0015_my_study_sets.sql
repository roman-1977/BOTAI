begin;
create or replace function public.my_study_sets() returns table(quiz_id uuid,quiz_version_id uuid,title text,description text,version_number int,created_at timestamptz,submission_status text) language sql security definer set search_path=public as $$
 select s.id,s.id,s.title,s.description,1,s.created_at,null::text from study_sets s where s.owner_user_id=auth.uid() order by s.created_at desc;
$$;
grant execute on function public.my_study_sets() to authenticated;
commit;
