-- Applied to Supabase project khadcbgzziuwaxwptftw on 2026-10-14.
-- Enforce that a service order's agreed amount and currency match the approved listing.

begin;
drop policy if exists "buyers create orders for approved services" on public.service_orders;
create policy "buyers create orders for approved services"
  on public.service_orders
  for insert
  to authenticated
  with check (
    buyer_id = (select auth.uid())
    and status = 'requested'
    and exists (
      select 1
      from public.marketplace_services s
      where s.id = service_orders.service_id
        and s.status = 'approved'
        and s.user_id = service_orders.seller_id
        and s.user_id <> (select auth.uid())
        and s.price_amount = service_orders.agreed_amount
        and s.currency = service_orders.currency
    )
  );
commit;
