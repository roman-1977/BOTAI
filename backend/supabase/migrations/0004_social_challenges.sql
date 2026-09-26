-- BOTAI
-- Migration 0004: Social, Sharing, Challenges
-- Depends on 0001, 0002, 0003
-- DESIGN STATUS: Accepted design draft.
-- Not yet applied to Supabase.

begin;

-- ============================================================
-- Friendship
-- ============================================================

create type public.friendship_status as enum (
    'pending',
    'accepted',
    'declined',
    'cancelled'
);

create table public.friendships (
    id uuid primary key default gen_random_uuid(),

    requester_user_id uuid not null
        references auth.users(id) on delete cascade,

    addressee_user_id uuid not null
        references auth.users(id) on delete cascade,

    status public.friendship_status not null default 'pending',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    responded_at timestamptz,

    constraint friendships_not_self
        check (requester_user_id <> addressee_user_id)
);

create unique index friendships_pair_uidx
on public.friendships (
    least(requester_user_id, addressee_user_id),
    greatest(requester_user_id, addressee_user_id)
);

create index friendships_requester_idx
    on public.friendships(requester_user_id);

create index friendships_addressee_idx
    on public.friendships(addressee_user_id);

create trigger friendships_set_updated_at
before update on public.friendships
for each row execute function public.set_updated_at();


-- ============================================================
-- Shared results
-- ============================================================

-- Nothing is shared automatically.
-- This is an explicit snapshot created by the learner.

create type public.shared_result_scope as enum (
    'friends',
    'challenge'
);

create table public.shared_results (
    id uuid primary key default gen_random_uuid(),

    user_id uuid not null
        references auth.users(id) on delete cascade,

    scope public.shared_result_scope not null,

    quiz_id uuid
        references public.quizzes(id) on delete set null,

    title text not null,

    -- Snapshot rather than a live reference to LearningState.
    questions_answered integer not null default 0,
    correct_answers integer not null default 0,
    score double precision,

    period_started_at timestamptz,
    period_ended_at timestamptz,

    created_at timestamptz not null default now(),
    revoked_at timestamptz,

    constraint shared_results_title_not_blank
        check (btrim(title) <> ''),

    constraint shared_results_counts_valid
        check (
            questions_answered >= 0
            and correct_answers >= 0
            and correct_answers <= questions_answered
        ),

    constraint shared_results_score_valid
        check (
            score is null
            or score between 0.0 and 1.0
        ),

    constraint shared_results_period_valid
        check (
            period_started_at is null
            or period_ended_at is null
            or period_ended_at >= period_started_at
        )
);

create index shared_results_user_idx
    on public.shared_results(user_id, created_at desc);


-- ============================================================
-- Challenges
-- ============================================================

create type public.challenge_status as enum (
    'draft',
    'open',
    'active',
    'completed',
    'cancelled'
);

create type public.challenge_participant_status as enum (
    'invited',
    'accepted',
    'declined',
    'left',
    'completed'
);

create type public.challenge_metric as enum (
    'questions_answered',
    'correct_answers',
    'accuracy'
);

create table public.challenges (
    id uuid primary key default gen_random_uuid(),

    creator_user_id uuid
        references auth.users(id) on delete set null,

    title text not null,
    description text,

    metric public.challenge_metric not null,

    quiz_id uuid
        references public.quizzes(id) on delete set null,

    starts_at timestamptz not null,
    ends_at timestamptz not null,

    status public.challenge_status not null default 'draft',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint challenges_title_not_blank
        check (btrim(title) <> ''),

    constraint challenges_time_valid
        check (ends_at > starts_at)
);

create index challenges_creator_idx
    on public.challenges(creator_user_id);

create index challenges_status_idx
    on public.challenges(status, starts_at);

create trigger challenges_set_updated_at
before update on public.challenges
for each row execute function public.set_updated_at();


create table public.challenge_participants (
    challenge_id uuid not null
        references public.challenges(id) on delete cascade,

    user_id uuid not null
        references auth.users(id) on delete cascade,

    status public.challenge_participant_status not null default 'invited',

    invited_at timestamptz not null default now(),
    responded_at timestamptz,
    completed_at timestamptz,

    primary key (challenge_id, user_id)
);

