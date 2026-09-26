-- BOTAI
-- Migration 0002: Learning
-- PostgreSQL / Supabase
--
-- Depends on: 0001_identity_content.sql
-- DESIGN STATUS: Accepted. Not yet applied to Supabase.

begin;

-- ============================================================
-- Devices
-- ============================================================

create table public.user_devices (
    id uuid primary key,
    user_id uuid not null
        references auth.users(id) on delete cascade,

    platform text not null default 'ios',
    app_version text,

    created_at timestamptz not null default now(),
    last_seen_at timestamptz,

    constraint user_devices_platform_not_blank
        check (btrim(platform) <> '')
);

create index user_devices_user_id_idx
    on public.user_devices(user_id);

-- ============================================================
-- Enrollments
-- ============================================================

create table public.enrollments (
    id uuid primary key default gen_random_uuid(),

    user_id uuid not null
        references auth.users(id) on delete cascade,

    quiz_id uuid not null
        references public.quizzes(id) on delete restrict,

    -- Version currently adopted by this learner.
    quiz_version_id uuid not null
        references public.quiz_versions(id) on delete restrict,

    enrolled_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    archived_at timestamptz,

    constraint enrollments_user_quiz_unique
        unique (user_id, quiz_id)
);

create index enrollments_user_id_idx
    on public.enrollments(user_id);

create index enrollments_quiz_id_idx
    on public.enrollments(quiz_id);

create trigger enrollments_set_updated_at
before update on public.enrollments
for each row execute function public.set_updated_at();

-- ============================================================
-- Study sessions
-- ============================================================

create table public.study_sessions (
    id uuid primary key,

    user_id uuid not null
        references auth.users(id) on delete cascade,

    device_id uuid
        references public.user_devices(id) on delete set null,

    -- Client timestamps describe the actual user session.
    started_at timestamptz not null,
    ended_at timestamptz,

    -- Server receipt timestamp is independent of device clock.
    received_at timestamptz not null default now(),

    constraint study_sessions_time_order
        check (
            ended_at is null
            or ended_at >= started_at
        )
);

create index study_sessions_user_started_idx
    on public.study_sessions(user_id, started_at desc);

-- ============================================================
-- Attempt enums
-- ============================================================

create type public.learning_direction as enum (
    'default',
    'a_to_b',
    'b_to_a'
);

create type public.attempt_result as enum (
    'incorrect',
    'hard',
    'correct'
);

-- ============================================================
-- Attempts
-- ============================================================

-- Attempts are append-oriented learning events.
--
-- The UUID is generated before upload. Re-sending the same
-- attempt therefore does not create a second event.

create table public.attempts (
    id uuid primary key,

    user_id uuid not null
        references auth.users(id) on delete cascade,

    device_id uuid
        references public.user_devices(id) on delete set null,

    study_session_id uuid
        references public.study_sessions(id) on delete set null,

    quiz_id uuid
        references public.quizzes(id) on delete set null,

    quiz_version_id uuid
        references public.quiz_versions(id) on delete set null,

    question_id uuid not null
        references public.questions(id) on delete restrict,

    question_version_id uuid not null,

    direction public.learning_direction not null default 'default',

    result public.attempt_result not null,

    -- Optional user confidence / future richer scale.
    -- 0.0 ... 1.0
    confidence double precision,

    -- Device time: when the answer actually occurred.
    answered_at timestamptz not null,

    -- Server time: when this event first arrived.
    received_at timestamptz not null default now(),

    constraint attempts_question_version_fk
        foreign key (question_id, question_version_id)
        references public.question_versions(question_id, id)
        on delete restrict,

    constraint attempts_confidence_range
        check (
            confidence is null
            or confidence between 0.0 and 1.0
        )
);

create index attempts_user_answered_idx
    on public.attempts(user_id, answered_at desc);

create index attempts_user_question_idx
    on public.attempts(user_id, question_id);

create index attempts_question_version_idx
    on public.attempts(question_version_id);

create index attempts_received_at_idx
    on public.attempts(received_at);

-- ============================================================
-- Learning state
-- ============================================================

-- LearningState is current calculated state.
-- Attempts remain historical evidence.
--
-- algorithm_version lets us recalculate states later when the
-- repetition algorithm changes.

