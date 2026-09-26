-- BOTAI
-- Migration 0001: Identity + Content
-- PostgreSQL / Supabase
--
-- IMPORTANT:
-- This migration is currently a design artifact.
-- Do not apply to production until the schema has been reviewed.

begin;

create extension if not exists pgcrypto;

-- ============================================================
-- Helpers
-- ============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

-- ============================================================
-- Identity
-- ============================================================

create table public.profiles (
    user_id uuid primary key references auth.users(id) on delete cascade,

    display_name text,
    avatar_path text,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint profiles_display_name_length
        check (
            display_name is null
            or char_length(display_name) between 1 and 80
        )
);

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();


-- ============================================================
-- Catalog
-- ============================================================

create table public.courses (
    id uuid primary key default gen_random_uuid(),

    title text not null,
    description text,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint courses_title_not_blank
        check (btrim(title) <> '')
);

create trigger courses_set_updated_at
before update on public.courses
for each row execute function public.set_updated_at();


create table public.subjects (
    id uuid primary key default gen_random_uuid(),

    course_id uuid references public.courses(id) on delete cascade,

    title text not null,
    description text,
    position integer not null default 0,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint subjects_title_not_blank
        check (btrim(title) <> '')
);

create index subjects_course_id_idx
    on public.subjects(course_id);

create trigger subjects_set_updated_at
before update on public.subjects
for each row execute function public.set_updated_at();


create table public.sections (
    id uuid primary key default gen_random_uuid(),

    subject_id uuid references public.subjects(id) on delete cascade,

    title text not null,
    description text,
    position integer not null default 0,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint sections_title_not_blank
        check (btrim(title) <> '')
);

create index sections_subject_id_idx
    on public.sections(subject_id);

create trigger sections_set_updated_at
before update on public.sections
for each row execute function public.set_updated_at();


create table public.topics (
    id uuid primary key default gen_random_uuid(),

    section_id uuid references public.sections(id) on delete cascade,

    title text not null,
    description text,
    position integer not null default 0,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint topics_title_not_blank
        check (btrim(title) <> '')
);

create index topics_section_id_idx
    on public.topics(section_id);

create trigger topics_set_updated_at
before update on public.topics
for each row execute function public.set_updated_at();


-- ============================================================
-- Quiz identity
-- ============================================================

create table public.quizzes (
    id uuid primary key default gen_random_uuid(),

    creator_user_id uuid references auth.users(id) on delete set null,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    archived_at timestamptz
);

create index quizzes_creator_user_id_idx
    on public.quizzes(creator_user_id);

create trigger quizzes_set_updated_at
before update on public.quizzes
for each row execute function public.set_updated_at();


-- A quiz may appear in more than one place in the catalog.

create table public.quiz_topic_placements (
    quiz_id uuid not null
        references public.quizzes(id) on delete cascade,

    topic_id uuid not null
        references public.topics(id) on delete cascade,

    position integer not null default 0,

    primary key (quiz_id, topic_id)
);

create index quiz_topic_placements_topic_idx
    on public.quiz_topic_placements(topic_id);


-- ============================================================
-- Quiz versions
-- ============================================================

create table public.quiz_versions (
    id uuid primary key default gen_random_uuid(),

    quiz_id uuid not null
        references public.quizzes(id) on delete cascade,

    version_number integer not null,

    title text not null,
    description text,

    created_by uuid references auth.users(id) on delete set null,

    created_at timestamptz not null default now(),

    constraint quiz_versions_version_positive
        check (version_number > 0),

    constraint quiz_versions_title_not_blank
        check (btrim(title) <> ''),

    constraint quiz_versions_unique_version
        unique (quiz_id, version_number)
);

create index quiz_versions_quiz_id_idx
    on public.quiz_versions(quiz_id);


-- ============================================================
-- Questions
-- ============================================================

create type public.question_type as enum (
    'pair',
    'self_check',
    'single_choice',
    'multiple_choice'
);

create table public.questions (
    id uuid primary key default gen_random_uuid(),

    quiz_id uuid not null
        references public.quizzes(id) on delete cascade,

    question_type public.question_type not null,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    archived_at timestamptz
);

create index questions_quiz_id_idx
    on public.questions(quiz_id);

create trigger questions_set_updated_at
before update on public.questions
for each row execute function public.set_updated_at();


-- ============================================================
-- Media
-- ============================================================

create type public.media_type as enum (
    'image'
);

create table public.media (
    id uuid primary key default gen_random_uuid(),

    owner_user_id uuid references auth.users(id) on delete set null,

    media_type public.media_type not null,
    storage_path text not null,

    mime_type text,
    width integer,
    height integer,

    created_at timestamptz not null default now(),

    constraint media_storage_path_not_blank
        check (btrim(storage_path) <> ''),

    constraint media_width_positive
        check (width is null or width > 0),

    constraint media_height_positive
        check (height is null or height > 0)
);

