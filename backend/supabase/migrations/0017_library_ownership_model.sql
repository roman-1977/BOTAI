begin;
create table if not exists public.user_quiz_library (
  user_id uuid not null references auth.users(id) on delete cascade,
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  relationship text not null check (relationship in ('owned','library')),
  added_at timestamptz not null default now(),
  primary key (user_id, quiz_id)
);
alter table public.user_quiz_library enable row level security;
create policy "read own quiz library" on public.user_quiz_library for select using (user_id=auth.uid());
create policy "add own quiz library" on public.user_quiz_library for insert with check (user_id=auth.uid());
create policy "remove own quiz library" on public.user_quiz_library for delete using (user_id=auth.uid());
comment on table public.user_quiz_library is 'Explicit personal-library membership and ownership. UI capabilities must not be inferred.';
commit;