create table public.learning_states (
    id uuid primary key default gen_random_uuid(),

    user_id uuid not null
        references auth.users(id) on delete cascade,

    question_id uuid not null
        references public.questions(id) on delete restrict,

    direction public.learning_direction not null default 'default',

    state text not null default 'new',

    strength double precision,
    difficulty double precision,

    review_count integer not null default 0,
    success_count integer not null default 0,
    failure_count integer not null default 0,

    last_reviewed_at timestamptz,
    next_review_at timestamptz,

    algorithm_version integer not null default 1,

    updated_at timestamptz not null default now(),

    constraint learning_states_user_question_direction_unique
        unique (user_id, question_id, direction),

    constraint learning_states_counts_nonnegative
        check (
            review_count >= 0
            and success_count >= 0
            and failure_count >= 0
        ),

    constraint learning_states_strength_range
        check (
            strength is null
            or strength between 0.0 and 1.0
        ),

    constraint learning_states_difficulty_range
        check (
            difficulty is null
            or difficulty between 0.0 and 1.0
        )
);

create index learning_states_due_idx
    on public.learning_states(user_id, next_review_at);

create index learning_states_user_state_idx
    on public.learning_states(user_id, state);

create trigger learning_states_set_updated_at
before update on public.learning_states
for each row execute function public.set_updated_at();

-- ============================================================
-- Goals
-- ============================================================

create table public.goals (
    id uuid primary key,

    user_id uuid not null
        references auth.users(id) on delete cascade,

    title text not null,

    target_date date,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    archived_at timestamptz,

    constraint goals_title_not_blank
        check (btrim(title) <> '')
);

create index goals_user_id_idx
    on public.goals(user_id);

create trigger goals_set_updated_at
before update on public.goals
for each row execute function public.set_updated_at();

-- A goal can contain several quizzes.
-- Later this may be generalized to subjects/topics if product
-- requirements show that it is necessary.

create table public.goal_quizzes (
    goal_id uuid not null
        references public.goals(id) on delete cascade,

    quiz_id uuid not null
        references public.quizzes(id) on delete restrict,

    priority integer not null default 0,

    created_at timestamptz not null default now(),

    primary key (goal_id, quiz_id)
);

create index goal_quizzes_quiz_id_idx
    on public.goal_quizzes(quiz_id);

-- ============================================================
-- RLS
-- ============================================================

alter table public.user_devices enable row level security;
alter table public.enrollments enable row level security;
alter table public.study_sessions enable row level security;
alter table public.attempts enable row level security;
alter table public.learning_states enable row level security;
alter table public.goals enable row level security;
alter table public.goal_quizzes enable row level security;

-- Devices

create policy "user devices own select"
on public.user_devices
for select
using (auth.uid() = user_id);

create policy "user devices own insert"
on public.user_devices
for insert
with check (auth.uid() = user_id);

create policy "user devices own update"
on public.user_devices
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Enrollments

create policy "enrollments own select"
on public.enrollments
for select
using (auth.uid() = user_id);

create policy "enrollments own insert"
on public.enrollments
for insert
with check (auth.uid() = user_id);

create policy "enrollments own update"
on public.enrollments
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Study sessions

create policy "study sessions own select"
on public.study_sessions
for select
using (auth.uid() = user_id);

create policy "study sessions own insert"
on public.study_sessions
for insert
with check (auth.uid() = user_id);

create policy "study sessions own update"
on public.study_sessions
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Attempts
--
-- No UPDATE policy.
-- Normal clients create Attempts but do not rewrite history.

create policy "attempts own select"
on public.attempts
for select
using (auth.uid() = user_id);

create policy "attempts own insert"
on public.attempts
for insert
with check (auth.uid() = user_id);

-- Learning state
--
-- Clients may read canonical LearningState but may not directly
-- insert or update it.
--
-- iOS maintains a local calculated LearningState in SQLite for
-- immediate offline operation.
--
-- Canonical server LearningState is calculated by trusted
-- server-side logic from synchronized Attempts.

create policy "learning states own select"
on public.learning_states
for select
using (auth.uid() = user_id);

-- Goals

create policy "goals own select"
on public.goals
for select
using (auth.uid() = user_id);

create policy "goals own insert"
on public.goals
for insert
with check (auth.uid() = user_id);

create policy "goals own update"
on public.goals
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- goal_quizzes access follows ownership of the parent Goal.

create policy "goal quizzes own select"
on public.goal_quizzes
for select
using (
    exists (
        select 1
        from public.goals g
        where g.id = goal_quizzes.goal_id
          and g.user_id = auth.uid()
    )
);

create policy "goal quizzes own insert"
on public.goal_quizzes
for insert
with check (
    exists (
        select 1
        from public.goals g
        where g.id = goal_quizzes.goal_id
          and g.user_id = auth.uid()
    )
);

create policy "goal quizzes own delete"
on public.goal_quizzes
for delete
using (
    exists (
        select 1
        from public.goals g
        where g.id = goal_quizzes.goal_id
          and g.user_id = auth.uid()
    )
);

commit;
