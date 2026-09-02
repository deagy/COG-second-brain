# P4 — CP-5 acceptance · AC-7

**EVIDENCE AC-7 | CP-5 | PASS** — the disposition question is asked where an action item is written, and a check enforces it.

`retro/SKILL.md` § Phase 4 asks, per item, whether a check can observe the defect, and states what each answer requires. § Phase 5 requires every row entering the backlog to carry its disposition and to run the lint. The template's Actions table carries the column, so there is no bare-`open` shape left to leave blank. Artifact: `CP-3v-round1.md`.

**EVIDENCE AC-7 | CP-5 | PASS** — `.claude/lib/backlog-lint.sh`, falsified against three real historical states recovered from git:

| State | Findings |
|---|---|
| The backlog at the start of the day — 14 bare `open` rows | 14, exit 1 |
| The six rows labelled `done`, a fourth vocabulary | 20, exit 1 |
| After the convention was written into the header, before it was followed | 4, exit 1 |
| Now | clean, exit 0 |

The third row is the argument for the check in one line: the rule had been recorded and was not being followed, on the table that introduced it.

**EVIDENCE — | CP-4 | PASS** — 12 claims, round 2. Artifact: `CP-4-integration.md`.

## What the gates caught

| Gate | Verdict | What it found |
|---|---|---|
| CP-3v | PASS, one note | The advice-location check was a bare substring match: any string containing `SKILL.md` passed, including a path to nothing. Now resolved against the filesystem |
| CP-4 round 1 | **FAIL** | The skill taught three disposition formats and the lint accepted a fourth |
| CP-4 round 2 | PASS | Every documented spelling passes; bad rows still fail; the backlog was not edited to make the lint pass |

### The CP-4 finding, because it is the clearest integration defect of the goal

`retro/SKILL.md` Phase 4 wrote **`control`**, Phase 5 wrote `control`, the template wrote plain `control` — and the lint accepted only `**control**`, the form existing rows happened to use, a convention stated nowhere. An author following either document failed on their first attempt, for a reason neither document could tell them, in the phase whose whole subject is making a rule stick.

**CP-3v could not have found it.** It tested the script against rows it had formatted itself and a live backlog already correct. Both directions were exercised and the falsification was real. But a check and the document teaching people to satisfy it are two artifacts, and testing one against itself proves nothing about the pair.

Fixed on both sides rather than by picking a winner: the lint reads the word and ignores decoration, and the template shows both row kinds in forms that pass.

## Carried out of P4

- **The row-versus-reality cross-check**, carried from P3 and still the honest next goal. `backlog-lint.sh` resolves a cited *advice* file, which is one square inch of content-truth; it does not resolve a cited commit, or check that a control guards what its row says it guards. P3's CP-4 found two rows with perfect shape and wrong content.
- The three limitations carried from P2 — the verified-skip trusting a string, AI-13 being narrower than its retro incident, AI-14's version case uncovered — re-confirmed by CP-4 as still stated and nowhere claimed closed.
