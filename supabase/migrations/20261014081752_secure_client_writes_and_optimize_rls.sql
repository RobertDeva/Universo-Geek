-- Harden client-facing writes while provider checkout is not yet available.
-- Existing rows are preserved. Order creation becomes backend-only so clients
-- cannot invent prices, provider invoice references, or payment metadata.

begin;

-- Profile owners may edit only public profile fields; role/email remain trusted.
drop policy if exists "profiles own update" on public.profiles;
drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));
revoke update on public.profiles from authenticated;
grant update (display_name, avatar_url) on public.profiles to authenticated;

-- Membership orders must be created by a trusted backend with server-side prices.
revoke insert on public.membership_orders from authenticated;
drop policy if exists "users create pending membership orders" on public.membership_orders;

-- Digital purchases also need a trusted order-creation path so client input cannot
-- choose purchase price, provider metadata, payment status, or delivery state.
revoke insert on public.digital_purchases from authenticated;
drop policy if exists "users create own pending purchases" on public.digital_purchases;
revoke update on public.digital_purchases from authenticated;
grant update (tx_hash) on public.digital_purchases to authenticated;

-- Marketplace buyers/sellers may advance workflow status, but cannot edit order
-- ownership, seller, service, agreed price, currency, or brief after creation.
revoke update on public.service_orders from authenticated;
grant update (status) on public.service_orders to authenticated;

-- Audit trail is read-only from the browser. Trusted functions/triggers write it.
revoke all privileges on public.admin_audit_logs from anon, authenticated;
grant select on public.admin_audit_logs to authenticated;

-- Auth helper calls are wrapped in scalar subqueries for policy initplan caching.
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