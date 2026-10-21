-- PostgreSQL requires both SELECT privileges and RLS policies.
-- These are content tables used by nested question/quiz visibility checks.
-- RLS stays enabled and restricts which rows authenticated users can see.
begin;
grant select on table
  public.quizzes,
  public.quiz_versions,
  public.quiz_version_items,
  public.questions,
  public.question_versions,
  public.answer_options,
  public.answer_option_versions,
  public.quiz_topic_placements,
  public.topics,
  public.sections,
  public.subjects,
  public.courses
  to authenticated;
commit;
