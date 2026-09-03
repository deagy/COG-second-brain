---
type: knowledge
domain: technical
project: cadre–COG Integration
topic: Recording Events Separately From Summarizing Them
created: 2026-09-03
last_updated: 2026-09-03
source: cadre/COG integration session; plan/authority-gates.md § "Why there is no approval record"
version: "1.0"
tags: ["#knowledge", "#verification", "#harness", "#run-record"]
related:
  - .claude/lib/checkpoint.sh
  - .claude/skills/closed-loop/SKILL.md
  - plan/authority-gates.md
  - 05-knowledge/technical/agentic-sdlc-governance.md
---

# Recording Events Separately From Summarizing Them

## Overview
An approval is a moment-fact; a run-record is a document written at the end of a run. Writing the first into the second is unsatisfiable twice over — the gated skills examined in the cadre/COG integration are not harness entry points, so no run-record exists in an ordinary session, and even inside `/closed-loop` the mutation happens at Phase 6 while the run-record is written at Phase 7. Naming that distinction collapsed five separate review findings from `plan/authority-gates.md`'s review history into one fix. Generalizes to any "record X before Y" requirement where X is an event and Y is a document summarizing events.

## Current State
- **The unsatisfiable design.** A Phase 7 approval fold and a Phase 7 re-entry fold both tried to write moment-facts into a document that is only assembled once, at the end. Both were schema- or field-incompatible on top of the timing problem (see [[2026-09-03-instructions-that-were-never-run]]), but the timing problem alone would have sunk them even with a compatible schema — the document the fact needed to land in did not exist yet at the moment the fact occurred. [Source: `plan/authority-gates.md` § "Why there is no approval record" | 2026-09-03 | confidence: high]
- **The mechanism that already solves this, elsewhere in the same repo.** `.claude/lib/checkpoint.sh` never writes into a summary document at the moment of the event. `record_cp` appends a timestamped row to `evidence/checkpoints.tsv` and a cross-run ledger; `record_reentry` appends to `evidence/re_entry_history.tsv` and the same ledger, with monotonic-attempt validation so a re-recorded earlier attempt can't hide a burned amend cycle. The run-record itself (Phase 7, `04-projects/harness/runs/<id>/run-record.json`) is assembled afterward from those logs — the append-only file is the moment-fact store, the run-record is the end-of-run document built from it. [Source: `.claude/lib/checkpoint.sh` (`record_cp`, `record_reentry`); `.claude/skills/closed-loop/SKILL.md` Phase 7 | 2026-09-03 | confidence: high]

### Key Details
- The tell that a design has this shape: a requirement phrased as "record X before Y happens" where X is instantaneous and Y is a summary artifact produced at a fixed later point in a pipeline. If the summary's phase number is higher than the event's phase number, the fact cannot be written into the summary at the moment it's true — it has to land in an append-only log first.
- This is a design pattern, not a rule specific to approvals — any future "the run-record must show Z" requirement for something that happens mid-run should default to an append-only log plus later assembly, following `record_cp`/`record_reentry`, rather than inventing a new fold into the end-of-run document.

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-09-03 | 1.0 | Initial entry from harvest staging, sourced from plan/authority-gates.md's withdrawn-change postmortem | harvest-curator |

## Related
- [Instructions that were never run](./2026-09-03-instructions-that-were-never-run.md)
- [What can attest a human decision](./2026-09-03-what-can-attest-a-human-decision.md)
- [Authority gates plan (withdrawn Change 3)](../../plan/authority-gates.md)
