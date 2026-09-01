# SPEC-001: Repository consolidation

> Lane: `full` · Ultragoal: `repo-consolidation` · Date: 2026-08-28

## North-star

Every concern has exactly one owning repository, and the losing implementations are deleted or archived rather than left running.

Today four repositories — `cadre`, `gloop`, `recall`, `agentic-lifecycle` — claim five concerns between them, most of them twice. The lifecycle exists as a rigorous kernel inside cadre and as a placeholder template in agentic-lifecycle. Orchestration exists in cadre's selector and again in gloop. Knowledge storage exists as an 8,123-line component in cadre and again as a 183-file platform in recall. Agent definitions exist in three places. Nothing is wrong with any single implementation; the duplication is the defect, and it is the same defect that produced three silent-drop bugs in one file on 2026-08-28, one scale up.

When this is done, a change to a contract has one place to make it, and no second copy to drift.

## Non-goals

- Building a new product from the parts. This is consolidation, not a product definition.
- Rewriting the lifecycle model. The G1–G10 model is preserved as-is; only its home changes.
- Changing role semantics. The 159 roles and their authority rules move, they do not get redesigned.
- Improving any implementation. A migration that also refactors is two changes wearing one commit.
- Anything in the COG vault.

## Acceptance criteria

| ID | Criterion | Verify method |
|---|---|---|
| AC-01 | The lifecycle kernel builds and tests standalone from its own repository | In a clean clone: `go build ./...` and `go test ./...` exit 0; `bin/agentic-sdlc --version` prints a version |
| AC-02 | cadre carries no kernel source | In cadre: `internal/kernel/`, `cmd/agentic-sdlc/`, and `kernel/` are absent; `go build ./...` exits 0; full suite passes under `CGO_ENABLED=1 go test -tags sqlite_fts5 ./...` |
| AC-03 | cadre and the extracted kernel still agree on the dispatch fingerprint | The golden fingerprint fixture test passes in both repositories, each importing only its own implementation, against a byte-identical fixture |
| AC-04 | cadre's copies of the lifecycle contracts are held to the kernel's | The vendored copies carry a drift check that fails both when a copy is hand-edited and when pointed at a divergent source |
| AC-05 | `agentic-lifecycle` is retired and no third contract definition survives | Repository archived; anything salvaged exists in exactly one other repository; no `run-record` definition exists outside the kernel |
| AC-06 | gloop executes from cadre's governed plan | For each case in cadre's golden corpus, gloop consumes the plan cadre emits and produces an execution plan whose roles are exactly the plan's `agents` (primary, reviewers, support), in a stated pattern |
| AC-07 | Only one selection implementation is reachable by new code | gloop's `selector.Select` and `roster.Select` carry Go `Deprecated:` markers naming `pkg/govplan` as the replacement; the CHANGELOG records the migration and the release that removes them; no code path in gloop other than the deprecated ones produces a plan. `catalog.MatchRoutes` is explicitly **not** in scope — see the 2026-09-01 amendment. **Removal completes at gloop's next major**, tracked as AC-07b |
| AC-08 | Knowledge storage has one owner, and it keeps the fail-closed contract | recall survives and cadre's `internal/knowledge` retrieval engine is deleted. The surviving path preserves all **six** refusals cadre's store makes, recorded as cases in `internal/knowledge/testdata/fail-closed-contract.json`: no query, no classification, no embedding provider, no source-scope decision, all-sources together with filters, and a blank filter entry. Every retrieval is recorded. **Each refusal has a test that fails when its check is removed.** |
| AC-09 | The role catalog has one publishing home | The catalog exists in exactly one repository; each consuming runtime resolves it from there with no vendored second copy lacking a drift check |
| AC-10 | No concern has two owners | The ownership table in `04-projects/agentic-sdlc/planning/repository-ownership-decision.md` names one repository per concern, and for each losing claimant the implementation is absent from its tree. **Removal of cadre's `runner="api"` completes as AC-10b** |
| AC-10b | cadre's endpoint runner retires onto gloop | gloop gains filesystem and command containment for its tool executor -- path confinement, a command allowlist, and the untrusted-brief fence -- and cadre's `internal/orchestration/api_runner_*.go` is absent from its tree, with `runner="api"` either routed through gloop or retired by name |
| AC-11 | The split pipeline runs end to end | A plan from `cadre select` is accepted by an installed released kernel's `agentic-sdlc validate` (exit 0), with that kernel wired to cadre's provider bundle |

**Amended 2026-09-01, then withdrawn the same day.** AC-10 was briefly amended to say that a row naming two implementations of what reading shows to be two concerns is a defect in the row. The reading behind it was sound and independently confirmed — cadre spawns agent CLIs and gloop drives LLM endpoints, and only `runner="api"` overlaps. The amendment was not.

