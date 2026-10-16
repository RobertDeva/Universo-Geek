-- Make the intended backend-only access to rate-limit records explicit.
-- submit_site_feedback runs as service_role; browser roles must never read or mutate this table.
begin;
drop policy if exists "rate limit records are backend only" on public.site_feedback_rate_limits;
create policy "rate limit records are backend only"
  on public.site_feedback_rate_limits
  for all
  to anon, authenticated
  using (false)
  with check (false);
revoke all privileges on table public.site_feedback_rate_limits from anon, authenticated;
commit;
