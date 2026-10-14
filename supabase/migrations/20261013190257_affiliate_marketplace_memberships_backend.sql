
-- Universo Geek: backend additions for affiliate ads, creator services, orders and memberships.
create extension if not exists pgcrypto;

create table if not exists public.affiliate_ads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 90),
  description text not null check (char_length(description) between 5 and 400),
  destination_url text not null check (destination_url ~ '^https://'),
  cta text not null default 'Ver oferta' check (char_length(cta) between 2 and 30),
  status text not null default 'pending' check (status in ('pending','approved','rejected','paused')),
  moderation_note text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.marketplace_services (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 100),
  description text not null check (char_length(description) between 10 and 2000),
  category text not null default 'Creatividad' check (char_length(category) between 2 and 60),
  price_amount numeric(12,2) not null check (price_amount >= 0),
  currency text not null default 'USD' check (currency ~ '^[A-Z]{3}$'),
  crypto_network text check (crypto_network is null or crypto_network in ('BTC','ETH','SOL','BNB')),
  status text not null default 'pending' check (status in ('pending','approved','rejected','paused')),
  moderation_note text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.service_orders (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.marketplace_services(id) on delete restrict,
  buyer_id uuid not null references auth.users(id) on delete restrict,
  seller_id uuid not null references auth.users(id) on delete restrict,
  brief text not null check (char_length(brief) between 10 and 3000),
  agreed_amount numeric(12,2) not null check (agreed_amount >= 0),
  currency text not null default 'USD' check (currency ~ '^[A-Z]{3}$'),
  status text not null default 'requested' check (status in ('requested','accepted','in_progress','delivered','completed','cancelled','disputed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (buyer_id <> seller_id)
);

create table if not exists public.membership_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_code text not null check (plan_code in ('geek','pro','creator')),
  amount_usd numeric(12,2) not null check (amount_usd > 0),
  crypto_network text not null check (crypto_network in ('BTC','ETH','SOL','BNB')),
  status text not null default 'pending' check (status in ('pending','awaiting_review','paid','expired','cancelled','failed')),
  payment_reference text not null unique default ('UG-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,12))),
  tx_hash text,
  payment_address text,
  crypto_amount numeric(30,12),
  expires_at timestamptz not null default (now() + interval '30 minutes'),
  paid_at timestamptz,
  reviewed_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.affiliate_ad_clicks (
  id bigint generated always as identity primary key,
  ad_id uuid not null references public.affiliate_ads(id) on delete cascade,
  source_page text check (source_page is null or char_length(source_page) <= 120),
  created_at timestamptz not null default now()
);

create index if not exists affiliate_ads_status_created_idx on public.affiliate_ads(status, created_at desc);
create index if not exists affiliate_ads_user_idx on public.affiliate_ads(user_id, created_at desc);
create index if not exists marketplace_services_status_created_idx on public.marketplace_services(status, created_at desc);
create index if not exists marketplace_services_user_idx on public.marketplace_services(user_id, created_at desc);
create index if not exists service_orders_buyer_idx on public.service_orders(buyer_id, created_at desc);
create index if not exists service_orders_seller_idx on public.service_orders(seller_id, created_at desc);
create index if not exists membership_orders_user_idx on public.membership_orders(user_id, created_at desc);
create index if not exists affiliate_ad_clicks_ad_idx on public.affiliate_ad_clicks(ad_id, created_at desc);

create or replace function public.ug_touch_updated_at()
returns trigger language plpgsql set search_path = public
as $$ begin new.updated_at = now(); return new; end; $$;

drop trigger if exists affiliate_ads_touch_updated_at on public.affiliate_ads;
create trigger affiliate_ads_touch_updated_at before update on public.affiliate_ads for each row execute function public.ug_touch_updated_at();
drop trigger if exists marketplace_services_touch_updated_at on public.marketplace_services;
create trigger marketplace_services_touch_updated_at before update on public.marketplace_services for each row execute function public.ug_touch_updated_at();
drop trigger if exists service_orders_touch_updated_at on public.service_orders;
create trigger service_orders_touch_updated_at before update on public.service_orders for each row execute function public.ug_touch_updated_at();

alter table public.affiliate_ads enable row level security;
alter table public.marketplace_services enable row level security;
alter table public.service_orders enable row level security;
alter table public.membership_orders enable row level security;
alter table public.affiliate_ad_clicks enable row level security;

drop policy if exists "public read approved affiliate ads" on public.affiliate_ads;
create policy "public read approved affiliate ads" on public.affiliate_ads for select to anon, authenticated using (status = 'approved' or user_id = (select auth.uid()) or (select public.is_admin()));
drop policy if exists "users submit own affiliate ads" on public.affiliate_ads;
create policy "users submit own affiliate ads" on public.affiliate_ads for insert to authenticated with check (user_id = (select auth.uid()) and status = 'pending' and reviewed_by is null and reviewed_at is null);
drop policy if exists "owners edit pending affiliate ads" on public.affiliate_ads;
create policy "owners edit pending affiliate ads" on public.affiliate_ads for update to authenticated using (user_id = (select auth.uid()) and status = 'pending') with check (user_id = (select auth.uid()) and status = 'pending' and reviewed_by is null and reviewed_at is null);
drop policy if exists "admins moderate affiliate ads" on public.affiliate_ads;
create policy "admins moderate affiliate ads" on public.affiliate_ads for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
drop policy if exists "owners delete pending affiliate ads" on public.affiliate_ads;
create policy "owners delete pending affiliate ads" on public.affiliate_ads for delete to authenticated using (user_id = (select auth.uid()) and status = 'pending');

drop policy if exists "public read approved services" on public.marketplace_services;
create policy "public read approved services" on public.marketplace_services for select to anon, authenticated using (status = 'approved' or user_id = (select auth.uid()) or (select public.is_admin()));
drop policy if exists "users submit own services" on public.marketplace_services;
create policy "users submit own services" on public.marketplace_services for insert to authenticated with check (user_id = (select auth.uid()) and status = 'pending' and reviewed_by is null and reviewed_at is null);
drop policy if exists "owners edit pending services" on public.marketplace_services;
create policy "owners edit pending services" on public.marketplace_services for update to authenticated using (user_id = (select auth.uid()) and status = 'pending') with check (user_id = (select auth.uid()) and status = 'pending' and reviewed_by is null and reviewed_at is null);
drop policy if exists "admins moderate services" on public.marketplace_services;
create policy "admins moderate services" on public.marketplace_services for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
drop policy if exists "owners delete pending services" on public.marketplace_services;
create policy "owners delete pending services" on public.marketplace_services for delete to authenticated using (user_id = (select auth.uid()) and status = 'pending');

drop policy if exists "buyers and sellers read own orders" on public.service_orders;
create policy "buyers and sellers read own orders" on public.service_orders for select to authenticated using (buyer_id = (select auth.uid()) or seller_id = (select auth.uid()) or (select public.is_admin()));
drop policy if exists "buyers create orders for approved services" on public.service_orders;
create policy "buyers create orders for approved services" on public.service_orders for insert to authenticated with check (
  buyer_id = (select auth.uid())
  and status = 'requested'
  and exists (select 1 from public.marketplace_services s where s.id = service_id and s.status = 'approved' and s.user_id = seller_id and s.user_id <> (select auth.uid()))
);
drop policy if exists "admins manage service orders" on public.service_orders;
create policy "admins manage service orders" on public.service_orders for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
drop policy if exists "seller updates order workflow" on public.service_orders;
create policy "seller updates order workflow" on public.service_orders for update to authenticated using (seller_id = (select auth.uid())) with check (seller_id = (select auth.uid()) and status in ('accepted','in_progress','delivered','cancelled','disputed'));

drop policy if exists "users read own membership orders" on public.membership_orders;
create policy "users read own membership orders" on public.membership_orders for select to authenticated using (user_id = (select auth.uid()) or (select public.is_admin()));
drop policy if exists "users create pending membership orders" on public.membership_orders;
create policy "users create pending membership orders" on public.membership_orders for insert to authenticated with check (user_id = (select auth.uid()) and status = 'pending' and reviewed_by is null and paid_at is null);
drop policy if exists "admins manage membership orders" on public.membership_orders;
create policy "admins manage membership orders" on public.membership_orders for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
drop policy if exists "users submit tx hash for own pending order" on public.membership_orders;
create policy "users submit tx hash for own pending order" on public.membership_orders for update to authenticated using (user_id = (select auth.uid()) and status = 'pending') with check (user_id = (select auth.uid()) and status in ('pending','awaiting_review') and reviewed_by is null and paid_at is null);

drop policy if exists "public record clicks on approved ads" on public.affiliate_ad_clicks;
create policy "public record clicks on approved ads" on public.affiliate_ad_clicks for insert to anon, authenticated with check (exists (select 1 from public.affiliate_ads a where a.id = ad_id and a.status = 'approved'));
drop policy if exists "admins read affiliate ad clicks" on public.affiliate_ad_clicks;
create policy "admins read affiliate ad clicks" on public.affiliate_ad_clicks for select to authenticated using ((select public.is_admin()));

-- Stop users changing their own role through the exposed Data API.
revoke update on public.profiles from authenticated;
grant update (display_name) on public.profiles to authenticated;
