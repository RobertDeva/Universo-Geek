-- Corrige la carrera de idempotencia cuando el mismo usuario reintenta
-- la misma solicitud desde dos peticiones concurrentes.
-- Esta función reemplaza la versión inicial de GeekPoints con una segunda
-- comprobación de request_key después de bloquear la cuenta del usuario.
create or replace function public.geekpoints_request_redemption(
  p_plan_code text,
  p_request_key text
) returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_plan public.geekpoints_plan_limits%rowtype;
  v_account public.geekpoints_accounts%rowtype;
  v_existing public.geekpoints_redemptions%rowtype;
  v_used integer;
  v_id uuid;
begin
  if v_user is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if p_request_key is null or length(p_request_key) < 16 or length(p_request_key) > 120 then
    raise exception 'Invalid request key' using errcode = '22023';
  end if;

  -- Atajo habitual: si el reintento ya terminó, devolver la misma solicitud.
  select * into v_existing from public.geekpoints_redemptions
    where request_key = p_request_key;
  if found then
    if v_existing.user_id <> v_user or v_existing.plan_code <> p_plan_code then
      raise exception 'Request key already used' using errcode = '23505';
    end if;
    return v_existing.id;
  end if;

  select * into v_plan from public.geekpoints_plan_limits
    where plan_code = p_plan_code and enabled = true for share;
  if not found then
    raise exception 'Redemption is not available for this plan' using errcode = '22023';
  end if;

  insert into public.geekpoints_accounts(user_id) values (v_user)
    on conflict (user_id) do nothing;
  select * into v_account from public.geekpoints_accounts
    where user_id = v_user for update;

  -- Corrección clave: serializamos por cuenta y comprobamos de nuevo la clave.
  -- Así una segunda petición idéntica no intenta descontar GP otra vez.
  select * into v_existing from public.geekpoints_redemptions
    where request_key = p_request_key;
  if found then
    if v_existing.user_id <> v_user or v_existing.plan_code <> p_plan_code then
      raise exception 'Request key already used' using errcode = '23505';
    end if;
    return v_existing.id;
  end if;

  if v_account.frozen_at is not null then
    raise exception 'GeekPoints account is frozen' using errcode = '42501';
  end if;
  if v_account.balance < v_plan.points_cost then
    raise exception 'Insufficient GeekPoints' using errcode = '22023';
  end if;

  select count(*) into v_used from public.geekpoints_redemptions
    where user_id = v_user and plan_code = p_plan_code
      and created_at >= now() - interval '24 months'
      and status in ('pending','approved','fulfilled');
  if v_used >= v_plan.max_redemptions_24m then
    raise exception '24-month redemption limit reached for this plan' using errcode = '22023';
  end if;

  insert into public.geekpoints_redemptions(user_id, plan_code, points_cost, request_key)
    values (v_user, p_plan_code, v_plan.points_cost, p_request_key)
    returning id into v_id;
  update public.geekpoints_accounts
    set balance = balance - v_plan.points_cost,
        lifetime_spent = lifetime_spent + v_plan.points_cost,
        updated_at = now()
    where user_id = v_user;
  insert into public.geekpoints_ledger(user_id, delta, event_type, event_key, description, metadata)
    values (v_user, -v_plan.points_cost, 'spend', 'redemption:' || v_id::text,
      'GeekPoints reservados para una solicitud de canje',
      jsonb_build_object('redemption_id', v_id, 'plan_code', p_plan_code));
  insert into public.geekpoints_audit_log(actor_id, target_user_id, action, target_type, target_id, details)
    values (v_user, v_user, 'redemption_requested', 'geekpoints_redemption', v_id::text,
      jsonb_build_object('plan_code', p_plan_code, 'points_cost', v_plan.points_cost));
  return v_id;
end;
$$;

revoke all on function public.geekpoints_request_redemption(text, text) from public, anon;
grant execute on function public.geekpoints_request_redemption(text, text) to authenticated;
