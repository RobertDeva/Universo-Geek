-- Applied to Supabase project khadcbgzziuwaxwptftw on 2026-10-14.
-- Harden client-facing writes while provider checkout is unavailable.
-- Existing rows are preserved.

begin;

drop policy if exists "profiles own update" on public.profiles;
drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));
revoke update on public.profiles from authenticated;
grant update (display_name, avatar_url) on public.profiles to authenticated;

revoke insert on public.membership_orders from authenticated;
drop policy if exists "users create pending membership orders" on public.membership_orders;

revoke insert on public.digital_purchases from authenticated;
drop policy if exists "users create own pending purchases" on public.digital_purchases;
revoke update on public.digital_purchases from authenticated;
grant update (tx_hash) on public.digital_purchases to authenticated;

revoke update on public.service_orders from authenticated;
grant update (status) on public.service_orders to authenticated;

revoke all privileges on public.admin_audit_logs from anon, authenticated;
grant select on public.admin_audit_logs to authenticated;

drop policy if exists "profiles own read" on public.profiles;
create policy "profiles own read" on public.profiles for select to authenticated
  using ((id = (select auth.uid())) or (select is_admin()));

drop policy if exists "read visible comments" on public.comments;
create policy "read visible comments" on public.comments for select to public
  using ((status = 'visible') or (user_id = (select auth.uid())) or (select is_admin()));

drop policy if exists "signed-in create comments" on public.comments;
create policy "signed-in create comments" on public.comments for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists "own comments update" on public.comments;
create policy "own comments update" on public.comments for update to authenticated
  using ((user_id = (select auth.uid())) or (select is_admin()))
  with check ((user_id = (select auth.uid())) or (select is_admin()));

drop policy if exists "own comments delete" on public.comments;
create policy "own comments delete" on public.comments for delete to authenticated
  using ((user_id = (select auth.uid())) or (select is_admin()));

drop policy if exists "users read own purchases" on public.digital_purchases;
create policy "users read own purchases" on public.digital_purchases for select to authenticated
  using ((user_id = (select auth.uid())) or (select is_admin()));

drop policy if exists "users attach tx hash" on public.digital_purchases;
create policy "users attach tx hash" on public.digital_purchases for update to authenticated
  using ((user_id = (select auth.uid())) and (status = 'pending'))
  with check ((user_id = (select auth.uid())) and (status = 'pending'));

commit;
