-- Client-side payment state is not authoritative.
-- Orders may be read by their owner (and by admins through the read policy), but
-- creating, updating, deleting, or marking a payment paid requires a trusted backend.
begin;

drop policy if exists "users attach tx hash" on public.digital_purchases;
drop policy if exists "admins manage purchases" on public.digital_purchases;
drop policy if exists "users submit tx hash for own pending order" on public.membership_orders;
drop policy if exists "admins manage membership orders" on public.membership_orders;

revoke all privileges on table public.digital_purchases from public, anon, authenticated;
grant select on table public.digital_purchases to authenticated;

revoke all privileges on table public.membership_orders from public, anon, authenticated;
grant select on table public.membership_orders to authenticated;

-- Fail the migration if any browser role still has a direct write path.
do $$
begin
  if has_table_privilege('anon', 'public.digital_purchases', 'INSERT')
     or has_table_privilege('anon', 'public.digital_purchases', 'UPDATE')
     or has_table_privilege('anon', 'public.digital_purchases', 'DELETE')
     or has_table_privilege('authenticated', 'public.digital_purchases', 'INSERT')
     or has_table_privilege('authenticated', 'public.digital_purchases', 'UPDATE')
     or has_table_privilege('authenticated', 'public.digital_purchases', 'DELETE') then
    raise exception 'Browser roles must not write directly to digital_purchases';
  end if;

  if has_table_privilege('anon', 'public.membership_orders', 'INSERT')
     or has_table_privilege('anon', 'public.membership_orders', 'UPDATE')
     or has_table_privilege('anon', 'public.membership_orders', 'DELETE')
     or has_table_privilege('authenticated', 'public.membership_orders', 'INSERT')
     or has_table_privilege('authenticated', 'public.membership_orders', 'UPDATE')
     or has_table_privilege('authenticated', 'public.membership_orders', 'DELETE') then
    raise exception 'Browser roles must not write directly to membership_orders';
  end if;

  if not has_table_privilege('authenticated', 'public.digital_purchases', 'SELECT')
     or not has_table_privilege('authenticated', 'public.membership_orders', 'SELECT') then
    raise exception 'Authenticated users must retain read access subject to RLS';
  end if;
end;
$$;

commit;
