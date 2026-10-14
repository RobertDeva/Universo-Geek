
drop policy if exists "buyers confirm delivered orders" on public.service_orders;
create policy "buyers confirm delivered orders" on public.service_orders
for update to authenticated
using (buyer_id = (select auth.uid()) and status = 'delivered')
with check (buyer_id = (select auth.uid()) and status in ('completed','disputed','cancelled'));
