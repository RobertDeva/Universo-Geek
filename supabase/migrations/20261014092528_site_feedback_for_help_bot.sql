begin;

create table if not exists public.site_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid null references auth.users(id) on delete set null,
  category text not null default 'suggestion'
    check (category in ('question','bug','suggestion','content','accessibility','other')),
  rating smallint null check (rating between 1 and 5),
  message text not null check (char_length(btrim(message)) between 5 and 2000),
  contact_email text null check (contact_email is null or char_length(contact_email) <= 254),
  page_path text null check (page_path is null or char_length(page_path) <= 300),
  status text not null default 'new' check (status in ('new','reviewing','planned','done','closed')),
  created_at timestamptz not null default now()
);

create index if not exists site_feedback_created_at_idx
  on public.site_feedback (created_at desc);
create index if not exists site_feedback_status_created_idx
  on public.site_feedback (status, created_at desc);

alter table public.site_feedback enable row level security;

revoke all on public.site_feedback from anon, authenticated;
grant insert on public.site_feedback to anon, authenticated;
grant select on public.site_feedback to authenticated;

drop policy if exists "public can submit site feedback" on public.site_feedback;
create policy "public can submit site feedback"
  on public.site_feedback
  for insert
  to anon, authenticated
  with check (
    status = 'new'
    and (user_id is null or user_id = (select auth.uid()))
  );

drop policy if exists "admins can read site feedback" on public.site_feedback;
create policy "admins can read site feedback"
  on public.site_feedback
  for select
  to authenticated
  using (private.is_admin());

commit;
