-- Aggregated counts only: no question identifiers, prompts or individual answers.
-- Apply only after migration 0025; not deployed automatically.
begin;
create table public.completed_session_topic_aggregates (
    user_id uuid not null,
    session_id uuid not null,
    course_id uuid not null,
    section_id uuid not null,
    topic_id uuid not null,
    answered integer not null check (answered > 0),
    correct integer not null check (correct >= 0 and correct <= answered),
    created_at timestamptz not null default now(),
    primary key (user_id, session_id, course_id, section_id, topic_id),
    foreign key (user_id, session_id)
        references public.completed_session_summaries(user_id, session_id) on delete cascade
);
create index completed_topic_user_course_idx
    on public.completed_session_topic_aggregates(user_id, course_id, topic_id);
alter table public.completed_session_topic_aggregates enable row level security;
create policy "own completed topic aggregates read"
    on public.completed_session_topic_aggregates for select to authenticated
    using (user_id = (select auth.uid()));
create policy "own completed topic aggregates insert"
    on public.completed_session_topic_aggregates for insert to authenticated
    with check (user_id = (select auth.uid()));
grant select, insert on public.completed_session_topic_aggregates to authenticated;
commit;
