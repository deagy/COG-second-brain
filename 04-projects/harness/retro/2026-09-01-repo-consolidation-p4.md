# Retro: repo-consolidation / P4 — cadre's retrieval engine moves to recall

> Date: 2026-09-01 · Run: `04-projects/repo-consolidation/evidence/P4` · Lane: `full` · Outcome: shipped, AC-08 closed

## What happened

Six tasks over two sessions. T-01 captured the fail-closed contract as a fixture while the engine still existed; T-02 deleted 3,297 lines of engine surface; T-03 built `recall/govern`; T-04 routed the CLI through it and retired 23 verbs; T-05 deleted the engine and separated the staged-record store; T-06 verified and measured.

Every task except T-01 changed shape after something was read rather than reasoned about. That is now the phase's defining property rather than an anecdote.

## Evidence quality

| AC | Had a PASS row | Observed the artifact | Notes |
|---|---|---|---|
| AC-08 | yes | yes — all six refusals driven at the built binary by three independent parties: the build, T-04's verifier, T-05's verifier, and CP-4 | The fixture is the authority and every layer is measured against it, including the CLI, which is where the last hole was |

Two claims in this ledger were **wrong when written and corrected by measurement**:

- "recall's full suite green" (T-03). True locally, false on the runner. The contract guard falls back to a sibling `../cadre` checkout that exists on this machine and never in CI, so v0.3.0 was tagged with that job red. Found by CP-4 reading the actual run, not the local suite.
- "a mismatched embedder scores as non-results" (inherited from cadre's own roster docs, repeated in my first draft of the guard). Measured: it returns *every* chunk in scope at score 0 in index order, with an audit row naming the wrong embedder. Worse than empty, and the correction changed the refusal message, the docs and the tests.

## What the gates caught

| CP | Verdict | What it caught |
|---|---|---|
| CP-2 (T-04) | escalated before starting | `delete` and 50 verbs had no destination; the task as written was neither one task nor unblocked |
| CP-2 (T-05) | escalated before starting | The staged workflow was already broken against recall stores — a defect T-04 shipped, invisible to a green suite |
| CP-3v (T-04) | FAIL:escalate | `delete` was not merely unmigrated but **broken**, failing with a raw SQL error against the only store type the migration creates |
| CP-3v (T-05) | PASS | Nothing. Eight checks, all clean — including a migration test that passed for the wrong reason |
| CP-4 | FAIL:fixable ×3 | recall's CI red on the pinned tag; **silent corpus corruption on the first documented command**; a roster workflow documenting a retired verb |

**The gates earned their cost three times over**, and the two escalations happened at CP-2 — before any code was written — which is the cheapest place for a task to change shape.

## The one that matters

`cadre knowledge init` against a genuine pre-migration store reported ordinary success and left the corpus permanently unreachable. recall's schema initializer is additive; it found the old engine's `chunks` table, created what was missing, and returned clean.

T-05's own verifier exercised the migration and passed, because it built its legacy store the way the tests do — from the staged schema alone. Only a store written by the actual pre-migration binary carries the colliding corpus tables.

**A fixture that is plausible is not the artifact.** CP-4 caught it because the task brief handed it a pre-migration binary and told it to walk the upgrade. Nothing about better care inside the fixture would have found it.

## Friction

- **Two verbs, one config path.** `delete` and every staged verb inherited `cfg.Database` from the governed verbs, so both broke the moment that path became a recall store. Neither had a test that opened a real recall store; both were found by running a command by hand. A suite that seeds its own stores cannot see a change in what the configured store *is*.
- **Four stale rationales**, all naming the knowledge store as the reason cadre needs cgo — `platforms_test.go`, `bin/cadre`, `DISTRIBUTION.md`, and `cadre doctor`'s warning. All true when written. The doctor one would have sent an operator to install a C toolchain for the wrong subsystem.
- **The disposition list named three verbs recall does not have.** `recall info`, `recall status`, `recall migrate` — assembled from prose, corrected by reading `cmd/recall/root.go`.
- **The generated plugin tree drifted** and two commits pushed past it. Nothing in `go test` looks at it; only the repository's own generator does.

## Actions

- [ ] Give recall metadata-scoped deletion and store-level embedder identity. Both P4 gaps — retention-scoped deletion, and the mismatch check being an assertion rather than a verification — collapse into these two capabilities 📅 2026-09-15
- [ ] When a task changes what a configured path *points at*, list every consumer of that path before writing code. Both of this phase's shipped defects were consumers nobody enumerated 📅 ongoing
- [ ] Hand every verifier the real artifact, not a fixture, whenever one exists — a prior binary, a real store, a live run. CP-4 found what CP-3v could not, and the only difference was the artifact 📅 ongoing
- [ ] Fix `govern`'s empty-query check to trim: a whitespace-only query currently produces a score-0 result and an audit row. Inherited faithfully from the deleted engine, so not a regression, but it belongs in recall 📅 2026-09-15

## What worked, and is worth keeping

- **Capturing the contract before deleting its implementation.** T-01 froze six refusals as a fixture while both the behaviour and its tests existed. Three separate parties have since been measured against that one file, across two repositories. Same move as P1's fingerprint agreement, same payoff.
- **Escalating at CP-2 rather than building the task as written.** Twice, and both times the task as written was larger and more wrong than the plan's one-line description.
- **Type aliases over re-declared shapes.** The retrieval envelope and `CorpusRecord` are aliases, not copies, specifically because two authorities for one shape is the defect class this consolidation keeps finding.
- **Making the operator state what nobody can verify.** The store's embedder identity has exactly the standing of classification and source scope: asserted, unauthenticated, and impossible to skip by omission. It converted a silent wrong answer into a refusal.
