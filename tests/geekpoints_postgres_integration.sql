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

-- Usuario 1: idempotencia, saldo, límite de canjes y aislamiento RLS.
SET ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000001', false);

DO $$
DECLARE
  first_id uuid;
  retry_id uuid;
  visible_accounts integer;
  current_balance bigint;
  third_failed boolean := false;
  invalid_key_failed boolean := false;
  direct_write_failed boolean := false;
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

  PERFORM public.geekpoints_request_redemption('geek', 'integration-key-000002');
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

  BEGIN
    PERFORM public.geekpoints_request_redemption('geek', 'short');
  EXCEPTION WHEN OTHERS THEN
    invalid_key_failed := true;
  END;
  IF NOT invalid_key_failed THEN
    RAISE EXCEPTION 'Validation failure: short request key unexpectedly succeeded';
  END IF;

  SELECT count(*) INTO visible_accounts FROM public.geekpoints_accounts;
  IF visible_accounts <> 1 THEN
    RAISE EXCEPTION 'RLS failure: user can see % accounts; expected only own account', visible_accounts;
  END IF;

  BEGIN
    INSERT INTO public.geekpoints_ledger(user_id, delta, event_type, event_key)
    VALUES (auth.uid(), 10, 'earn', 'unauthorized-direct-write');
  EXCEPTION WHEN insufficient_privilege THEN
    direct_write_failed := true;
  END;
  IF NOT direct_write_failed THEN
    RAISE EXCEPTION 'Privilege failure: authenticated user wrote directly to ledger';
  END IF;
END;
$$;

-- User 2: cannot reuse another account's idempotency key; frozen accounts are blocked.
RESET ROLE;
UPDATE public.geekpoints_accounts
SET frozen_at = now(), freeze_reason = 'integration test'
WHERE user_id = '10000000-0000-4000-8000-000000000002';

SET ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000002', false);

DO $$
DECLARE
  key_conflict_failed boolean := false;
  frozen_account_failed boolean := false;
  visible_accounts integer;
BEGIN
  BEGIN
    PERFORM public.geekpoints_request_redemption('geek', 'integration-key-000001');
  EXCEPTION WHEN OTHERS THEN
    key_conflict_failed := true;
  END;
  IF NOT key_conflict_failed THEN
    RAISE EXCEPTION 'Idempotency security failure: another user reused an existing key';
  END IF;

  BEGIN
    PERFORM public.geekpoints_request_redemption('geek', 'integration-user2-key-0001');
  EXCEPTION WHEN OTHERS THEN
    frozen_account_failed := true;
  END;
  IF NOT frozen_account_failed THEN
    RAISE EXCEPTION 'Frozen-account failure: redemption unexpectedly succeeded';
  END IF;

  SELECT count(*) INTO visible_accounts FROM public.geekpoints_accounts;
  IF visible_accounts <> 1 THEN
    RAISE EXCEPTION 'RLS failure: second user can see % accounts; expected only own account', visible_accounts;
  END IF;
END;
$$;

RESET ROLE;
