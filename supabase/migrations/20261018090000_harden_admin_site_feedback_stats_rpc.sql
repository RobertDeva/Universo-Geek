-- Refuerza el RPC de estadísticas del feedback administrativo.
-- La función pública es SECURITY INVOKER; la lógica privilegiada queda en
-- un esquema privado y vuelve a validar el rol administrativo en cada llamada.
-- No se deben conceder permisos de escritura sobre site_feedback al navegador.

create schema if not exists private;

revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated, service_role;

create or replace function private.admin_site_feedback_stats()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, auth
set row_security = off
as $function$
declare
  result jsonb;
begin
  -- No confiar en metadatos editables del usuario: comprobar el rol en profiles.
  if auth.uid() is null or not exists (
    select 1
    from public.profiles as p
    where p.id = auth.uid()
      and p.role = 'admin'
  ) then
    raise exception 'admin role required' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'total', count(*)::integer,
    'open', count(*) filter (where status in ('new', 'reviewing'))::integer,
    'last_30_days', count(*) filter (
      where created_at >= now() - interval '30 days'
    )::integer,
    'average_rating', round(avg(rating)::numeric, 2)
  )
  into result
  from public.site_feedback;

  return result;
end;
$function$;

revoke all on function private.admin_site_feedback_stats() from public, anon;
grant execute on function private.admin_site_feedback_stats() to authenticated, service_role;

create or replace function public.admin_site_feedback_stats()
returns jsonb
language sql
security invoker
set search_path = pg_catalog, public, private
as $function$
  select private.admin_site_feedback_stats();
$function$;

revoke all on function public.admin_site_feedback_stats() from public, anon;
grant execute on function public.admin_site_feedback_stats() to authenticated, service_role;
