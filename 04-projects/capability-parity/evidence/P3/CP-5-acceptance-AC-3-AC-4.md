# P2/P3 — CP-5 acceptance · AC-2, AC-3, AC-4

Verified at cadre `b534fb27` by a fresh-context read-only pass (round 4). Full report with file:line evidence for all 17 claims: `evidence/P2/CP-3v-round4-AC-2-3-4.md`.

**EVIDENCE AC-2 | CP-5 | PASS** — `roster/knowledge-store/{README,SECURITY,AGENT}.md` and `roster/workflows/knowledge-ingestion.md` read in full; each describes only the shipped surface and names recall for what moved there. `README.md:144-151` maps every removed verb to its replacement; `AGENT.md:15,17,31,33,51,67` states the two unperformable duties consistently at every point they arise.

**EVIDENCE AC-3 | CP-5 | PASS** — every document describing retention states it is an unenforced paper record and says what would change that: `SECURITY.md:38-44`, `AGENT.md:53`, `knowledge-use-policy.md:24-30`, `knowledge-ingestion.md:15`, `retention-and-deletion-executor/AGENT.md:15`.

**EVIDENCE AC-4 | CP-5 | PASS** — every document describing deletion of ingested content states cadre holds no capability and no evidence trail, and what that costs: `SECURITY.md:38,46`, `AGENT.md:51,67`, `knowledge-use-policy.md:26,32`, `knowledge-ingestion.md:28`, `dispatch-contract.md:25`, `internal/knowledge/README_CLI.md:172-186`.

Generated trees (`provider/`, `plugin/`, `cline-plugins/`) confirmed by diff to mirror `roster/` consistently.

## Four rounds, four distinct causes

Worth recording, because the phase closed on the fourth attempt and the pattern is the finding.

| Round | Verdict | What it missed, and why |
|---|---|---|
| 1 | FAIL | Fixed the locations the report named; never enumerated the set |
| 2 | FAIL | Same, plus introduced a verbatim duplicate paragraph via a slice-order edit — stale copy 19 lines above its own correction |
| 3 | FAIL | Enumerated, but **by removed-verb name**. Four documents assert the capabilities without naming any command ("TTL-based expiration", "does have deletion capability"), so no name-based grep could match them |
| 4 | PASS | Enumerated by capability concept, plus a mechanical near-duplicate detector |

The recurring cause across rounds 1-3 was searching for a name rather than the concept — the same failure this ultragoal's predecessor recorded twice (AC-05, and the `delete` verb defect). Round 3's fix commit made the mistake in the same message that diagnosed it.

The duplicate-paragraph shape appeared **four separate times**: `README.md:149/151`, `SECURITY.md:16-17` above its own § Storage rules, `AGENT.md:68` below its own banner, and `AGENT.md:31` immediately above the corrected line 32. Hand-checking caught none of them reliably. `/tmp/claude-1000/dupe-check.py` now reports zero pairs across these files; it belongs in the repository as a guard rather than in scratch, which is an open item.

The worst single defect was not in `roster/` at all: `RELEASE_NOTES_PHASE4.md`, last touched two hours before the rewrite that removed what it announces as COMPLETE and Production Ready, unlinked from anywhere, reading as a live feature list at the repository root for two and a half weeks.
