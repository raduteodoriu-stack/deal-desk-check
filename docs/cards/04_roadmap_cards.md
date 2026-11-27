# Roadmap: cards DD-001 to DD-014

Order matters: rules → answer keys → deterministic code → AI only where needed → Salesforce → packaging.
**MVP build order:** DD-001 → DD-002 → DD-003 → DD-004 → DD-006 → DD-014 → DD-007 → DD-008 → DD-005 → DD-013.
DD-005 needs only DD-002 and the DD-003 answer keys, so it can run alongside DD-006 to DD-008.
**Thin slice (demo without Salesforce):** DD-002 → DD-003 (first 8 deals) → DD-004 → DD-006 → DD-014 → DD-008 on text contracts.

| Card | Title | Phase | Depends on | Est. days | Job description bullet it proves |
|---|---|---|---|---|---|
| DD-001 | Scope & governance | MVP | — | 0.5 | "Redesigned a commercial process end to end… documented it" |
| DD-002 | Deal desk policy & rules v1.2 | MVP | 001 | 0.5 | "Review submitted quotes… multi-year, step-ups, non-standard terms"; "ARR/TCV" |
| DD-003 | Test deal set & answer keys | MVP | 002 | 1 | "You notice when numbers don't reconcile" |
| DD-004 | Quote engine (slim) | MVP | 002, 003 | 1 | "Keep approvals moving" |
| DD-006 | Standard contract, clause playbook, contract generator | MVP | 003 | 1 | "Commercial runbooks, process maps, system documentation" |
| DD-014 | Deterministic pre-check: hash, diff, regex | MVP | 006 | 1 | "AI workflows to remove manual work" (rules ahead of AI) |
| DD-007 | LLM extraction for changed clauses | MVP | 014 | 1 | "AI workflows to remove manual work" |
| DD-008 | Comparator & decision (C-rules) | MVP | 004, 014, 007 | 1 | "Check every closed-won deal against the signed contract before it's booked" |
| DD-005 | Salesforce thin slice: gate, approvals, Flows | MVP | 002, 003 | 3.5 | "Salesforce admin changes: fields, page layouts, validation rules, flows"; "price books and SKUs" |
| DD-013 | Portfolio (slim) | MVP | all MVP | 0.5 | "Commercial runbooks, process maps, system documentation" |
| DD-012 | Claude skills packaging + evals | Post-MVP (first add-on) | 004, 008 | 1 | "Claude skills and plugins" |
| DD-009 | Orchestration in n8n | Post-MVP | 005, 008 | 1.5 | "n8n, Workato, or Zapier"; "integrations… test before rollout" |
| DD-010 | Booking queue & Finance export | Post-MVP | 005, 009 | 1 | "Reconcile bookings with Finance" |
| DD-011 | Deal desk analytics (dbt + Superset) | Post-MVP | 004, 010 | 1.5 | "Snowflake, dbt, Superset"; "analyse… turn findings into recommendations" |

**MVP total: about 11 days.** Post-MVP: about 5 days.

---

## DD-003 — Test deal set & answer keys
**Purpose:** prove the build against hand-written expectations that exist before any code.
**Story:** each deal is a small bundle (quote, opportunity, account, contract text) with exactly one planted error, or none. Every figure is worked out by hand so the code can't mark its own homework.
**Decisions:** 15 deals (DEC-11). Each planted error is chosen so that one stage (pre-check, LLM or comparator) is expected to catch it.
**Acceptance criteria**
- [ ] 15 deals in `tests/deals/<deal_id>/` (quote.json, opportunity.json, account.json, contract.txt)
- [ ] 3 clean (expected PASS); 12 with exactly one planted error each, covering at least 10 different C-rules
- [ ] At least 3 errors that only the template diff catches (changed clause wording, e.g. C-13, C-15, C-17) and at least 3 that only regex extraction catches (numbers and dates, e.g. C-05, C-08, C-09)
- [ ] At least 1 prompt-injection contract (C-21) and 1 contract with a missing page (C-20, page sequence)
- [ ] Every deal also has a quote-review key: expected approvers with reason codes, booked ARR, ACV, TCV
- [ ] `tests/answer_keys.csv`: deal_id, expected_outcome, expected_failed_rules, expected_catching_stage, expected_approvers, expected_booked_arr, expected_acv, expected_tcv
- [ ] Workings in `tests/workings/`, figures calculated by hand (spreadsheet allowed)
- [ ] Owner signs off on the keys before DD-004 starts

