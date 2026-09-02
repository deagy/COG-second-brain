# Controls, not advice — spec

**North-star:** every open retro action is either a mechanical check that fails on its own defect, or is recorded as advice with a stated reason it cannot be one.

## Why this is a goal rather than a backlog sweep

The harness backlog holds fourteen open action items, each written after a retro found a real defect. Nine of them are shaped as working practice: a sentence describing what to do differently next time. That shape has now failed measurably, twice, in ways this project can date.

**AI-5**, written 2026-08-29, says: *"Decide whether CP-4 applies to a first phase, or state it begins at P2. Skipped by omission in P1."* It stayed open. The next ultragoal, `capability-parity`, then skipped CP-4 in **all five** of its phases and shipped through two north-star gates without anyone noticing. The action item predicted its own recurrence with precision and prevented nothing.

**AI-19** was written 2026-09-01 and says to diff against HEAD after a `git checkout --`, because a revert restores to HEAD rather than to what you had in mind. One commit later, in the same session, a `git checkout --` silently discarded three real edits. The rule was written, filed, and inert.

Against that, the controls built in the same period held every time they were asked. `ci-status.sh` refused an in-flight run three times in one day. The AC-7 drift guard failed on a phantom verb in eight falsifications. `phase-gates.sh` found the missing CP-4 the instant it was pointed at the goal. A near-duplicate check found in one pass four stale-paragraph defects that three verification rounds had read past.

The pattern is not that advice is worthless. It is that **advice and controls are not interchangeable, and the backlog does not distinguish them** — every row reads `open`, whether it is waiting to be built or can never be built at all. A reader cannot tell an unfixable rule from an unbuilt one, so neither gets done.

This goal forces the judgment per item. Some of these genuinely cannot be mechanised; saying so, with the reason, is a real disposition and not a failure.

## Baseline, measured 2026-09-02

Fourteen open items, from five retros across two ultragoals.

| Shape | Count | Items |
|---|---|---|
| Working practice (no target file) | 9 | AI-2, AI-3, AI-7, AI-8, AI-9, AI-10, AI-12, AI-13, AI-14 |
| Skill patch (concrete target) | 3 | AI-4, AI-5, AI-6 — all `.claude/skills/ultragoal/SKILL.md` |
| Migration-plan guidance (target shipped) | 2 | AI-1, AI-11 — aimed at the repo-consolidation P3 plan, closed weeks ago |

First-pass read on which could become checks, to be tested rather than trusted: **AI-3** (a test that builds external tooling on demand rather than skipping) and **AI-13** (a guard that resolves an external tool without reporting which one) look mechanizable in cadre; **AI-9** (repository visibility) looks scriptable. The rest look behavioural. That read is the lead's own and is exactly what AC-4 exists to challenge.

**Outcome, recorded 2026-09-02:** that read was wrong in both directions. Nine items became controls, not three. Neither of the two items predicted `superseded` survived as one — AI-1 and AI-11 merged into a control, and the only landed item was a half of AI-6 that nobody had predicted. AC-4's challenge is what moved seven of them; see `evidence/P1/CP-3v-challenge-round1.md`.

## Acceptance criteria

| ID | Criterion | Verification |
|---|---|---|
| AC-1 | Every open item carries a disposition | Each of the fourteen is `control`, `advice`, or `superseded`. No row still reads bare `open`. A disposition without a reason does not count |
| AC-2 | Every `control` item has a check that fails on its own defect | For each, the defect it describes is reintroduced and the check fails; removed, and it passes. Both directions demonstrated, output recorded. A check that has only been seen passing is not evidence |
| AC-3 | Every `advice` item states why it cannot be a control, and lives where it loads | The reason is specific to that item, not a generic "behavioural". The rule is in `CLAUDE.md` or a skill body — somewhere read at session start — not only in the backlog |
| AC-4 | The control/advice split is not self-assessed | An independent read-only pass reviews every item classified `advice` and reports any that could be a control. Its finding is acted on or answered, not filed |
| AC-5 | Nothing is closed as superseded without evidence | For each `superseded` item, the artifact it targeted is shown to be gone or shipped. "It looks stale" is not evidence |
| AC-6 | The backlog distinguishes the three dispositions | A reader can tell an unfixable rule from an unbuilt one without opening a retro. The file's own header explains the split |
| AC-7 | The disposition question outlives this goal | `/retro` asks it when an action item is written: is this a check, or advice with a reason? A new item cannot enter the backlog as bare `open` |

**AC-7 is the criterion that matters**, on the same argument as its predecessor's: the other six clear a backlog once, and AC-7 is what stops it refilling with inert rows. The evidence for that argument is this goal's own premise — AI-5 sat open through an entire ultragoal that then committed the exact error it named.

**AC-4 is the criterion most likely to be quietly failed**, because classifying an item as `advice` is the cheap disposition and the lead is the one doing the classifying. Every `advice` call is a decision not to build something, made by the party who would have to build it.

## Phases

| Phase | Scope | AC covered | State |
|---|---|---|---|
| P1 | Triage all fourteen: disposition each with its reason, and evidence any closure | AC-1, AC-4, AC-5 | **done** |
| P2 | Build every `control`, falsified in both directions | AC-2 | **done** |
| P3 | Land every `advice` item where it loads, with its reason | AC-3, AC-6 | **done** |
| P4 | Make the disposition question part of writing an action item | AC-7 | **done** |

P1 before P2 deliberately, and P1 carries AC-4 rather than P2: the classification has to survive an independent challenge *before* anything is built, or the challenge arrives after the effort is sunk and will lose to it.

P4 last, because the question it adds to `/retro` should be phrased from what triage actually taught, not from what this spec guesses triage will teach.

## Traceability
| AC | Phase | Evidence | Status |
|---|---|---|---|
| AC-1 | P1 | evidence/P1/CP-3-triage.md · 14 ids, each dispositioned with a reason | verified |
| AC-2 | P2 | evidence/P2/CP-5-acceptance.md — 9 controls, both directions, independently reproduced | verified |
| AC-3 | P3 | evidence/P3/CP-5-acceptance.md — five items landed, reasons non-interchangeable | verified |
| AC-4 | P1 | evidence/P1/CP-3v-challenge-round1.md — 7 of 8 challenged, all acted on or answered | verified |
| AC-5 | P1 | evidence/P1/CP-3v-round3.md — the one unevidenced closure (AI-14) was withdrawn | verified |
| AC-6 | P3 | evidence/P3/CP-5-acceptance.md — 20/20 rows, one vocabulary, header defines it | verified |
| AC-7 | P4 | evidence/P4/CP-5-acceptance.md — asked at write time, enforced by backlog-lint.sh, falsified on 3 historical states | verified |


## Checkpoint log

| CP | Verdict | Note |
|---|---|---|
| CP-1 | PASS | 7 criteria, 4 phases, from a 14-item baseline |
| CP-2 | PASS | Planned for every phase |
| CP-3 | PASS | All four phases built |
| CP-3v | PASS | P1 took 3 rounds, P2 took 2, P3 and P4 one each |
| CP-4 | PASS | Ran on all four phases. Found 2 defects P3's component checks passed over, and 1 in P4 that CP-3v structurally could not see |
| CP-5 | PASS | All 7 AC accepted against observed artifacts |
| CP-6 | PASS | Vault, cadre `fd2c2295`, gloop `0088da3` |
| CP-7 | PASS | `04-projects/harness/retro/2026-09-02-controls-not-advice.md` |
