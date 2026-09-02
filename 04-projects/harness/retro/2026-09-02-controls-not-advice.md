# Retro: controls-not-advice (ultragoal, P1–P4 + north-star gate)

> Date: 2026-09-02 · Goal: `04-projects/controls-not-advice/` · Lane: `full` · Outcome: shipped

## What happened

Fourteen backlog items, nine of them working-practice notes, were triaged into `control` / `advice` / `landed`; the nine controls were built and falsified; the five advice items were landed where they load; and the disposition question was written into `/retro` with a lint behind it. The north-star gate returned COMPLETE on all seven criteria and then reported the north-star itself was not literally true — the backlog had grown to twenty rows and five carried no reason. That gap was closed rather than caveated, and round 2 confirmed the claim holds.

## Evidence quality

| AC | PASS row | Artifact observed | Notes |
|---|---|---|---|
| AC-1 | yes | Backlog read and counted independently | 14 ids, AI-6 the only deliberate split |
| AC-2 | yes | Four of nine falsifications reproduced by the gate, both directions | Two Go tests, two shell lints |
| AC-3 | yes | Five rules found in `CLAUDE.md` / `WORKFLOW.md`, reasons judged non-interchangeable | |
| AC-4 | yes | The challenge report re-read; all seven challenges traced to an action or an answer | |
| AC-5 | yes | AI-6a confirmed at `WORKFLOW.md:72`, commit `6d09b29` | |
| AC-6 | yes | 20/20 rows, one vocabulary, header defines it | |
| AC-7 | yes | Rows written from the template's own instructions, run through the lint | |

No PASS rested on a worker's summary. Every gate was briefed to treat the evidence bundle as claims.

## What the gates caught

| CP | Verdict | What it caught |
|---|---|---|
| CP-2 | PASS | P4's plan named its own failure mode in advance — a skill patch with no check behind it would close AC-7 by the method the goal argues against |
| CP-3v | caught 3 rounds across P1, 1 in P2, 1 in P4 | P1: under-classified, then over-corrected. P2: a passing direction claimed but never run. P4: an advice-location check that was a bare substring match |
| CP-4 | **caught 3 defects no component check could** | P3: two rows contradicting the record they summarised. P4: the skill teaching a format its own lint rejected |
| CP-5 | PASS | — |
| CP-6 | PASS | cadre `fd2c2295`, gloop `0088da3`, both green on their runners |
| North-star | **caught the claim being false while every criterion passed** | Five rows dispositioned without reasons |

## Friction

- **P1 failed twice in opposite directions.** Round 1 called eleven of fourteen `advice`, applying the narrowing move that rescues unmechanizable prose only where it was cheap. Round 2 over-corrected under that criticism, promoting AI-2 on an observable its own caveat admitted could not reach the defect, and closing AI-14 against an artifact that did not exist.
- **Eight bugs in P2, every one found by running a check rather than reading it.** Three silently disabled a check while it reported success.
- **Three of nine dispositions did not survive being built**, and two of the nine controls guarantee something narrower than the item that named them.
- **The conventions failed first on the tables that introduced them.** Six rows labelled `done` hours after the three-disposition vocabulary was written; three `control` rows with no citation after the citation rule was added.

## Actions

| ID | Action | Target | Disposition |
|---|---|---|---|
| AI-21 | Build the row-versus-reality cross-check: does a cited commit resolve, does a named file exist, does a control guard what its row says it guards. Six of eight defects in P2 and P3 were a claim contradicting another document or the code, and `duplicate_paragraphs_test.go` catches none of them | new goal | **control — unbuilt** |
| AI-22 | `spec-lint.sh`'s verified-skip trusts the literal word `verified` with no cross-check against an evidence file. Not currently exploitable, and the same shape as the defect this goal closed | `.claude/lib/spec-lint.sh` | **control — unbuilt** |
| AI-23 | AI-13's control guards a discarded path; the incident that named it turned on an unlogged version. Nothing covers the version case | cadre | **control — unbuilt** |
| AI-24 | When a check and a document teaching people to satisfy it are both authored, test the pair — write the artifact the document instructs and run the check on it. CP-3v tested the script against rows it had formatted itself and passed a skill that taught three rejected formats | `.claude/skills/closed-loop/SKILL.md` § CP-3v | **advice** — no artifact exists at authoring time to compare against; the defect is that two artifacts were never brought together, which nothing can observe until someone does it |

## The lesson worth keeping

**A gate that only checks the criteria will pass a goal that has not achieved its purpose.** All seven criteria passed while the sentence they exist to make true was false for a quarter of the backlog. What caught it was asking the gate to judge the claim, not the checklist — and the temptation at that moment was to record a defensible caveat, since the goal was chartered on fourteen items and the extra six arrived from elsewhere.

Taking the caveat would have been reading a criterion generously at its own gate: the exact failure this goal landed a rule against, three phases earlier, in the document the gate was reading. The rule held because something external asked the question, not because the rule was written down. That is the goal's own thesis, demonstrated on itself at the last possible moment.
