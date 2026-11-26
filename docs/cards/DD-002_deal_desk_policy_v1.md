# DD-002 — Deal desk policy & rules v1.1

> Human-readable version of `rules/deal_desk_rules_v1.1.json`. If they disagree, the JSON wins and the gap is a bug.
> All prices are fictional, in EUR, and annual unless stated. The structure (platform plans + committed compute credits + overage) is modelled on Seqera's public pricing. The numbers are invented.

## 1. Standard terms (no approval needed)
| Term | Standard |
|---|---|
| Currency | EUR |
| Term length | 12, 24 or 36 months |
| Billing | Annually in advance (multi-year upfront also allowed) |
| Payment terms | Net 30 |
| Renewal | Auto-renews for the same term; 60 days' notice of non-renewal |
| Renewal uplift | Up to 7% on renewal |
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

## 3. Quote validation (Q-rules). Any failure means the quote can't be submitted.
| ID | Rule |
|---|---|
| Q-01 | Start date ≥ quote date; end date = start date + term − 1 day |
| Q-02 | Every SKU is active in the price book, and its list price equals the price book entry |
| Q-03 | PLT-PRO users in total (10 included + additional) ≤ 50 |
| Q-04 | SUP-PREM can't be quoted with PLT-ENT-* |
| Q-05 | If credits are quoted, ≥ 10,000 CMP-CRED per contract year |
| Q-06 | Account has a legal entity name, VAT ID and billing contact |
| Q-07 | Expansion quotes co-term: end date = end date of the existing contract |
| Q-08 | Academic prices only when `Academic_Verified__c = true` |
| Q-09 | CMP-OVG never appears as a quoted quantity |
| Q-10 | Exactly one platform SKU (PLT-PRO or PLT-ENT-*) on new-business quotes |

## 4. Discount bands (D-rules)
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
| A-01 | The discount chain is sequential up to the highest level required: Sales Manager → VP Sales → CRO. CFO, Finance and Legal are added in parallel when a rule names them |
| A-02 | TCV ≥ €250,000 → CRO review (in parallel; doesn't add VP Sales) |
| A-03 | TCV ≥ €500,000 → CFO review as well |
| A-04 | Deal Desk reviews every quote that needs VP Sales or higher, triggers any N-rule, or hits A-02/A-03 |
| A-05 | An approval is valid only for the exact quote version approved. Any change to price, quantity, term, dates or terms means re-approval |
| A-06 | No one approves their own quote. An absent approver's standing deputy approves "on behalf of", and this is logged |
| A-07 | An approval expires with the quote (30 days). Expired quotes need re-approval |
| A-08 | Approval targets (for K-02): Sales Manager, VP Sales and Deal Desk 1 business day; CRO, CFO, Finance and Legal 2 business days |

## 6. Definitions (contract values)
- **Recurring lines:** PLT-*, SUP-PREM, CMP-CRED. **One-off lines:** SVC-*. **Excluded everywhere:** CMP-OVG (overage), taxes, expenses.
- **Contract year y:** the 12-month period starting on the start date, or the remaining months when co-terming.
- **ARR_y (contracted ARR schedule):** the sum of net recurring amounts for contract year y, at run-rate. Partial years are annualised (× 12 ÷ months). Free months don't reduce ARR.
- **Booked ARR (new business):** ARR_1. **Contracted step-up ARR:** ARR_y − ARR_(y−1) for y ≥ 2. It is recorded in the ARR schedule and shows in the ARR bridge as "contracted step-up" when year y starts. It is not a new booking. *(DEC-04)*
- **Expansion booked ARR:** ARR_1 of the added lines, annualised. **Renewal ARR:** ARR_1 of the renewal contract. Change against the expiring ARR splits into uplift (price), expansion (quantity or new SKU) and contraction.
- **ACV:** (Σ ARR_y) ÷ term in years. Average annual recurring value, without one-offs.
- **TCV:** Σ net recurring amounts actually invoiced over the term (free months deducted, partial years prorated) + Σ net one-off amounts. Overage is never included.
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
- Approvals: D-01 15% → Sales Manager; A-02 → CRO; A-03 → CFO; A-04 → Deal Desk. **Result: Sales Manager, Deal Desk, CRO, CFO**

## 7. Non-standard terms (N-rules)
| ID | Term | Trigger | Approval |
|---|---|---|---|
| N-01 | Payment terms | > Net 30 to Net 60 / > Net 60 | Finance / CFO |
| N-02 | Billing frequency | Quarterly / monthly | Finance / CFO |
| N-03 | Term length | > 36 months / not 12, 24 or 36 (except co-termed expansions) | CFO / Deal Desk |
| N-04 | Step-up shape | Y1 ARR < 60% of ACV, or any year below the year before | CFO |
| N-05 | Renewal uplift cap | Cap < 3%, or price lock beyond the term | VP Sales + Finance |
| N-06 | Auto-renewal | Removed, notice > 90 days, or notice < 60 days | Deal Desk |
| N-07 | Opt-out (termination for convenience) | Multi-year only, at an anniversary, ≥ 90 days' notice. Any other shape is not allowed | Legal + CFO |
| N-08 | Credit rollover | Up to 25% of unused committed credits into the next year. More is not allowed | Finance |
| N-09 | Legal terms | Liability cap > 12 months' fees, uncapped liability, MFN, custom SLA credits, custom data residency | Legal |
| N-10 | Currency | Not EUR | Not allowed (v1) |
| N-11 | Governing law | Not Spain | Legal |
| N-12 | Delayed start | Start date > 90 days after quote date | Deal Desk |

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
| C-13 | Auto-renewal and notice days = standard or approved exception | BLOCK |
| C-14 | Renewal uplift cap = standard or approved exception | BLOCK |
| C-15 | Opt-out clause appears only if approved under N-07, with the same date and notice | BLOCK |
| C-16 | Credit rollover appears only if approved under N-08, with the same % | BLOCK |
| C-17 | Other non-standard clauses (N-09, N-11) only if approved | REVIEW (route to Legal) |
| C-18 | Contract references the approved quote number and version, and the approval was valid on the signature date (A-05, A-07) | BLOCK |
| C-19 | Every required field extracted, its source snippet verified in the text, confidence ≥ 0.80 | REVIEW |
| C-20 | Document complete ("Page x of y" sequence intact) and has a text layer | REVIEW |
| C-21 | Text addressed to an AI or system ("ignore previous instructions…") | REVIEW + security flag; never followed |
| C-22 | Opportunity close date = last signature date | BLOCK if a different fiscal quarter; REVIEW if same quarter |

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
