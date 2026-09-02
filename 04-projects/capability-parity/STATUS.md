# Capability parity — status ledger

North-star: every capability the roster's governance documents describe exists, or the documents say it does not.
Spec: 04-projects/capability-parity/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: — · Overall: **DONE**. North-star gate returned COMPLETE at cadre `b534fb27`, CI run 33572609424

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | evidence/P0/ | 47 claims tested against the binary: 34 exist, 10 absent, 2 partial, 1 untestable |
| P1 | AC-1, AC-7 | **done** | evidence/P1/ | Six verbs answered by name; guard falsified eight ways. cadre `e752376e`, run 33557815235 |
| P2 | AC-2, AC-6 | **done** | evidence/P2/ | Closed on the fourth verification round. cadre `b534fb27`, run 33572609424 |
| P3 | AC-3, AC-4 | **done** | evidence/P3/ | Declared, not built, with cost and reversal conditions stated. Same commit and round as P2 |
| P4 | AC-5 | **done** | evidence/P4/ | Three mutations, each failed its test. The tests existed; the proof did not |

## Open AC-n (no PASS row yet)

None. All seven verified — `evidence/northstar-gate.md`.

The gate did not take the traceability table's word for any of them. It built the binary and ran the verbs for AC-1, read the drift guard's source for AC-7, re-ran the T-03 mutation live and reverted it for AC-5, and read every governance document cited by the round-4 report **in full** rather than at the cited lines — the check that three earlier rounds had failed. It also confirmed the generated plugin and Cline trees are exact copies of the corrected policy rather than independently drifted claims.

One exclusion it examined and accepted: the drift guard skips `roster/orchestration/runs/`, which holds dated run records rather than present-tense claims.

## Next action (resume cold from here)

Nothing. The goal is closed. The three open items below were carried out deliberately and are not blockers.

## Open items carried out of this goal

Three, none of them blocking, all worth someone's attention:

- **The near-duplicate detector lives in scratch, not in the repository.** Four separate times in this goal a stale passage was left standing beside its own correction — `README.md:149/151`, `SECURITY.md:16-17`, `AGENT.md:68`, `AGENT.md:31`. Hand-checking caught none of them reliably; a 30-line similarity check caught all of them at once. It belongs next to `documented_verbs_test.go` as a guard, for exactly the reason AC-7 exists: an action item in a retro was not applied the next day, while the same rule written into a gate was.
- **"Four separation checks, one predicate" is true of three of them.** `DispositionStagedRecord` (`internal/knowledge/staged_store.go:559`) compares the incoming decider against `staged_by` with its own inline comparison — it cannot share `StagedRecordIsSelfApproved`, because the decider arrives as an argument rather than inside the record. That is correct, but nothing would catch the two implementations diverging, which is the drift the single-predicate design exists to prevent.
- **Two capabilities are closer than the documents suggest**, carried forward from P1 and sharpened by the second north-star gate, which checked them against source rather than accepting the prose. `list-staged` is one CLI wire away: `ListStagedRecords(status)` (`internal/knowledge/staged_store.go:253`) is live, filterable, called internally by `staged_ingest.go:184` and covered by tests — no dispatch entry points at it. Staged-deletion evidence is closer still than "a missing reader" suggested: `StagedDeletionEvidenceRows()` (`staged_store.go:367`) already reads `staged_record_deletions` back, and its only callers are `staged_separation_test.go`. The reader exists and is tested; nothing but a test calls it. Both are a CLI wire, not an implementation.

## What this goal cost, and why the number is the finding

P2 and P3 took **four verification rounds** to close. Each round failed for a different reason, and the sequence is the most useful thing this goal produced:

| Round | Cause |
|---|---|
| 1 | Fixed the locations the report named; never enumerated the set |
| 2 | Same, and introduced a verbatim duplicate paragraph via a bad slice edit |
| 3 | Enumerated — but by removed-verb **name**. Four documents assert the capabilities without naming any command |
| 4 | Enumerated by **concept**, plus a mechanical duplicate detector. Passed |

Round 3's fix commit made the name-vs-concept mistake in the same message that diagnosed it as round 2's root cause. Naming a failure mode does not protect against it. The two things that actually worked were mechanical: an enumeration built before any editing, and a similarity check that does not depend on choosing the right search term.

The single worst defect was outside every phase's assumed scope. `RELEASE_NOTES_PHASE4.md` sat at the repository root announcing retention and deletion as COMPLETE and Production Ready — last touched about two hours before the commit that removed those exact commands, never updated, linked from nowhere. AC-3 and AC-4 say *every* document, and that word is what eventually reached it.