## DD-004 — Quote engine (slim)
**Purpose:** compute the numbers and the approval path for every quote from the rules file, so Salesforce and the contract check have one source of truth.
**Story:** the contract check needs ARR and TCV recomputed from the quote (C-10), and the Salesforce Flow must route the same approvers. One small Python engine does both and is checked against the answer keys.
**Decisions:** only the Q-rules the test set uses are implemented now; the rest wait. Money is Decimal, never float.
**Acceptance criteria**
- [ ] `dealdesk/quote.py`: applicable list (credit tiers, academic), effective line discount, ARR schedule, booked ARR, ACV, TCV
- [ ] `dealdesk/approvals.py`: approver list from the D, A and N rules with reason codes, e.g. `["Sales Manager: D-01 15.0%", "CRO: A-02 TCV ≥ 250k"]`
- [ ] Q-rules limited to those the test set uses (Q-01, Q-03, Q-04, Q-05, Q-09, Q-10); the rest are deferred
- [ ] Rules read only from the current rules JSON; no thresholds hard-coded
- [ ] Decimal arithmetic; amounts rounded to cents only at line level; the DD-002 §6 worked example reproduced to the cent
- [ ] Pytest: every DD-003 quote key matches
- [ ] Output `quote_review_result/v1` JSON, also flattened to CSV for the DD-005 import (one row per quote: tier, approvers, ARR, ACV, TCV)

## DD-006 — Standard contract, clause playbook, contract generator
**Purpose:** give the checker a fixed standard to compare against, and give reviewers a written playbook of what is allowed.
**Story:** most contracts are the standard agreement with the deal's numbers filled in. If every clause has a stable ID and every allowed variant is written down, code can recognise almost everything without an LLM.
**Decisions:** plain text with page markers; no PDF in the MVP. Planted errors come only from the answer key.
**Acceptance criteria**
- [ ] `contracts/template/standard_v1.md`: the standard MoP Cloud subscription agreement, every clause tagged with a stable clause ID (e.g. `[CL-PAY-01]`)
- [ ] `contracts/playbook_v1.md` + `contracts/playbook_v1.json`: for each clause, the standard wording, allowed variants (with the N-rule that approves them), forbidden variants, and the C-rule it maps to
- [ ] Number and date slots in the template (`{{start_date}}`, `{{line_items}}`) so regex extraction has fixed anchors
- [ ] Generator turns each DD-003 deal into `contract.txt` from the template and playbook variants
- [ ] "Page x of y" markers in every generated contract
- [ ] Synthetic names, VAT IDs and signatories only

## DD-014 — Deterministic pre-check: hash, diff, regex
**Purpose:** decide as much as possible without an LLM. Only clauses that differ from the template, or that the playbook doesn't recognise, go to the LLM.
**Story:** hashing tells us when a clause is unchanged, a diff shows what changed, and regex reads numbers and dates from the fixed slots. That leaves the LLM a few short clauses, which keeps cost near zero and results repeatable.
**Decisions:** SHA-256 on whitespace-normalised clause bodies with slots masked. The deterministic value wins over the LLM value where both exist.
**Acceptance criteria**
- [ ] Split each contract into clauses by clause ID; normalise whitespace; hash each clause body with slots masked
- [ ] Clause hash = template hash → `standard`, no LLM call
- [ ] Clause hash = an allowed playbook variant → `known_variant` (with the N-rule it needs), no LLM call
- [ ] Otherwise → `changed` or `unrecognised`; a word-level diff against the template is stored as evidence and the clause is queued for DD-007
- [ ] Regex/parser extraction of slot values (dates, term, currency, line items, payment days, notice days, uplift %, rollover %, quote reference, VAT ID, signatures) into `contract_extraction/v1.1`, with the matched text as `source_snippet`
- [ ] Missing or extra clause IDs and broken page sequences flagged (C-20)
- [ ] Injection screen (phrases addressed to an AI or system) flags C-21 before any LLM call
- [ ] Pytest on DD-003: every planted "pre-check" error is caught here; LLM calls per contract are logged (target: 0 on clean deals)

