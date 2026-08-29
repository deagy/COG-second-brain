# P3 / T-05 — escalated before touching anything

AC-07 requires gloop's `Select()` and `catalog.MatchRoutes` to be gone. Inventorying dependents first, per AI-1, showed this is not the internal cleanup the plan assumed.

## What T-05 actually is

`gloop` is a **published Go module**. Tags `v0.1.0` and `v0.2.0` exist; the README carries a Go Report Card badge and a pkg.go.dev reference; it is MIT-licensed and describes itself as an SDK.

`selector.Select` and `catalog.MatchRoutes` are **exported**. Removing them is a breaking API change for anyone importing `github.com/deagy/gloop/pkg/selector` or `pkg/catalog`.

`gloop select` is a released CLI command, and it exists only to call `Select()`. Retiring the function retires the command.

## Dependents

| Caller | Kind |
|---|---|
| `cmd/gloop/cmd/select.go:91` | the `gloop select` CLI command |
| `pkg/selector/selector_test.go`, `pkg/catalog/coverage_test.go` | tests describing the behaviour being retired |
| `pkg/selector/doc.go` | package documentation |

Nothing else in gloop calls either. The internal surface is as small as it looked; the *published* surface is the issue.

## The three answers

**Remove now, release as a breaking change.** Satisfies AC-07 immediately. gloop goes to v0.3.0 (or v1 if the SDK is considered stable) with a changelog entry saying selection moved to cadre and `govplan` reads its output. Anyone importing `Select` breaks on upgrade, which for a v0.x module is permitted and for an SDK is still rude without a deprecation cycle.

**Deprecate now, remove later.** Mark both as deprecated pointing at `pkg/govplan`, leave them working, remove in the next major. Kindest to consumers, and it does not satisfy AC-07 — the criterion says gone, not marked. AC-07 would have to move to a later phase or be reworded to accept deprecation as the interim state.

**Leave them.** Fails AC-07 and leaves two ways to get a plan in one repository, which is the duplication this ultragoal exists to remove.

## Recommendation

**Deprecate now, remove at the next major, and move AC-07's completion to that release.**

The reasoning is not caution about breaking things — it is that AC-07 as written measures the wrong moment. It says "only one selection implementation survives", and what actually matters is that only one is *reachable by new code*. A deprecated function with a doc comment naming its replacement is not a competing implementation; it is a migration path with an expiry date. Removing it on the same afternoon the replacement landed, from a module other people may already import, buys the criterion's literal wording at the cost of the thing the criterion is for.

The counter-argument is real and worth stating: this is exactly the reasoning that produced P2's failure, where a criterion's literal reading was correct and the generous one was mine. The difference is that this is a proposal to *amend the criterion* in the open, before the gate, rather than a claim that the criterion is already met.

## What is not blocked

T-06 (prose in both repositories) can proceed either way. AC-06's evidence is complete and unaffected.
