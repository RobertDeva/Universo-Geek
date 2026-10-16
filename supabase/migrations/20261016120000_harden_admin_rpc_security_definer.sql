-- Keep privileged routines outside the exposed public API schema.
-- Public RPC wrappers run as invoker; authorization and privileged writes stay
-- inside private SECURITY DEFINER routines with a fixed search_path.
begin;

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create or replace function private.admin_set_profile_role(target_user uuid, new_role text)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
set row_security = off
as $$
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  ) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if new_role not in ('user','admin','moderator') then
    raise exception 'Invalid role' using errcode = '22023';
  end if;
  update public.profiles set role = new_role where id = target_user;
  if not found then raise exception 'Profile not found' using errcode = 'P0002'; end if;
end;
$$;
revoke all on function private.admin_set_profile_role(uuid,text) from public, anon;
grant execute on function private.admin_set_profile_role(uuid,text) to authenticated;

create or replace function public.admin_set_profile_role(target_user uuid, new_role text)
returns void
language sql
security invoker
set search_path = pg_catalog, public, private
as $$ select private.admin_set_profile_role($1,$2); $$;
revoke all on function public.admin_set_profile_role(uuid,text) from public, anon;
grant execute on function public.admin_set_profile_role(uuid,text) to authenticated;

create or replace function private.admin_site_feedback_stats()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, auth
set row_security = off
as $$
declare result jsonb;
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  ) then
    raise exception 'admin role required' using errcode = '42501';
  end if;
  select jsonb_build_object(
    'total', count(*)::integer,
    'open', count(*) filter (where status in ('new','reviewing'))::integer,
    'last_30_days', count(*) filter (where created_at >= now() - interval '30 days')::integer,
    'average_rating', round(avg(rating)::numeric, 2)
  ) into result
  from public.site_feedback;
  return result;
end;
$$;
revoke all on function private.admin_site_feedback_stats() from public, anon;
grant execute on function private.admin_site_feedback_stats() to authenticated;

create or replace function public.admin_site_feedback_stats()
returns jsonb
language sql
security invoker
set search_path = pg_catalog, public, private
as $$ select private.admin_site_feedback_stats(); $$;
revoke all on function public.admin_site_feedback_stats() from public, anon;
grant execute on function public.admin_site_feedback_stats() to authenticated;

-- This routine intentionally never deletes an Auth user; that operation requires
-- the trusted Auth Admin API. Keep it private and preserve a non-definer wrapper.
create or replace function private.admin_delete_profile(target_user uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
set row_security = off
as $$
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  ) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if target_user = auth.uid() then
    raise exception 'Cannot delete your own account from this panel' using errcode = '22023';
  end if;
  raise exception 'Account deletion requires the trusted Auth Admin API' using errcode = '0A000';
end;
$$;
revoke all on function private.admin_delete_profile(uuid) from public, anon;
grant execute on function private.admin_delete_profile(uuid) to authenticated;

create or replace function public.admin_delete_profile(target_user uuid)
returns void
language sql
security invoker
set search_path = pg_catalog, public, private
as $$ select private.admin_delete_profile($1); $$;
revoke all on function public.admin_delete_profile(uuid) from public, anon;
grant execute on function public.admin_delete_profile(uuid) to authenticated;

commit;
