# Retro: repo-consolidation / P3 — compose gloop with cadre's governed plan

> Date: 2026-08-29 · Run: `04-projects/repo-consolidation/evidence/P3` · Lane: `full` · Outcome: shipped

## What happened

Planned as a port of cadre's selection engine into gloop. Reading gloop's selector changed it into a composition: cadre keeps governed selection, gloop executes beneath it, and gloop's own selection retires. Six tasks: a conformance fixture pinning plan validity, `pkg/govplan` reading cadre's plan, refusing past a human gate, equivalence across cadre's 25-case corpus, deprecating gloop's selection, and prose.

The deprecation shipped wrong and was corrected twice.

## Evidence quality

| AC | Had a PASS row | Observed the artifact | Notes |
|---|---|---|---|
| AC-06 | yes | yes — a **live `cadre select` piped across the repository boundary** into gloop; a production-deploy task and a destructive-migration task each refused with exit 2 and empty stdout | Every earlier check ran against a vendored fixture. This was the only run of the real pipeline. |
| AC-07 | yes, after one FAIL | yes — all 147 non-test files searched by a verifier that counted before reading | The criterion this phase got wrong twice |

## What the gates caught

| CP | Verdict | What it caught |
|---|---|---|
| CP-2 | PASS | Ordered T-01 before the port. The reason given was wrong — no window was closing — but the ordering was right: it is the acceptance oracle. |
| CP-3v | FAIL:fixable | An unmarked route-matching path in `pkg/tenant`, and a changelog asserting the opposite of the source. Searched exhaustively and counted first, which is exactly what the lead had failed to do. |
| CP-4 | PASS with caveat | A guard that had been **passing while checking the wrong artifact** since P1: it resolved a legacy CLI on `PATH` at 0.13.2 rather than the pinned 0.14.2, and passed only because 0.13.2 sits on the window's inclusive minimum. |
| CP-5 | PASS | The first and only end-to-end run. |

## Friction

- **The plan was wrong three times, in three different ways.** It called a port what was a composition; it named cadre prose that does not exist (cadre mentions gloop nowhere); and it designed a deprecation against an inventory truncated by `head -10`. Every one surfaced from doing the *next task*, not from a checkpoint.
- **An inventory piped through `head` is not an inventory.** Eleven hits, ten shown. The truncation was invisible in the output and read as completeness. Already filed as AI-10.
- **Prose was corrected in one artifact and left wrong in its twin, twice in this ultragoal.** A commit message described a file its commit did not contain; a changelog said a function would be removed after the source had un-deprecated it. No suite covers prose.
- **An environment note was filed as trivia and was not.** P1 recorded "installed kernel 0.13.2, repository 0.14.2" as a curiosity. It meant a guard had never exercised the kernel the repository depends on, which took a verifier to see.
- **The destination was never inventoried.** AI-1 requires four axes of the source. All four were run on cadre and none on gloop, which is how a port was planned against a repository that already had a selector.

## Actions

| ID | Action | Target file | Status |
|---|---|---|---|
| AI-11 | Add a fifth inventory axis: **what does the destination already do?** AI-1's four axes describe what is being moved; none of them look at what is being moved into. | `04-projects/harness/BACKLOG.md`, and any migration plan | proposed |
| AI-12 | When a correction lands in code, find its twin in prose in the same change — changelog, doc comment, commit message, README. Two of this ultragoal's defects were a corrected artifact beside an uncorrected description of it. | working practice | proposed |
| AI-13 | A guard that resolves an external tool must report which one it resolved. A pass that does not say what it checked is not evidence, and a stale binary shadowing a name on `PATH` is invisible otherwise. | working practice | proposed |
| AI-14 | Treat an "environment note" as a finding until shown otherwise. The version mismatch recorded in P1 as trivia was a guard checking the wrong artifact. | working practice | proposed |

## What worked, and is worth keeping

**Reading before deciding, every time it was done.** Reading gloop's selector turned a port into a composition. Reading cadre's `exclude_paths` implementation found a divergence in gloop's reimplementation of it — of a rule that is correction #2 in this ultragoal's own list. Reading the corpus revealed it covered all three outcomes with real data. Every one of those changed a decision, and none came from reasoning.

**Deviating from two fix hints.** The verifier suggested deprecating `pkg/tenant`'s helper and marking `pkg/roster` deprecated at package level. Both would have marked the wrong thing — an introspection helper because something it does not do moved, and three capabilities to retire one. A verifier's finding is authoritative; its suggested fix is not.

**CP-5 as a real end-to-end run rather than a re-assertion.** Twenty-five corpus cases proved the mapping. One live pipe proved the pipeline. They are not the same claim, and only the second would have caught a broken seam between the repositories.