## DD-007 — LLM extraction for changed clauses
**Purpose:** turn the few non-standard clauses into the fixed schema, with verified snippets, so code can decide.
**Story:** the LLM never sees the whole contract and never decides. It extracts, and every value must point to text that really exists.
**Decisions:** Mistral by default behind a provider-agnostic interface (DEC-03); one comparison run against one other model.
**Acceptance criteria**
- [ ] Input is only the `changed` / `unrecognised` clauses from DD-014
- [ ] `prompts/extract_v1.md`; output fills `contract_extraction/v1.1` fields plus `other_non_standard_clauses[]`, each with a verbatim snippet verified against the contract text
- [ ] `extractor/base.py` + `extractor/mistral.py`; one comparison run on the same inputs against one other provider: per-field accuracy, cost, stability over 3 runs at temperature 0
- [ ] JSON schema validation + up to 2 repair retries; still invalid → REVIEW (`extraction_failed`)
- [ ] Recorded LLM outputs saved as JSON fixtures so all tests run offline
- [ ] Retry with backoff on 429 or timeout, then park as REVIEW (`pipeline_error`)
- [ ] Cost logged per contract (target < €0.01); total project LLM spend < €5

## DD-008 — Comparator & decision
**Purpose:** apply every C-rule in plain code and return one outcome per deal.
**Story:** the comparator merges what the pre-check and the LLM found, compares it with the quote, opportunity and account, and explains every finding with evidence.
**Decisions:** any BLOCK → BLOCK; otherwise any REVIEW → REVIEW; otherwise PASS. A person still books.
**Acceptance criteria**
- [ ] Every C-rule implemented as a pure function with its own tests (C-20 limited to page sequence in the MVP)
- [ ] Inputs: DD-014 output merged with DD-007 output; a conflict between them → C-19 REVIEW
- [ ] Output `contract_check_result/v1` JSON, plus a CSV shaped for the DD-005 import (Contract_Check__c and Contract_Check_Finding__c)
- [ ] Scored per C-rule on the full test set: K-09 = 100%, K-10 ≤ 10%, K-11 reported; any miss explained in `docs/test_report.md`

## DD-005 — Salesforce thin slice (Developer Edition)
**Purpose:** show both jobs live in a standard Sales Cloud org with no code. Discounts route to the right approvers, and a deal can't be booked until its contract check passes or a named person clears it with a reason.
**Story:** the deal desk engine runs offline. Salesforce holds the price book, runs the approvals and enforces the gate. Checker results arrive by CSV import, so there is no API integration to build or secure in the MVP.
**Decisions:** standard Quotes, not CPQ. The gate is on Booking Status, not Stage (DEC-10). Validation rules and Flow are used instead of Apex because they are native, admin-maintainable and auditable.

**A. Booking gate**
- [ ] Opportunity fields: `Booking_Status__c` (Not Ready, Checking, Review, Blocked, Ready to Book, Booked), `Booked_ARR__c`, `ACV__c`, `TCV__c`, `Term_Months__c`, `Booking_Date__c`
- [ ] Custom object `Contract_Check__c` (lookup to Opportunity): `Outcome__c` (PASS / REVIEW / BLOCK), `Failed_Rules__c`, `Rules_Version__c`, `Run_At__c`, `Is_Latest__c`, `Cleared_By__c` (User), `Cleared_At__c`, `Clear_Reason_Code__c` (the 5 DD-002 override codes), `Clear_Reason__c`
- [ ] Child object `Contract_Check_Finding__c` (master-detail): `Rule__c`, `Severity__c`, `Expected__c`, `Found__c`, `Evidence__c`
- [ ] Opportunity fields for the latest check (`Latest_Check_Outcome__c`, `Latest_Check_Cleared__c`), set by the Flow in C
- [ ] Validation rule on Contract_Check__c: a clearance needs Cleared_By, Cleared_At and Reason Code; code `other` needs Clear_Reason__c text
- [ ] Validation rule on Opportunity: Booking_Status__c can't be Booked unless the latest check is PASS or was cleared with a logged reason
- [ ] Field history tracking on Booking_Status__c and the clearance fields
- [ ] CSV import of DD-008 results (Data Import Wizard or Data Loader) for the DD-003 deals
- [ ] Permission sets: AE, Sales Manager, Deal Desk, Finance; only Deal Desk and Finance can clear checks or set Booked

