begin;

-- Administrative audit logs are not writable from browser roles.
revoke all privileges on table public.admin_audit_logs from anon;
revoke insert, update, delete, truncate, references, trigger on table public.admin_audit_logs from authenticated;
grant select on table public.admin_audit_logs to authenticated;

-- Profiles are not anonymously accessible.
revoke all privileges on table public.profiles from anon;

-- Optimize RLS predicates for comments.
drop policy if exists "read visible comments" on public.comments;
create policy "read visible comments" on public.comments for select to anon, authenticated
using ((status = 'visible') or (user_id = (select auth.uid())) or (select public.is_admin()));

drop policy if exists "signed-in create comments" on public.comments;
create policy "signed-in create comments" on public.comments for insert to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "own comments update" on public.comments;
create policy "own comments update" on public.comments for update to authenticated
using ((user_id = (select auth.uid())) or (select public.is_admin()))
with check ((user_id = (select auth.uid())) or (select public.is_admin()));

drop policy if exists "own comments delete" on public.comments;
create policy "own comments delete" on public.comments for delete to authenticated
using ((user_id = (select auth.uid())) or (select public.is_admin()));

-- Purchase records are read-only to clients; a trusted backend owns payment creation
-- and status changes. Do not define policies against crypto columns that do not exist.
drop policy if exists "users read own purchases" on public.digital_purchases;
create policy "users read own purchases" on public.digital_purchases for select to authenticated
using ((user_id = (select auth.uid())) or (select public.is_admin()));

drop policy if exists "users create own pending purchases" on public.digital_purchases;
drop policy if exists "users attach tx hash" on public.digital_purchases;

drop policy if exists "profiles own read" on public.profiles;
create policy "profiles own read" on public.profiles for select to authenticated
using ((id = (select auth.uid())) or (select public.is_admin()));

drop policy if exists "profiles own update" on public.profiles;
drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile" on public.profiles for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

commit;
