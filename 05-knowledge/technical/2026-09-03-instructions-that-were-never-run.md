---
type: knowledge
domain: technical
project: cadre–COG Integration
topic: Prose Review vs. Execution For Written Instructions
created: 2026-09-03
last_updated: 2026-09-03
source: cadre/COG integration session — PR #1 review through PR #5 merge
version: "1.0"
tags: ["#knowledge", "#verification", "#review", "#harness"]
related:
  - CLAUDE.md
  - 05-knowledge/technical/2026-09-01-verification-that-depends-on-the-room.md
  - .claude/lib/checkpoint.sh
  - plan/authority-gates.md
---

# Prose Review vs. Execution For Written Instructions

## Overview
Three defects in one session were instructions written into a skill or plan doc for a future agent to execute — not assertions made to a user — and all three passed a high-effort review as prose before failing on first execution. `CLAUDE.md` § "Before you assert it, check it" covers assertions where no artifact exists to check; this is the adjacent case where the artifact does exist (the skill or plan text) but nobody ran it, and review substituted for execution across four passes without noticing.

## Current State
- **Schema-invalid fold.** A Phase 7 approval-record design folded `human_approvals` into the run-record root, which the vendored schema declares `additionalProperties: false`. The fold would have failed the moment anything tried to write it — not a subtle bug, a first-write rejection — and it survived four review passes as prose. [Source: session, cadre/COG integration | 2026-09-03 | confidence: high]
- **Unfillable fold.** A Phase 7 re-entry fold carried AC-ids where `$defs/invalidation` requires G-enums, plus three required fields the source TSV never captured. No re-entry record produced by the existing `checkpoint.sh record_reentry` path could have satisfied the schema it was supposed to feed. [Source: session, cadre/COG integration | 2026-09-03 | confidence: high]
- **A ledger check that always passed.** `worker-publisher`'s proposed approval-ledger check used `grep -P "\tG[89]\t" … | tail`, matching on gate number alone (so it could not distinguish an approval for *this* mutation from any other G8/G9 row ever written) while piping into `tail`, which discards `grep`'s exit status — a ledger with zero matching rows and a ledger with the wrong row both read as pass. [Source: session, cadre/COG integration; corroborated by absence of this pattern in the current `.claude/agents/worker-publisher.md`, confirming it was withdrawn rather than merged | 2026-09-03 | confidence: high]

### Key Details
- **The generalization:** review evaluates whether prose is plausible and internally consistent; only execution evaluates whether the artifact does what it claims. A schema fold, a TSV-to-enum mapping, and a `grep` pipeline are all cheap to run — none of the four review passes ran any of them.
- **Distinct from `CLAUDE.md`'s three existing bullets.** Those cover assertions with no artifact to check before the claim is made (a name, a repo's visibility, an unexplained version pair). This is the mirror case: the artifact exists, the check is mechanical and available, and it simply wasn't run before the instruction was declared done. The fix in each case here was the same one-line move: execute the fold/check once against a real or synthetic input before considering the design finished.
- **Relation to `plan/authority-gates.md`.** The withdrawn Change 3 (gated mutations) is where all three instances originated; that plan doc's own postmortem language is the direct source for two of the three. This note generalizes past that one withdrawn change.

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-09-03 | 1.0 | Initial entry from harvest staging, cadre/COG integration session | harvest-curator |

## Related
- [Checks that depend on the room](./2026-09-01-verification-that-depends-on-the-room.md)
- [Authority gates plan (withdrawn Change 3)](../../plan/authority-gates.md)
