
create table if not exists public.role_memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  source_role text not null check (source_role in ('admin','moderator')),
  plan_code text not null check (plan_code in ('creator','otaku_pro')),
  active boolean not null default true,
  activated_at timestamptz not null default now(),
  deactivated_at timestamptz,
  created_at timestamptz not null default now(),
  constraint role_memberships_role_plan_match check (
    (source_role = 'admin' and plan_code = 'creator')
    or (source_role = 'moderator' and plan_code = 'otaku_pro')
  ),
  constraint role_memberships_deactivation_match check (
    (active and deactivated_at is null) or (not active and deactivated_at is not null)
  )
);

create unique index if not exists role_memberships_one_active_per_user
  on public.role_memberships(user_id) where active;
create index if not exists role_memberships_user_history
  on public.role_memberships(user_id, created_at desc);

alter table public.role_memberships enable row level security;
revoke all on table public.role_memberships from anon, authenticated;
grant select on table public.role_memberships to authenticated;

drop policy if exists "users read own role memberships" on public.role_memberships;
create policy "users read own role memberships" on public.role_memberships
  for select to authenticated
  using (user_id = (select auth.uid()) or (select public.is_admin()));

create or replace function public.sync_role_membership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  mapped_plan text;
begin
  if TG_OP = 'UPDATE' and NEW.role is not distinct from OLD.role then
    return NEW;
  end if;

  -- Retain history, but immediately deactivate the entitlement from the old role.
  update public.role_memberships
     set active = false, deactivated_at = now()
   where user_id = NEW.id and active;

  mapped_plan := case NEW.role
    when 'admin' then 'creator'
    when 'moderator' then 'otaku_pro'
    else null
  end;

  if mapped_plan is not null then
    insert into public.role_memberships(user_id, source_role, plan_code, active)
    values (NEW.id, NEW.role, mapped_plan, true);
  end if;

  return NEW;
end;
$$;

drop trigger if exists profiles_sync_role_membership on public.profiles;
create trigger profiles_sync_role_membership
after insert or update of role on public.profiles
for each row execute function public.sync_role_membership();

revoke execute on function public.sync_role_membership() from public, anon, authenticated;

-- Backfill current elevated roles, including the existing site administrator.
insert into public.role_memberships(user_id, source_role, plan_code, active)
select p.id, p.role,
       case p.role when 'admin' then 'creator' when 'moderator' then 'otaku_pro' end,
       true
from public.profiles p
where p.role in ('admin','moderator')
  and not exists (
    select 1 from public.role_memberships rm
    where rm.user_id = p.id and rm.active
  );
