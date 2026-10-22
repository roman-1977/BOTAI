-- Completed learning sessions: aggregate statistics only, never individual answers.
-- Client inserts are idempotent; immutable rows cannot be updated or deleted by clients.
begin;
create table public.completed_session_summaries (
    session_id uuid not null,
    user_id uuid not null references auth.users(id) on delete cascade,
    started_at timestamptz not null,
    ended_at timestamptz not null,
    active_seconds integer not null check (active_seconds >= 0),
    answered integer not null check (answered >= 0),
    correct integer not null check (correct >= 0 and correct <= answered),
    created_at timestamptz not null default now(),
    primary key (user_id, session_id),
    constraint completed_session_time_order check (ended_at >= started_at)
);
create index completed_session_user_started_idx
    on public.completed_session_summaries (user_id, started_at desc);
alter table public.completed_session_summaries enable row level security;
create policy "own completed sessions read" on public.completed_session_summaries
    for select to authenticated using (user_id = (select auth.uid()));
create policy "own completed sessions insert" on public.completed_session_summaries
    for insert to authenticated with check (user_id = (select auth.uid()));
grant select, insert on public.completed_session_summaries to authenticated;
commit;
