-- Integración en PostgreSQL desechable. No usar en producción.
\set ON_ERROR_STOP on

INSERT INTO auth.users(id, email) VALUES
 ('10000000-0000-4000-8000-000000000001', 'gp-user-1@example.invalid'),
 ('10000000-0000-4000-8000-000000000002', 'gp-user-2@example.invalid');

INSERT INTO public.geekpoints_accounts(user_id, balance)
VALUES
 ('10000000-0000-4000-8000-000000000001', 3000),
 ('10000000-0000-4000-8000-000000000002', 3000);

UPDATE public.geekpoints_plan_limits SET enabled = true WHERE plan_code = 'geek';

-- Prueba como usuario autenticado: idempotencia, saldo y límite de dos canjes.
SET ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000001', false);

DO $$
DECLARE
  first_id uuid;
  retry_id uuid;
  second_id uuid;
  visible_accounts integer;
  current_balance bigint;
  third_failed boolean := false;
BEGIN
  first_id := public.geekpoints_request_redemption('geek', 'integration-key-000001');
  retry_id := public.geekpoints_request_redemption('geek', 'integration-key-000001');
  IF first_id <> retry_id THEN
    RAISE EXCEPTION 'Idempotency failure: retry returned another redemption';
  END IF;

  SELECT balance INTO current_balance
  FROM public.geekpoints_accounts
  WHERE user_id = auth.uid();
  IF current_balance <> 2000 THEN
    RAISE EXCEPTION 'Idempotency/balance failure: expected 2000, got %', current_balance;
  END IF;

  second_id := public.geekpoints_request_redemption('geek', 'integration-key-000002');
  SELECT balance INTO current_balance
  FROM public.geekpoints_accounts
  WHERE user_id = auth.uid();
  IF current_balance <> 1000 THEN
    RAISE EXCEPTION 'Second redemption balance failure: expected 1000, got %', current_balance;
  END IF;

  BEGIN
    PERFORM public.geekpoints_request_redemption('geek', 'integration-key-000003');
  EXCEPTION WHEN OTHERS THEN
    third_failed := true;
  END;
  IF NOT third_failed THEN
    RAISE EXCEPTION 'Plan limit failure: third redemption unexpectedly succeeded';
  END IF;

  SELECT count(*) INTO visible_accounts FROM public.geekpoints_accounts;
  IF visible_accounts <> 1 THEN
    RAISE EXCEPTION 'RLS failure: user can see % accounts; expected only own account', visible_accounts;
  END IF;
END;
$$;

RESET ROLE;
