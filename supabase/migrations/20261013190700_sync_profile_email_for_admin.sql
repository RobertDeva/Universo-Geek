
alter table public.profiles add column if not exists email text;
update public.profiles p set email=u.email from auth.users u where u.id=p.id and p.email is distinct from u.email;
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
  insert into public.profiles(id,display_name,email)
  values(new.id,coalesce(new.raw_user_meta_data->>'display_name',''),new.email)
  on conflict (id) do update set email=excluded.email;
  return new;
end;
$$;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
