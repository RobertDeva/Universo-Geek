"""Simulación de GeekPoints con 500 usuarios ficticios.

Prueba reglas de negocio en Python; no sustituye las pruebas reales de PostgreSQL.
Los planes están deshabilitados por defecto, igual que en la migración.
"""
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
import unittest

PLANS = {
    "geek": {"limit": 2, "cost": 1000, "enabled": False},
    "pro": {"limit": 1, "cost": 2500, "enabled": False},
    "creator": {"limit": 0, "cost": 5000, "enabled": False},
}

@dataclass
class Redemption:
    user_id: int
    plan_code: str
    request_key: str
    created_at: datetime
    status: str = "pending"
    redemption_id: int = 0

@dataclass
class Account:
    user_id: int
    balance: int = 0
    frozen: bool = False
    redemptions: list = field(default_factory=list)
    ledger_keys: set = field(default_factory=set)

class FakeGeekPoints:
    """Modelo didáctico de los controles económicos esperados."""
    def __init__(self):
        self.accounts = {i: Account(i, balance=5000) for i in range(1, 501)}
        self.plans = {key: dict(value) for key, value in PLANS.items()}
        self.requests = {}
        self.next_id = 1
        self.now = datetime.now(timezone.utc)

    def redeem(self, user_id, plan_code, request_key):
        account = self.accounts[user_id]
        if not request_key or len(request_key) < 16 or len(request_key) > 120:
            raise ValueError("invalid_request_key")
        if request_key in self.requests:
            old = self.requests[request_key]
            if old.user_id != user_id or old.plan_code != plan_code:
                raise ValueError("request_key_conflict")
            return old
        plan = self.plans.get(plan_code)
        if not plan or not plan["enabled"]:
            raise ValueError("plan_disabled")
        if account.frozen:
            raise ValueError("account_frozen")
        if account.balance < plan["cost"]:
            raise ValueError("insufficient_points")
        cutoff = self.now - timedelta(days=365.25 * 2)
        used = sum(
            1 for item in account.redemptions
            if item.plan_code == plan_code and item.created_at >= cutoff
            and item.status in {"pending", "approved", "fulfilled"}
        )
        if used >= plan["limit"]:
            raise ValueError("plan_limit_reached")
        redemption = Redemption(
            user_id, plan_code, request_key, self.now,
            redemption_id=self.next_id
        )
        self.next_id += 1
        account.balance -= plan["cost"]
        account.redemptions.append(redemption)
        account.ledger_keys.add(f"redemption:{redemption.redemption_id}")
        self.requests[request_key] = redemption
        return redemption

class GeekPointsSimulationTests(unittest.TestCase):
    def setUp(self):
        self.app = FakeGeekPoints()
        # Activación solo dentro del modelo de prueba, nunca en Supabase.
        self.app.plans["geek"]["enabled"] = True
        self.app.plans["pro"]["enabled"] = True

    def test_500_fictional_users_created(self):
        self.assertEqual(len(self.app.accounts), 500)
        self.assertEqual(sum(a.balance for a in self.app.accounts.values()), 2_500_000)

    def test_geek_limit_is_two(self):
        self.app.redeem(1, "geek", "request-geek-000001")
        self.app.redeem(1, "geek", "request-geek-000002")
        with self.assertRaisesRegex(ValueError, "plan_limit_reached"):
            self.app.redeem(1, "geek", "request-geek-000003")

    def test_pro_limit_is_one(self):
        self.app.redeem(2, "pro", "request-pro-00000001")
        with self.assertRaisesRegex(ValueError, "plan_limit_reached"):
            self.app.redeem(2, "pro", "request-pro-00000002")

    def test_limits_are_independent_by_plan(self):
        self.app.redeem(3, "geek", "request-geek-user003-1")
        self.app.redeem(3, "pro", "request-pro-user003-01")
        self.assertEqual(len(self.app.accounts[3].redemptions), 2)

    def test_creator_is_not_redeemable(self):
        with self.assertRaisesRegex(ValueError, "plan_disabled"):
            self.app.redeem(4, "creator", "request-creator-00001")

    def test_same_key_is_idempotent(self):
        first = self.app.redeem(5, "geek", "request-idempotent-0001")
        second = self.app.redeem(5, "geek", "request-idempotent-0001")
        self.assertEqual(first.redemption_id, second.redemption_id)
        self.assertEqual(self.app.accounts[5].balance, 4000)
        self.assertEqual(len(self.app.accounts[5].redemptions), 1)

    def test_key_cannot_be_reused_by_another_user(self):
        self.app.redeem(6, "geek", "request-shared-key-0001")
        with self.assertRaisesRegex(ValueError, "request_key_conflict"):
            self.app.redeem(7, "geek", "request-shared-key-0001")

    def test_insufficient_balance(self):
        self.app.accounts[8].balance = 999
        with self.assertRaisesRegex(ValueError, "insufficient_points"):
            self.app.redeem(8, "geek", "request-low-balance-001")
        self.assertEqual(self.app.accounts[8].balance, 999)

    def test_frozen_account(self):
        self.app.accounts[9].frozen = True
        with self.assertRaisesRegex(ValueError, "account_frozen"):
            self.app.redeem(9, "geek", "request-frozen-user-001")

    def test_disabled_plan(self):
        self.app.plans["geek"]["enabled"] = False
        with self.assertRaisesRegex(ValueError, "plan_disabled"):
            self.app.redeem(10, "geek", "request-disabled-0001")

    def test_invalid_request_key(self):
        with self.assertRaisesRegex(ValueError, "invalid_request_key"):
            self.app.redeem(11, "geek", "short")

    def test_bulk_500_user_scenario(self):
        for user_id in range(1, 501):
            self.app.redeem(user_id, "geek", f"bulk-geek-user-{user_id:04d}")
            self.app.redeem(user_id, "pro", f"bulk-pro-user-{user_id:04d}")
        self.assertEqual(sum(len(a.redemptions) for a in self.app.accounts.values()), 1000)
        self.assertTrue(all(a.balance >= 0 for a in self.app.accounts.values()))

if __name__ == "__main__":
    unittest.main(verbosity=2)
