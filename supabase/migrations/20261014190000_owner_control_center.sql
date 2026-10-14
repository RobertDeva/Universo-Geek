-- Universo Geek: propietario exclusivo y panel financiero de solo lectura.
-- No se agrega ninguna cuenta automáticamente. Consulta docs/OWNER-CONTROL-CENTER.md.
begin;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create table if not exists private.owner_allowlist (
 user_id uuid primary key references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 created_by uuid references auth.users(id) on delete set null,
 note text not null default 'Owner control center'
);
revoke all on private.owner_allowlist from public, anon, authenticated;
create or replace function private.is_owner()
returns boolean language sql stable security definer
set search_path = '' set row_security = off
as $$
 select exists(select 1 from private.owner_allowlist oa where oa.user_id=(select auth.uid()));
$$;
revoke all on function private.is_owner() from public, anon;
grant execute on function private.is_owner() to authenticated;
create or replace function public.owner_dashboard_summary()
returns jsonb language plpgsql stable security definer
set search_path = '' set row_security = off
as $$
declare result jsonb;
begin
 if (select auth.uid()) is null or not private.is_owner() then
  raise exception 'Not authorized' using errcode = '42501';
 end if;
 select jsonb_build_object(
  'authorized',true,
  'membership_revenue_usd',coalesce((select sum(mo.amount_usd) from public.membership_orders mo where mo.status='paid'),0),
  'paid_membership_orders',(select count(*) from public.membership_orders mo where mo.status='paid'),
  'digital_revenue_usd',coalesce((select sum(dp.amount) from public.digital_purchases dp where dp.status='paid'),0),
  'paid_digital_purchases',(select count(*) from public.digital_purchases dp where dp.status='paid'),
  'active_memberships',(select count(*) from public.active_memberships am where am.active=true),
  'published_services',(select count(*) from public.marketplace_services ms where ms.status='approved'),
  'service_orders',(select count(*) from public.service_orders so),
  'affiliate_clicks',(select count(*) from public.affiliate_ad_clicks ac)
 ) into result;
 return result;
end;
$$;
revoke all on function public.owner_dashboard_summary() from public, anon;
grant execute on function public.owner_dashboard_summary() to authenticated;
commit;
