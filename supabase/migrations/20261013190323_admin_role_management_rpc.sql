
create or replace function public.admin_set_profile_role(target_user uuid, new_role text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if new_role not in ('user','admin','moderator') then
    raise exception 'Invalid role' using errcode = '22023';
  end if;
  update public.profiles set role = new_role where id = target_user;
  if not found then raise exception 'Profile not found' using errcode = 'P0002'; end if;
end;
$$;
revoke all on function public.admin_set_profile_role(uuid,text) from public, anon;
grant execute on function public.admin_set_profile_role(uuid,text) to authenticated;

create or replace function public.admin_delete_profile(target_user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if target_user = auth.uid() then
    raise exception 'Cannot delete your own account from this panel' using errcode = '22023';
  end if;
  -- Deleting the auth user must be done through the trusted server/Admin API.
  raise exception 'Account deletion requires the trusted Auth Admin API' using errcode = '0A000';
end;
$$;
revoke all on function public.admin_delete_profile(uuid) from public, anon;
grant execute on function public.admin_delete_profile(uuid) to authenticated;
