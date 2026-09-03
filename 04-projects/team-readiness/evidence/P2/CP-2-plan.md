# P2 — CP-2 plan

**The map, and the claims.** AC-4 (one document explaining the three) and AC-5
(no live document makes a false or dangling claim). Documentation only; no
shipped code, so no release owed.

## What P0 and P1 already established

**AC-4.** No document in any repository states how the three relate. cadre's
`README.md` and `IDENTITY.md` never mention recall. recall never mentions cadre.
What exists is one-directional pointers, each visible only from inside the
dependent repository — including the sole statement of the cadre↔recall
relationship, three directories deep in a subsystem README. No adoption order
exists anywhere.

**AC-5.** P1 built the instrument almost by accident: resolving every markdown
link target and backticked path against the tree found **114 dead references
across 492 live files**. Three-quarters sit in documents that are records:

| Document | Dead refs | Live or record |
|---|---|---|
| `CHANGELOG.md` | 23 | record |
| `PYTHON_ELIMINATION_PLAN.md` | 15 | record |
| `docs/proposals/` | 10 | record |
| `ADR-001-CLI-GO-REFACTOR.md` | 8 | record |
| `DISPATCH_CORE_ROADMAP.md`, `CADRE_CLI_GO_ARCHITECTURE.md` | 10 | record |
| `roster/knowledge-store/proposed-knowledge/` | 5 | record |
| `docs/migration/` | 4 | record |
| everything else | ~39 | **live** |

So AC-5 is roughly 39 live corrections plus a bannering decision, not 114 edits.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | One overview document — what each tool is for, that the kernel records and validates while cadre drives, that recall is the knowledge backend both cadre and gloop use independently, and the adoption order — linked from all three front pages | AC-4 |
| T-02 | A glossary covering the terms a newcomer meets, including the two collisions P0 found: **provider** means three different things across the repositories, and **kernel** means three different things within two of them | AC-4 |
| T-03 | Ship P1's dead-reference enumeration into cadre as a test, reporting `file:line`, so AC-5 has an instrument rather than a one-off script | AC-5 |
| T-04 | Correct the ~39 live dead references the instrument reports | AC-5 |
| T-05 | Banner the record documents, so their dead paths are correct as history rather than wrong as instruction | AC-5 |
| T-06 | recall's five orphaned or contradictory claims: `govern/` undocumented at top level, `cmd/recall/README.md` and `embedder/README.md` unlinked from anywhere, two contradictory `reasoning.NewEngine` signatures in one file, and a "READMEs for all 32 packages" count that is off | AC-5 |

Six tasks, so CP-4 is owed.

## The amendment AC-4 needs, recorded rather than taken

**AC-4's glossary names `lane`, and the term appears in none of the four
repositories.** P0 checked: `grep -rn -i '\blane\b'` across `.md`, `.go` and
`.json` returns zero real hits in cadre, cadre-kernel, recall and gloop.

Defining it would mean inventing vocabulary to satisfy a criterion — which is
the failure mode the harness exists to prevent, pointed at itself. The
criterion's intent is *a newcomer can look up the words these projects use*,
and `lane` is a word from the harness that wrote the spec, not from the
software it describes.

**Amendment:** `lane` is struck from AC-4's list. The remaining eight terms
stand. Recorded here rather than edited silently into the spec, per
`WORKFLOW.md` § Amending a gated criterion — the criterion's substance is
unchanged and no work is avoided by the change.

## Where this is most likely to go wrong

**T-05 is a judgment call wearing a mechanical costume.** Bannering a document
takes it out of AC-5's scope, so a wrong call there silently shrinks the
criterion. The test is whether the document *describes a present state* or
*records a past one* — `PYTHON_ELIMINATION_PLAN.md` describes work that
finished, and `docs/getting-started.md` describes how to use the thing today.
Anything I am unsure about goes to the verifier as a question, not into a
banner.

**T-01 has no falsifier that a machine can run.** "Explains how the three
relate" is satisfied by a document existing and being linked; whether it
*explains* is a reading. The nearest thing to a check is that every claim in it
resolves — which T-03's instrument gives — and that a fresh verifier reading
only that document can state the adoption order back.
