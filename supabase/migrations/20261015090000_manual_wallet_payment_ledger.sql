begin;

-- Phase A ledger only. It does not publish wallet addresses, create invoices,
-- verify on-chain transactions, or enable checkout. Trusted backend/admin
-- procedures must create and update rows after independent verification.
create table if not exists public.manual_wallet_payment_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  order_type text not null check (order_type in ('membership','service','digital_product')),
  order_reference text not null check (length(order_reference) between 1 and 160),
  idempotency_key text not null unique,
  asset text not null check (asset in ('USDC','USDT')),
  network text not null check (network in ('ethereum','solana','bsc')),
  token_contract text,
  destination_address text not null,
  expected_amount numeric(30,12) not null check (expected_amount > 0),
  expires_at timestamptz not null,
  status text not null default 'awaiting_payment' check (status in (
    'awaiting_payment','submitted_for_review','under_review','confirmed',
    'underpaid','expired','rejected','refunded','under_review_risk'
  )),
  submitted_tx_hash text,
  verified_tx_hash text,
  received_amount numeric(30,12) check (received_amount is null or received_amount >= 0),
  confirmations integer check (confirmations is null or confirmations >= 0),
  reviewed_by uuid references auth.users(id) on delete restrict,
  review_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  verified_at timestamptz,
  constraint manual_wallet_payment_verified_requires_hash
    check (status <> 'confirmed' or (verified_tx_hash is not null and verified_at is not null))
);

create unique index if not exists manual_wallet_payment_chain_tx_unique
  on public.manual_wallet_payment_requests(network, verified_tx_hash)
  where verified_tx_hash is not null;

create index if not exists manual_wallet_payment_user_created_idx
  on public.manual_wallet_payment_requests(user_id, created_at desc);

create index if not exists manual_wallet_payment_status_expiry_idx
  on public.manual_wallet_payment_requests(status, expires_at);

create or replace function public.ug_manual_wallet_payment_touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists manual_wallet_payment_touch_updated_at
  on public.manual_wallet_payment_requests;
create trigger manual_wallet_payment_touch_updated_at
before update on public.manual_wallet_payment_requests
for each row execute function public.ug_manual_wallet_payment_touch_updated_at();

alter table public.manual_wallet_payment_requests enable row level security;

-- Browser users can only read their own request records. They cannot create,
-- edit, confirm, refund, or reject payment records from the client.
revoke all on public.manual_wallet_payment_requests from public, anon, authenticated;
grant select on public.manual_wallet_payment_requests to authenticated;

drop policy if exists "users read own manual wallet payment requests"
  on public.manual_wallet_payment_requests;
create policy "users read own manual wallet payment requests"
on public.manual_wallet_payment_requests
for select to authenticated
using (user_id = (select auth.uid()));

commit;
