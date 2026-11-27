# DD-002 — Deal desk policy & rules v1.4

> Human-readable version of `rules/deal_desk_rules_v1.4.json`. If they disagree, the JSON wins and the gap is a bug.
> All prices are fictional, in EUR, and annual unless stated. The structure (platform plans + committed compute credits + overage) is modelled on Seqera's public pricing. The numbers are invented.

## Card
**Purpose:** one versioned policy that every other card reads: price book, quote validation, discount bands, approval rules, non-standard terms, contract checks and KPIs. Code never holds a threshold of its own.

**Story:** today the approval rules live in people's heads, so AEs can't predict what needs approval and Finance can't tell a valid exception from a mistake. Writing every rule once, with an ID, makes routing automatic, makes every finding traceable to a rule, and makes a policy change a reviewed, versioned event instead of a quiet edit.

### What this card delivers
| # | Deliverable | Where | What it contains |
|---|---|---|---|
| 1 | Machine-readable rules | `rules/deal_desk_rules_v1.4.json` | Every rule value with its ID; money as strings so code parses it with Decimal |
| 2 | Human-readable policy | This file, sections 1 to 9 | The same rules in tables, with definitions and two worked examples |
| 3 | Consistency tests | `tests/test_rules_consistency.py` | IDs unique, bands contiguous, credit tiers contiguous, every ID cited here exists in the JSON, worked example 1 reproduced |
| 4 | Version history | JSON `change_log` + Change log below | What changed in each version and why |

### Rule groups and who uses them
| Group | IDs | What it decides | Used by |
|---|---|---|---|
| Price book | P-01 to P-12 | List price, applicable list (credit tiers, academic) | DD-004 quote engine; DD-005 Products, Pricebooks, `Applicable_List__c` |
| Quote validation | Q-01 to Q-12 | Whether a quote can be submitted (block) or goes ahead with a recorded warning (warn) | DD-004 (all); DD-005 validation rules (Q-01, Q-08) and Quote Flow (Q-10) |
| Discount bands | D-01 to D-04 | **Reference only (v1.3).** Approved upstream in CPQ; not routed here | DD-004 applicable list and ARR/TCV only |
| Approval rules | A-02 to A-08 (A-01 retired) | TCV thresholds, who reviews, validity, targets | DD-004; DD-005 Approval Process; C-18 |
| Non-standard terms | N-01 to N-13 | Which exception needs which approver, or is not allowed | DD-004; DD-006 playbook variants; DD-014 known variants |
| Contract checks | C-01 to C-23 | PASS / REVIEW / BLOCK per finding | DD-014 pre-check; DD-008 comparator; DD-005 findings |
| KPIs | K-01 to K-11 | How results are measured | Test report (K-09 to K-11); DD-011 later (K-01 to K-08) |

### Values loaded into Salesforce (DD-005 Custom Metadata `Deal_Desk_Rule__mdt`)
N-rule thresholds (payment days, term months, uplift cap, notice bands, rollover %) · A-02 and A-03 TCV thresholds · P-06 credit tier edges and discounts · P-12 academic factor. The load is generated from the JSON, so Salesforce and Python can't drift; the DD-005 parity test proves it.

### Decisions
| Topic | Decided |
|---|---|
| Source of truth | The JSON. The markdown explains it; any gap between them is a bug |
| Money | Strings in JSON, Decimal in code, rounded to cents only at line level |
| Discount measure | Per line, per contract year, against the applicable list (after credit tier or academic price) |
| Academic price | Becomes the applicable list; discount bands apply on top |
| Credit tiers | Per contract year, on that year's committed quantity |
| Free months | Don't reduce ARR (full yearly rate). Reduce TCV and ACV, which use what is actually invoiced. Their value is recorded as a concession |
| Approval scope | Price and discount approvals happen upstream in CPQ; the approved net price arrives with the quote. This deal desk routes non-standard terms, contract language, rebates, volume commitments and deal-size review (A-02/A-03) to Deal Desk, Finance, CFO, CRO and Legal, in parallel |
| Money tolerance in contract checks | ±€1 per line per year |
| Quote validation severity (v1.4) | Block anything that would make the numbers, eligibility or the contract wrong (Q-01, Q-06, Q-07, Q-08, Q-10). Warn on product setup owned by CPQ (Q-02 to Q-05, Q-09) and on discount data (Q-11, Q-12). Warnings are kept on record |
| Changing a value | New version (e.g. v1.2 → v1.3) with a change-log reason, PR labelled `rule-change`, tests re-run. Never an in-place edit |
| Calibration | Values are proposed; after DD-003 any change goes to v1.2 |

