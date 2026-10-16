#!/usr/bin/env bash
# Concurrent idempotency test against the disposable PostgreSQL service.
set -euo pipefail
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
run_request() {
  psql -X -q -A -t -v ON_ERROR_STOP=1 \
    -c "SET ROLE authenticated; SET request.jwt.claim.sub='10000000-0000-4000-8000-000000000003'; SELECT public.geekpoints_request_redemption('geek', 'concurrent-idempotency-user3-0001');"
}
run_request > "$tmpdir/one" &
pid_one=$!
run_request > "$tmpdir/two" &
pid_two=$!
wait "$pid_one"
wait "$pid_two"
id_one="$(tr -d '[:space:]' < "$tmpdir/one")"
id_two="$(tr -d '[:space:]' < "$tmpdir/two")"
if [[ -z "$id_one" || "$id_one" != "$id_two" ]]; then
  echo "Concurrent idempotency failed: first='$id_one' second='$id_two'" >&2
  exit 1
fi
psql -X -q -v ON_ERROR_STOP=1 <<'SQL'
DO $$
DECLARE
  v_count integer;
  v_balance bigint;
  v_ledger_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.geekpoints_redemptions
    WHERE request_key = 'concurrent-idempotency-user3-0001';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Expected exactly one redemption for concurrent key; found %', v_count;
  END IF;
  SELECT balance INTO v_balance FROM public.geekpoints_accounts
    WHERE user_id = '10000000-0000-4000-8000-000000000003';
  IF v_balance <> 2000 THEN
    RAISE EXCEPTION 'Concurrent requests should deduct 1000 points once; balance is %', v_balance;
  END IF;
  SELECT count(*) INTO v_ledger_count
    FROM public.geekpoints_ledger
    WHERE event_key = 'redemption:' || (
      SELECT id::text FROM public.geekpoints_redemptions
      WHERE request_key = 'concurrent-idempotency-user3-0001'
    );
  IF v_ledger_count <> 1 THEN
    RAISE EXCEPTION 'Expected exactly one ledger event; found %', v_ledger_count;
  END IF;
END
$$;
SQL
echo "Concurrent idempotency passed: both calls returned ${id_one} and deducted points once."
