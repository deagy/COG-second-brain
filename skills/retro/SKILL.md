---
name: retro
description: >
  CP-7 retrospective: audit checkpoints, evidence quality, action items,
  and harvest candidates. Closes the V-model cycle and feeds the next run.
  Use via /retro after ship, escalate, or significant session.
---

# /retro — CP-7 close the V

Every non-`tiny` shipped or escalated run gets a retro. Retro is **advisory** but strongly expected: it is how the harness improves.

## When to run

- After CP-6 ship (approved publish, merged PR, vault deliverable done)
- After escalate (capture why verifier failed)
- End of an `/ultragoal` phase (one retro per phase)
- Manual: `/retro <run-dir or spec path>`

## Phase 1 — Gather evidence bundle

Read:

1. Spec or card description + acceptance criteria
2. `04-projects/harness/runs/<id>/evidence/` (ledger, checkpoints.tsv, CP-* files)
3. `.claude/logs/loop-ledger.tsv` (last rows for this run)
4. `04-projects/<goal>/STATUS.md` if an ultragoal phase

## Phase 2 — Checkpoint audit

For each CP the lane required, mark Expected vs Actual vs Gap:

| CP | `tiny` | `normal` | `full` |
|---|---|---|---|
| CP-1 spec | skip | required | required |
| CP-3v component | skip | required | required |
| CP-4 integration | skip | skip | required if multi-task |
| CP-5 acceptance | if mutate | required | required |
| CP-6 ship | if external | if external | required |

## Phase 3 — Evidence quality pass

Ask:

- Any AC-n shipped without a PASS evidence row? (traceability violation)
- Any PASS row where observation is tool-return not artifact? (confident-but-unchecked)
- Any criterion that wasn't falsifiable? (fix in next spec)

## Phase 4 — Write retro

Copy `references/retro-template.md` to:

`04-projects/harness/retro/YYYY-MM-DD-<slug>.md`

Fill all sections. Action items get IDs (`AI-01`…) **and a disposition**.

For each one, ask: **can a check observe this defect?**

- **`control`** — yes. Name the observable: what would a program look at, and what would make it fail. If you cannot state that, it is not a control yet.
- **`advice`** — no. State what a check would have to observe and *why that is unobservable*, specific to this item. A reason that would fit three other items is not a reason for this one. If a check is possible but not worth its infrastructure, say that as a cost argument — otherwise nobody can revisit it when the cost changes.

Both are legitimate. Advice is not a lesser answer, and a backlog of advice is not a failure — but a backlog that cannot tell the two apart is, because an unbuildable rule and an unbuilt one then look identical and both wait forever.

The evidence for asking at all: `AI-5` sat open as a working-practice note for four days, and the next ultragoal committed the exact error it named. Fourteen items had accumulated before anyone asked which of them anything could enforce.

## Phase 5 — Feed forward

1. **Harvest**: append action items + lessons to today's harvest staging
2. **Backlog**: add `AI-n` rows to `04-projects/harness/BACKLOG.md` if harness work. **Every row carries its disposition — never a bare `open`.** A `control` cites where its check lives, or reads `control — unbuilt` while it waits; an `advice` cites where the rule landed. See that file's header for what closes each. Then:

   ```bash
   bash .claude/lib/backlog-lint.sh
   bash .claude/lib/crossref-lint.sh
   ```

   The second is for rows that talk about each other. Three defects in one
   ultragoal were a row making a claim another row contradicted — a merged
   item with two dispositions, a coverage claim the covering row denied, a
   reference to a control that had been withdrawn — and all three had
   perfect shape.

   It reads the word and ignores the decoration, so `control`, **control** and
   **`control`** are the same answer. What it will not accept is a row that
   answers nothing.
3. **STATUS.md**: if an ultragoal phase, advance the phase state + log open `AC-n`
4. **Spec checkpoint log**: update spec `## Checkpoint log` CP-7 row
5. Record: `bash .claude/lib/checkpoint.sh record <run-dir> CP-7 PASS "retro: <path>"`

## Output to the user

TL;DR: outcome, top lesson, top action item, retro path.
