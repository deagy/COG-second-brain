# P4 — CP-2 plan: knowledge storage moves to recall, carrying the refusals

Covers AC-08 as amended: recall survives, cadre's retrieval engine is deleted, and the surviving path keeps every refusal cadre's store makes — each with a test that fails when its check is removed.

## Five-axis inventory

AI-11 added the fifth axis after P3 was planned as a port against a destination nobody had opened. It is run first here.

### Axis 5 — what the destination already does

Recorded in `CP-2-finding-recall-parity.md`. recall has every primitive (`Source`, `Namespace`, `Filter`, `TermFilter`) and none of the posture: `Search` takes filters a caller may omit and spans all namespaces by default. The gap is a missing default, not a missing feature.

### Axis 1 — what imports it

Ten files, all in `internal/cli` — the knowledge CLI, its staged-record verbs and their tests — plus one `internal/contextstore` boundary test. `internal/knowledge` itself imports only `internal/config`, `internal/platform` and `internal/textutil`.

The Go surface is small and reached entirely through one CLI command.

### Axis 2 — what names it in prose

Large, and mostly not about the implementation. `knowledge-store` appears in 519 files, `.agents/knowledge-store` in 366, `proposed-knowledge` in 217 — the roster's policy, every role's `knowledge_focus`, the skills. **These describe the concept and the policy, not cadre's Go code.** An agent told to retrieve authorized context does not care which engine answers, so almost none of this moves.

### Axis 3 — what reads its data

`knowledge.db` in 8 files. The staged-record store under `proposed-knowledge/` is a separate, file-based concern with its own schema and is not part of the retrieval engine.

### Axis 4 — what models it as a releasable component

Not a program and not a watched release component. But it is why `internal/release`'s comments say the CLI needs `CGO_ENABLED=1`.

**A hypothesis worth recording because it was wrong.** The obvious inference — migrating to recall's pure-Go SQLite makes cadre cgo-free — does not hold. Three components import `mattn/go-sqlite3`: `internal/knowledge`, `internal/contextstore/database.go`, and `internal/engine/executor/sqlite.go`. Removing one leaves two. Checked before it reached this plan as a promised benefit.

It does open a follow-on that is not P4's: recall's `modernc.org/sqlite` could serve the other two, and cadre's cgo requirement is three migrations away rather than one.

## Tasks

| ID | Task | Covers | Gate |
|---|---|---|---|
| T-01 | Write the fail-closed contract down as a specification with a case per refusal, extracted from `Store.Search` while it still exists | AC-08 | internal |
| T-02 | Delete `sharding.go`, `federation.go`, `rebalancing.go`, `disaster_recovery.go` (937 lines) and their CLI verbs | AC-08 | internal |
| T-03 | Build the governed retrieval layer over recall, carrying all five refusals, with a test each that fails when its check is removed | AC-08 | internal |
| T-04 | Cut `cadre knowledge` over to it | AC-08 | internal |
| T-05 | Delete `internal/knowledge`'s retrieval engine | AC-08 | internal |
| T-06 | Verify: suites, generator checks, and what cgo status actually became | AC-08 | internal |

**T-01 before anything.** The contract exists only as code inside the component being retired, exactly as the fingerprint agreement did in P1. Writing it down while both the old behaviour and its tests are present is the same move, and for the same reason: afterwards it can only be reconstructed from one side's memory of it.

**T-02 before T-03** so that 937 lines of capability a single-operator store does not need are deleted rather than migrated. Deleting them is part of the migration, not scope creep — a store carrying sharding, federation, rebalancing and disaster recovery grew past its purpose, and carrying that across would entrench it.

## The five refusals T-01 must capture

From `internal/knowledge/search.go` and `requireExplicitSourceScope`:

1. A search with no classification is refused.
2. A search with no explicit source scope is refused.
3. `AllSources` together with source filters is refused as ambiguous.
4. A blank source-filter entry is refused.
5. Every retrieval is recorded, with provider, model and result count.

## Risks

- **The posture is the whole point and it lives in one function.** If T-03 reimplements it approximately, the migration trades a fail-closed store for a fail-open one with a similar API, and nothing in recall would object.
- **519 files mention the knowledge store in prose.** Almost none should change, and the risk is a well-meaning sweep that rewrites policy describing a concept because an implementation moved.
- **The staged-record governance is not in scope.** `propose`, `disposition-staged`, `ingest-accepted` and their four self-approval checks are a separate concern from retrieval, and P2 already recorded that they should not be merged with anything.
