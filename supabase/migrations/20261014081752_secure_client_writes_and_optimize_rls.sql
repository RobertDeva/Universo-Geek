-- Harden client-facing writes while provider checkout is not yet available.
-- Existing rows are preserved. Payment order creation stays backend-only.
begin;

-- Profile owners may edit only the public display name; role/email remain trusted.
drop policy if exists "profiles own update" on public.profiles;
drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));
revoke update on public.profiles from authenticated;
grant update (display_name) on public.profiles to authenticated;

-- Membership and digital purchase records must be created by trusted backend code.
revoke insert on public.membership_orders from authenticated;
drop policy if exists "users create pending membership orders" on public.membership_orders;

revoke insert on public.digital_purchases from authenticated;
drop policy if exists "users create own pending purchases" on public.digital_purchases;
revoke update on public.digital_purchases from authenticated;
drop policy if exists "users attach tx hash" on public.digital_purchases;

-- Marketplace participants can change status only, never price, ownership or order details.
revoke update on public.service_orders from authenticated;
grant update (status) on public.service_orders to authenticated;

-- Audit trail is read-only from the browser.
revoke all privileges on public.admin_audit_logs from anon, authenticated;
grant select on public.admin_audit_logs to authenticated;

-- Cache auth predicates in row-level security policies.
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

commit;
