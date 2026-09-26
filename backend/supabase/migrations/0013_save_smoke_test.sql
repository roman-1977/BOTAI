begin;
create or replace function public.smoke_test_study_set_storage(p_rows jsonb) returns integer language plpgsql security definer set search_path=public as $$ declare n integer; begin select jsonb_array_length(p_rows) into n; if n < 1 then raise exception 'rows required'; end if; perform pg_column_size(p_rows); return n; end; $$;
grant execute on function public.smoke_test_study_set_storage(jsonb) to anon, authenticated;
commit;
