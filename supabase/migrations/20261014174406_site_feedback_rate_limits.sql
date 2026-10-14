create table if not exists public.site_feedback_rate_limits (
  ip_hash text primary key,
  window_started_at timestamptz not null default now(),
  request_count integer not null default 0
);
alter table public.site_feedback_rate_limits enable row level security;
revoke all on public.site_feedback_rate_limits from public, anon, authenticated;

