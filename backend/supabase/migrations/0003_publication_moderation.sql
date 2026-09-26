-- BOTAI
-- Migration 0003: Publication, Moderation, Reports, Blocking
-- PostgreSQL / Supabase
--
-- Depends on:
--   0001_identity_content.sql
--   0002_learning.sql
--
-- DESIGN STATUS: Accepted design draft.
-- Not yet applied to Supabase.

begin;

-- ============================================================
-- Server-controlled staff roles
-- ============================================================

create type public.staff_role as enum (
    'moderator',
    'admin'
);

create table public.staff_members (
    user_id uuid primary key
        references auth.users(id) on delete cascade,

    role public.staff_role not null,

    created_at timestamptz not null default now()
);

-- IMPORTANT:
-- No client INSERT/UPDATE/DELETE policies will be created.
-- Membership is controlled only by trusted server/admin logic.

-- ============================================================
-- Publication enums
-- ============================================================

create type public.submission_status as enum (
    'submitted',
    'in_review',
    'approved',
    'rejected',
    'cancelled'
);

create type public.publication_status as enum (
    'published',
    'suspended',
    'withdrawn'
);

create type public.moderation_case_status as enum (
    'open',
    'reviewing',
    'resolved'
);

create type public.moderation_decision as enum (
    'approve',
    'reject',
    'suspend',
    'restore',
    'remove'
);

create type public.report_reason as enum (
    'inappropriate',
    'incorrect',
    'copyright',
    'spam',
    'harassment',
    'other'
);

create type public.report_status as enum (
    'open',
    'reviewing',
    'resolved',
    'dismissed'
);

-- ============================================================
-- Publication submissions
-- ============================================================

create table public.publication_submissions (
    id uuid primary key default gen_random_uuid(),

    quiz_id uuid not null
        references public.quizzes(id) on delete cascade,

    quiz_version_id uuid not null
        references public.quiz_versions(id) on delete restrict,

    submitted_by uuid
        references auth.users(id) on delete set null,

    status public.submission_status not null default 'submitted',

    author_note text,

    submitted_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    reviewed_at timestamptz,

    constraint publication_submission_quiz_version_fk
        foreign key (quiz_id, quiz_version_id)
        references public.quiz_versions(quiz_id, id)
        on delete restrict
);

create index publication_submissions_quiz_idx
    on public.publication_submissions(quiz_id);

create index publication_submissions_status_idx
    on public.publication_submissions(status, submitted_at);

create trigger publication_submissions_set_updated_at
before update on public.publication_submissions
for each row execute function public.set_updated_at();

-- ============================================================
-- Publications
-- ============================================================

create table public.publications (
    id uuid primary key default gen_random_uuid(),

    quiz_id uuid not null
        references public.quizzes(id) on delete cascade,

    quiz_version_id uuid not null
        references public.quiz_versions(id) on delete restrict,

    submission_id uuid
        references public.publication_submissions(id) on delete set null,

    status public.publication_status not null default 'published',

    published_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    suspended_at timestamptz,
    withdrawn_at timestamptz,

    constraint publications_quiz_version_fk
        foreign key (quiz_id, quiz_version_id)
        references public.quiz_versions(quiz_id, id)
        on delete restrict,

    constraint publications_unique_version
        unique (quiz_version_id)
);

create index publications_quiz_idx
    on public.publications(quiz_id);

create index publications_status_idx
    on public.publications(status, published_at desc);

create trigger publications_set_updated_at
before update on public.publications
for each row execute function public.set_updated_at();

-- ============================================================
-- Moderation cases
-- ============================================================

create table public.moderation_cases (
    id uuid primary key default gen_random_uuid(),

    submission_id uuid
        references public.publication_submissions(id) on delete set null,

    publication_id uuid
        references public.publications(id) on delete set null,

    status public.moderation_case_status not null default 'open',

    assigned_to uuid
        references public.staff_members(user_id) on delete set null,

    decision public.moderation_decision,
    internal_note text,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    resolved_at timestamptz,

    constraint moderation_case_has_target
        check (
            submission_id is not null
            or publication_id is not null
        )
);

create index moderation_cases_status_idx
    on public.moderation_cases(status, created_at);

create index moderation_cases_submission_idx
    on public.moderation_cases(submission_id);

create index moderation_cases_publication_idx
    on public.moderation_cases(publication_id);

create trigger moderation_cases_set_updated_at
before update on public.moderation_cases
for each row execute function public.set_updated_at();

-- ============================================================
-- Reports
-- ============================================================

