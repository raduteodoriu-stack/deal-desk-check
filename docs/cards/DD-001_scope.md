# DD-001 — Scope & governance

## Purpose
Define what the Deal Desk & Contract-to-Booking Check covers in the MVP, who uses it, which decisions it makes, and which it never makes. Every later card builds on this one.

## Story
MoP Cloud sells platform subscriptions plus usage-based compute credits to research organisations in Spain, Portugal and France. Deal volume and complexity are growing: multi-year deals, step-ups, committed credits and non-standard terms requested by procurement. Today three things go wrong:

1. **Quotes leak margin.** AEs send quotes with discounts or terms nobody approved, because the approval rules live in people's heads.
2. **Approvals are slow.** Nobody knows who has to approve what, so quotes wait in inboxes and deals slip.
3. **Bookings don't match contracts.** The signed contract sometimes differs from the Opportunity: a different start date, an extra opt-out clause, different credits or payment terms. Finance finds this at month-end close, or worse, at renewal. ARR, commissions and revenue schedules end up wrong.

The deal desk fixes these with one written policy, an approval path the system works out automatically, and a check that compares every Closed Won deal with the signed contract before it is booked. The check is deterministic first (hash, template diff, regex). An LLM reads only clauses that changed or that the playbook does not recognise.

## Stakeholders
| Role | Needs | Uses |
|---|---|---|
| Account Executive (AE) | Fast, predictable approvals; knows upfront what needs approval | Quote approval status in Salesforce |
| Sales Manager / VP Sales | Discount control without becoming a bottleneck | Approval requests |
| Deal Desk (Business Ops Analyst) | One policy, one queue, evidence for every exception | Quote review, contract check results, booking gate |
| Finance / CFO | Bookings that match contracts; correct ARR and commission base | Booking status, check findings |
| Legal | Non-standard clauses routed to them | Approval requests for N-rules |
| Director of RevOps | Quote turnaround, discount trends, booking accuracy | Test report now; dashboard after the MVP |

## In scope (MVP)
- New business, expansion (upsell) and renewal quotes for the products in the DD-002 price book.
- Term lengths of 12, 24 and 36 months (longer needs CFO approval), annual step-ups, and committed credits per contract year.
- **Quote review computation** (Python, offline): ARR schedule, ACV, TCV and the approver list from the rules file (DD-004).
- **Contract-to-booking check**: hash → template diff → regex extraction (DD-014) → LLM only for changed or unrecognised clauses (DD-007) → C-rules → PASS / REVIEW / BLOCK (DD-008).
- **Standard contract and clause playbook** with stable clause IDs; synthetic test contracts generated from them (DD-006).
- **Salesforce Developer Edition thin slice** (DD-005): price books, Quote discount approvals, Contract Check object, booking gate, record-triggered Flows. Checker results go in by CSV import.
- **Human booking step**: a named person clears REVIEW/BLOCK with a logged reason and sets Booking Status = Booked.
- **Offline testing** with JSON fixtures, scored by precision and recall per C-rule (05_test_method.md).

## Out of scope (v1)
- n8n orchestration and any Salesforce API integration (deferred, DD-009).
- Booking queue, override UI and Finance export beyond the gate itself (deferred, DD-010).
- dbt / Superset analytics (deferred, DD-011). The MVP reports K-09, K-10 and K-11 from the test report.
- Claude skills packaging (deferred, first add-on after the MVP, DD-012).
- PDF parsing and scanned documents. Contracts are plain text in v1. The C-20 page-sequence check stays; the text-layer check is deferred.
- Generating real contract documents, e-signature integration and redlining.
- Invoicing, revenue recognition (ASC 606 / IFRS 15) and real ERP integration.
- Commission calculation itself (only the booking data it relies on).
- Usage metering of credits (that belongs to the Credit Burn & Renewal Radar).
- Salesforce CPQ / Revenue Cloud. Standard Quotes are used instead.
- Real customer data of any kind.

## Decisions the system makes vs never makes
| The system decides | A person always decides |
|---|---|
| Which approvals a quote needs (from the A-rules) | Whether to approve |
| Whether a contract matches the booking data (C-checks) | Whether to book, override or send back |
| ARR/ACV/TCV figures from the policy formulas | Changing the policy (versioned rules) |
| Flags for non-standard clauses | Whether a non-standard clause is acceptable |