Two reasons it was withdrawn. **This document already rejects that move**, in the AC-08 section: cadre's knowledge store "happens to contain both an engine recall does better and a refusal layer recall lacks. That is one concern with a requirement attached, not two concerns." The resolution there was to move the engine *and port the refusals* — `recall/govern`. The same shape applies here: containment is a requirement attached to the endpoint loop, not a second concern, and the honest resolution is a containment layer in gloop with cadre's runner retiring onto it.

And **it was made at the gate**: the spec was edited after the finding that would otherwise have failed the row, by the party being judged, against a table that same party can edit. This document draws exactly that distinction when defending AC-07 — "there, a criterion was read generously at the gate to make failing work pass. Here the criterion was changed before the gate." AC-10's amendment was the second of those, not the first.

The work is real and is tracked as **AC-10b** rather than dissolved by definition. AC-10 stays open until it lands.

**Amended 2026-09-01 — `catalog.MatchRoutes` leaves AC-07's scope.** The criterion required a `Deprecated:` marker on it. gloop's own CHANGELOG retracts that in public: *"`catalog.MatchRoutes` is **not** deprecated and is not going away. It is the shared low-level matching engine that the deprecated selectors wrap and that `pkg/tenant` also uses. An earlier draft of this entry said it would be removed; that was wrong, and the code never said so."*

`grep -n Deprecated pkg/catalog/*.go` finds nothing, correctly. The criterion was asking for a marker on a function that is not deprecated, so a repository doing the right thing could never have satisfied it. Scope is now `selector.Select` and `roster.Select`, both of which do carry markers naming `pkg/govplan`.

This is the legitimate shape of a criterion amendment and worth contrasting with AC-10's, withdrawn the same day: **AC-07 has not been gated.** Nothing is recorded as verified against the old wording, and the correction makes the criterion match a fact its subject published, rather than making failing work pass.

### Named corrections list — retained as a regression guard

**Amended 2026-08-29.** These were written as the acceptance test for a port: each correction had to survive the move to gloop with a test that fails when its rule is removed. Under the amended shape nothing is ported — cadre keeps governed selection — so the criterion they served no longer applies.

They are kept, not deleted, because they remain the list of things that must not quietly stop working in cadre. Each already has a test there. Their role changes from "prove the port carried them" to "prove nothing removed them":

