-- Tighten execution rights for trusted trigger/helper routines.
-- The old hosted schema had an optional rls_auto_enable() helper that is not
-- part of the tracked baseline. Keep clean installs replayable by revoking it
-- only when it exists; do not invent a replacement helper in this migration.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.prevent_role_escalation() from public, anon, authenticated;
do $$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    execute 'revoke execute on function public.rls_auto_enable() from public, anon, authenticated';
  end if;
end
$$;

drop function if exists public.admin_delete_profile(uuid);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
