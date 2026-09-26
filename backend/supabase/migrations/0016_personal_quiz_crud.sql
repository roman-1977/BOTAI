begin;
create or replace function public.get_study_set(p_id uuid) returns jsonb language sql stable security definer set search_path=public as $$ select jsonb_build_object('id',id,'title',title,'description',description,'headers',headers,'rows',rows,'mappings',mappings) from study_sets where id=p_id and owner_user_id=auth.uid() $$;
create or replace function public.update_study_set(p_id uuid,p_title text,p_description text,p_headers jsonb,p_rows jsonb,p_mappings jsonb) returns void language plpgsql security definer set search_path=public as $$ begin update study_sets set title=p_title,description=nullif(p_description,''),headers=p_headers,rows=p_rows,mappings=p_mappings,updated_at=now() where id=p_id and owner_user_id=auth.uid(); if not found then raise exception 'not found'; end if; end $$;
grant execute on function public.get_study_set(uuid) to authenticated;
grant execute on function public.update_study_set(uuid,text,text,jsonb,jsonb,jsonb) to authenticated;
commit;
