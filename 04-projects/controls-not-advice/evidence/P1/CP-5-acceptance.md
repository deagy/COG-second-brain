# P1 — CP-5 acceptance · AC-1, AC-4, AC-5

Accepted at vault state after three CP-3v rounds and a CP-4 PASS.

**EVIDENCE AC-1 | CP-5 | PASS** — all fourteen backlog ids carry a disposition with a reason: 9 `control`, 5 `advice`, 1 landed. AI-6 spans two rows because it was two rules under one id; verified honest against its original text. Artifact: `CP-3-triage.md`, confirmed by an independent count of every id.

**EVIDENCE AC-4 | CP-5 | PASS** — the split faced an adversarial pass that challenged 7 of the 8 items it was asked to attack. Every challenge was acted on (reclassified with a named observable) or answered. One item, AI-6b, was upheld as clean advice. Artifact: `CP-3v-challenge-round1.md`.

**EVIDENCE AC-5 | CP-5 | PASS** — one closure was claimed without evidence (AI-14 "folded into AI-13", where AI-13 is an unbuilt proposal) and was withdrawn. The single remaining landed claim, AI-6a, was independently confirmed against `WORKFLOW.md` and commit `6d09b29`. Artifact: `CP-3v-round3.md`.

**EVIDENCE — | CP-4 | PASS** — 13 integration claims. No cross-task contradictions; no proposed control duplicates existing cadre tooling; AI-8 and AI-10 confirmed distinct checks. Artifact: `CP-4-integration.md`.

## What this phase cost, and what moved

| Round | Verdict | What it was |
|---|---|---|
| CP-3v 1 | FAIL | Under-classified: 11 of 14 called advice. The narrowing that rescued AI-3 and AI-5 into controls was withheld from every item where applying it meant building something |
| CP-3v 2 | FAIL | Over-corrected: AI-2 promoted to `control` on an observable that by its own caveat could not reach its defect, and AI-14 closed against an unbuilt artifact. Tally double-counted |
| CP-3v 3 | PASS | One stale cross-reference, fixed |
| CP-4 | PASS | — |

Both failures came from the same place: letting the pressure of the moment set the classification rather than the evidence. Round 1's pressure was the cost of building nine checks. Round 2's was having just been told the split was too advice-heavy.

## Carried into P2

- **Two artifact-count questions CP-4 raised and P1 did not answer:** whether AI-3 and AI-13 land as one test or two, and the same for AI-8 and AI-10. CP-4 confirmed AI-8 and AI-10 are *distinct checks*; whether they share a file is a P2 decision.
- **AI-5's rule is prose, not a gate.** `phase-gates.sh` has no task-count logic, so "CP-4 is owed when a phase has more than one task" is a statement for a human or skill to apply. P2 either encodes it or records why it cannot.
- **AI-2 and AI-9 share one unmechanizable shape:** a decision made in conversation leaves no artifact. If that ever becomes checkable, both close together.
