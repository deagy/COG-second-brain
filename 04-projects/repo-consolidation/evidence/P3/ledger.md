# P3 evidence ledger

## T-01 — pin plan validity, not only plan shape (cadre `984314fe`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-06 | CP-3 | PASS | `conformance-plan.json` is one complete plan as emitted. Two guards, both falsified: dropping `dispatch_fingerprint` fails the required-field check and the redundancy check; setting the captured version to 7 fails the staleness check. |

**Why it was needed.** cadre's golden corpus records each case's *canonical* plan, which strips `dispatch_fingerprint`, `generated_at` and `provenance` because a golden carrying them would change every run. Measured: the schema requires 18 fields, the canonical form carries 16 — and the two absent are required. A producer could reproduce all twenty-five golden cases exactly and still emit documents the schema rejects, with nothing in the corpus noticing.

## T-02 — gloop reads cadre's governed plan (gloop `bb1fd81`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-06 | CP-3 | PASS | `pkg/govplan` parses the real conformance plan: task_id read, agents block mapped, disposition read as `staffed`. |
| AC-06 | CP-3 | PASS | A plan declaring an unsupported `schema_version` is refused with an error naming both numbers. A document with no `schema_version` is refused rather than guessed at. |
| AC-06 | CP-3 | PASS | The vendored fixture is held to cadre's copy by a guard that skips locally and fails under CI. Falsified: hand-editing the copy fails it, naming both paths. |
| — | CP-3 | PASS | gloop's full suite green. |

### The design decision inside T-02

gloop is a consumer of cadre's contract, not a second author of it. Two approaches were rejected explicitly, in the package's own doc comment so the next reader finds the reasoning rather than re-deriving it:

- **Vendor `selection.schema.json` and compile it.** That places an unguarded copy of someone else's contract in gloop — the failure that produced four defects in cadre.
- **Hand-write Go structs for all eighteen required fields.** The same problem wearing a different hat: a second representation, free to drift, of a document this repository does not define.

What it does instead: pin the version, refuse anything else, and read only the fields execution consumes. A plan carrying fields gloop ignores is fine — that is forward compatibility from the consuming side. A plan carrying a version gloop does not know is not, and fails naming both numbers, which is what cadre's versioning rule was written to produce.

**This preserves gloop's immunity to the drift class.** It still has no `*.schema.json` and no schema compiler; its Go types remain its own contract, for the subset it consumes.

`human_gates` and `required_quality_gates` are carried rather than dropped despite gloop having no equivalent concept. An executor that silently ignores a human gate is the failure the gate exists to prevent. What it should *do* about one is T-03's open question.

## T-03 — governed plan to execution plan (gloop `85a5c55`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-06 | CP-3 | PASS | A real cadre plan converts: task_id carried, primary role first, sequential pattern, status pending. |
| AC-06 | CP-3 | PASS | Roles keep kind and order across a four-role plan — primary, two reviewers, support — with `PresetID` set to cadre's role id. |
| AC-06 | CP-3 | PASS | A gated plan yields no executable object and refuses with `ErrHumanGate`. **Falsified**: deleting the gate check fails the test with "a gated plan produced an execution plan; the gate can be executed past". |
| AC-06 | CP-3 | PASS | `advisory-only` and `no-agents-selected` both refused as unstaffed; so is a disposition claiming staffed with an empty agents block. |
| — | CP-3 | PASS | gloop's full suite green. |

### The decision, and why it took the shape it did

**Refuse to execute past a human gate** — the user's call, and the only one consistent with cadre's own rule that an agent may not proceed on presumed consent.

The implementation choice underneath it was less obvious. A gated plan could have returned an execution plan carrying a blocked status. It does not: it returns nothing. A returned plan is a runnable object in a caller's hands, and honouring the gate would then depend on that caller checking a field — which is how a gate gets executed past by someone who meant no harm. Having nothing to proceed with is the only version that does not rely on downstream care.

The same reasoning refuses both unstaffed dispositions rather than executing what little matched.

### Two things the mapping revealed

