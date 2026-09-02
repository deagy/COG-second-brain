# P2 — CP-5 acceptance · AC-2

**EVIDENCE AC-2 | CP-5 | PASS** — nine controls, each falsified in both directions and each independently reproduced by a verifier that ran them rather than reading the claims. Artifacts: `CP-3-build.md`, `CP-3v-round1.md`, `CP-3v-round2.md`.

Two are falsified against real history rather than fixtures: the axes check fires on repo-consolidation's P3 plan (four axes) and is clean on P4 (five), which is the check's own before-and-after; and AI-4a/AI-4b fire on the criteria recovered from the spec's first commit.

**EVIDENCE — | CP-4 | PASS** — 6 integration claims. The one real cross-phase risk was that P2 modified `phase-gates.sh`, a gate P1 had already been judged by. Checked by running the pre-AI-5 script and diffing its output across all three goals: byte-identical. Artifact: `CP-4-integration.md`.

**No control is dead.** Verified independently: cadre and gloop CI run the Go tests, and all three scripts are referenced in `.claude/skills/ultragoal/SKILL.md`. The phase's plan said a check nothing invokes would be recorded as advice rather than a control; none needed to be.

## What this phase cost

| Round | Verdict | What it was |
|---|---|---|
| CP-3v 1 | FAIL | AI-4a/AI-4b claimed a passing direction that was never run, and fired on every closed spec |
| CP-3v 2 | PASS | Both directions reproduced on real artifacts; seven others unregressed |
| CP-4 | PASS | — |

**Eight bugs, every one found by running a check rather than reading it.** Three silently disabled a check while it reported success: a finding counted inside a pipeline subshell so the lint printed a defect and exited 0; a greedy `${row##*|*|}` left the verify column empty so the universal-negative check examined nothing; and `tr | while read` dropped the final clause, which was the unbounded one. A fourth killed `phase-gates.sh` mid-run under `set -e`, printing one phase and returning non-zero on two goals that were clean.

The failure CP-3v caught is the inverse of the one AC-2 is written against. The criterion says a check seen only passing is not evidence. Here a check was *claimed* passing on evidence that did not exist — the same error, and only one direction of it is spelled out.

## Carried into P3

- **The verified-skip trusts a string.** `spec-lint.sh` takes the word `verified` in a traceability row at face value; nothing cross-checks it against an evidence file. Not currently exploitable, and the same shape as the defect this goal exists to close.
- **Three dispositions narrowed under construction** (AI-3, AI-13, AI-4a), reconciled in P1's triage. A disposition written before building is a hypothesis about what a check can observe, and three of nine did not survive being built.
