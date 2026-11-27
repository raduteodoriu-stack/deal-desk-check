# Deal Desk & Contract-to-Booking Check

> Portfolio project · synthetic data only · fictional company **MoP Cloud** (research-technology SaaS, ES/PT/FR) · pricing structure modelled on Seqera's public model (platform plans + committed compute credits)

## The problem
As deals get more complex (multi-year terms, step-ups, committed credits, non-standard terms), three things break:
1. Quotes go out with discounts and terms nobody approved.
2. Approvals stall because nobody knows who has to approve what.
3. Bookings don't match the signed contract, and Finance finds out at month-end close or at renewal.

## What this does
- **Quote review:** checks every quote against one versioned policy (price book, discount bands, non-standard terms), computes ARR / ACV / TCV, and works out the approval path. Salesforce routes the approvals.
- **Contract-to-booking check:** before a Closed Won deal is booked, the signed contract is compared with a standard template and playbook (hash, diff, regex). An LLM reads only the clauses that changed, and must quote its source. Deterministic code then runs 22 checks against the Opportunity, Quote and Account and returns **PASS / REVIEW / BLOCK**. A Salesforce validation rule blocks booking until the check passes or a named person clears it with a reason.

## Status
| Card | Title | Phase | Status |
|---|---|---|---|
| DD-001 | Scope & governance | MVP | Decisions recorded |
| DD-002 | Policy & rules v1.2 | MVP | Draft (proposed values) |
| DD-003 | Test deal set & answer keys | MVP | Next |
| DD-004 | Quote engine (slim) | MVP | Not started |
| DD-006 | Standard contract, clause playbook, generator | MVP | Not started |
| DD-014 | Deterministic pre-check: hash, diff, regex | MVP | Not started |
| DD-007 | LLM extraction for changed clauses | MVP | Not started |
| DD-008 | Comparator & decision | MVP | Not started |
| DD-005 | Salesforce thin slice: gate, approvals, Flows | MVP | Not started |
| DD-013 | Portfolio (slim) | MVP | Not started |
| DD-012 | Claude skills | Post-MVP | Deferred |
| DD-009 | n8n orchestration | Post-MVP | Deferred |
| DD-010 | Booking queue & Finance export | Post-MVP | Deferred |
| DD-011 | Analytics (dbt + Superset) | Post-MVP | Deferred |

Progress is tracked as one GitHub issue per card on the project board. Card details: `docs/cards/04_roadmap_cards.md`.

## Repo layout
```
rules/       versioned policy (deal_desk_rules_vX.Y.json): the single source of truth
schemas/     contract_extraction_v1.1.json (extraction output contract)
docs/cards/  DD-xxx cards (scope, policy, roadmap, test method, architecture)
contracts/   standard template + clause playbook (DD-006)
dealdesk/    engine: quote engine, pre-check, comparator (DD-004, DD-014, DD-008)
extractor/   LLM extraction, provider-agnostic (DD-007)
prompts/     versioned prompts
tests/       deals, answer keys + pytest
salesforce/  Salesforce metadata (SF CLI project, DD-005)
tools/github/ issue bodies + setup script for the GitHub Project
n8n/, reporting/, skills/   post-MVP (DD-009, DD-011, DD-012)
```

## Run the tests
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pytest -q
```

## Principles
Rules before code · hand-written answer keys before code · deterministic checks before AI · the LLM extracts, code decides · a human books · synthetic data only · no secrets in git.

## Licence
MIT
