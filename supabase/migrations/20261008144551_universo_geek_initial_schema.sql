create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (char_length(display_name) <= 100),
  role text not null default 'user' check (role in ('user','admin','moderator')),
  created_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 180),
  slug text not null unique,
  description text not null default '',
  category text not null default 'Gaming',
  product_type text not null default 'catalog' check (product_type in ('affiliate','catalog','digital')),
  price_amount numeric(12,2) check (price_amount is null or price_amount >= 0),
  currency text not null default 'USD' check (currency ~ '^[A-Z]{3}$'),
  market_codes text[] not null default array['US','LATAM'],
  affiliate_url text,
  image_url text,
  emoji text not null default '🎮',
  tone text not null default '',
  tag text not null default 'Destacado',
  availability_status text not null default 'unknown' check (availability_status in ('available','unavailable','unknown')),
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint affiliate_url_https check (affiliate_url is null or affiliate_url ~ '^https://')
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references public.profiles(id) on delete set null,
  title text not null check (char_length(title) between 3 and 220),
  slug text not null unique,
  excerpt text not null default '',
  body text not null default '',
  category text not null default 'Guías',
  cover_emoji text not null default '📰',
  published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.contact_requests (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 100),
  email text not null check (char_length(email) <= 180),
  topic text not null check (char_length(topic) <= 120),
  message text not null check (char_length(message) between 1 and 2000),
  status text not null default 'new' check (status in ('new','in_progress','answered','closed')),
  created_at timestamptz not null default now()
);

create table if not exists public.newsletter_subscribers (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  locale text not null default 'es' check (locale in ('es','en')),
  consent_at timestamptz not null default now(),
  unsubscribed_at timestamptz
);

create table if not exists public.service_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  name text not null check (char_length(name) <= 100),
  email text not null check (char_length(email) <= 180),
  service_slug text not null,
  brief text not null check (char_length(brief) between 1 and 3000),
  budget_amount numeric(12,2) check (budget_amount is null or budget_amount >= 0),
  currency text not null default 'USD' check (currency ~ '^[A-Z]{3}$'),
  status text not null default 'pending' check (status in ('pending','quoted','accepted','in_progress','delivered','completed','cancelled')),
  created_at timestamptz not null default now()
);

create table if not exists public.click_events (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id) on delete set null,
  source_page text,
  market_code text,
  created_at timestamptz not null default now()
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1500),
  status text not null default 'visible' check (status in ('visible','hidden','reported')),
  created_at timestamptz not null default now()
);

create table if not exists public.digital_purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  product_id uuid not null references public.products(id) on delete restrict,
  provider text not null,
  provider_session_id text unique,
  provider_payment_id text unique,
  amount numeric(12,2) not null check (amount >= 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  status text not null default 'pending' check (status in ('pending','paid','refunded','failed')),
  created_at timestamptz not null default now()
);

create table if not exists public.admin_audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  target_table text not null,
  target_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','moderator')); $$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$ begin insert into public.profiles(id, display_name) values (new.id, coalesce(new.raw_user_meta_data->>'display_name','')); return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.posts enable row level security;
alter table public.contact_requests enable row level security;
alter table public.newsletter_subscribers enable row level security;
alter table public.service_requests enable row level security;
alter table public.click_events enable row level security;
alter table public.comments enable row level security;
alter table public.digital_purchases enable row level security;
alter table public.admin_audit_logs enable row level security;

drop policy if exists "published products readable" on public.products;
create policy "published products readable" on public.products for select using (published = true or public.is_admin());
drop policy if exists "admins manage products" on public.products;
create policy "admins manage products" on public.products for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "categories readable" on public.categories;
create policy "categories readable" on public.categories for select using (true);
drop policy if exists "admins manage categories" on public.categories;
create policy "admins manage categories" on public.categories for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "published posts readable" on public.posts;
create policy "published posts readable" on public.posts for select using (published = true or public.is_admin());
drop policy if exists "admins manage posts" on public.posts;
create policy "admins manage posts" on public.posts for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "public submit contact" on public.contact_requests;
create policy "public submit contact" on public.contact_requests for insert to anon, authenticated with check (true);
drop policy if exists "admins manage contact" on public.contact_requests;
create policy "admins manage contact" on public.contact_requests for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "public subscribe newsletter" on public.newsletter_subscribers;
create policy "public subscribe newsletter" on public.newsletter_subscribers for insert to anon, authenticated with check (char_length(email) between 5 and 254);
drop policy if exists "admins manage newsletter" on public.newsletter_subscribers;
create policy "admins manage newsletter" on public.newsletter_subscribers for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "public submit service request" on public.service_requests;
create policy "public submit service request" on public.service_requests for insert to anon, authenticated with check (true);
drop policy if exists "admins manage service requests" on public.service_requests;
create policy "admins manage service requests" on public.service_requests for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "public record affiliate clicks" on public.click_events;
create policy "public record affiliate clicks" on public.click_events for insert to anon, authenticated with check (true);
drop policy if exists "admins read clicks" on public.click_events;
create policy "admins read clicks" on public.click_events for select to authenticated using (public.is_admin());

drop policy if exists "profiles own read" on public.profiles;
create policy "profiles own read" on public.profiles for select to authenticated using (id = auth.uid() or public.is_admin());
create or replace function public.prevent_role_escalation()
returns trigger language plpgsql security definer set search_path = public
as $$ begin
  if new.role is distinct from old.role and not public.is_admin() then
    raise exception 'Only an administrator can change profile roles';
  end if;
  return new;
end; $$;
drop trigger if exists protect_profile_role on public.profiles;
create trigger protect_profile_role before update on public.profiles for each row execute procedure public.prevent_role_escalation();
drop policy if exists "profiles own update" on public.profiles;
create policy "profiles own update" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
drop policy if exists "admins manage profiles" on public.profiles;
create policy "admins manage profiles" on public.profiles for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "read visible comments" on public.comments;
create policy "read visible comments" on public.comments for select using (status = 'visible' or user_id = auth.uid() or public.is_admin());
drop policy if exists "signed-in create comments" on public.comments;
create policy "signed-in create comments" on public.comments for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "own comments update" on public.comments;
create policy "own comments update" on public.comments for update to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
drop policy if exists "own comments delete" on public.comments;
create policy "own comments delete" on public.comments for delete to authenticated using (user_id = auth.uid() or public.is_admin());

drop policy if exists "users read own purchases" on public.digital_purchases;
create policy "users read own purchases" on public.digital_purchases for select to authenticated using (user_id = auth.uid() or public.is_admin());
drop policy if exists "admins read audit logs" on public.admin_audit_logs;
create policy "admins read audit logs" on public.admin_audit_logs for select to authenticated using (public.is_admin());

insert into public.categories(name,slug) values
('Gaming','gaming'),('Accesorios','accesorios'),('Anime','anime'),('Coleccionables','coleccionables'),('Productos digitales','productos-digitales')
on conflict (slug) do nothing;

insert into public.products(name,slug,description,category,product_type,emoji,tag,published) values
('Auriculares gaming RGB','auriculares-gaming-rgb','Explora opciones para mejorar tu setup.','Accesorios','affiliate','🎧','Setup',false),
('Control inalámbrico','control-inalambrico','Comodidad para tus sesiones de juego.','Gaming','affiliate','🎮','Gaming',false),
('Kit de papelería anime','kit-papeleria-anime','Idea de regalo para fans del anime.','Anime','catalog','🌸','Otaku',false)
on conflict (slug) do nothing;