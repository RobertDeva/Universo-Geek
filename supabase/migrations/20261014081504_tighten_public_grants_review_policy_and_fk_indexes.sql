-- Tighten exposed-table privileges, fix review ownership validation, and index FK columns.
-- No rows are deleted or rewritten by this migration.

begin;

-- Remove privileges that browser roles never need. TRUNCATE bypasses RLS.
revoke truncate, references, trigger on all tables in schema public from anon, authenticated;

-- Cover foreign keys flagged by Supabase Performance Advisor.
create index if not exists idx_active_memberships_source_order_id
  on public.active_memberships(source_order_id);
create index if not exists idx_admin_audit_logs_actor_id
  on public.admin_audit_logs(actor_id);
create index if not exists idx_blog_posts_author_id
  on public.blog_posts(author_id);
create index if not exists idx_comments_user_id
  on public.comments(user_id);
create index if not exists idx_contact_messages_user_id
  on public.contact_messages(user_id);
create index if not exists idx_digital_purchases_product_id
  on public.digital_purchases(product_id);
create index if not exists idx_platform_settings_updated_by
  on public.platform_settings(updated_by);
create index if not exists idx_posts_author_id
  on public.posts(author_id);
create index if not exists idx_service_requests_user_id
  on public.service_requests(user_id);
create index if not exists idx_service_reviews_buyer_id
  on public.service_reviews(buyer_id);

-- The prior condition compared service_orders.service_id to itself, so it did
-- not ensure that the review's service_id matched the completed order.
drop policy if exists "completed buyers can review" on public.service_reviews;
create policy "completed buyers can review"
  on public.service_reviews
  for insert
  to authenticated
  with check (
    buyer_id = (select auth.uid())
    and exists (
      select 1
      from public.service_orders o
      where o.id = service_reviews.order_id
        and o.buyer_id = (select auth.uid())
        and o.service_id = service_reviews.service_id
        and o.status = 'completed'
    )
  );

commit;