# Capability parity — spec

**North-star:** every capability the roster's governance documents describe exists, or the documents say it does not.

## Why this is a goal rather than a cleanup

A governance document is read by agents and operators as a statement of what the system does. When it describes `cadre knowledge delete-ingested` as "the one capability that does [delete ingested content]... steward-only, requiring `--reason`, `--deleted-by`, `--authorized-by`", and the shipped CLI answers `unknown subcommand`, the document is not merely stale — it is a **compliance claim with no implementation behind it**. That is worse than a missing feature, because nothing about reading it reveals the absence.

The repo-consolidation ultragoal that preceded this one found three separate cases where prose and code had diverged and the prose was believed. This goal is the same defect class, aimed at the layer where it does the most damage.

## Baseline, measured 2026-09-01

A full sweep of `roster/shared/`, `roster/workflows/`, `roster/knowledge-store/`, `roster/context-store/`, `roster/RUNBOOK.md` and the role `AGENT.md` files recorded **47 claims**, each tested by running the binary or tracing the enforcing code rather than by reading:

| Status | Count |
|---|---|
| EXISTS | 34 |
| ABSENT | 10 |
| PARTIAL | 2 |
| UNTESTABLE | 1 |

Full inventory: `evidence/P0/capability-inventory.md`.

The ten absences fall into two kinds, and the difference decides the fix:

- **Retired, and the CLI says so** — `ingest`, `stats`. Running them prints what replaced them. The code is honest; the documents have not caught up.
- **Documented, never shipped, and the CLI says nothing useful** — `context`, `retention-report`, `delete-ingested`, `list-staged`, `export-staged`, `deletion-evidence`. All six return `unknown subcommand`, and none is in the retired-verb map, so an operator following a governance document gets no signal at all about where the capability went or whether it ever existed.

## Acceptance criteria

| ID | Criterion | Verification |
|---|---|---|
| AC-1 | No governance document names a `cadre` verb that answers `unknown subcommand` | For every verb named in `roster/**`, running it either succeeds, or is answered by name with what replaced it and why. Zero fall-throughs to the generic unknown-subcommand handler |
| AC-2 | The knowledge-store documents describe the surface that exists | `roster/knowledge-store/{README,SECURITY,AGENT}.md` and `roster/workflows/knowledge-ingestion.md` describe no capability that is ABSENT in the inventory, and name recall for what moved there |
| AC-3 | Retention has a stated owner | Either per-message retention windows are recorded and reportable by a shipped command, **or** every document that describes retention states that it is a steward's paper record with no enforcement, and says what would change that |
| AC-4 | Deletion of ingested content has a stated owner | Either a shipped command deletes ingested content and writes the evidence the documents describe, **or** every document states that this is done in recall, that cadre holds no evidence of it, and what that costs |
| AC-5 | Every enforcement claim is exercised by a test that fails when its check is removed | The two PARTIAL claims — `import-staged`'s self-approval refusal and `ingest-accepted`'s stager/decider match — each gain a mutation-proven test. No enforcement claim rests on a passing happy path |
| AC-6 | A convention is not written as a control | The steward-only rule (recorded UNTESTABLE, since the CLI has no caller identity) is labelled in its document as a convention that nothing enforces, next to the limitation that makes it one |
| AC-7 | The parity property is enforced, not restored | A check fails when a governance document names a `cadre` verb that does not exist. Falsified in both directions before it counts: it passes on the repaired tree and fails when a phantom verb is reintroduced |

**AC-7 is the criterion that matters.** The other six describe one cleanup; AC-7 is what stops the drift recurring, and the preceding ultragoal is the argument for it — an action item written into a retro was not applied the next day, while the same rule written into a gate was.

## Phases

| Phase | Goal | AC covered | State |
|---|---|---|---|
| P0 | Charter and inventory | — | **done** |
| P1 | The CLI stops saying nothing: every documented verb answers by name, and a drift check enforces it | AC-1, AC-7 | **done** |
| P2 | The documents describe what exists | AC-2, AC-6 | not started |
| P3 | Retention and deletion: build or declare | AC-3, AC-4 | not started |
| P4 | The asserted enforcements get mutation-proven tests | AC-5 | not started |

P1 before P2 deliberately. Correcting a document while the CLI still answers `unknown subcommand` leaves every already-distributed copy of that document pointing at nothing — the plugin tree ships copies, and so does every checkout. Making the binary self-describing first means a stale document degrades into a pointer rather than a dead end.

P3 carries the only decisions: whether retention and ingested-content deletion are built or declared absent. Both are governance capabilities, so declaring them absent is a real choice with a cost, not a formality.

## Traceability

| AC | Phase | Evidence | Status |
|---|---|---|---|
| AC-1 | P1 | evidence/P1/CP-5-acceptance.md · cadre `e752376e`, run 33557815235 | verified |
| AC-2 | P2 | evidence/P2/CP-5-acceptance-AC-2.md · cadre `b534fb27`, run 33572609424 | verified |
| AC-3 | P3 | evidence/P3/CP-5-acceptance-AC-3-AC-4.md · cadre `b534fb27`, run 33572609424 | verified |
| AC-4 | P3 | evidence/P3/CP-5-acceptance-AC-3-AC-4.md · cadre `b534fb27`, run 33572609424 | verified |
| AC-5 | P4 | evidence/P4/CP-5-acceptance-AC-5.md — 3 mutations, each failed its test | verified |
| AC-6 | P2 | evidence/P2/ledger.md § AC-6 · cadre `b534fb27`, run 33572609424 | verified |
| AC-7 | P1 | evidence/P1/CP-5-acceptance.md — falsified 8 ways | verified |

## Checkpoint log

| CP | Verdict | Note |
|---|---|---|
| CP-1 | PASS | 7 criteria, 5 phases, from a 47-claim measured inventory |
| CP-2 | PASS | P2 and P4 planned; P1/P3 built from the spec directly |
| CP-3 | PASS | All five phases built |
| CP-3v | PASS on round 4 | P1 took 2 rounds; P2/P3 took 4. Every defect was found by a verifier, none by the author afterwards |
| CP-4 | FAIL:fixable → fixed | Skipped at phase time; run retrospectively under AI-15. Found the AC-7 guard never reached the repository root, leaving AC-2's two root-file corrections unprotected. Fixed in cadre `f378fee1`, falsified four ways — see `evidence/CP-4-integration.md` |
| CP-5 | PASS | All 7 AC accepted against observed artifacts |
| CP-6 | PASS | cadre `b534fb27`, CI run 33572609424 green on the runner |
| CP-7 | PASS | `04-projects/harness/retro/2026-09-01-capability-parity.md` |
