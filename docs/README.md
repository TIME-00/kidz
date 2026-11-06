# Kidz Store Documentation

This folder holds the historical and current-state documentation for **Kidz
Store**, a Flutter mobile shopping application for children's products with a
Supabase backend. It is written for project handover and future maintenance.

## How to read this documentation

The documents follow the order of events. The historical plans and the current
implementation are kept in separate documents.

| # | Document | Covers | Period |
| --- | --- | --- | --- |
| 1 | [Evidence Register and Timeline](history/01-evidence-and-timeline.md) | Sources, how the year and dates were established, timeline, and the register of unverifiable information | All |
| 2 | [Initial Project Plan](history/02-initial-project-plan.md) | Background, objectives, scope, target users, initial requirements, technology choices, original architecture. **[RECONSTRUCTED]** | March 2025 |
| 3 | [Development History](history/03-development-history.md) | GitHub Iterations 1–4, unpublished legacy expansion, original Buyer/Seller/Admin functions, known defects | March 2025 – July 2026 baseline |
| 4 | [July 2026 Improvement Plan](history/04-july-2026-improvement-plan.md) | Problems, objectives, planned changes, priorities, expected outcomes, and what July 2026 executed. **[RECONSTRUCTED]** | June–July 2026 |
| 5 | [Requirements Traceability](history/05-requirements-traceability.md) | Original requirement → improvement requirement → implementation, with status labels | All |
| 6 | [Current State (2026-11-06)](current-state-2026-11-06.md) | Architecture, Supabase Auth, RLS, restored Admin permissions, Android, verification status | 6 November 2026 |

## Status labels

| Label | Meaning |
| --- | --- |
| **PLANNED** | Stated as an intention or recommendation, but not implemented as of 2026-11-06 |
| **IMPLEMENTED** | Delivered substantially as stated (evidence cited) |
| **MODIFIED** | Delivered differently from how it was stated, or later changed, restricted or disabled |
| **UNVERIFIED** | Insufficient evidence |

Provenance tags: **[ORIGINAL]** (quoted from a dated source), **[RECONSTRUCTED]**
(derived from code or commit evidence), **[INFERRED]** (derived from indirect
evidence such as file timestamps).

## Key facts at a glance

- The **original application** was published on GitHub as four iterations on
  **10–11 March 2025** (`Iteration-1` … `Iteration-4`, tags `Version_1` …
  `Version_4`).
- **No original standalone "Initial Plan" or "Improvement Plan" document was found**
  in the inspected repository history or preserved backups. Both plans are reconstructed from the
  README files, the source code, two technical assessments dated
  **17–18 June 2026**, and the improvement commits of **27–28 July 2026**.
- "July" in "July Improvement Plan" refers to **July 2026**. No Kidz activity
  in July 2025 is evidenced.
- The Admin functionality was rebuilt on Supabase Auth with server-side RLS and
  scoped RPCs on **6 November 2026**. Both migrations are present in the hosted
  migration history, independently checked read-only.
- **Final integration is blocked:** Seller order visibility/status changes and
  sales reports fail for other buyers' orders under current RLS. The issue is
  reproduced with isolated synthetic fixtures; a separate minimal fix needs approval.

## Related technical documents (repository root)

| Document | Content |
| --- | --- |
| [KIDZ_PROJECT_DOCUMENTATION.md](../KIDZ_PROJECT_DOCUMENTATION.md) | Screen-by-screen analysis of the baseline application (self-dated 2026-06-17) with an Admin restoration notice |
| [SUPABASE.md](../SUPABASE.md) | Backend configuration, schema, tests, account-deletion design |
| [ADMIN_PHASES.md](../ADMIN_PHASES.md) | Admin Phase 1 design, operator runbook, original Admin function inventory |
| [ADMIN_VERIFICATION.md](../ADMIN_VERIFICATION.md) | Phase 1 verification record |
| [ADMIN_PHASE2.md](../ADMIN_PHASE2.md) | Restored Admin management permissions and deletion semantics |
| [ADMIN_PHASE2_VERIFICATION.md](../ADMIN_PHASE2_VERIFICATION.md) | Phase 2 verification record and file manifest |

## Confidentiality

This documentation contains no credentials, keys, account identities or database
contents. Local operator records and backups are referred to by file name only.
The hosted Supabase project reference is shown as `<project-ref>`.
