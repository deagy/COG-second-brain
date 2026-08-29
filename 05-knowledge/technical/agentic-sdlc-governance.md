---
type: knowledge
domain: technical
project: Agentic SDLC
topic: Per-Task Denial Contract & Governance
created: 2026-08-28 11:17
last_updated: 2026-08-28
source: periodic-review
version: "1.0"
tags: ["#knowledge", "#agentic-sdlc", "#governance", "#agents", "#spec"]
related:
  - 05-knowledge/product/agentic-sdlc.md
  - 04-projects/agentic-sdlc/planning/per-task-denial-contract.md
  - 04-projects/agentic-sdlc/planning/defect-finding-schema-capture-drift.md
---

# Agentic SDLC — Per-Task Denial Contract & Governance

## Overview
Design work porting three phase-level governance rules down to the per-task verify loop: earliest-affected re-entry point, invalidation cascade, and reviewer-becomes-author transfer. The throughline is that denial must have teeth — it must change what the pipeline does next.

## Current State
- **The gap being filled:** the phase-level loop already has amend/re-entry specified (failed gates return to the responsible artifact owner; material change invalidates that gate *and every dependent downstream gate*), but the per-task loop — which runs far more often and entirely without humans — historically had the weaker rules.
- **What's being added** (per the draft contract): the *kind* of refusal issued, where work resumes, what the refusal voids, how many times it may repeat, and what happens when it repeats too often.

### Denial dispositions (three values)
Every refusal states exactly one disposition, each mapping to an existing mechanism rather than a new one:
- **`amend`** — artifact is defective, correctable within this task. Returns to author with a re-entry step + invalidation set. **Bounded by an amend budget.** The ordinary case.
- **`escalate`** — cannot be resolved inside the task (conflicting instructions, decision exceeds role authority, or a condition `escalation-policy.md` reserves for a human). Leaves the task; **not bounded by the amend budget** (it is not a retry).
- **`halt`** — a stop condition under `halt-authority`'s remit; arrests work beyond this task. Only `halt-authority` may issue it and it may not lift it (requires the condition resolved *and* independently confirmed).

### Key Details
- **Denial vocab ≠ handoff vocab:** `denial` dispositions (`amend`/`escalate`/`halt`) state *what happens next after a refusal*; handoff dispositions (`complete`/`approve`/`request-changes`/`needs-information`/`blocked`) state the *condition of the work*. `blocked` covers both `escalate` and `halt` but they differ in blast radius and who may lift them. The two must not be conflated.
- **Adoption sequence (draft contract):** (0) reconcile `finding.schema.json` with the capture validator — **done, commit `40644827`**; (1) define `denial.schema.json`; (2) add re-entry/invalidation/input-revisions to that schema; (3) add the banded amend budget + liveness timeout to the task brief template (this step changes control flow); (4) telemetry, escape-attribution, `agent-performance-evaluator` coverage finding, nullable `owner`.
- **Validation was done before step 1 by design** — a real run's OD-2 objection did not classify into the three dispositions, which produced the authority-boundary section.

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-08-28 | 1.0 | Initial entry from per-task denial contract spec and peer-review/authority braindump | Periodic review |
| 2026-08-28 | 1.0 | Recorded schema-capture-drift defect as fixed (commit `40644827`) | Defect doc cross-reference |

## Related
- [Agentic SDLC overview](../product/agentic-sdlc.md)
- [Denial contract spec](../../04-projects/agentic-sdlc/planning/per-task-denial-contract.md)
- [Schema-capture-drift defect (fixed)](../../04-projects/agentic-sdlc/planning/defect-finding-schema-capture-drift.md)

## Notes
- **Fixed defect (high severity, commit `40644827`):** schema-conformant agent findings were silently dropped at final-handoff capture because `findingKeys` allowlisted only 6 fields while `finding.schema.json` requires 8. Widened the allowlist to the full schema; regression tests added. Failure was silent by construction.
- **Open:** whether other `*Keys` allowlists (`artifactKeys`, `knowledgeHandoffKeys`) have drifted from their documented counterparts; whether `not_captured` should be visible in the dispatch result.

---

*Last updated: 2026-08-28 | Source: 04-projects/agentic-sdlc planning docs + braindump*