## Decisions
| ID | Decision | Options | Decided |
|---|---|---|---|
| DEC-01 | Company | Reuse MoP Cloud / new fictional company | **Reuse MoP Cloud**: one end-to-end story with LeadFlow, RLR and MDH |
| DEC-02 | CRM | Real Salesforce Developer Edition / simulated | **Real Developer Edition, thin slice only** (DD-005). JSON fixtures stay the test source |
| DEC-03 | LLM for extraction | Mistral / Claude / provider-agnostic | **Provider-agnostic interface, Mistral by default** (EU processing). One comparison run against one other model on the same changed clauses: accuracy, cost, stability |
| DEC-04 | Booking ARR for step-up deals | Book Year-1 ARR + scheduled step-ups / book average ARR | **Book Year-1 ARR**, with step-ups kept in a contracted ARR schedule (see DD-002 §6) |
| DEC-05 | Committed credits in ARR | Count / don't count | **Count committed credits**; overage and pay-as-you-go never count |
| DEC-06 | Orchestration | n8n / Salesforce Flow only / Python only | **Salesforce Flow + Approval Process** for quote approvals and the booking gate. n8n deferred (DD-009) |
| DEC-07 | Analytics | PostgreSQL + dbt + Superset / Power BI / Snowflake trial | **Deferred** (DD-011). When built: PostgreSQL + dbt + Superset |
| DEC-08 | Repo | `deal-desk-check` (public, MIT) | The owner creates it and runs git/gh locally |
| DEC-09 | Currency | EUR only / EUR + USD | **EUR only** in v1; a USD contract against an EUR quote is a C-check failure |
| DEC-10 | Where the Salesforce gate sits | Block Stage = Closed Won / block Booking_Status__c = Booked | **Block Booked.** Closed Won is set at signature (C-22 needs close date = last signature date); the check runs on the signed contract, then gates booking |
| DEC-11 | Test set size | 20 / 15 / 10 deals | **15**: 12 with exactly one planted error, 3 clean |
| DEC-12 | ID for the deterministic pre-check card | Renumber DD-007+ / new ID | **DD-014**, built before DD-007; no references break |
| DEC-13 | Precision KPI | K-11 in rules v1.1 / test report only | **K-11 in rules v1.1** (finding precision, test set) |
| DEC-14 | Short non-renewal notice | Add "< 60 days" to N-06 in v1.1 / leave the gap | **Add in v1.1**: notice < 60 days → Deal Desk |

## Governance
- The policy owner is the Director of RevOps, with the CFO as co-approver for any change to discount bands or payment terms.
- Rules are versioned (`deal_desk_rules_vX.Y.json`). Changes go through a pull request labelled `rule-change` with a change note, and the test set is re-run before merge.
- Every approval and override is logged with who, when, which rule and why.
- Salesforce permissions: AEs see their own quotes; only Deal Desk and Finance can clear a check or set Booking Status = Booked.
- Progress is tracked as one GitHub issue per card on a GitHub Project board; every change lands through a pull request that references its card.

## Success measures (portfolio)
Measured on the synthetic test set. These are not claims about real impact.
- 100% of planted booking-blocking errors caught (K-09 recall); a false-positive BLOCK rate of 10% or less on clean deals (K-10); finding precision reported (K-11).
- Zero LLM calls on clean deals; LLM spend logged per contract.
- Every extracted field carries a source snippet that is verified against the text.
- Approval routing matches the answer key for 100% of test quotes, in Python and in the Salesforce Flow.
- A one-page "how to size the value" note: deals per quarter × error rate × cost per correction, plus hours saved per month-end close.

## Acceptance criteria
- [x] Scope, out of scope and stakeholders agreed
- [x] DEC-01 to DEC-14 decided and recorded here
- [ ] Repo `deal-desk-check` created on GitHub with this card as `docs/cards/DD-001_scope.md`
- [ ] Glossary terms (ARR, ACV, TCV, booking, step-up, opt-out) link to DD-002
