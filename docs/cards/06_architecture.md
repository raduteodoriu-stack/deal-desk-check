# Architecture

Two flows that share one rules file. Automation/AI logic is kept apart from analytics/reporting.
MVP: the engine runs offline and hands results to Salesforce by CSV. Dashed boxes are post-MVP.

```mermaid
flowchart LR
  subgraph SF[Salesforce Developer Edition]
    Q[Quote + Quote lines] -->|Record-triggered Flow| T[Approval_Tier__c<br/>Required_Approvers__c]
    T --> AP[Approval Process]
    OPP[Opportunity<br/>Closed Won at signature] -->|Flow| BS[Booking_Status__c = Checking<br/>Contract_Check__c placeholder]
    CC[Contract_Check__c<br/>+ Findings]
    G{Validation rule:<br/>Booked only if PASS<br/>or cleared with reason}
    BK[Deal Desk / Finance:<br/>clear + Book]
  end
  subgraph ENG[Deal desk engine - Python, offline]
    R[(rules v1.2 JSON)]
    QE[Quote engine<br/>ARR/ACV/TCV, approvers]
    PC[Pre-check<br/>hash, template diff, regex]
    EX[LLM extraction<br/>changed clauses only<br/>Mistral default]
    CMP[Comparator<br/>C-rules -> PASS/REVIEW/BLOCK]
    PB[(Standard contract<br/>+ clause playbook)]
  end
  R --- QE & PC & CMP
  PB --- PC
  PC -->|changed / unrecognised| EX --> CMP
  PC -->|standard + slot values| CMP
  QE --> CMP
  CMP -->|CSV import| CC --> G --> BK
  QE -.->|parity check| T
  subgraph LATER[Post-MVP]
    N8N[n8n pipeline]:::later
    AN[PostgreSQL + dbt + Superset]:::later
    SK[Claude skills]:::later
  end
  classDef later stroke-dasharray: 5 5
```

## Why this split
- **Approvals live in Salesforce** (Approval Process + Flow) because it's native, auditable and what admins maintain. Python computes the same approver list for testing; the parity check proves they agree.
- **The gate is on Booking Status, not Stage** (DEC-10). Closed Won happens at signature; the check runs on the signed contract and gates booking.
- **The contract check lives outside Salesforce** because text comparison and LLM calls don't belong in Flow, and the engine must be testable offline.
- **Deterministic before AI.** Hash and diff recognise standard and approved-variant clauses; regex reads numbers and dates. The LLM only sees what's left, so cost stays near zero and results are repeatable.
- **The LLM sits behind a schema.** The comparator never reads raw LLM prose, so a hallucinated clause can't change a decision without an unverifiable snippet, which itself raises C-19.

## Environments and cost
| Component | Choice | Cost | Phase |
|---|---|---|---|
| CRM | Salesforce Developer Edition | Free | MVP |
| Engine | Python, pydantic, pytest | Free | MVP |
| LLM | Mistral low-cost model via API (EU), one comparison model | A few cents for the whole test set | MVP |
| Orchestration | n8n self-hosted (Docker) | Free | Post-MVP |
| Analytics | PostgreSQL + dbt-postgres + Superset (Docker) | Free | Post-MVP |
| Interactive path | Claude skills | Included in the plan | Post-MVP |

## Security and privacy
- Secrets only in `.env`; `.env` is in `.gitignore`.
- Synthetic data only. For real use: document the LLM provider's retention policy and processing region, send only changed clause text (never Account notes or whole contracts when not needed), and keep contract files 7 years for audit or under the company retention policy.
- Salesforce permission sets restrict who can clear a check or set Booked.