### Open questions (owner decides)
| # | Question | Options | Recommendation |
|---|---|---|---|
| OQ-1 | Which renewal uplift caps need approval? | Keep the 3% floor / owner's policy | **Answered (v1.2):** standard is 5–7% or CPI + 2 pp (greater), 1 renewal cycle, on prior net price, platform and support only. Below 5%, a 0% hold, multi-cycle caps and caps on credit/usage rates → Deal Desk + Finance |
| OQ-2 | What notice period is standard? | One band / 60 days / by segment | **Answered (v1.2):** by segment from the platform SKU: Pro 30–60 days, Enterprise 60–90 days; outside the band → Deal Desk |

### Acceptance criteria
- [x] Rules v1.1 JSON with change log (N-06 short notice, K-11 precision)
- [x] Rules v1.2: N-05 uplift cap policy and N-06 notice by segment
- [x] Rules v1.3: price and discount approvals out of scope (CPQ); D-rules reference only; A-01 retired
- [x] N-13 bonus credits (volume incentive) and C-23 added in v1.3
- [x] Rules v1.4: Q-rule severity (block / warn), Q-11 line arithmetic and Q-12 discount provenance as recorded warnings
- [x] Markdown matches the JSON (N-01 wording, legal-form suffixes)
- [x] Every rule has an ID, and every rule group names the card that uses it
- [x] `pytest tests/test_rules_consistency.py` passes on v1.4
- [x] Worked example 1 (3-year Enterprise with credit step-up) reproduced in a test
- [ ] Worked example 2 (academic Pro with services discount) added to `tests/test_rules_consistency.py`
- [x] OQ-1 and OQ-2 answered (released as v1.2)
- [ ] Owner signs off on the v1.4 values
- [ ] After DD-003: values calibrated against the test set; changes, if any, released as the next version

**Proves:** "Review submitted quotes… multi-year, step-ups, non-standard terms"; "understands B2B deals: quotes, contracts, renewals, ARR/TCV".

---

# Policy

## 1. Standard terms (no approval needed)
| Term | Standard |
|---|---|
| Currency | EUR |
| Term length | 12, 24 or 36 months |
| Billing | Annually in advance (multi-year upfront also allowed) |
| Payment terms | Net 30 |
| Renewal | Auto-renews for the same term. Non-renewal notice by segment (platform SKU): Pro 30–60 days, Enterprise 60–90 days. Template default: 60 days |
| Renewal uplift | MoP may raise prices at renewal. A customer cap is standard when it is 5–7%, or CPI + 2 pp if higher (CPI = Spain INE general index, annual rate for the month before the renewal notice). Standard caps cover 1 renewal cycle, apply to the prior net price, and cover platform and support lines only, never credits or overage |
| Termination for convenience | None |
| Credits | Committed per contract year; unused credits expire at the end of each contract year |
| Liability cap | 12 months of fees |
| Governing law | Spain |
| Quote validity | 30 days |

