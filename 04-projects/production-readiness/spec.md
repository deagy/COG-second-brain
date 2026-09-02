# Production readiness — spec

**North-star:** cadre, the lifecycle kernel, recall and gloop each install from their own published artifacts, claim nothing they cannot keep, and record who actually did what.

Three properties, in the order they can be tested: **installable**, **honest**, **attributable**.

## The bar this goal is written to

The operator is the author and their agents, running it daily. That decides several things that would otherwise be open:

- **Licensing matters where a public repository makes a false claim**, not as compliance theatre. A private repo asserting MIT is a defect; a private repo with no licence and no claim is not.
- **Caller identity is being built, and not to defeat an adversary.** With one operator there is nobody to impersonate. What breaks without it is the *evidence trail*: a deletion record naming an actor that was never verified is a record of a string, and this project's whole method rests on evidence being true. That reframing makes the target smaller and sharper than an auth system — derive from a source that already exists locally, and refuse where none does.
- **Retention and erasure stay declared rather than built.** No third party's content enters the store, so the obligation does not arise. What must change is *where* the declaration lives: a document nobody reads at the moment of use is not a refusal.

## Baseline, measured 2026-09-01

| | cadre | lifecycle kernel | recall | gloop |
|---|---|---|---|---|
| Visibility | public | public | public | private |
| Licence | Apache-2.0 | **none** | MIT | **none**, README claims MIT |
| Latest release | `cli-v0.6.5` (Aug 19) | `v0.14.2` | `v0.3.1` | `v0.2.0` (Aug 20) |
| Unreleased commits | 46 | 1 | 1 | 39 |
| CI at HEAD | green | green | green | green |
| Open issues | 1 (`#249`, reproduced) | 0 | 0 | 0 |
| Test files | 235 | 33 | 163 | 148 |

Full assessment: `04-projects/production-readiness/evidence/P0/readiness-assessment.html`.

The two findings that order the work: **the lifecycle kernel is public with no licence while cadre's generated installer downloads it by version** (`internal/generators/plugin_generation.go:235`), and **gloop's README asserts a licence and two public-indexing badges that a private, unlicensed repository cannot support** (`pkg.go.dev/github.com/deagy/gloop` returns 404).

## Acceptance criteria

| ID | Criterion | Verification |
|---|---|---|
| AC-1 | No repository claims a licence it does not carry | For each of the four: the licence GitHub reports matches every licence assertion in that repository's own README and docs. A repository with no licence makes no licence claim |
| AC-2 | Nothing installable resolves an unlicensed dependency | Every artifact cadre's generated installer fetches by name or version comes from a repository carrying a licence. Bounded to the dependency set that installer actually names |
| AC-3 | gloop's self-description is true of gloop **about licensing, visibility and the removed commands** | No badge requiring public indexing, no licence claim, and no live document describing `gloop select`, `gloop roster plan`, `selector.Select`, `roster.Select` or `pkg/selector` as current. Checked by fetching each badge URL and reading every live document end to end |
| AC-3b | Every other claim in gloop's documentation holds against the binary | Deferred from P1 on evidence, not relaxed at its gate. Round 3 found two falsehoods predating this goal — the docs claim a cobra CLI where none exists, and the `--config` contract is documented wrongly in a way that resisted three attempts to state correctly. A claim-by-claim audit of README and `docs/` against a built binary, each command and flag run |
| AC-4 | Actor fields are derived, not asserted | Every command accepting `--staged-by`, `--decided-by`, `--deleted-by` or `--authorized-by` derives the value from a verifiable local source, or refuses to run. The evidence row it writes carries the derived value, and a caller-supplied override is either rejected or recorded as unverified |
| AC-5 | An absent capability is refused where it is reached for | A retention or erasure request is refused at the point of use, naming the gap — not only in `SECURITY.md`. Falsified by running the command and reading what it says |
| AC-6 | Everything on `main` is released | At the goal's close each of the four has zero commits between its latest release tag and `HEAD`, or a stated reason for each that remains. Releases cut in P5 |
| AC-7 | A clean machine reaches a working state | On a machine with none of the four checked out, installing from the artifacts P5 publishes produces a `cadre` that answers `cadre sdlc --version` and `cadre knowledge search`. Run in a container or equivalent, not a developer machine |
| AC-8 | The known defects are closed | `#249` fixed with a test that fails without the fix, and the issue body corrected where it describes deleted Python. The lifecycle kernel has one release home, not two |

**AC-4 is the criterion that carries the most risk of being satisfied dishonestly.** "Derived from a verifiable source" admits a weak reading — an environment variable the caller also sets is not verification. The criterion is met when the value cannot be chosen by the caller at the moment of the call, or the command says plainly that it was.

**AC-7 is the only criterion an outside party could run.** Everything else is checkable from inside a working checkout, which is exactly the position that hides installation defects. It is last because it needs P5's artifacts.

## Phases

| Phase | Scope | AC covered | State |
|---|---|---|---|
| P1 | Licensing and identity: settle gloop on evidence, licence the kernel, make every claim true | AC-1, AC-2, AC-3 | **done** |
| P2 | Known defects: `#249` and its stale issue body, the kernel's two release homes | AC-8 | **done** |
| P3 | Caller identity: derive the actor fields, or refuse | AC-4 | **done** |
| P4 | Refuse the absent capability where it is reached for | AC-5 | **done** |
| P5 | Release all four, then prove a clean machine reaches a working state | AC-6, AC-7 | in progress |
| P6 | Audit gloop's documentation claim by claim against the binary | AC-3b | not started |

**P1 first because it is legal rather than technical**, and because releasing an unlicensed artifact is worse than not releasing. **P5 last because it releases the finished thing** — cutting releases before P3 and P4 would publish a version whose behaviour the goal then changes, and AC-7 would verify an artifact nobody should install.

P2 before P3 deliberately: `#249` is in the config resolution that P3's identity work will read, and fixing it afterwards means fixing it twice.

## What would falsify this goal

Declaring it done from a developer machine. Every criterion except AC-7 is checkable from a working checkout with all four repositories present, which is the exact position that cannot see an installation defect — and this project has already recorded a case where a guard passed locally for months off a sibling checkout that exists on no runner.

## Traceability
| AC | Phase | Evidence | Status |
|---|---|---|---|
| AC-1 | P1 | evidence/P1/CP-5-acceptance.md · cadre-kernel `8da1b13` | verified |
| AC-2 | P1 | evidence/P1/CP-5-acceptance.md · fetch set read from `plugin_generation.go` | verified |
| AC-3 | P1 | evidence/P1/CP-5-acceptance.md · gloop `04c356a` | verified |
| AC-3b | P6 | | pending |
| AC-4 | P3 | evidence/P3/CP-5-acceptance.md · cadre `4da28060`, run 33643385856 | verified |
| AC-5 | P4 | evidence/P4/CP-5-acceptance.md · cadre `0e249942`, run 33648430913 | verified |
| AC-6 | P5 | | pending |
| AC-7 | P5 | | pending |
| AC-8 | P2 | evidence/P2/CP-5-acceptance.md · cadre `0f4bd58c`, run 33635041600 | verified |
