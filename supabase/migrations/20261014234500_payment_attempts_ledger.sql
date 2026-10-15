begin;

-- Preparatory ledger only. No checkout or payment provider is enabled by this migration.
create table if not exists public.payment_attempts (
  id uuid primary key default gen_random_uuid(),
  membership_order_id uuid not null references public.membership_orders(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete restrict,
  provider_code text not null check (provider_code ~ '^[a-z0-9_-]{2,40}$'),
  payment_method text not null check (payment_method in ('card','paypal','local_transfer','crypto')),
  provider_reference text,
  provider_event_id text,
  idempotency_key text not null unique,
  status text not null default 'created' check (status in (
    'created','awaiting_payment','payment_detected','payment_confirmed',
    'conversion_pending','settlement_confirming','paid','underpaid',
    'expired','failed','refunded','chargeback','under_review'
  )),
  input_amount numeric(20,8) check (input_amount is null or input_amount >= 0),
  input_currency text check (input_currency is null or input_currency ~ '^[A-Z0-9]{2,12}$'),
  settlement_asset text not null check (settlement_asset in ('USDC','USDT')),
  settlement_network text not null check (settlement_network in ('ethereum','solana','bsc')),
  destination_address text,
  settlement_amount numeric(30,12) check (settlement_amount is null or settlement_amount >= 0),
  settlement_tx_hash text,
  conversion_reference text,
  provider_status text,
  safe_metadata jsonb not null default '{}'::jsonb check (pg_column_size(safe_metadata) <= 8192),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  verified_at timestamptz,
  paid_at timestamptz
);

create unique index if not exists payment_attempts_provider_reference_unique
  on public.payment_attempts(provider_code, provider_reference)
  where provider_reference is not null;

create unique index if not exists payment_attempts_provider_event_unique
  on public.payment_attempts(provider_code, provider_event_id)
  where provider_event_id is not null;

create unique index if not exists payment_attempts_settlement_tx_unique
  on public.payment_attempts(settlement_network, settlement_tx_hash)
  where settlement_tx_hash is not null;

create index if not exists payment_attempts_user_created_idx
  on public.payment_attempts(user_id, created_at desc);

create index if not exists payment_attempts_status_created_idx
  on public.payment_attempts(status, created_at);

create or replace function public.ug_payment_attempts_touch_updated_at()
returns trigger language plpgsql set search_path = public
as $$ begin new.updated_at = now(); return new; end; $$;

drop trigger if exists payment_attempts_touch_updated_at on public.payment_attempts;
create trigger payment_attempts_touch_updated_at
before update on public.payment_attempts
for each row execute function public.ug_payment_attempts_touch_updated_at();

alter table public.payment_attempts enable row level security;

-- No browser-side INSERT/UPDATE/DELETE. A trusted backend creates and advances attempts.
revoke all on public.payment_attempts from public, anon, authenticated;
grant select on public.payment_attempts to authenticated;

drop policy if exists "users read own payment attempts" on public.payment_attempts;
create policy "users read own payment attempts"
on public.payment_attempts for select to authenticated
using (user_id = (select auth.uid()));

commit;
