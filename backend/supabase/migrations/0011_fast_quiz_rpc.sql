begin;
create or replace function public.create_quiz_with_cards(p_title text,p_description text,p_cards jsonb) returns uuid language plpgsql security definer set search_path=public as $$
declare uid uuid:=auth.uid(); qid uuid:=gen_random_uuid(); vid uuid:=gen_random_uuid(); n int:=jsonb_array_length(p_cards);
begin
 if uid is null then raise exception 'authentication required'; end if; if nullif(trim(p_title),'') is null then raise exception 'title required'; end if; if n=0 then raise exception 'cards required'; end if;
 insert into quizzes(id,creator_user_id) values(qid,uid); insert into quiz_collaborators(quiz_id,user_id,role) values(qid,uid,'owner'); insert into quiz_versions(id,quiz_id,version_number,title,description,created_by) values(vid,qid,1,p_title,nullif(p_description,''),uid);
 with c as (select ordinality-1 pos, value, gen_random_uuid() qid, gen_random_uuid() qvid from jsonb_array_elements(p_cards) with ordinality),
 iq as (insert into questions(id,creator_user_id,question_type) select qid,uid,'self_check' from c returning id),
 iqv as (insert into question_versions(id,question_id,version_number,prompt_text,answer_text,created_by) select c.qvid,c.qid,1,c.value->>'prompt',c.value->>'answer',uid from c join iq on iq.id=c.qid returning id)
 insert into quiz_version_items(quiz_version_id,question_id,question_version_id,position) select vid,c.qid,c.qvid,c.pos from c join iqv on iqv.id=c.qvid;
 return qid;
end; $$;
commit;
