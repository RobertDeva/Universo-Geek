-- Align the service-order trigger with the documented order lifecycle and RLS policies.
create or replace function public.ug_validate_service_order_transition()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
declare
  caller_role text;
begin
  select role into caller_role from public.profiles where id = auth.uid();

  if new.service_id is distinct from old.service_id
     or new.buyer_id is distinct from old.buyer_id
     or new.seller_id is distinct from old.seller_id
     or new.brief is distinct from old.brief
     or new.agreed_amount is distinct from old.agreed_amount
     or new.currency is distinct from old.currency then
    if caller_role is distinct from 'admin' then
      raise exception 'Los datos de una orden no se pueden cambiar después de crearla.'
        using errcode = '42501';
    end if;
  end if;

  if caller_role = 'admin' then
    return new;
  end if;

  if auth.uid() = old.seller_id then
    if not (
      (old.status = 'requested' and new.status in ('accepted','cancelled'))
      or (old.status = 'accepted' and new.status in ('in_progress','cancelled'))
      or (old.status = 'in_progress' and new.status in ('delivered','cancelled','disputed'))
    ) then
      raise exception 'Transición de estado no permitida para el vendedor.'
        using errcode = '42501';
    end if;
  elsif auth.uid() = old.buyer_id then
    if not (
      (old.status = 'requested' and new.status in ('cancelled','disputed'))
      or (old.status = 'delivered' and new.status in ('completed','disputed','cancelled'))
    ) then
      raise exception 'Transición de estado no permitida para el comprador.'
        using errcode = '42501';
    end if;
  else
    raise exception 'No tienes permiso para modificar esta orden.'
      using errcode = '42501';
  end if;

  return new;
end;
$function$;