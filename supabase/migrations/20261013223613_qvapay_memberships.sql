begin;

-- Identify the payment provider explicitly. Existing/manual crypto orders retain
-- their original behavior and are not misidentified as QvaPay invoices.
alter table public.membership_orders
  add column if not exists provider text not null default 'manual_crypto';
alter table public.membership_orders
  add column if not exists provider_invoice_id text;
alter table public.membership_orders
  add column if not exists provider_checkout_url text;

alter table public.membership_orders
  alter column crypto_network drop not null;
alter table public.membership_orders
  drop constraint if exists membership_orders_crypto_network_check;
alter table public.membership_orders
  add constraint membership_orders_crypto_network_check
  check (crypto_network is null or crypto_network = any (array['BTC','ETH','SOL','BNB']::text[]));

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'membership_orders_provider_check'
      and conrelid = 'public.membership_orders'::regclass
  ) then
    alter table public.membership_orders
      add constraint membership_orders_provider_check
      check (provider in ('manual_crypto','qvapay'));
  end if;
end $$;

create unique index if not exists membership_orders_qvapay_invoice_unique
  on public.membership_orders(provider_invoice_id)
  where provider = 'qvapay' and provider_invoice_id is not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'membership_orders_provider_checkout_url_https'
      and conrelid = 'public.membership_orders'::regclass
  ) then
    alter table public.membership_orders
      add constraint membership_orders_provider_checkout_url_https
      check (provider_checkout_url is null or provider_checkout_url ~ '^https://');
  end if;
end $$;

commit;
