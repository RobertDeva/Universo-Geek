begin;
grant update (status) on public.site_feedback to authenticated;
drop policy if exists "admins update site feedback status" on public.site_feedback;
create policy "admins update site feedback status"
  on public.site_feedback
  for update
  to authenticated
  using (private.is_admin())
  with check (private.is_admin());
commit;
