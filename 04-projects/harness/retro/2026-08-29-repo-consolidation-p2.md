# Retro: repo-consolidation / P2 — retire `agentic-lifecycle`

> Date: 2026-08-29 · Run: `04-projects/repo-consolidation/evidence/P2` · Lane: `full` · Outcome: shipped

## What happened

Compared the ten stage agents against cadre's 159 roles, found nine had counterparts with stronger authority rules and the tenth described a concern cadre owns in five separate places. Committed and pushed 209 lines of work found uncommitted in the working tree, salvaged the intent-brief template into cadre's `product-intent-agent`, added a forwarding notice, and archived the repository. The verifier failed it, the fix went out wrong, and a third commit corrected the record.

## Evidence quality

| AC | Had a PASS row | Observed the artifact | Notes |
|---|---|---|---|
| AC-05 | yes, after one FAIL | yes — GitHub API for the archive flag, `git ls-files` for what survives at HEAD, cross-checks of the pointer's claims against both live repositories | The PASS came only after the criterion was read literally rather than generously |

## What the gates caught

| CP | Verdict | What it caught |
|---|---|---|
| CP-2 | PASS | Established the salvage question early, so the decision was made on measured overlap rather than instinct. |
| CP-3v | **FAIL:fixable** | The one thing the lead got wrong, and it was the clause the lead had explicitly flagged as arguable. Reading your own criterion generously is not a defensible reading. |
| CP-3v (re) | PASS | Asked to check the *history's* honesty as well as the files, and did — quoting the correcting commit rather than only listing what exists now. |
| CP-4 | PASS | Run deliberately because P1's AI-5 recorded it being skipped by omission. Found seven references, judged them prose provenance, and recorded the judgment instead of silently accepting. |
| CP-6 | PASS | Gated. The archive waited; so did the unarchive-and-fix cycle, which was inside the already-approved retirement. |

## Friction

- **The lead read its own acceptance criterion generously.** "No `run-record` definition exists outside the kernel" was argued as met because an archived file cannot drift. The verifier read it literally and was right: read-only stops drift in place, not a reader taking two plausible files as a definition. *A file at HEAD reads as current.*
- **A shell failure published an inaccurate commit.** `git rm` removed the last two files in `schemas/`, deleting the directory; the heredoc that was meant to write a pointer into it failed; the commit went out anyway with a message describing a file it did not contain. The write and the commit were in one compound command, so the failed write never stopped the commit.
- **The repository's visibility was not checked before arguing for a forwarding note.** The note was justified as helping "someone a year from now". It is private, so it helps whoever has access, which is the author.
- **The salvage assessment was made from committed state only.** 209 lines sat uncommitted in the working tree, including the very artifact that turned out to be worth salvaging. "Nothing survives as code" was recommended before that tree was looked at.

## Actions

| ID | Action | Target file | Status |
|---|---|---|---|
| AI-6 | When a criterion has a literal and an intended reading that differ, the literal one governs, or the criterion is rewritten before the phase closes — never read generously in your own favour at gate time. | `.claude/skills/ultragoal/SKILL.md` § acceptance gates | proposed |
| AI-7 | Never put a file write and the commit that describes it in one compound command. Write, verify the file exists, then commit — a failed write must not be able to ship a message about it. | working practice | proposed |
| AI-8 | Assess a repository's salvage value from its working tree as well as its history. Uncommitted work is where the most recent thinking lives. | working practice | proposed |
| AI-9 | Check a repository's visibility before reasoning about who its documentation reaches. | working practice | proposed |

## What worked, and is worth keeping

Asking the re-verifier to check whether the *history* was honest, not only whether the files were right. A fix that leaves a false commit message standing is half a fix, and nothing else in the loop would have looked.

Running CP-4 because the previous retro recorded skipping it. The finding was minor — seven prose references, correctly benign — but it was recorded as a judgment rather than an absence, which is the difference AI-5 was written about.
