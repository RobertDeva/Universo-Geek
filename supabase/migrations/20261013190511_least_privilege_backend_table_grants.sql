
-- Remove broad default grants on the new tables; RLS is necessary but not a substitute for SQL privileges.
revoke all on table public.affiliate_ads, public.marketplace_services, public.service_orders,
  public.membership_orders, public.affiliate_ad_clicks from anon, authenticated;

grant select on table public.affiliate_ads, public.marketplace_services to anon;
grant select, insert, update, delete on table public.affiliate_ads, public.marketplace_services to authenticated;
grant select, insert, update on table public.service_orders to authenticated;
grant select, insert, update on table public.membership_orders to authenticated;
grant insert on table public.affiliate_ad_clicks to anon;
grant select, insert on table public.affiliate_ad_clicks to authenticated;
