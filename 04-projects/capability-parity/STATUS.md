# Capability parity — status ledger

North-star: every capability the roster's governance documents describe exists, or the documents say it does not.
Spec: 04-projects/capability-parity/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P1 · Overall: **chartered** — baseline measured, nothing built yet

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | evidence/P0/ | 47 claims tested against the binary: 34 exist, 10 absent, 2 partial, 1 untestable |
| P1 | AC-1, AC-7 | not started | — | Every documented verb answers by name; a drift check enforces it |
| P2 | AC-2, AC-6 | not started | — | The knowledge-store documents describe what exists |
| P3 | AC-3, AC-4 | not started | — | Retention and ingested-content deletion: build or declare. **Carries the decisions** |
| P4 | AC-5 | not started | — | Mutation-proven tests for the two asserted-but-unexercised enforcements |

## Open AC-n (no PASS row yet)
All seven. Nothing has been built; P0 measured the gap rather than closing any of it.

## Next action (resume cold from here)

**Start P1.** Six verbs named in governance documents — `context`, `retention-report`, `delete-ingested`, `list-staged`, `export-staged`, `deletion-evidence` — return `unknown subcommand` and are absent from `internal/cli/knowledge.go`'s `retiredVerbs` map. An operator following a policy document gets no signal about where the capability went or whether it ever existed.

P1 is two things:
1. Each of those six answers by name, saying what it is and what replaced it. The map and its message format already exist from the retrieval migration — this extends it to verbs that were never built rather than only those that were retired, which is a distinction the operator does not care about and the code currently makes.
2. **AC-7's drift check**: a test that reads every `cadre <verb>` named under `roster/**` and fails when one is not answerable. Falsify it in both directions before counting it — it must fail when a phantom verb is reintroduced.

Note for whoever picks this up: `context` is the odd one. `cadre context` exists as a top-level command; `cadre knowledge context` is what the documents name and what does not exist. Check which the document meant before answering it — this is a case where the same word is a real capability in one place and a phantom in another.

## Decisions waiting
None yet. P3 will carry two, and both are real: whether retention enforcement and ingested-content deletion get built or declared absent.
