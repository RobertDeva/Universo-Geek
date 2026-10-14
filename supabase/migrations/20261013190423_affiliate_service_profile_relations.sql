
do $$ begin
  if not exists (select 1 from pg_constraint where conname='affiliate_ads_profile_fkey') then
    alter table public.affiliate_ads add constraint affiliate_ads_profile_fkey foreign key (user_id) references public.profiles(id) on delete cascade;
  end if;
  if not exists (select 1 from pg_constraint where conname='marketplace_services_profile_fkey') then
    alter table public.marketplace_services add constraint marketplace_services_profile_fkey foreign key (user_id) references public.profiles(id) on delete cascade;
  end if;
end $$;
