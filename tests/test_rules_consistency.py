"""DD-002: consistency checks for the current deal desk rules file (v1.1).

These tests protect the rules JSON itself (no engine code yet):
- IDs are unique and every rule ID cited in the policy doc exists in the JSON
- discount bands are contiguous with no gaps or overlaps
- credit tiers are contiguous
- the DD-002 worked example can be reproduced from the JSON values
"""
from __future__ import annotations

import json
import re
from decimal import Decimal
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
RULES_PATH = ROOT / "rules" / "deal_desk_rules_v1.1.json"
POLICY_DOC = ROOT / "docs" / "cards" / "DD-002_deal_desk_policy_v1.md"


@pytest.fixture(scope="module")
def rules() -> dict:
    return json.loads(RULES_PATH.read_text(encoding="utf-8"))


def all_rule_ids(rules: dict) -> list[str]:
    ids = [p["id"] for p in rules["price_book"]]
    ids += [rules["credit_volume_tiers"]["rule"], rules["academic"]["rule"]]
    ids += [q["id"] for q in rules["quote_validation"]]
    ids += [d["id"] for d in rules["discount_bands"]]
    ids += [a["id"] for a in rules["approval_rules"]]
    ids += [n["id"] for n in rules["non_standard_terms"]]
    ids += [c["id"] for c in rules["contract_checks"]["rules"]]
    ids += rules["kpis"]
    return ids


def test_rule_ids_unique(rules):
    ids = [i for i in all_rule_ids(rules) if i != "P-06"]  # P-06 is cited twice by design (SKU + tiers)
    dupes = {i for i in ids if ids.count(i) > 1}
    assert not dupes, f"duplicate rule ids: {dupes}"


def test_skus_unique(rules):
    skus = [p["sku"] for p in rules["price_book"]]
    assert len(skus) == len(set(skus))


def test_every_rule_in_policy_doc_exists_in_json(rules):
    doc = POLICY_DOC.read_text(encoding="utf-8")
    cited = set(re.findall(r"\b([PQDANCK]-\d{2})\b", doc))
    missing = cited - set(all_rule_ids(rules))
    assert not missing, f"cited in DD-002 but missing in JSON: {sorted(missing)}"


def _lower(band: dict) -> tuple[Decimal, bool]:
    if "min_incl" in band:
        return Decimal(band["min_incl"]), True
    return Decimal(band["min_excl"]), False


@pytest.mark.parametrize("rule_id", ["D-01", "D-02", "D-03", "D-04"])
def test_discount_bands_contiguous(rules, rule_id):
    rule = next(d for d in rules["discount_bands"] if d["id"] == rule_id)
    bands = rule["bands"]
    lo, inclusive = _lower(bands[0])
    assert lo == 0 and inclusive, f"{rule_id} must start at 0 inclusive"
    for prev, nxt in zip(bands, bands[1:]):
        assert prev["max_incl"] is not None, f"{rule_id}: open-ended band must be last"
        nlo, ninc = _lower(nxt)
        assert nlo == Decimal(prev["max_incl"]) and not ninc, f"{rule_id}: gap/overlap after {prev}"
    last = bands[-1]
    if last["max_incl"] is not None:
        assert Decimal(last["max_incl"]) == 100, f"{rule_id}: bands must reach 100% or be open-ended"


def test_credit_tiers_contiguous(rules):
    tiers = rules["credit_volume_tiers"]["tiers"]
    assert tiers[0]["min_qty"] == next(p for p in rules["price_book"] if p["sku"] == "CMP-CRED")["min_qty_per_year"]
    for prev, nxt in zip(tiers, tiers[1:]):
        assert nxt["min_qty"] == prev["max_qty"] + 1
    assert tiers[-1]["max_qty"] is None


def _tier_price(rules: dict, qty: int) -> Decimal:
    list_price = Decimal(next(p for p in rules["price_book"] if p["sku"] == "CMP-CRED")["list_price"])
    for t in rules["credit_volume_tiers"]["tiers"]:
        if qty >= t["min_qty"] and (t["max_qty"] is None or qty <= t["max_qty"]):
            return list_price * (1 - Decimal(t["discount_pct"]) / 100)
    raise ValueError(qty)


def test_worked_example_reproducible(rules):
    """DD-002 section 6: 3-year Enterprise cloud deal with credit step-up."""
    ent = Decimal(next(p for p in rules["price_book"] if p["sku"] == "PLT-ENT-CLD")["list_price"])
    platform = ent * Decimal("0.85")
    credits = [100_000, 150_000, 200_000]
    arr = [platform + q * _tier_price(rules, q) for q in credits]
    onboarding = Decimal(next(p for p in rules["price_book"] if p["sku"] == "SVC-ONB")["list_price"])

    assert arr == [Decimal("146000"), Decimal("193500"), Decimal("231000")]
    acv = sum(arr) / 3
    assert acv.quantize(Decimal("0.01")) == Decimal("190166.67")
    assert sum(arr) + onboarding == Decimal("578500")

    n04 = next(n for n in rules["non_standard_terms"] if n["id"] == "N-04")
    assert arr[0] / acv >= Decimal(n04["min_y1_arr_to_acv"])

    a02 = next(a for a in rules["approval_rules"] if a["id"] == "A-02")
    a03 = next(a for a in rules["approval_rules"] if a["id"] == "A-03")
    tcv = sum(arr) + onboarding
    assert tcv >= Decimal(a02["tcv_threshold"]) and tcv >= Decimal(a03["tcv_threshold"])


def test_money_values_are_strings(rules):
    """Money is stored as strings so the engine parses it with Decimal, never float."""
    for p in rules["price_book"]:
        assert isinstance(p["list_price"], str), p["sku"]
