# Controls, not advice — status ledger

North-star: every open retro action is either a mechanical check that fails on its own defect, or is recorded as advice with a stated reason it cannot be one.
Spec: 04-projects/controls-not-advice/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P4 · Overall: **in progress**

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | evidence/P0/ | 7 criteria, 4 phases, from a 14-item baseline |
| P1 | AC-1, AC-4, AC-5 | **done** | evidence/P1/ | 9 control, 5 advice, 1 landed. Three CP-3v rounds: under-classified, then over-corrected, then clean. CP-4 PASS |
| P2 | AC-2 | **done** | evidence/P2/ | 9 controls across 3 repos, each falsified both directions. CP-3v took 2 rounds; CP-4 PASS |
| P3 | AC-3, AC-6 | **done** | evidence/P3/ | Five items landed in CLAUDE.md and WORKFLOW.md; backlog restructured. CP-4 took 2 rounds |
| P4 | AC-7 | not started | evidence/P4/ | The disposition question becomes part of writing an action item |

## Open AC-n (no PASS row yet)
AC-7 (P4) only. Six of seven closed.

## Next action (resume cold from here)

**P4 — make the disposition question part of writing an action item (AC-7).**

`.claude/skills/retro/SKILL.md` § Phase 4 tells a retro to write action items with ids. It does not ask what kind of item each is, which is how fourteen rows accumulated with no way to tell an unbuildable rule from an unbuilt one.

What P4 has to add:

- The retro asks, per item: **can a check observe this defect?** If yes it is a `control` and names the observable. If no it is `advice` and states what a check would have to see and why that is unobservable. A cost argument says so as a cost argument.
- A new item cannot enter `BACKLOG.md` as bare `open`. The vocabulary and the `control — unbuilt` convention are already in the file's header, so P4 wires the retro to them rather than inventing anything.

AC-7 is the criterion that matters, on the same argument as its two predecessors: the other six clear a backlog once, and this is what stops it refilling with inert rows. The evidence is the goal's own premise — AI-5 sat open through an entire ultragoal that then committed the exact error it named.

## Watch for## Watch for## Watch for## Watch for

That prediction was correct, and P1 failed on it twice in opposite directions before passing.

Round 1 under-classified — eleven of fourteen as advice — because the narrowing move that turns unmechanizable prose into a checkable half was applied only where it was cheap. Round 2 then over-corrected under criticism: AI-2 was promoted to `control` on an observable that, by its own caveat in the same row, could not reach the defect it was written for, and AI-14 was closed against an artifact that does not exist yet.

The lesson for P2 is the same in both directions: **classify against what the retro actually saw, not against the item's sentence and not against the last piece of feedback received.**

P2 has its own version of this. A control that is built but never invoked is advice with extra steps, and nine controls is enough that at least one will be tempting to declare done on the strength of the file existing. Each needs falsifying in both directions — the defect reintroduced and the check seen failing.
