begin;
create or replace function public.create_quiz_with_cards(p_title text,p_description text,p_cards jsonb) returns uuid language plpgsql security definer set search_path=public as $$
declare uid uuid:=auth.uid(); qid uuid:=gen_random_uuid(); vid uuid:=gen_random_uuid(); item jsonb; q uuid; qv uuid; pos int:=0;
begin
 if uid is null then raise exception 'authentication required'; end if;
 if nullif(trim(p_title),'') is null then raise exception 'title required'; end if;
 if jsonb_array_length(p_cards)=0 then raise exception 'cards required'; end if;
 insert into quizzes(id,creator_user_id) values(qid,uid);
 insert into quiz_collaborators(quiz_id,user_id,role) values(qid,uid,'owner');
 insert into quiz_versions(id,quiz_id,version_number,title,description,created_by) values(vid,qid,1,p_title,nullif(p_description,''),uid);
 for item in select value from jsonb_array_elements(p_cards) loop
   q:=gen_random_uuid(); qv:=gen_random_uuid();
   insert into questions(id,creator_user_id,question_type) values(q,uid,'self_check');
   insert into question_versions(id,question_id,version_number,prompt_text,answer_text,created_by) values(qv,q,1,item->>'prompt',item->>'answer',uid);
   insert into quiz_version_items(quiz_version_id,question_id,question_version_id,position) values(vid,q,qv,pos); pos:=pos+1;
 end loop;
 return qid;
end; $$;
grant execute on function public.create_quiz_with_cards(text,text,jsonb) to authenticated;
commit;
