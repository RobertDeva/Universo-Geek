
revoke update on table public.membership_orders from authenticated;
grant update (tx_hash) on table public.membership_orders to authenticated;
revoke update on table public.service_orders from authenticated;
grant update (status) on table public.service_orders to authenticated;
