-- Separate administrator privileges from moderator privileges.
-- Moderators can review user-generated content via narrow RPCs; they cannot
-- promote users, edit payment records, or change platform settings.

begin;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path to 'public'
set row_security to 'off'
as $function$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  );
$function$;

create or replace function private.is_moderator_or_admin()
returns boolean
language sql
stable
security definer
set search_path to 'public'
set row_security to 'off'
as $function$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('admin','moderator')
  );
$function$;
revoke all on function private.is_moderator_or_admin() from public;
grant execute on function private.is_moderator_or_admin() to anon, authenticated;

create or replace function public.is_admin()
returns boolean
language sql
stable
set search_path to 'public'
as $function$ select private.is_admin(); $function$;

-- Privileged role changes are now admin-only because private.is_admin() is strict.
-- Keep moderator access to community comments and posts without exposing account roles.
drop policy if exists "read visible comments" on public.comments;
create policy "read visible comments" on public.comments for select to anon, authenticated
  using ((status = 'visible') or (user_id = (select auth.uid())) or (select private.is_moderator_or_admin()));

drop policy if exists "own comments update" on public.comments;
create policy "own comments update" on public.comments for update to authenticated
  using ((user_id = (select auth.uid())) or (select private.is_moderator_or_admin()))
  with check ((user_id = (select auth.uid())) or (select private.is_moderator_or_admin()));

drop policy if exists "own comments delete" on public.comments;
create policy "own comments delete" on public.comments for delete to authenticated
  using ((user_id = (select auth.uid())) or (select private.is_moderator_or_admin()));

drop policy if exists "admins manage posts" on public.posts;
create policy "moderators manage community posts" on public.posts for all to authenticated
  using ((select private.is_moderator_or_admin()))
  with check ((select private.is_moderator_or_admin()));

-- Keep direct, broad management of ads/services admin-only.
drop policy if exists "admins moderate affiliate ads" on public.affiliate_ads;
create policy "admins moderate affiliate ads" on public.affiliate_ads for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

drop policy if exists "admins moderate services" on public.marketplace_services;
create policy "admins moderate services" on public.marketplace_services for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

-- Moderators can inspect all submissions but must use the narrow RPCs below
-- to approve/reject/pause them; they cannot directly rewrite price or ownership.
drop policy if exists "moderators read affiliate ads for moderation" on public.affiliate_ads;
create policy "moderators read affiliate ads for moderation" on public.affiliate_ads
  for select to authenticated using ((select private.is_moderator_or_admin()));

drop policy if exists "moderators read services for moderation" on public.marketplace_services;
create policy "moderators read services for moderation" on public.marketplace_services
  for select to authenticated using ((select private.is_moderator_or_admin()));

create or replace function private.moderate_marketplace_service(
  target_service uuid, new_status text, note text default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not private.is_moderator_or_admin() then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if new_status not in ('approved','rejected','paused') then
    raise exception 'Invalid moderation status' using errcode = '22023';
  end if;

  update public.marketplace_services
     set status = new_status,
         moderation_note = nullif(left(trim(coalesce(note,'')),500),''),
         reviewed_by = auth.uid(),
         reviewed_at = now(),
         updated_at = now()
   where id = target_service;
  if not found then raise exception 'Service not found' using errcode = 'P0002'; end if;

  insert into public.admin_audit_logs(actor_id, action, target_table, target_id, details)
  values (auth.uid(), 'moderate_service', 'marketplace_services', target_service::text,
          jsonb_build_object('status',new_status,'note',left(coalesce(note,''),500)));
end;
$function$;

create or replace function private.moderate_affiliate_ad(
  target_ad uuid, new_status text, note text default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not private.is_moderator_or_admin() then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if new_status not in ('approved','rejected','paused') then
    raise exception 'Invalid moderation status' using errcode = '22023';
  end if;

  update public.affiliate_ads
     set status = new_status,
         moderation_note = nullif(left(trim(coalesce(note,'')),500),''),
         reviewed_by = auth.uid(),
         reviewed_at = now(),
         updated_at = now()
   where id = target_ad;
  if not found then raise exception 'Affiliate ad not found' using errcode = 'P0002'; end if;

  insert into public.admin_audit_logs(actor_id, action, target_table, target_id, details)
  values (auth.uid(), 'moderate_affiliate_ad', 'affiliate_ads', target_ad::text,
          jsonb_build_object('status',new_status,'note',left(coalesce(note,''),500)));
end;
$function$;

revoke all on function private.moderate_marketplace_service(uuid,text,text) from public;
revoke all on function private.moderate_affiliate_ad(uuid,text,text) from public;
grant execute on function private.moderate_marketplace_service(uuid,text,text) to authenticated;
grant execute on function private.moderate_affiliate_ad(uuid,text,text) to authenticated;

create or replace function public.moderate_marketplace_service(
  target_service uuid, new_status text, note text default null
)
returns void language sql set search_path to 'public'
as $function$ select private.moderate_marketplace_service($1,$2,$3); $function$;

create or replace function public.moderate_affiliate_ad(
  target_ad uuid, new_status text, note text default null
)
returns void language sql set search_path to 'public'
as $function$ select private.moderate_affiliate_ad($1,$2,$3); $function$;

revoke all on function public.moderate_marketplace_service(uuid,text,text) from public, anon;
revoke all on function public.moderate_affiliate_ad(uuid,text,text) from public, anon;
grant execute on function public.moderate_marketplace_service(uuid,text,text) to authenticated;
grant execute on function public.moderate_affiliate_ad(uuid,text,text) to authenticated;

commit;