## 2. Price book (P-rules)
| ID | SKU | Product | Type | List price | Notes |
|---|---|---|---|---|---|
| P-01 | PLT-PRO | Cloud Pro platform | Recurring | €12,000 / year | Includes 10 users; max 50 users in total |
| P-02 | PLT-PRO-USER | Additional Pro user | Recurring | €900 / user / year | Only with PLT-PRO |
| P-03 | PLT-ENT-CLD | Enterprise platform, cloud | Recurring | €60,000 / year | Includes 50 users, SSO, 99.9% SLA, premium support |
| P-04 | PLT-ENT-SH | Enterprise platform, self-hosted | Recurring | €72,000 / year | Same inclusions as P-03 |
| P-05 | PLT-ENT-USER | Additional Enterprise user | Recurring | €700 / user / year | Only with PLT-ENT-* |
| P-06 | CMP-CRED | Committed compute credits | Recurring (committed) | €1.00 / credit | Min 10,000 per contract year; volume tiers below |
| P-07 | CMP-OVG | Overage credits | Usage, in arrears | €1.20 / credit | Never quoted as a quantity; never ARR or TCV |
| P-08 | SUP-PREM | Premium support (Pro only) | Recurring | €3,000 / year | Already included in Enterprise |
| P-09 | SVC-ONB | Onboarding package | One-off | €8,000 | |
| P-10 | SVC-TRN | Training day | One-off | €2,000 / day | |
| P-11 | SVC-PS | Professional services | One-off | €180 / hour | |

**Credit volume tiers (P-06), per contract year:** 10,000–49,999 credits: 0% · 50,000–199,999: 5% · 200,000 or more: 10%. The tiered price is the "applicable list" for credits.

**Academic programme (P-12):** verified academic institutions (`Account.Academic_Verified__c = true`) get platform and support lines at 60% of list. That price becomes the applicable list, and discount bands apply on top of it. Credits and services have no academic price.

Cloud Basic is free self-serve and can't be quoted.

## 3. Quote validation (Q-rules)
**Block** means the quote is invalid and is not routed until it is fixed. **Warn** means it is routed as normal, and the warning is returned and kept on record. The test for blocking (v1.4): would this error make the ARR, the approver list, eligibility or the contract wrong? Product setup that CPQ already enforces only warns.

| ID | Rule | Severity | Owner | Why |
|---|---|---|---|---|
| Q-01 | Start date ≥ quote date; end date = start date + term − 1 day | Block | Deal desk | Wrong dates make ARR, TCV and the contract check wrong |
| Q-02 | Every SKU is active in the price book, and its list price equals the price book entry | Warn | CPQ | Price book setup is owned by CPQ |
| Q-03 | PLT-PRO users in total (10 included + additional) ≤ 50 | Warn | CPQ | Product limit |
| Q-04 | SUP-PREM can't be quoted with PLT-ENT-* | Warn | CPQ | Product bundling |
| Q-05 | If credits are quoted, ≥ 10,000 CMP-CRED per contract year | Warn | CPQ | Minimum order size |
| Q-06 | Account has a legal entity name, VAT ID and billing contact | Block | Deal desk | The contract can't be issued or checked (C-03) without them |
| Q-07 | Expansion quotes co-term: end date = end date of the contract named in `amended_contract_ref` | Block | Deal desk | Breaks co-terming, partial-year ARR and the renewal date |
| Q-08 | Academic prices only when `Academic_Verified__c = true` | Block | Deal desk | Eligibility, not price; a miss is revenue leakage |
| Q-09 | CMP-OVG never appears as a quoted quantity | Warn | CPQ | Overage is excluded from ARR and TCV anyway |
| Q-10 | New business: exactly one platform SKU (PLT-PRO or PLT-ENT-*). Expansion / renewal: exactly one platform SKU, or `amended_contract_ref` names an active contract on the same account (never an account-wide lookup) | Block | Deal desk | Segment (N-06) and ARR are read from the platform SKU of the quote or of the contract it amends |
| Q-11 | Each line's net amount = applicable list × quantity × (1 − discount), within ±€0.01 | Warn | CPQ | Inconsistent CPQ data, not a price approval |
| Q-12 | Each discounted line names who approved the discount in CPQ (`discount_approved_by`) and the CPQ approval reference (`cpq_approval_ref`) | Warn | CPQ | Shows who gave the discount at the quoting stage |

