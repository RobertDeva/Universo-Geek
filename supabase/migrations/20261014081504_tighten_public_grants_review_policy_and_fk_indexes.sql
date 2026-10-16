-- Tighten exposed-table privileges and index foreign keys that exist in this schema.
-- No rows are deleted or rewritten by this migration.
begin;

revoke truncate, references, trigger on all tables in schema public from anon, authenticated;

create index if not exists idx_admin_audit_logs_actor_id
  on public.admin_audit_logs(actor_id);
create index if not exists idx_comments_user_id
  on public.comments(user_id);
create index if not exists idx_digital_purchases_product_id
  on public.digital_purchases(product_id);
create index if not exists idx_posts_author_id
  on public.posts(author_id);
create index if not exists idx_service_requests_user_id
  on public.service_requests(user_id);

commit;
