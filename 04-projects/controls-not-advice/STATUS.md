# Controls, not advice — status ledger

North-star: every open retro action is either a mechanical check that fails on its own defect, or is recorded as advice with a stated reason it cannot be one.
Spec: 04-projects/controls-not-advice/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: — · Overall: **DONE**. North-star gate COMPLETE; the claim is literally true of all 20 backlog rows

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | evidence/P0/ | 7 criteria, 4 phases, from a 14-item baseline |
| P1 | AC-1, AC-4, AC-5 | **done** | evidence/P1/ | 9 control, 5 advice, 1 landed. Three CP-3v rounds: under-classified, then over-corrected, then clean. CP-4 PASS |
| P2 | AC-2 | **done** | evidence/P2/ | 9 controls across 3 repos, each falsified both directions. CP-3v took 2 rounds; CP-4 PASS |
| P3 | AC-3, AC-6 | **done** | evidence/P3/ | Five items landed in CLAUDE.md and WORKFLOW.md; backlog restructured. CP-4 took 2 rounds |
| P4 | AC-7 | **done** | evidence/P4/ | Retro asks it; `backlog-lint.sh` enforces it. CP-4 took 2 rounds |

## Open AC-n (no PASS row yet)

None. All seven carry PASS rows traced to observed artifacts.

## Next action (resume cold from here)

Nothing. The goal is closed.

The gate returned COMPLETE on all seven criteria and then reported the north-star itself was not literally true: the backlog held 20 rows, not the 14 chartered, and five of them were dispositioned `advice` while stating only where they landed. Accepting that as a caveat was available and defensible. It would also have been reading a criterion generously at its own gate — the failure this goal landed a rule against in P3. The gap was closed instead, and round 2 confirmed the sentence now holds for every row.

## Watch for## Watch for## Watch for## What this goal produced

Nine checks that did not exist, across three repositories, each falsified against the defect that generated it — several against real history rather than fixtures. Five rules landed where they load, each with a reason specific to it. A backlog that says which of its rows anything could ever enforce, and a retro that asks the question when an item is written.

## Watch for

That prediction was correct, and P1 failed on it twice in opposite directions before passing.

Round 1 under-classified — eleven of fourteen as advice — because the narrowing move that turns unmechanizable prose into a checkable half was applied only where it was cheap. Round 2 then over-corrected under criticism: AI-2 was promoted to `control` on an observable that, by its own caveat in the same row, could not reach the defect it was written for, and AI-14 was closed against an artifact that does not exist yet.

The lesson for P2 is the same in both directions: **classify against what the retro actually saw, not against the item's sentence and not against the last piece of feedback received.**

P2 has its own version of this. A control that is built but never invoked is advice with extra steps, and nine controls is enough that at least one will be tempting to declare done on the strength of the file existing. Each needs falsifying in both directions — the defect reintroduced and the check seen failing.