Every Q-11 and Q-12 warning is kept: in the quote review result, in the batch CSV and in `records/discount_warnings.csv` (see DD-004).

## 4. Discount bands (D-rules)

> **Reference only from v1.3.** Price and discount approvals are owned by CPQ at the quoting stage. This deal desk does not route the approvers below; the approved net price arrives with the quote. The bands stay here because they document the pricing policy and feed the applicable-list and ARR/TCV calculations.
Effective line discount = 1 − net amount ÷ (applicable list × quantity), per contract year.

| ID | Applies to | Band | Required approval |
|---|---|---|---|
| D-01 | Platform + support lines | 0–10% | None (AE) |
| | | >10–20% | Sales Manager |
| | | >20–30% | VP Sales (+ Deal Desk) |
| | | >30–40% | CRO + CFO (+ Deal Desk) |
| | | >40% | Not allowed |
| D-02 | CMP-CRED extra discount beyond the tier | 0 pp | None |
| | | >0–5 pp | Deal Desk |
| | | >5–10 pp | CFO |
| | | >10 pp | Not allowed |
| D-03 | Services (SVC-*) | 0–15% | Sales Manager if >0% |
| | | >15–100% | VP Sales |
| D-04 | Free months at start of term | 1–2 months | Sales Manager (counts as discount; see §6) |
| | | >2 months | Not allowed |

