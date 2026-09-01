# Capability parity — status ledger

North-star: every capability the roster's governance documents describe exists, or the documents say it does not.
Spec: 04-projects/capability-parity/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P1 · Overall: **in progress** — P1 built and pushed, round-two verification in flight

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | evidence/P0/ | 47 claims tested against the binary: 34 exist, 10 absent, 2 partial, 1 untestable |
| P1 | AC-1, AC-7 | **built, verifying** | evidence/P1/ | Six verbs answered by name; guard falsified five ways. Round one FAILed on the replacement claim itself and is fixed in cadre `20119003`; PASS rows pending round two |
| P2 | AC-2, AC-6 | not started | — | The knowledge-store documents describe what exists |
| P3 | AC-3, AC-4 | not started | — | Retention and ingested-content deletion: build or declare. **Carries the decisions** |
| P4 | AC-5 | not started | — | Mutation-proven tests for the two asserted-but-unexercised enforcements |

## Open AC-n (no PASS row yet)
All seven. AC-1 and AC-7 are built, pushed and CI-green (`run 33556372778`), but neither has a PASS row: round-one verification failed them and round two has not returned. A build is not a criterion.

## Next action (resume cold from here)

**Await round-two CP-3v on AC-1 and AC-7**, then close P1 or fix again. Note the loop's rule: this is attempt two of two before the honest move stops being "patch it" and becomes "escalate the decision".

If it passes, **P2 is next** and its first item is already identified: `.agents/skills/knowledge-ingestion/SKILL.md:37` and `.agents/skills/agent-stores/SKILL.md:53` both instruct an agent to run `cadre knowledge context`, which was removed in the Go rewrite. AC-1 is satisfied — the verb now explains itself — but a live instruction to run a dead command is exactly what AC-2 exists to fix.

### What P1 established that P2 should not have to rediscover

The six verbs were **not** phantoms. They were real, tested commands in `roster/knowledge-store/src/cli.py`, removed in `b418031e` when Go replaced Python. Every document describing them was accurate when written. That reframes P2 from "delete wrong claims" to "say what happened", which is a different and more careful edit — and it means the documents' *reasoning* is often still worth keeping even where the command is gone.

Two capabilities are closer than the documents suggest, which P3's build-or-declare decision should weigh:
- `list-staged` is one CLI wire away: `ListStagedRecords(status)` is live, tested and filterable exactly as the documented `--status` flag describes.
- Staged-record deletion evidence **is** retained in `staged_record_deletions`; nothing reads it back. That is a missing reader, not a missing capability.

## Decisions waiting
None yet. P3 will carry two, and both are real: whether retention enforcement and ingested-content deletion get built or declared absent.
