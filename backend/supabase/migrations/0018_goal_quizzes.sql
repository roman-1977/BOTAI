begin;
create table if not exists public.goal_study_sets (goal_id uuid not null references public.goals(id) on delete cascade, study_set_id uuid not null references public.study_sets(id) on delete cascade, created_at timestamptz not null default now(), primary key(goal_id,study_set_id));
alter table public.goal_study_sets enable row level security;
create policy "manage own goal study sets" on public.goal_study_sets for all using(exists(select 1 from goals g where g.id=goal_id and g.user_id=auth.uid())) with check(exists(select 1 from goals g where g.id=goal_id and g.user_id=auth.uid()));
commit;
