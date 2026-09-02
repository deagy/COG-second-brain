# Controls, not advice — status ledger

North-star: every open retro action is either a mechanical check that fails on its own defect, or is recorded as advice with a stated reason it cannot be one.
Spec: 04-projects/controls-not-advice/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P3 · Overall: **in progress**

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | evidence/P0/ | 7 criteria, 4 phases, from a 14-item baseline |
| P1 | AC-1, AC-4, AC-5 | **done** | evidence/P1/ | 9 control, 5 advice, 1 landed. Three CP-3v rounds: under-classified, then over-corrected, then clean. CP-4 PASS |
| P2 | AC-2 | **done** | evidence/P2/ | 9 controls across 3 repos, each falsified both directions. CP-3v took 2 rounds; CP-4 PASS |
| P3 | AC-3, AC-6 | not started | evidence/P3/ | Land every `advice` item where it loads |
| P4 | AC-7 | not started | evidence/P4/ | The disposition question becomes part of writing an action item |

## Open AC-n (no PASS row yet)
AC-3 and AC-6 (P3), AC-7 (P4). AC-1, AC-2, AC-4 and AC-5 closed.

## Next action (resume cold from here)

**P3 — land the five `advice` items where they load, and make the backlog distinguish the three dispositions.**

The five, from `evidence/P1/CP-3-triage.md`, each with the reason that must travel with it:

| ID | Rule | Home |
|---|---|---|
| AI-2 | Verify a naming or destination target exists before putting the decision to the user | `CLAUDE.md` |
| AI-6b | Where a criterion's literal and intended readings differ, the literal one governs | `WORKFLOW.md`, beside § "Amending a gated criterion", which covers the other half |
| AI-7 | Never put a file write and the commit describing it in one compound command | `CLAUDE.md` § Git |
| AI-9 | Check repository visibility before reasoning about who documentation reaches | `CLAUDE.md` |
| AI-14 | Treat an environment note as a finding until shown otherwise | `CLAUDE.md`, and struck once AI-13's control covers its originating instance |

AC-3 requires the reason to be **specific to that item** — "behavioural" is not a reason — and the rule to live somewhere read at session start, not only in the backlog. AC-6 requires the backlog itself to distinguish `control`, `advice` and landed, with its header explaining the split.

AI-2 and AI-9 share one limitation and should say so in the same words: a decision made in conversation leaves no artifact to lint. If that ever becomes checkable, both close together.

## Watch for## Watch for## Watch for

That prediction was correct, and P1 failed on it twice in opposite directions before passing.

Round 1 under-classified — eleven of fourteen as advice — because the narrowing move that turns unmechanizable prose into a checkable half was applied only where it was cheap. Round 2 then over-corrected under criticism: AI-2 was promoted to `control` on an observable that, by its own caveat in the same row, could not reach the defect it was written for, and AI-14 was closed against an artifact that does not exist yet.

The lesson for P2 is the same in both directions: **classify against what the retro actually saw, not against the item's sentence and not against the last piece of feedback received.**

P2 has its own version of this. A control that is built but never invoked is advice with extra steps, and nine controls is enough that at least one will be tempting to declare done on the strength of the file existing. Each needs falsifying in both directions — the defect reintroduced and the check seen failing.
