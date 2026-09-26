begin;
create or replace function public.submit_quiz_for_publication(p_quiz_id uuid,p_version_id uuid,p_note text default null) returns uuid language plpgsql security definer set search_path=public as $$ declare sid uuid:=gen_random_uuid(); begin if not exists(select 1 from quizzes q where q.id=p_quiz_id and q.creator_user_id=auth.uid()) then raise exception 'not owner'; end if; insert into publication_submissions(id,quiz_id,quiz_version_id,submitted_by,author_note) values(sid,p_quiz_id,p_version_id,auth.uid(),p_note); return sid; end; $$;
create or replace function public.respond_friendship(p_friendship_id uuid,p_accept boolean) returns void language plpgsql security definer set search_path=public as $$ begin update friendships set status=case when p_accept then 'accepted'::friendship_status else 'declined'::friendship_status end,responded_at=now() where id=p_friendship_id and addressee_user_id=auth.uid() and status='pending'; end; $$;
grant execute on function public.submit_quiz_for_publication(uuid,uuid,text) to authenticated;
grant execute on function public.respond_friendship(uuid,boolean) to authenticated;
commit;