## 5. Approval rules (A-rules)
| ID | Rule |
|---|---|
| A-01 | *Retired in v1.3.* The discount approval chain is owned by CPQ upstream |
| A-02 | TCV ≥ €250,000 → CRO review (in parallel; doesn't add VP Sales) |
| A-03 | TCV ≥ €500,000 → CFO review as well |
| A-04 | Deal Desk reviews every quote that triggers any N-rule or hits A-02/A-03 |
| A-05 | An approval is valid only for the exact quote version approved. Any change to price, quantity, term, dates or terms means re-approval |
| A-06 | No one approves their own quote. An absent approver's standing deputy approves "on behalf of", and this is logged |
| A-07 | An approval expires with the quote (30 days). Expired quotes need re-approval |
| A-08 | Approval targets (for K-02): Deal Desk 1 business day; CRO, CFO, Finance and Legal 2 business days |

## 6. Definitions (contract values)
- **Recurring lines:** PLT-*, SUP-PREM, CMP-CRED. **One-off lines:** SVC-*. **Excluded everywhere:** CMP-OVG (overage), taxes, expenses.
- **Contract year y:** the 12-month period starting on the start date, or the remaining months when co-terming.
- **ARR_y (contracted ARR schedule):** the sum of net recurring amounts for contract year y, at run-rate. Partial years are annualised (× 12 ÷ months). Free months don't reduce ARR.
- **Booked ARR (new business):** ARR_1. **Contracted step-up ARR:** ARR_y − ARR_(y−1) for y ≥ 2. It is recorded in the ARR schedule and shows in the ARR bridge as "contracted step-up" when year y starts. It is not a new booking. *(DEC-04)*
- **Expansion booked ARR:** ARR_1 of the added lines, annualised. **Renewal ARR:** ARR_1 of the renewal contract. Change against the expiring ARR splits into uplift (price), expansion (quantity or new SKU) and contraction.
- **ACV:** Σ net recurring amounts actually invoiced over the term ÷ term in years. Average annual recurring value, without one-offs. With no free months this equals (Σ ARR_y) ÷ term in years. *Changed in v1.4:* free months now reduce ACV as well as TCV.
- **TCV:** Σ net recurring amounts actually invoiced over the term (free months deducted, partial years prorated) + Σ net one-off amounts. Overage is never included.
- **Bonus credits (N-13) never count** in ARR, ACV or TCV: they are free and expire with the contract year.
- **Concession value (v1.4):** free months at run-rate (net × free months ÷ 12) + bonus credits at the applicable list price for that year's credit tier. Reported on its own so the cost of give-aways is visible; never part of ARR, ACV or TCV.
  Example: 3 years at €60,000 a year with 2 free months → ARR €60,000 each year, TCV €170,000, ACV €56,666.67, concession value €10,000.
- **Committed credits count as recurring** (DEC-05) because they're contracted and prepaid every year. Overage and pay-as-you-go credits never count.
- **Close date:** date of the last signature. **Booking date:** date Booking Status is set to Booked.

### Worked example: 3-year Enterprise deal with a credit step-up
| Line | Year 1 | Year 2 | Year 3 |
|---|---|---|---|
| PLT-ENT-CLD at 15% discount | €51,000 | €51,000 | €51,000 |
| CMP-CRED (credits) | 100,000 @ €0.95 = €95,000 | 150,000 @ €0.95 = €142,500 | 200,000 @ €0.90 = €180,000 |
| SVC-ONB (one-off) | €8,000 | | |
| **ARR_y** | **€146,000** | **€193,500** | **€231,000** |

- Booked ARR = **€146,000**; contracted step-ups +€47,500 (Y2) and +€37,500 (Y3)
- ACV = (146,000 + 193,500 + 231,000) ÷ 3 = **€190,166.67**
- TCV = 570,500 + 8,000 = **€578,500**
- N-04 step-up shape: Y1 ÷ average = 146,000 ÷ 190,166.67 = 76.8% (≥ 60%, passes); no step-downs (passes)
- Approvals: the 15% discount was approved upstream in CPQ. A-02 → CRO; A-03 → CFO; A-04 → Deal Desk. **Result: Deal Desk, CRO, CFO**

### Worked example 2: 2-year academic Pro deal with a services discount
Account has `Academic_Verified__c = true` (Q-08). 24 months, 20 users in total (Q-03: ≤ 50), 30,000 credits per year (Q-05: ≥ 10,000).

| Line | List | Applicable list | Discount | Net per year |
|---|---|---|---|---|
| PLT-PRO | €12,000 | €7,200 (60%, P-12) | 12% | €6,336 |
| PLT-PRO-USER × 10 | €9,000 | €5,400 | 12% | €4,752 |
| SUP-PREM | €3,000 | €1,800 | 12% | €1,584 |
| CMP-CRED 30,000 | €30,000 | €30,000 (tier 0%, no academic price) | 0 pp | €30,000 |
| SVC-TRN × 2 days (one-off, year 1) | €4,000 | €4,000 | 10% | €3,600 |

- ARR_1 = ARR_2 = 12,672 + 30,000 = **€42,672**; Booked ARR = **€42,672**; no step-up
- ACV = **€42,672**
- TCV = 42,672 × 2 + 3,600 = **€88,944**
- Approvals: discounts approved upstream in CPQ; no N-rule triggered; TCV below A-02. **Result: no deal desk approval needed**

## 7. Non-standard terms (N-rules)
| ID | Term | Trigger | Approval |
|---|---|---|---|
| N-01 | Payment terms | > Net 30 to Net 60 / > Net 60 | Finance / CFO |
| N-02 | Billing frequency | Quarterly / monthly | Finance / CFO |
| N-03 | Term length | > 36 months / not 12, 24 or 36 (except co-termed expansions) | CFO / Deal Desk |
| N-04 | Step-up shape | Y1 ARR < 60% of ACV, or any year below the year before | CFO |
| N-05 | Renewal uplift cap | Cap below 5% (including a 0% price hold); a cap covering more than one renewal cycle (multi-term or perpetual, price lock beyond the term); any cap on credit or usage rates | Deal Desk + Finance |
| N-06 | Auto-renewal | Removed, or non-renewal notice outside the segment band (Pro 30–60 days, Enterprise 60–90 days) | Deal Desk |
| N-07 | Opt-out (termination for convenience) | Multi-year only, at an anniversary, ≥ 90 days' notice. Any other shape is not allowed | Legal + CFO |
| N-08 | Credit rollover | Up to 25% of unused committed credits into the next year. More is not allowed | Finance |
| N-09 | Legal terms | Liability cap > 12 months' fees, uncapped liability, MFN, custom SLA credits, custom data residency | Legal |
| N-10 | Currency | Not EUR | Not allowed (v1) |
| N-11 | Governing law | Not Spain | Legal |
| N-12 | Delayed start | Start date > 90 days after quote date | Deal Desk |
| N-13 | Bonus credits (volume incentive) | Free credits on top of committed CMP-CRED, as % of that year's commit: > 0–5% / > 5–10% / > 10%. Must expire with the contract year, can't be refunded or cashed, never count in ARR or TCV. Cash rebates and usage-based credit-back are not allowed | Deal Desk / Deal Desk + Finance / Not allowed |

## 8. Contract-to-booking checks (C-rules)
Inputs: the signed contract (extracted to `03_contract_extraction_schema.md`), the Opportunity, the approved Quote with its lines, the Account and the approval log.
Money tolerance: ±€1 per line per year. Names are normalised (case, punctuation, accents, legal-form suffixes: S.L., SL, S.L.U., SLU, S.A., SA, Lda., Lda, S.A.S., SAS, SARL, S.A.R.L.).

| ID | Check | Fail result |
|---|---|---|
| C-01 | Both parties signed; last signature date present | BLOCK |
| C-02 | Customer legal entity = Account legal name (normalised) | BLOCK if different; REVIEW if similarity ≥ 0.90 but not exact |
| C-03 | Customer VAT ID = Account VAT ID (normalised) | BLOCK |
| C-04 | Currency = EUR = quote currency | BLOCK |
| C-05 | Start date = quote start date | BLOCK |
| C-06 | Term (months) and end date = quote | BLOCK |
| C-07 | Same set of SKUs as the quote; none missing, none extra | BLOCK |
| C-08 | Net amount per line per contract year = quote (±€1) | BLOCK |
| C-09 | Committed credits per contract year = quote | BLOCK |
| C-10 | ARR_1 and TCV recomputed from the contract = Opportunity Booked ARR and TCV (±€1) | BLOCK |
| C-11 | Payment terms = approved terms | BLOCK if worse for MoP; REVIEW if better |
| C-12 | Billing frequency = approved | BLOCK |
| C-13 | Auto-renewal and notice days = standard band for the segment or approved exception | BLOCK |
| C-14 | Renewal uplift cap (%, fixed or CPI-based, renewal cycles covered, lines covered) = standard or approved exception | BLOCK |
| C-15 | Opt-out clause appears only if approved under N-07, with the same date and notice | BLOCK |
| C-16 | Credit rollover appears only if approved under N-08, with the same % | BLOCK |
| C-17 | Other non-standard clauses (N-09, N-11) only if approved | REVIEW (route to Legal) |
| C-18 | Contract references the approved quote number and version, and the approval was valid on the signature date (A-05, A-07) | BLOCK |
| C-19 | Every required field extracted, its source snippet verified in the text, confidence ≥ 0.80 | REVIEW |
| C-20 | Document complete ("Page x of y" sequence intact) and has a text layer | REVIEW |
| C-21 | Text addressed to an AI or system ("ignore previous instructions…") | REVIEW + security flag; never followed |
| C-22 | Opportunity close date = last signature date | BLOCK if a different fiscal quarter; REVIEW if same quarter |
| C-23 | Bonus credits appear only if approved under N-13, with the same quantity per year and the same expiry | BLOCK |

**Outcome:** any BLOCK → **BLOCK**; otherwise any REVIEW → **REVIEW**; otherwise **PASS** ("ready to book"). A named Deal Desk or Finance user still clicks Book. Overrides need a reason code: `customer_amendment_pending`, `approved_post_signature`, `extraction_error`, `policy_exception_cfo` or `other` (free text required).

## 9. KPIs (K-rules)
Business hours: Monday to Friday, 09:00–18:00 Europe/Madrid, excluding Spanish national holidays.

| ID | KPI | Definition |
|---|---|---|
| K-01 | Quote turnaround time | Business hours from submission for review to final approval (0 if no approval needed). Median and P90 |
| K-02 | Approval cycle time | Business hours per approver step, compared with the A-08 targets |
| K-03 | First-pass approval rate | Quotes approved without being sent back ÷ quotes submitted |
| K-04 | Non-standard deal rate | Quotes triggering ≥ 1 N-rule ÷ quotes submitted |
| K-05 | Weighted subscription discount | 1 − Σ net ÷ Σ applicable list on platform and support lines |
| K-06 | Contract check outcome mix | % PASS / REVIEW / BLOCK on first run |
| K-07 | Booking accuracy | Booked deals with zero corrections within 90 days ÷ booked deals |
| K-08 | Days to book | Calendar days from close date to booking date. Median |
| K-09 | Catch rate (test set) | Planted errors flagged with the right C-rule ÷ planted errors |
| K-10 | False block rate (test set) | Clean deals given BLOCK ÷ clean deals |
| K-11 | Finding precision (test set) | Correct rule findings ÷ all rule findings raised, i.e. TP ÷ (TP + FP) per 05_test_method.md |

## Change log
- v1.0: first version (proposed values, to be calibrated against the test set in DD-003).
- v1.1: N-06 also triggers when non-renewal notice is under 60 days (closes a gap: shorter notice moves renewal risk to MoP). K-11 finding precision added so precision/recall scoring has a rule ID. Markdown fixes with no value change: N-01 wording now matches the JSON (> Net 30), legal-form suffix list matches the JSON.
- v1.2: N-05 rewritten to the owner's uplift-cap policy (standard 5–7% or CPI + 2 pp, one renewal cycle, prior net price, platform and support only; below 5%, 0% hold, multi-cycle caps and caps on credit or usage rates need Deal Desk + Finance). Reason: protect renewal margin, stop multi-year price locks, keep usage pricing free to change. N-06 notice standard set by segment from the platform SKU (Pro 30–60 days, Enterprise 60–90 days), replacing the single 60-day standard. Reason: match market norms per segment.
- v1.3: price and discount approvals moved out of scope; they are owned by CPQ at the quoting stage and the approved net price arrives with the quote. D-01 to D-04 kept as reference data, not routed. A-01 (discount chain) retired; A-04 and A-08 updated to match. N-13 bonus credits added (up to 5% Deal Desk, over 5–10% Deal Desk + Finance, above 10% or any cash rebate / usage credit-back not allowed) with contract check C-23. Reason: the deal desk approves terms, contract language, rebates and volume commitments, not price; usage-based SaaS usually rewards volume with credits rather than cash.
- v1.4: quote validation rules get a severity. Block: Q-01, Q-06, Q-07, Q-08, Q-10. Warn: Q-02 to Q-05 and Q-09 (product setup owned by CPQ). New warnings Q-11 (line net amount vs list × quantity × discount) and Q-12 (discounted line must name who approved it in CPQ and the CPQ reference), kept on record. Reason: owner's decision (DEC-16, option C): block anything that would make the numbers, eligibility or the contract wrong; leave product setup to CPQ; keep an audit trail of discount data without approving price here. Also in v1.4: ACV now uses invoiced recurring ÷ term years, so free months reduce ACV as well as TCV (worked examples 1 and 2 are unchanged, as they have no free months), and a separate concession value records free months and bonus credits. Reason: owner's decision on how free months and bonus credits are counted. Also in v1.4: Q-07 and Q-10 bind expansions and renewals to the contract named in `amended_contract_ref` (Salesforce `Amended_Contract__c`), so an account with two active contracts or an early renewal can't pick the wrong segment; a missing, inactive or other-account contract blocks under Q-10.
