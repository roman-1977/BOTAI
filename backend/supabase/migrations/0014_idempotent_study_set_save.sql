begin;
drop function if exists public.create_study_set(text,text,jsonb,jsonb,jsonb);
create or replace function public.create_study_set(p_id uuid,p_title text,p_description text,p_headers jsonb,p_rows jsonb,p_mappings jsonb) returns uuid language plpgsql security definer set search_path=public as $$ declare uid uuid:=auth.uid(); begin if uid is null then raise exception 'authentication required'; end if; insert into study_sets(id,owner_user_id,title,description,headers,rows,mappings) values(p_id,uid,p_title,nullif(p_description,''),p_headers,p_rows,p_mappings) on conflict(id) do nothing; if not exists(select 1 from study_sets where id=p_id and owner_user_id=uid) then raise exception 'study set id conflict'; end if; return p_id; end; $$;
grant execute on function public.create_study_set(uuid,text,text,jsonb,jsonb,jsonb) to authenticated;
commit;