1. `workflow_shape` declaration guard — a route omitting it is a defect, not a default ([#210](https://github.com/deagy/cadre/issues/210))
2. Overlay widen-only merge, including `exclude_paths` immutability and its inverted polarity
3. `schema_version` increments on any change to the emitted field set, with the release-tag drift check
4. `undeclared_workflow_shape_routes` inside the `dispatch_fingerprint` payload
5. Finding capture accepts everything `finding.schema.json` declares (`40644827`)
6. Envelope dispositions cover the run record's vocabulary (`1988b428`)
7. Artifact manifest field set is closed and documented (`1a301f38`)
8. Denial records validate, including the objection case (`51be12bc`)

## Phases

| Phase | Scope | Covers | State |
|---|---|---|---|
| P0 | Charter and baseline | — | done |
| P1 | Extract the lifecycle kernel to its own repository | AC-01, AC-02, AC-03, AC-04 | **done** |
| P2 | Retire `agentic-lifecycle` | AC-05 | not started |
| P3 | Compose: gloop executes from cadre's governed plan; gloop's own selection retires | AC-06, AC-07 | in progress |
| P4 | Decide and execute the knowledge-store question | AC-08 | not started |
| P5 | Settle cadre's remainder and the catalog's home | AC-09, AC-10, AC-11 | not started |

**Amended 2026-08-28.** Two criteria could not close in the phase that owned them, and both were spec defects rather than execution ones. AC-03 required a plan to be accepted by the *released* kernel — releasing is downstream of the push, which is P1's last task, so half the criterion sat after the phase meant to satisfy it. AC-04 required "no third definition", which needs `agentic-lifecycle`'s schemas gone and is therefore P2's work. AC-03 is now the fixture property alone, the "no third definition" clause moved into AC-05 where it belongs, and the end-to-end pipeline run became AC-11 in P5 where an installed, released, provider-wired kernel actually exists.

## Traceability matrix

| AC | Phase | Evidence row | Status |
|---|---|---|---|
| AC-01 | P1 | ledger P1 § T-06, release | verified |
| AC-02 | P1 | evidence/P1/ledger.md · re-verified on a green runner: `gh run view 33534720412` at cadre `c4447718` | verified |
| AC-03 | P1 | ledger P1 § T-01, T-02 | verified |
| AC-04 | P1 | ledger P1 § T-03 | verified |
| AC-05 | P2 · re-closed P5 | evidence/P2/ledger.md § correction · evidence/P5/ledger.md | verified |
| AC-06 | P3 | | pending |
| AC-07 | P3 | | pending |
| AC-07b | post-P3, at gloop's next major | | deferred |
| AC-08 | P4 | | pending |
| AC-09 | P5 | evidence/P5/CP-2-plan.md | verified |
| AC-10 | P5 | evidence/P5/CP-3-AC10-dispatch-finding.md | **open** — blocked on AC-10b |
| AC-10b | deferred | evidence/P5/CP-3-AC10-dispatch-finding.md | not started |
| AC-11 | P5 | evidence/P5/CP-5-acceptance-AC11.md | verified |

### AC-08 amended 2026-08-29 — one owner, and the contract it must carry

AC-08 originally said "exactly one of cadre's `internal/knowledge` or recall survives" and asked for a documented parity check. Reading recall showed the criterion was forcing a choice between two things that are not alternatives.

recall has the primitives — `Source` and `Namespace` are first-class on `Document`, `query` has `Filter` and `TermFilter` — so all four of cadre's features are expressible. What it does not have is the **posture**. `store.Search(ctx, query, opts)` takes filters a caller may omit, and `Namespace`'s own documentation says search "spans all namespaces present in a store". cadre's `Store.Search` refuses a search with no classification, refuses one with no explicit source scope, refuses both-at-once as ambiguous, requires `AllSources` to be asked for by name, and records every retrieval.

**cadre's store fails closed. recall's library searches everything if you say nothing.**

The tempting move was to split the concern in two, as P3 correctly did for execution and governed selection. That was rejected as pattern-matching. P3's split was right because the two repositories held genuinely different *artifacts* — an execution plan and a governed selection record, neither a subset of the other. Here there is one artifact: a retrieval interface. cadre's happens to contain both an engine recall does better and a refusal layer recall lacks. That is one concern with a requirement attached, not two concerns.

So AC-08 keeps its single owner and names the contract the survivor must carry. The refusals are listed individually and each needs a test that fails when its check is removed, for the same reason AC-07's corrections list was written that way: a posture that survives only as prose does not survive.

### AC-07 amended 2026-08-29 — deprecate, then remove

AC-07 originally required `Select()` and `catalog.MatchRoutes` to be gone. Inventorying dependents before deleting showed both functions are exported and gloop carries release tags (`v0.1.0`, `v0.2.0`), so removing them is a breaking change for any importer.

**Corrected 2026-09-01.** That sentence also said gloop was "MIT-licensed, on pkg.go.dev". Neither is true: `gh api repos/deagy/gloop` returns `private: true, license: null`, and `pkg.go.dev/github.com/deagy/gloop` is a 404, as a private module must be. The deprecate-rather-delete conclusion survives — exported functions with tagged releases are still a compatibility surface — but it survives **weaker** than it was argued. Every importer is inside this account, so the cost of removing them is knowable rather than unbounded, which is an argument for doing it at the next major rather than deferring further.

The criterion measured the wrong moment. What matters is that only one implementation is **reachable by new code**; a deprecated function whose doc comment names its replacement is a migration path with an expiry date, not a competing implementation. So AC-07 now closes on deprecation, and **AC-07b** carries the removal to gloop's next major.

This is an amendment made in the open before the gate, not a claim that the original criterion was already met. The distinction matters because P2's failure was exactly the second thing.

## Risks and open questions

- **The agreement test cannot survive the split.** `internal/canonicaljson/agreement_test.go` imports both `internal/kernel` and `internal/selector` to prove they fingerprint a plan identically, guarding a failure that already happened once and was total. Mitigation: freeze a golden fingerprint fixture in P1 *before* anything moves, plus an end-to-end `cadre select` → `agentic-sdlc validate` check in CI. Deferring this past the move loses the ability to generate the fixture from two live agreeing implementations.
- **Version coupling becomes real.** After P1, a contract change is a two-repository release. Mitigation: the existing `schema_version` discipline extends across the boundary rather than stopping at it.
- **`internal/engine` (6,787 lines) drives G1–G10 but is classed roster-side by the boundary test.** Open: does it follow the kernel, and on what trigger? P1 deliberately excludes it — its coupling is already "ask, don't link", so moving it later costs nothing that moving it now saves.
- **recall parity is unverified.** cadre's store does classification filtering, source scoping with a canonical-path-hash fallback, audit metadata, and a shared-global-store fallback. Whether recall covers those gates AC-08 and is unknown today.
- **Solo maintainer, four active repositories.** The largest risk to this goal is starting a fifth thing before P1 lands.

## Details

Full analysis: [[04-projects/agentic-sdlc/planning/repository-ownership-decision]] · P1 plan: [[04-projects/agentic-sdlc/planning/kernel-extraction-plan]] · Origin: [[04-projects/agentic-sdlc/braindumps/braindump-2026-08-28-1928-scrapping-cadre-for-gloop-and-recall]]
