-- Cover the user_id foreign key so user-scoped feedback queries and deletes
-- do not require a sequential scan as the feedback table grows.
create index if not exists site_feedback_user_id_idx
  on public.site_feedback (user_id);