create table public.reports (
    id uuid primary key default gen_random_uuid(),

    reporter_user_id uuid
        references auth.users(id) on delete set null,

    publication_id uuid not null
        references public.publications(id) on delete cascade,

    reason public.report_reason not null,
    details text,

    status public.report_status not null default 'open',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    resolved_at timestamptz,

    resolved_by uuid
        references public.staff_members(user_id) on delete set null,

    resolution_note text
);

create index reports_status_idx
    on public.reports(status, created_at);

create index reports_publication_idx
    on public.reports(publication_id);

create index reports_reporter_idx
    on public.reports(reporter_user_id);

create trigger reports_set_updated_at
before update on public.reports
for each row execute function public.set_updated_at();

-- ============================================================
-- User blocking
-- ============================================================

create table public.user_blocks (
    blocker_user_id uuid not null
        references auth.users(id) on delete cascade,

    blocked_user_id uuid not null
        references auth.users(id) on delete cascade,

    created_at timestamptz not null default now(),

    primary key (blocker_user_id, blocked_user_id),

    constraint user_blocks_not_self
        check (blocker_user_id <> blocked_user_id)
);

create index user_blocks_blocked_idx
    on public.user_blocks(blocked_user_id);

-- ============================================================
-- Account deletion requests
-- ============================================================

create type public.account_deletion_status as enum (
    'requested',
    'processing',
    'completed',
    'failed',
    'cancelled'
);

create table public.account_deletion_requests (
    id uuid primary key default gen_random_uuid(),

    user_id uuid not null
        references auth.users(id) on delete cascade,

    status public.account_deletion_status not null default 'requested',

    requested_at timestamptz not null default now(),
    processing_started_at timestamptz,
    completed_at timestamptz,

    last_error text,

    constraint account_deletion_one_active_request
        unique (user_id)
);

-- ============================================================
-- Staff helper
-- ============================================================

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.staff_members sm
        where sm.user_id = auth.uid()
    );
$$;

-- ============================================================
-- RLS
-- ============================================================

alter table public.staff_members enable row level security;
alter table public.publication_submissions enable row level security;
alter table public.publications enable row level security;
alter table public.moderation_cases enable row level security;
alter table public.reports enable row level security;
alter table public.user_blocks enable row level security;
alter table public.account_deletion_requests enable row level security;

-- ------------------------------------------------------------
-- Staff members
-- ------------------------------------------------------------

create policy "staff may read staff membership"
on public.staff_members
for select
using (public.is_staff());

-- No client write policies.

-- ------------------------------------------------------------
-- Submission ownership
-- ------------------------------------------------------------

create policy "submission author read"
on public.publication_submissions
for select
using (
    submitted_by = auth.uid()
    or public.is_staff()
);

create policy "submission collaborator insert"
on public.publication_submissions
for insert
with check (
    submitted_by = auth.uid()
    and exists (
        select 1
        from public.quiz_collaborators qc
        where qc.quiz_id = publication_submissions.quiz_id
          and qc.user_id = auth.uid()
          and qc.role in ('owner', 'editor')
    )
);

-- Clients deliberately cannot approve/reject submissions.
-- Status transitions are trusted server/moderator operations.

-- ------------------------------------------------------------
-- Public publications
-- ------------------------------------------------------------

create policy "published content readable"
on public.publications
for select
using (
    status = 'published'
    or public.is_staff()
);

-- No normal client INSERT/UPDATE/DELETE policies.
-- Publication state is controlled by trusted server logic.

-- ------------------------------------------------------------
-- Moderation cases
-- ------------------------------------------------------------

create policy "staff moderation read"
on public.moderation_cases
for select
using (public.is_staff());

-- No normal client write policies.

-- ------------------------------------------------------------
-- Reports
-- ------------------------------------------------------------

create policy "reporter read own reports"
on public.reports
for select
using (
    reporter_user_id = auth.uid()
    or public.is_staff()
);

create policy "authenticated user create report"
on public.reports
for insert
with check (
    reporter_user_id = auth.uid()
);

-- Resolution is server/moderator controlled.

-- ------------------------------------------------------------
-- User blocks
-- ------------------------------------------------------------

create policy "user blocks read own"
on public.user_blocks
for select
using (blocker_user_id = auth.uid());

create policy "user blocks create own"
on public.user_blocks
for insert
with check (
    blocker_user_id = auth.uid()
    and blocked_user_id <> auth.uid()
);

create policy "user blocks delete own"
on public.user_blocks
for delete
using (blocker_user_id = auth.uid());

-- ------------------------------------------------------------
-- Account deletion requests
-- ------------------------------------------------------------

create policy "account deletion read own"
on public.account_deletion_requests
for select
using (user_id = auth.uid());

create policy "account deletion request own"
on public.account_deletion_requests
for insert
with check (
    user_id = auth.uid()
    and status = 'requested'
);

-- Processing/completion is trusted server-side work.

commit;
