# P4 — CP-3 build · AC-7

## The question is asked where the item is written

`retro/SKILL.md` § Phase 4 previously read *"Action items get IDs (`AI-01`…)"* and asked nothing else. It now asks, per item: **can a check observe this defect?** — with what each answer requires. A `control` names the observable; an `advice` states what a check would have to see and why that is unobservable, specific to the item, and says so as a cost argument if the check is possible but not worth its infrastructure.

The section says plainly that both are legitimate. Advice is not a lesser answer and a backlog of advice is not a failure. **A backlog that cannot tell the two apart is**, because an unbuildable rule and an unbuilt one look identical and both wait forever.

§ Phase 5 now requires every row entering the backlog to carry its disposition, never a bare `open`, and to run the check. The template's Actions table gained a Disposition column, so the question is answered where the item is written rather than recalled later.

## The check, because a skill instruction is advice about writing advice

`.claude/lib/backlog-lint.sh` fails on:

- a row with no disposition;
- a `control` citing neither a commit nor `unbuilt` — so a built control and an unbuilt one cannot read the same;
- an `advice` that does not name where it landed — a rule only in the backlog is a rule nobody reads.

**Falsified against three real historical states**, recovered from git rather than constructed:

| State | Result |
|---|---|
| The backlog at the start of today — 14 bare `open` rows | 14 findings, exit 1 |
| After P3's restructure, before citations were completed | 4 findings, exit 1 — the three uncited controls and one more |
| The six rows labelled `done`, a fourth vocabulary | 20 findings, exit 1 |
| Now | clean, exit 0 |

The second row is the one worth keeping: it is the state **after** the convention was written into the header, and it still failed. The rule had been recorded and was not being followed, on the table that introduced it, which is the argument for the check in one line.

## What this check does not do, stated rather than implied

It verifies a row **answers** the question, not that the answer is **true**. A `control` citing a file that does not exist, or a commit that does not resolve, passes here. P3's CP-4 found two rows whose shape was perfect and whose content was wrong — AI-14 claiming coverage AI-13 does not give, and AI-1 labelling a built control as advice.

Shape is what this phase can afford. The content cross-check is carried out of P3 as the next goal, and the script's own header says so rather than letting a reader assume it is covered.

## Strengthened after CP-3v

The advice-location check was a bare substring match: any string containing `SKILL.md` satisfied it, including a path to nothing. It now resolves the cited file and fails if it does not exist — the one piece of content-truth this check can afford, since a file either opens or it does not. Falsified: a row citing `.claude/skills/nonexistent/SKILL.md` fails.

That closes a gap between what the script did and what its header claimed. The header said the check verifies a row *answers* the question rather than that the answer is *true*; a rule pointing at a file nobody can open has not landed, and calling that "answered" was too generous a reading of its own limitation.

**Correction to the record:** the commit I supplied to CP-3v for the six `done` rows was `5a73393`, which is wrong. The correct commit is `d188941`, and it does produce the claimed 20 findings at exit 1. The build record cites no SHAs, so nothing written down was wrong — but the verifier was handed a bad one and had to find the right one itself.
