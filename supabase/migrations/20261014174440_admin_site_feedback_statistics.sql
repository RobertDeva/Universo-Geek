create or replace function public.admin_site_feedback_stats()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare result jsonb;
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  ) then
    raise exception 'admin role required' using errcode = '42501';
  end if;
  select jsonb_build_object(
    'total', count(*)::integer,
    'open', count(*) filter (where status in ('new','reviewing'))::integer,
    'last_30_days', count(*) filter (where created_at >= now() - interval '30 days')::integer,
    'average_rating', round(avg(rating)::numeric, 2)
  ) into result
  from public.site_feedback;
  return result;
end;
$$;
revoke all on function public.admin_site_feedback_stats() from public, anon;
grant execute on function public.admin_site_feedback_stats() to authenticated;