create unique index media_storage_path_uidx
    on public.media(storage_path);


-- ============================================================
-- Question versions
-- ============================================================

create table public.question_versions (
    id uuid primary key default gen_random_uuid(),

    question_id uuid not null
        references public.questions(id) on delete cascade,

    quiz_version_id uuid not null
        references public.quiz_versions(id) on delete cascade,

    version_number integer not null,

    position integer not null default 0,

    -- Prompt
    prompt_text text,
    prompt_latex text,
    prompt_media_id uuid
        references public.media(id) on delete set null,

    -- Answer / second side
    answer_text text,
    answer_latex text,
    answer_media_id uuid
        references public.media(id) on delete set null,

    -- Pair configuration
    allow_a_to_b boolean not null default true,
    allow_b_to_a boolean not null default false,

    created_at timestamptz not null default now(),

    constraint question_versions_version_positive
        check (version_number > 0),

    constraint question_versions_has_prompt
        check (
            prompt_text is not null
            or prompt_latex is not null
            or prompt_media_id is not null
        ),

    constraint question_versions_unique_version
        unique (question_id, version_number),

    constraint question_version_once_per_quiz_version
        unique (quiz_version_id, question_id)
);

create index question_versions_question_idx
    on public.question_versions(question_id);

create index question_versions_quiz_version_idx
    on public.question_versions(quiz_version_id);


-- ============================================================
-- Answer options
-- ============================================================

-- Stable option identity. This allows reordering without changing
-- the identity of the answer option.

create table public.answer_options (
    id uuid primary key default gen_random_uuid(),

    question_id uuid not null
        references public.questions(id) on delete cascade,

    created_at timestamptz not null default now(),

    archived_at timestamptz
);

create index answer_options_question_idx
    on public.answer_options(question_id);


create table public.answer_option_versions (
    id uuid primary key default gen_random_uuid(),

    answer_option_id uuid not null
        references public.answer_options(id) on delete cascade,

    question_version_id uuid not null
        references public.question_versions(id) on delete cascade,

    position integer not null default 0,

    text_content text,
    latex_content text,

    media_id uuid
        references public.media(id) on delete set null,

    is_correct boolean not null default false,

    created_at timestamptz not null default now(),

    constraint answer_option_versions_has_content
        check (
            text_content is not null
            or latex_content is not null
            or media_id is not null
        ),

    constraint answer_option_once_per_question_version
        unique (question_version_id, answer_option_id)
);

create index answer_option_versions_question_version_idx
    on public.answer_option_versions(question_version_id);


-- ============================================================
-- RLS
-- ============================================================

alter table public.profiles enable row level security;
alter table public.courses enable row level security;
alter table public.subjects enable row level security;
alter table public.sections enable row level security;
alter table public.topics enable row level security;
alter table public.quizzes enable row level security;
alter table public.quiz_topic_placements enable row level security;
alter table public.quiz_versions enable row level security;
alter table public.questions enable row level security;
alter table public.question_versions enable row level security;
alter table public.answer_options enable row level security;
alter table public.answer_option_versions enable row level security;
alter table public.media enable row level security;


-- A user may read and update their own profile.

create policy "profile read own"
on public.profiles
for select
using (auth.uid() = user_id);

create policy "profile insert own"
on public.profiles
for insert
with check (auth.uid() = user_id);

create policy "profile update own"
on public.profiles
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);


-- Draft quiz access.
--
-- Public library access is deliberately NOT implemented here.
-- Publication/moderation will introduce the rules that expose
-- accepted versions to other users.

create policy "quiz creator read"
on public.quizzes
for select
using (auth.uid() = creator_user_id);

create policy "quiz creator insert"
on public.quizzes
for insert
with check (auth.uid() = creator_user_id);

create policy "quiz creator update"
on public.quizzes
for update
using (auth.uid() = creator_user_id)
with check (auth.uid() = creator_user_id);


-- Media owner access.

create policy "media owner read"
on public.media
for select
using (auth.uid() = owner_user_id);

create policy "media owner insert"
on public.media
for insert
with check (auth.uid() = owner_user_id);

create policy "media owner update"
on public.media
for update
using (auth.uid() = owner_user_id)
with check (auth.uid() = owner_user_id);


-- IMPORTANT:
-- Child tables intentionally do not yet receive broad client policies.
-- Access paths will be finalized together with Publication and RLS rules
-- rather than accidentally exposing unpublished content.

commit;
