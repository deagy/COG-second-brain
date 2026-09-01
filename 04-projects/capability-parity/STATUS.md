# Capability parity — status ledger

North-star: every capability the roster's governance documents describe exists, or the documents say it does not.
Spec: 04-projects/capability-parity/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P2–P4 · Overall: **in progress** — all phases built and pushed; one verification pass covers AC-2 through AC-6

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | evidence/P0/ | 47 claims tested against the binary: 34 exist, 10 absent, 2 partial, 1 untestable |
| P1 | AC-1, AC-7 | **done** | evidence/P1/ | Six verbs answered by name; guard falsified eight ways across three hand-authored surfaces. Round one FAILed on the replacement claim itself; fixed and re-verified. cadre `e752376e`, run 33557815235 |
| P2 | AC-2, AC-6 | **built, verifying** | evidence/P2/ | 7 files corrected; the Python-era design preserved verbatim as a note rather than deleted. cadre `36ba82d6` |
| P3 | AC-3, AC-4 | **built, verifying** | evidence/P3/ | Declared, with what would change it and what its absence costs. cadre `7d0b2ea0` |
| P4 | AC-5 | **built, verifying** | evidence/P4/ | Both call sites mutation-proven independently. The tests existed; the proof did not |

## Open AC-n (no PASS row yet)
AC-2, AC-3, AC-4, AC-5, AC-6 — all built and pushed, none verified. AC-1 and AC-7 closed at P1.

A build is not a criterion. Every one of these rests on my own reading until an independent pass says otherwise, and P1's first verification round failed on exactly that: the fix was sound and the claim it made was false.

## Next action (resume cold from here)

**A single CP-3v pass covers AC-2 through AC-6**, running against cadre `7d0b2ea0`. It was briefed to search for the concept rather than trust the file list in the commits — AC-3 and AC-4 say *every* document, and the phases edited the ones they knew about.

Then the **north-star gate**: a fresh verifier checking that all seven criteria carry PASS rows traced to observed artifacts, briefed not to accept the spec's own traceability table as evidence of itself.

Three things that pass should be pointed at specifically:
- **AC-3 and AC-4 were closed by writing a paragraph.** That is the branch the criteria allow, and it is the branch most vulnerable to a document that states a gap without the required elements — what would change it, what it costs.
- **The design note preserves prose describing a system that does not exist.** The whole question is whether a reader can tell. If it reads as current behaviour anywhere, P2 has moved the defect rather than fixed it.
- **AC-5 was closed by demonstration, not by new tests.** The proof is reproducible mutations, and mutations are only evidence if someone else can reproduce them.

### What P1 established that P2 should not have to rediscover

The six verbs were **not** phantoms. They were real, tested commands in `roster/knowledge-store/src/cli.py`, removed in `b418031e` when Go replaced Python. Every document describing them was accurate when written. That reframes P2 from "delete wrong claims" to "say what happened", which is a different and more careful edit — and it means the documents' *reasoning* is often still worth keeping even where the command is gone.

Two capabilities are closer than the documents suggest, which P3's build-or-declare decision should weigh:
- `list-staged` is one CLI wire away: `ListStagedRecords(status)` is live, tested and filterable exactly as the documented `--status` flag describes.
- Staged-record deletion evidence **is** retained in `staged_record_deletions`; nothing reads it back. That is a missing reader, not a missing capability.

## Decisions waiting
None yet. P3 will carry two, and both are real: whether retention enforcement and ingested-content deletion get built or declared absent.
