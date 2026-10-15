begin;
create table if not exists public.geekpoints_accounts (
 user_id uuid primary key references auth.users(id) on delete cascade,
 balance bigint not null default 0 check (balance >= 0),
 lifetime_earned bigint not null default 0 check (lifetime_earned >= 0),
 lifetime_spent bigint not null default 0 check (lifetime_spent >= 0),
 frozen_at timestamptz, freeze_reason text, created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.geekpoints_ledger (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete restrict,
 delta bigint not null check (delta <> 0),
 event_type text not null check (event_type in ('earn','spend','refund','reversal','admin_adjustment')),
 event_key text not null unique, description text not null default '',
 actor_id uuid references auth.users(id) on delete set null,
 metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create index if not exists geekpoints_ledger_user_created_idx on public.geekpoints_ledger(user_id, created_at desc);
create table if not exists public.geekpoints_rules (
 rule_key text primary key, points bigint not null check (points >= 0),
 enabled boolean not null default false, config jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now()
);
create table if not exists public.geekpoints_redemptions (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete restrict,
 plan_code text not null check (plan_code ~ '^[a-z][a-z0-9_]{1,39}$'),
 points_cost bigint not null check (points_cost > 0),
 status text not null default 'pending' check (status in ('pending','approved','fulfilled','rejected','cancelled')),
 request_key text not null unique, period_started_at timestamptz not null default now(),
 period_ends_at timestamptz not null default (now() + interval '24 months'),
 reviewed_by uuid references auth.users(id) on delete set null, reviewed_at timestamptz,
 review_note text, fulfilled_at timestamptz, created_at timestamptz not null default now(),
 constraint geekpoints_redemption_period_valid check (period_ends_at > period_started_at)
);
create index if not exists geekpoints_redemptions_user_plan_period_idx
 on public.geekpoints_redemptions(user_id, plan_code, created_at desc)
 where status in ('pending','approved','fulfilled');
create table if not exists public.geekpoints_plan_limits (
 plan_code text primary key check (plan_code ~ '^[a-z][a-z0-9_]{1,39}$'),
 max_redemptions_24m integer not null check (max_redemptions_24m >= 0),
 points_cost bigint not null check (points_cost > 0), enabled boolean not null default false,
 notes text not null default '', updated_at timestamptz not null default now()
);
create table if not exists public.geekpoints_audit_log (
 id bigint generated always as identity primary key,
 actor_id uuid references auth.users(id) on delete set null,
 target_user_id uuid references auth.users(id) on delete set null,
 action text not null, target_type text not null, target_id text,
 details jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
alter table public.geekpoints_accounts enable row level security;
alter table public.geekpoints_ledger enable row level security;
alter table public.geekpoints_rules enable row level security;
alter table public.geekpoints_redemptions enable row level security;
alter table public.geekpoints_plan_limits enable row level security;
alter table public.geekpoints_audit_log enable row level security;
revoke all on public.geekpoints_accounts, public.geekpoints_ledger, public.geekpoints_rules,
 public.geekpoints_redemptions, public.geekpoints_plan_limits, public.geekpoints_audit_log from anon, authenticated;
grant select on public.geekpoints_accounts, public.geekpoints_ledger, public.geekpoints_redemptions to authenticated;
drop policy if exists "read own GeekPoints account" on public.geekpoints_accounts;
create policy "read own GeekPoints account" on public.geekpoints_accounts for select to authenticated
 using (user_id = (select auth.uid()) or exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin'));
drop policy if exists "read own GeekPoints ledger" on public.geekpoints_ledger;
create policy "read own GeekPoints ledger" on public.geekpoints_ledger for select to authenticated
 using (user_id = (select auth.uid()) or exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin'));
drop policy if exists "read own GeekPoints redemptions" on public.geekpoints_redemptions;
create policy "read own GeekPoints redemptions" on public.geekpoints_redemptions for select to authenticated
 using (user_id = (select auth.uid()) or exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin'));
insert into public.geekpoints_plan_limits(plan_code,max_redemptions_24m,points_cost,enabled,notes) values
 ('geek',2,1000,false,'Pilot proposal; disabled pending margin review'),
 ('pro',1,2500,false,'Pilot proposal; disabled pending margin review'),
 ('creator',0,5000,false,'Not redeemable; creator access requires application/approval')
on conflict (plan_code) do nothing;
insert into public.geekpoints_rules(rule_key,points,enabled,config) values
 ('verified_referral',50,false,'{"monthly_cap":10,"requires_verified_signup":true}'),
 ('referral_first_valid_contribution',25,false,'{"requires_approved_original_content":true}'),
 ('approved_original_post',20,false,'{"one_reward_per_post":true}'),
 ('valid_views_per_10',1,false,'{"dedupe":true,"per_post_30d_cap":500,"per_author_30d_cap":1500}'),
 ('featured_participation',5,false,'{"manual_review":true,"max_per_award":5}')
on conflict (rule_key) do nothing;
create or replace function public.geekpoints_request_redemption(p_plan_code text,p_request_key text)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare
 v_user uuid := auth.uid(); v_plan public.geekpoints_plan_limits%rowtype;
 v_account public.geekpoints_accounts%rowtype; v_used integer; v_id uuid; v_existing public.geekpoints_redemptions%rowtype;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 if p_request_key is null or length(p_request_key)<16 or length(p_request_key)>120 then
  raise exception 'Invalid request key' using errcode='22023';
 end if;
 select * into v_existing from public.geekpoints_redemptions where request_key=p_request_key;
 if found then
  if v_existing.user_id <> v_user or v_existing.plan_code <> p_plan_code then raise exception 'Request key already used' using errcode='23505'; end if;
  return v_existing.id;
 end if;
 select * into v_plan from public.geekpoints_plan_limits where plan_code=p_plan_code and enabled=true for share;
 if not found then raise exception 'Redemption is not available for this plan' using errcode='22023'; end if;
 insert into public.geekpoints_accounts(user_id) values(v_user) on conflict(user_id) do nothing;
 select * into v_account from public.geekpoints_accounts where user_id=v_user for update;
 if v_account.frozen_at is not null then raise exception 'GeekPoints account is frozen' using errcode='42501'; end if;
 if v_account.balance<v_plan.points_cost then raise exception 'Insufficient GeekPoints' using errcode='22023'; end if;
 select count(*) into v_used from public.geekpoints_redemptions
  where user_id=v_user and plan_code=p_plan_code and created_at>=now()-interval '24 months'
   and status in ('pending','approved','fulfilled');
 if v_used>=v_plan.max_redemptions_24m then raise exception '24-month redemption limit reached for this plan' using errcode='22023'; end if;
 insert into public.geekpoints_redemptions(user_id,plan_code,points_cost,request_key)
 values(v_user,p_plan_code,v_plan.points_cost,p_request_key) returning id into v_id;
 update public.geekpoints_accounts set balance=balance-v_plan.points_cost,
  lifetime_spent=lifetime_spent+v_plan.points_cost,updated_at=now() where user_id=v_user;
 insert into public.geekpoints_ledger(user_id,delta,event_type,event_key,description,metadata)
 values(v_user,-v_plan.points_cost,'spend','redemption:'||v_id::text,
  'GeekPoints reserved for membership redemption request',jsonb_build_object('redemption_id',v_id,'plan_code',p_plan_code));
 insert into public.geekpoints_audit_log(actor_id,target_user_id,action,target_type,target_id,details)
 values(v_user,v_user,'redemption_requested','geekpoints_redemption',v_id::text,
  jsonb_build_object('plan_code',p_plan_code,'points_cost',v_plan.points_cost));
 return v_id;
end; $$;
revoke all on function public.geekpoints_request_redemption(text,text) from public, anon;
grant execute on function public.geekpoints_request_redemption(text,text) to authenticated;
commit;