**B. Price book and quote approvals**
- [ ] Quotes enabled; Product2 for every price-book SKU (P-01 to P-11); Pricebooks "MoP Standard" and "MoP Academic" (P-12)
- [ ] CMP-CRED has one PricebookEntry at €1.00; the tier price is stored on the line as `Applicable_List__c` (standard price books have no volume tiers)
- [ ] QuoteLineItem fields: `Contract_Year__c`, `Applicable_List__c`, `Effective_Discount_Pct__c` (formula), `Rule_Family__c`
- [ ] Quote fields: `Max_Platform_Discount__c`, `Max_Credit_Extra_Discount__c`, `Max_Services_Discount__c`, `Approval_Tier__c`, `Required_Approvers__c`, `Payment_Terms_Days__c`, `Billing_Frequency__c`
- [ ] Validation rules for Q-03, Q-04, Q-09 and the "not allowed" bands (D-01 > 40%, D-02 > 10 pp, D-04 > 2 months, N-10 non-EUR)
- [ ] Approval Process on Quote: A-01 chain (Sales Manager → VP Sales → CRO) driven by `Approval_Tier__c`; CFO, Finance, Deal Desk and Legal steps when `Required_Approvers__c` names them
- [ ] A-05: a change to price, quantity, term or dates on an approved quote resets its approval status
- [ ] Manual test script `docs/sf_test_script.md`: one quote per D-band plus the DD-002 worked example (expected: Sales Manager, Deal Desk, CRO, CFO)

**C. Record-triggered Flows**
- [ ] Quote / QuoteLineItem Flow: sets `Applicable_List__c`, works out the max discount per family, sets `Approval_Tier__c` and `Required_Approvers__c` from the D-band and A-rule thresholds
- [ ] Thresholds stored in Custom Metadata (`Deal_Desk_Rule__mdt`) loaded from the rules JSON, not typed into the Flow
- [ ] Opportunity Flow: Stage becomes Closed Won → Booking_Status__c = Checking and a Contract_Check__c placeholder is created
- [ ] Contract_Check__c Flow: on import, mark the newest check as latest, untick older ones, set Booking_Status__c (PASS → Ready to Book, REVIEW → Review, BLOCK → Blocked)
- [ ] Parity test: for every DD-003 quote, the Flow's `Required_Approvers__c` equals the DD-004 output

**Shared**
- [ ] Metadata retrieved into `salesforce/` with the Salesforce CLI, plus a README of Setup steps for anything not retrieved
- [ ] Test data loaded from DD-003 only (small volume)

## DD-013 — Portfolio (slim)
**Purpose:** make the work readable in five minutes by a RevOps hiring manager.
**Acceptance criteria**
- [ ] README: problem → what it does → architecture → results on the test set (precision/recall table, LLM calls and cost) → how to run
- [ ] Architecture diagram showing hash → diff → regex → LLM → comparator → CSV → Salesforce
- [ ] Screenshots or a short recording of the Salesforce slice: quote approval routing and a blocked booking being cleared
- [ ] Deferred: 3-minute pitch, interview Q&A, 30/60/90-day plan

---

## Post-MVP cards
Deferred: not part of the MVP (see DD-001). Card text kept for later.

### DD-012 — Claude skills (first add-on)
- [ ] `skills/deal-desk-quote-review/SKILL.md` and `skills/contract-booking-check/SKILL.md` (plus the test-deal generator skill used to build DD-003)
- [ ] Eval set: the DD-003 deals; pass mark = same outcome and same failed rules as the answer key
- [ ] Packaged as a plugin repo folder with a README

### DD-009 — Orchestration (n8n)
- [ ] Trigger: Salesforce Flow → n8n webhook (or n8n polls every 15 min with a SOQL query on Booking_Status__c = Checking)
- [ ] Steps: fetch the Opportunity, Quote, lines, Account and the contract file (ContentVersion) → pre-check → extract → compare → write Contract_Check__c and findings → update Booking_Status__c → Slack or email the Deal Desk queue
- [ ] Error handling: retry with backoff (3 tries), then Booking_Status__c = Review with `pipeline_error`; idempotent on the same contract version
- [ ] Credentials in n8n credentials / `.env` only; exported workflow JSON committed without secrets

### DD-010 — Booking queue & Finance export
- [ ] Deal Desk queue (list view or report) of Review/Blocked/Ready to Book deals
- [ ] Book, Override (reason code + text) and Send back to AE actions, all logged
- [ ] Booking export (CSV) for Finance: opportunity, account, booked ARR, ACV, TCV, ARR schedule, booking date
- [ ] Reconciliation check: Σ Booked ARR in Salesforce = Σ in the export = Σ in the dbt mart

### DD-011 — Analytics
- [ ] dbt models: stg_quotes, stg_approvals, stg_contract_checks → fct_quotes, fct_approvals, fct_bookings; dim_account, dim_product, dim_date
- [ ] K-01 to K-08 as dbt models with tests; K-09 to K-11 from the test report
- [ ] Superset dashboard: one page that passes the 5-second test (turnaround, discount trend, outcome mix, queue age)
- [ ] One-page findings memo: 3 recommendations with the KPI each one moves
