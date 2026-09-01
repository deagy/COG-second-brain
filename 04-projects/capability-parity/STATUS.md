# Capability parity — status ledger

North-star: every capability the roster's governance documents describe exists, or the documents say it does not.
Spec: 04-projects/capability-parity/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P2 · Overall: **in progress** — P1 done; 2 of 7 criteria verified

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | evidence/P0/ | 47 claims tested against the binary: 34 exist, 10 absent, 2 partial, 1 untestable |
| P1 | AC-1, AC-7 | **done** | evidence/P1/ | Six verbs answered by name; guard falsified eight ways across three hand-authored surfaces. Round one FAILed on the replacement claim itself; fixed and re-verified. cadre `e752376e`, run 33557815235 |
| P2 | AC-2, AC-6 | not started | — | The knowledge-store documents describe what exists |
| P3 | AC-3, AC-4 | not started | — | Retention and ingested-content deletion: build or declare. **Carries the decisions** |
| P4 | AC-5 | not started | — | Mutation-proven tests for the two asserted-but-unexercised enforcements |

## Open AC-n (no PASS row yet)
AC-2, AC-3, AC-4, AC-5, AC-6. AC-1 and AC-7 closed at P1.

## Next action (resume cold from here)

**Start P2 — the documents describe what exists** (AC-2, AC-6). Three concrete items are already located:

1. `.agents/skills/knowledge-ingestion/SKILL.md:37` and `.agents/skills/agent-stores/SKILL.md:53` instruct an agent to run `cadre knowledge context`, removed in the Go rewrite. AC-1 makes the verb explain itself; a live instruction to run it is still wrong.
2. `CHANGELOG.md`'s `[Unreleased]` section describes `--source` as newly repeatable on `cadre knowledge context` — a change to a command that no longer exists. It was true when written; it is not now.
3. `roster/knowledge-store/{README,SECURITY,AGENT}.md` describe the full Python-era surface as current. This is the bulk of AC-2.

### What P1 established that P2 should not have to rediscover

The six verbs were **not** phantoms. They were real, tested commands in `roster/knowledge-store/src/cli.py`, removed in `b418031e` when Go replaced Python. Every document describing them was accurate when written. That reframes P2 from "delete wrong claims" to "say what happened", which is a different and more careful edit — and it means the documents' *reasoning* is often still worth keeping even where the command is gone.

Two capabilities are closer than the documents suggest, which P3's build-or-declare decision should weigh:
- `list-staged` is one CLI wire away: `ListStagedRecords(status)` is live, tested and filterable exactly as the documented `--status` flag describes.
- Staged-record deletion evidence **is** retained in `staged_record_deletions`; nothing reads it back. That is a missing reader, not a missing capability.

## Decisions waiting
None yet. P3 will carry two, and both are real: whether retention enforcement and ingested-content deletion get built or declared absent.
