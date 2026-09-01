# P1 evidence ledger — the CLI stops answering with silence

Covers AC-1 (no governance document names a verb the CLI answers with `unknown subcommand`) and AC-7 (the parity property is enforced by a falsifiable check).

## CP-3 — build

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-1 | CP-3 | PASS | Six verbs that answered `unknown subcommand` — `context`, `retention-report`, `delete-ingested`, `list-staged`, `export-staged`, `deletion-evidence` — now answer by name, at exit 2, saying what happened to them and what to use instead. cadre `27783e6b`, corrected in `20119003`. |
| AC-7 | CP-3 | PASS | `TestEveryDocumentedKnowledgeVerbIsAnswerable` walks the hand-authored roots, extracts every `cadre <verb>` and `cadre knowledge <verb>` a document names, and fails on any the CLI would meet with silence — citing file and line. |
| AC-7 | CP-3 | PASS | **Falsified in five directions**: a phantom top-level verb in a document, a phantom knowledge verb, a verb dropped from the answerable set while documents still name it, a top-level verb removed from `bin/subcommands.tsv` — four kills — plus ordinary prose ("the cadre binary", "a cadre role") which correctly does *not* trip it. |
| — | CP-3 | PASS | Full gate green and, for the first time in this trail, checked rather than asserted: `bash .claude/lib/ci-status.sh` → `deagy/cadre 20119003 success run 33556372778`. |

### The check's bar is deliberately low

Running, naming a replacement, or admitting the capability went away all pass. "The documents are correct" is not a property a test can decide; "a document cannot send a reader nowhere" is. Choosing the second is what makes this enforceable rather than a periodic cleanup.

### Two drifts found by widening the scan

The first version scanned only `cadre knowledge <verb>`, where the known absences were — so it would have passed while the criterion it enforces was unmet at the top level. Widened before verification rather than after, because shipping a check already believed incomplete and waiting to see whether a verifier catches it is gaming the gate rather than passing it.

Widening it immediately found two instances of the same two-authorities defect this consolidation keeps meeting:

- **`schema-validate` runs, exits 0 on `--help`, and `cadre help` lists it — but it was missing from `bin/subcommands.tsv`.** The table and the help text disagreed about what exists, and `TestEverySubcommandExitsZeroOnHelp`, which reads the table, never covered it.
- **`packagedSubcommandExclusions` excluded `version` from the packaged plugin.** `cadre version` does not exist and is not in the table: a rule guarding a subcommand that had already been deleted.

## CP-3v — round one: FAIL:fixable, and the finding was the fix itself

An independent verifier was asked to attack the thing I was least sure of: replacing `unknown subcommand` with a **positive factual claim** is only an improvement if the claim is true. It was not.

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-1 | CP-3v | **FAIL** | "Never built in this CLI" was false. Five of the six, and `context`, were real, tested, shipped commands in `roster/knowledge-store/src/cli.py` — with handler code and dedicated test modules — removed wholesale in `b418031e` when the Go replacement landed. Literally true of the Go binary; false to anyone who used them. |
| AC-1 | CP-3v | **FAIL** | Three pointers wrong. `deletion-evidence` claimed `show-staged` shows the retained evidence — reproduced: stage, delete, then `show-staged` errors "no staged record with that id", because it resolves by record and the record is gone. `list-staged`'s "no listing verb" concealed that `ListStagedRecords(status)` is live, tested and filterable exactly as the documented flag describes. `delete-ingested` implied a recall CLI delete command that does not exist. |
| AC-1 | CP-3v | **FAIL** | The scan missed `.agents/skills/`, which `plugin_generation.go` reads as an **input root** and where two `SKILL.md` files instruct an agent to run `cadre knowledge context`. Scoped to `roster/` the guard reported parity while live instructions pointed at a dead verb. |
| AC-7 | CP-3v | PASS | The guard itself held: `AnswerableKnowledgeVerbs()` matches the dispatcher for all 34 verbs, and it falsifies in every direction tested. |

**A wrong pointer is worse than no pointer**, because it costs a reader a detour before they discover the capability is not there either — and I wrote all five from memory of a codebase I had been changing all day. That is the specific failure this session has produced twice: reliable when verifying deliberately, unreliable when explaining in passing.

Fixed in `20119003`: the six are answered as *shipped in the Python CLI, removed in the Go rewrite (`b418031e`), never rebuilt*; the three pointers corrected against the binary; both hand-authored roots scanned. Round-two verification is what decides whether AC-1 and AC-7 earn their PASS rows — **they do not have them yet.**

## CP-3v — round two

An independent re-verification of the four round-one findings, plus an instruction to *look* for further unscanned surfaces rather than assume the set complete. Report: `CP-3v-round2.md`.

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-1 | CP-3v | PASS | The reclassification holds. All six verbs' Go history walked independently; the Python-era claim and the `b418031e` attribution check out, and none was rebuilt in Go at any commit. |
| AC-1 | CP-3v | PASS | All three corrected pointers re-tested against the binary, not read: a real record staged and deleted to confirm the deletion-evidence sentence, `ListStagedRecords`'s four claimed properties checked in code, recall's CLI rebuilt to confirm it exposes no delete command. |
| AC-1 | CP-3v | PASS | The `.agents/skills/` widening holds, and a phantom verb in that root is caught. |
| AC-7 | CP-3v | PASS | Guard falsifies in every direction tested; `AnswerableKnowledgeVerbs()` matches the dispatcher across all 34 verbs. |
| — | CP-3v | PASS | CI green at `20119003`; full local gate clean. |
| AC-1 | CP-3v | **FAIL** | `CHANGELOG.md:166` — a third hand-authored surface naming the dead `context` verb, outside the widened scan. |
| AC-7 | CP-3v | **FAIL** | The guard's own failure message still named `neverShippedVerbs`, a symbol the previous commit had renamed everywhere else. |

### The exclusion I nearly talked myself into

My first instinct on the CHANGELOG finding was to exclude it as history, on the same principle that keeps `roster/orchestration/runs/` out of the scan. Checking the heading settled it the other way: the mention is under `## [Unreleased]`, not a dated release.

That distinction is now the rule. A dated section records what was true when it shipped, and rewriting it would falsify the changelog. `[Unreleased]` is a claim about what the next release contains, read as current — so an entry describing `--source` as repeatable on a command the binary no longer has is live, not historical. The scan reads `[Unreleased]` and stops at the first dated heading, falsified both ways: a phantom inside `[Unreleased]` is caught and cited by line; the same phantom inside `0.21.0` is correctly ignored.

**Twice in one phase I nearly narrowed a guard's scope to make it pass**, and the two cases had opposite correct answers — `runs/` should be excluded, `[Unreleased]` should not. Nothing about the instinct distinguished them; only reading the heading did. A scope exclusion argued from principle is still a scope exclusion, and it deserves the same falsification as the check itself.

### Fixed in `e752376e`, and what that means for these rows

Both residuals are fixed and I falsified the changelog scanner in both directions myself. **That is a weaker standard than the rest of this ledger**, and it is recorded as such: the loop budgets two fix-and-verify cycles before escalating, and both are spent, so the delta between `20119003` and `e752376e` carries my own falsification rather than an independent one. Every substantive finding — the classification, the pointers, the scan roots, the guard's behaviour — was independently verified across two rounds.