**The role taxonomies already agree.** cadre's `primary` / `reviewers` / `support` maps exactly onto gloop's `RoleTypePrimary` / `RoleTypeReviewer` / `RoleTypeSupport`. Two systems that disagree about everything else — gates, risk, fingerprints, schema versioning, execution patterns — independently arrived at the same three role kinds. That is why composing them is cheap.

**Sequential is not a safe default here, it is the only correct one.** Fan-out would run reviewers concurrently with the primary, and a reviewer reviewing nothing is not a review. cadre's agents block encodes that relationship implicitly; this is where it becomes an execution property.

## T-04 — equivalence across the corpus (gloop `5dc28ac`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-06 | CP-3 | PASS | All 25 of cadre's corpus cases resolve as their own fields predict: **20 converted, 4 gated, 1 unstaffed**. Roles equal the plan's agents in every converted case. |
| AC-06 | CP-3 | PASS | **Falsified**: removing reviewers from the mapping fails on `supply-chain-by-keyword` with "3 roles from 4 agents; the mapping lost or invented one". |
| AC-06 | CP-3 | PASS | **Falsified**: hand-editing the vendored corpus fails the derivation guard, naming the case. |
| — | CP-3 | PASS | gloop's full suite green. |

### Nothing is hardcoded per case

Each plan's own disposition and gate list predict what conversion must do, and the test checks that conversion agrees. A mapping that dropped a reviewer or executed a gated plan disagrees with the plan that produced it — which is a stronger property than twenty-five recorded expected outputs, because it cannot be satisfied by updating the expectations.

### The corpus is a better oracle than it was asked to be

It exercises all three outcomes with real data: twenty conversions, four genuinely gated plans, one unstaffed. Before this, both refusal paths were covered only by hand-written mutations of a single fixture. An assertion now fails the suite if any outcome ever has no case, because a corpus of twenty-five staffed plans would be a weaker oracle than it looks.

### A precedence the corpus made visible

The counts are 20/4/1 against a corpus holding **two** unstaffed dispositions. One case is both gated and unstaffed, and the gate check runs first, so it reports the gate.

That is the correct order — a human gate blocks regardless of who was staffed — but it was not a decision anyone made explicitly. It fell out of the order the checks were written in, and the corpus is what surfaced it.

## T-05 — deprecate rather than remove (gloop `9ce408b`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-07 | CP-3 | PASS | `selector.Select` and `catalog.MatchRoutes` carry Go `Deprecated:` paragraphs naming `pkg/govplan`, placed at the end of each doc comment per convention so tooling and pkg.go.dev surface them. |
| AC-07 | CP-3 | PASS | `gloop select`'s help text opens with the deprecation and the migration; its `Short` is prefixed `[deprecated]`. Observed by running `gloop select --help`, not by reading the source. |
| AC-07 | CP-3 | PASS | CHANGELOG records the deprecation, the replacement, and that removal lands at the next major. |
| — | CP-3 | PASS | Build, vet and full suite green. |

AC-07b — the removal — is deferred to gloop's next major and tracked in the spec matrix.

### Why deprecation and not deletion

gloop is a published module: `v0.1.0` and `v0.2.0` tagged, MIT-licensed, on pkg.go.dev, and both functions are exported. Deleting them the same day the replacement landed would break importers to satisfy the criterion's wording rather than its purpose.

The criterion measured the wrong moment. What matters is that only one implementation is **reachable by new code**, and a deprecated function whose doc comment names its replacement is a migration path with an expiry date rather than a competitor. AC-07 was amended in the open before the gate, and AC-07b carries the removal.

The distinction from P2's failure is deliberate and worth keeping visible: there, a criterion was read generously *at* the gate to make failing work pass. Here the criterion was changed *before* the gate, with the reasoning written down and the deferred half tracked rather than dropped.

### A correction the work surfaced

The P3 finding and the ownership decision both describe gloop's selector as dispatching "the single primary role". That came from `doc.go`. `selector.go`'s own comment is more complete: it plans reviewer and support presets after the primary when the route declares them.

The conclusion is unchanged — gloop's selector has no concept of risk rules, quality gates, human gates, fingerprints or schema versioning, so it remains an execution planner rather than a governed selector. But the characterisation was wrong in a way that undersold it, and the deprecation notice says "the difference is governance rather than capability" for that reason.
