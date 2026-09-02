# P4 — CP-2 plan · AC-7

**AC-7:** the disposition question outlives this goal. `/retro` asks it when an action item is written — is this a check, or advice with a reason? A new item cannot enter the backlog as bare `open`.

## Why this is the criterion that matters

The other six clear a backlog once. This is what stops it refilling with inert rows, and the goal's own premise is the evidence: AI-5 sat open as a working-practice note for four days, and the next ultragoal committed the exact error it named. Fourteen rows accumulated because `retro/SKILL.md` says *"Action items get IDs"* and never asks what kind of item each is.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | `retro/SKILL.md` § Phase 4: ask the disposition question per item, with what each answer requires | AC-7 |
| T-02 | `retro/SKILL.md` § Phase 5: a row entering `BACKLOG.md` carries a disposition, never bare `open` | AC-7 |
| T-03 | `references/retro-template.md`: the Actions table gains a Disposition column, so the question is answered where the item is written rather than recalled later | AC-7 |
| T-04 | A check: `backlog-lint.sh` fails on a row with no disposition, or a `control` row citing neither a commit nor `unbuilt` | AC-7 |

## T-04 is the point

A skill instruction is advice about writing advice. This goal's whole finding is that advice loses to habit, so the phase that makes the question permanent cannot itself be a paragraph asking nicely. **The convention already failed twice on the table that introduced it** — six rows labelled `done`, and three `control` rows with no commit — both caught by counting rather than reading, and both after the rule was written down.

The check must fail on the state the backlog was in this morning, and pass on the state it is in now. That is the falsification, and it is available from git history rather than a fixture.

## What would falsify this phase

A skill patch with no check behind it. That would make AC-7 a rule of exactly the kind this goal exists to convert, closed by the method it argues against.

The second, subtler: a check that only validates shape. A row reading `**control** — foo.sh, commit abc1234` passes a shape check whether or not `foo.sh` exists or `abc1234` resolves. P3's CP-4 found two rows whose *content* was wrong while their shape was perfect. Shape is what this phase can afford; the content cross-check is recorded as the next goal, and this phase should say so rather than imply it is covered.

## Not in scope

The row-versus-reality cross-check carried out of P3. Six of eight defects in P2 and P3 were a claim contradicting another document or the code, and nothing checks that. It is a goal, not a task.
