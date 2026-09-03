---
type: knowledge
domain: technical
project: cadre–COG Integration
topic: What A Control Can And Cannot Attest In A Solo Vault
created: 2026-09-03
last_updated: 2026-09-03
source: cadre/COG integration session; plan/authority-gates.md § Enforcement (withdrawn Change 3 postmortem)
version: "1.0"
tags: ["#knowledge", "#verification", "#harness", "#governance"]
related:
  - plan/authority-gates.md
  - 05-knowledge/technical/agentic-sdlc-governance.md
  - CLAUDE.md
---

# What A Control Can And Cannot Attest In A Solo Vault

## Overview
Change 3's approval gate (a `checkpoint.sh record_approval` command, a per-gate `human_approvals` fold, a ledger check in `worker-publisher`) was withdrawn after four review passes, not patched, because the defect was structural: in a solo vault the agent supplies every field of its own approval record. `record_approval` was a bash command the agent ran, with arguments the agent chose, where the Publisher and the approver are the same person. A control that looks like a control but passes unconditionally is worse than no control — it publishes anyway *and* leaves an audit trail asserting a human said yes.

## Current State
- **The row was strictly weaker than what already existed.** `publish-to-confluence` Phase 4 already waits for an explicit "yes"; `update-knowledge-base` Phase 6 already says never auto-publish. In both, the ledger row would have been written after a real human turn and added nothing. In `team-brief` and `content-factory` — the latter explicitly designed to run unattended on a schedule — there was no human turn to record, so the row would have manufactured the appearance of a control where none existed. [Source: `plan/authority-gates.md` § Enforcement | 2026-09-03 | confidence: high]
- **The mechanisms that can attest a human decision are specifically the ones the agent cannot execute on its own.** A permission prompt (the harness stops and waits on infrastructure outside the agent's control) and the user's own turn (a message the agent did not generate) are the two that hold. A bash command run by the agent, with fields the agent fills, validated by a schema the same agent satisfies — no matter how carefully specified — is not a third option, because the agent controls both the write and the check on the write. [Source: `plan/authority-gates.md` § Enforcement | 2026-09-03 | confidence: high]

### Key Details
- **The test to apply before trusting any future "approval record":** who chose the values in this record, and could that same actor have chosen different values and still passed validation? If the answer is "the agent, and yes," the record attests the agent's intent, not the human's decision, regardless of how the schema is shaped.
- **Existing mitigations this generalizes from, already in CLAUDE.md:** the Skill Post-Condition Rule's insistence on observing the *artifact* rather than a tool's return value is the same principle one layer down — a check is only as good as its independence from the thing it's checking.

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-09-03 | 1.0 | Initial entry from harvest staging, sourced from plan/authority-gates.md's withdrawn-change postmortem | harvest-curator |

## Related
- [Moment-facts and end-of-run documents](./2026-09-03-moment-facts-and-end-of-run-documents.md)
- [Authority gates plan (withdrawn Change 3)](../../plan/authority-gates.md)
