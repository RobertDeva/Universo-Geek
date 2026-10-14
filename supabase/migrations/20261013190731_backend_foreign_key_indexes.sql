
create index if not exists affiliate_ads_reviewed_by_idx on public.affiliate_ads(reviewed_by);
create index if not exists marketplace_services_reviewed_by_idx on public.marketplace_services(reviewed_by);
create index if not exists service_orders_service_id_idx on public.service_orders(service_id);
create index if not exists membership_orders_reviewed_by_idx on public.membership_orders(reviewed_by);
