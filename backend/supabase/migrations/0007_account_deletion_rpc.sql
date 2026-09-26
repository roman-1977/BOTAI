begin;
create or replace function public.request_account_deletion() returns void language plpgsql security definer set search_path=public as $$ begin insert into public.account_deletion_requests(user_id,status) values(auth.uid(),'requested') on conflict(user_id) do update set status='requested',requested_at=now(),last_error=null; end; $$;
grant execute on function public.request_account_deletion() to authenticated;
commit;
