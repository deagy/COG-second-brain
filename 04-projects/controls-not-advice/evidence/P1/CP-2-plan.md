# P1 — CP-2 plan · AC-1, AC-4, AC-5

Triage all fourteen open backlog items. Each gets `control`, `advice`, or `superseded`, with a reason specific to that item.

## The test each disposition must pass

- **`control`** — name the check, and the defect that would make it fail. If the defect cannot be stated as something a machine could observe, this is not a control.
- **`advice`** — state why no check could catch it, specific to this item. "Behavioural" alone is not a reason; the question is *what would a check have to observe*, and why is that unobservable.
- **`superseded`** — name the artifact it targeted and show it is gone or shipped. AC-5 refuses an assumption here.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | Disposition the nine working-practice items (AI-2, 3, 7, 8, 9, 10, 12, 13, 14) | AC-1 |
| T-02 | Disposition the three skill patches (AI-4, AI-5, AI-6) — concrete targets, but a target is not a disposition; ask the same question | AC-1 |
| T-03 | Disposition AI-1 and AI-11, with evidence for or against superseded | AC-1, AC-5 |
| T-04 | Independent read-only challenge over every `advice` call | AC-4 |
| T-05 | Act on or answer each challenge finding | AC-4 |

## What would falsify this phase

Every item classified `advice`. That would mean the triage answered a question about effort with a judgment about feasibility, and AC-4's challenge should catch it. A split with no `control` items is a failed triage, not a finding about the backlog — the two mechanizable candidates were identified before this phase started.

The opposite failure is subtler and worth naming: classifying an item `control` because a check is *conceivable*, when nothing would ever run it. AI-9 is the live risk — repository visibility is scriptable, but a script nothing invokes is advice with extra steps.

## Not in scope

Building anything. P2 does that, after the classification has survived a challenge — the ordering is deliberate, so the challenge lands while changing course is still cheap.