create index challenge_participants_user_idx
    on public.challenge_participants(user_id);


-- Server-calculated challenge result.
-- Normal clients do not write this table.

create table public.challenge_results (
    challenge_id uuid not null
        references public.challenges(id) on delete cascade,

    user_id uuid not null
        references auth.users(id) on delete cascade,

    questions_answered integer not null default 0,
    correct_answers integer not null default 0,
    score double precision,

    calculated_at timestamptz not null default now(),

    primary key (challenge_id, user_id),

    constraint challenge_results_counts_valid
        check (
            questions_answered >= 0
            and correct_answers >= 0
            and correct_answers <= questions_answered
        ),

    constraint challenge_results_score_valid
        check (
            score is null
            or score between 0.0 and 1.0
        )
);


-- ============================================================
-- Helper: accepted friendship
-- ============================================================

create or replace function public.are_friends(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.friendships f
        where f.status = 'accepted'
          and (
              (f.requester_user_id = a and f.addressee_user_id = b)
              or
              (f.requester_user_id = b and f.addressee_user_id = a)
          )
    )
    and not exists (
        select 1
        from public.user_blocks ub
        where
            (ub.blocker_user_id = a and ub.blocked_user_id = b)
            or
            (ub.blocker_user_id = b and ub.blocked_user_id = a)
    );
$$;


-- ============================================================
-- RLS
-- ============================================================

alter table public.friendships enable row level security;
alter table public.shared_results enable row level security;
alter table public.challenges enable row level security;
alter table public.challenge_participants enable row level security;
alter table public.challenge_results enable row level security;


-- Friendships

create policy "friendship participants read"
on public.friendships
for select
using (
    auth.uid() = requester_user_id
    or auth.uid() = addressee_user_id
);

create policy "friendship requester insert"
on public.friendships
for insert
with check (
    auth.uid() = requester_user_id
    and requester_user_id <> addressee_user_id
    and not exists (
        select 1
        from public.user_blocks ub
        where
            (ub.blocker_user_id = requester_user_id
             and ub.blocked_user_id = addressee_user_id)
            or
            (ub.blocker_user_id = addressee_user_id
             and ub.blocked_user_id = requester_user_id)
    )
);

-- Status transitions should ultimately be performed through
-- trusted RPC/server functions so one participant cannot forge
-- another participant's action.
-- No broad UPDATE policy is intentionally provided here.


-- Shared results

create policy "shared result owner read"
on public.shared_results
for select
using (auth.uid() = user_id);

create policy "shared result owner insert"
on public.shared_results
for insert
with check (auth.uid() = user_id);

create policy "shared result friends read"
on public.shared_results
for select
using (
    scope = 'friends'
    and revoked_at is null
    and public.are_friends(auth.uid(), user_id)
);

create policy "shared result owner revoke"
on public.shared_results
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);


-- Challenges

create policy "challenge creator read"
on public.challenges
for select
using (auth.uid() = creator_user_id);

create policy "challenge participant read"
on public.challenges
for select
using (
    exists (
        select 1
        from public.challenge_participants cp
        where cp.challenge_id = challenges.id
          and cp.user_id = auth.uid()
    )
);

create policy "challenge creator insert"
on public.challenges
for insert
with check (auth.uid() = creator_user_id);

create policy "challenge creator update"
on public.challenges
for update
using (auth.uid() = creator_user_id)
with check (auth.uid() = creator_user_id);


-- Challenge participants

create policy "challenge participants read involved"
on public.challenge_participants
for select
using (
    auth.uid() = user_id
    or exists (
        select 1
        from public.challenges c
        where c.id = challenge_participants.challenge_id
          and c.creator_user_id = auth.uid()
    )
);

-- Participant invitations/status transitions are intentionally
-- left for trusted RPC/server functions.


-- Challenge results

create policy "challenge results participant read"
on public.challenge_results
for select
using (
    exists (
        select 1
        from public.challenge_participants cp
        where cp.challenge_id = challenge_results.challenge_id
          and cp.user_id = auth.uid()
          and cp.status in ('accepted', 'completed')
    )
);

-- No client write policies.
-- Results are calculated from authoritative Attempts.

commit;
