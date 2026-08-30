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

## T-05 corrected (gloop `9fbcbff`, `348cb2d`)

`9ce408b` shipped a deprecation that was both wrong and incomplete. Both defects are fixed; the ledger keeps the original rather than rewriting it.

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-07 | CP-3 | PASS | `catalog.MatchRoutes` un-deprecated. It is the shared matching engine and `pkg/roster` and `pkg/tenant` both call it; marking it told their readers they were built on something scheduled for removal. Only `selector.Select` was ever meant to be marked. |
| AC-07 | CP-3 | PASS | `roster.Select` and `gloop roster plan` deprecated on the same timeline, pointing at `pkg/govplan`. Now no undeprecated path in gloop produces a plan from route matching. |
| — | CP-3 | PASS | The `exclude_paths` divergence is documented in the deprecation notice, `CHANGELOG.md` and `docs/ROSTER.md`. |
| — | CP-3 | PASS | Build, vet, full suite green. |

### The defect, and how it was found

T-05's inventory was `grep ... | head -10` against eleven hits. Two production callers were below the cut, and the truncation was invisible in the output. The deprecation was designed against a partial list, committed, and pushed.

T-06 found it — writing prose about what gloop no longer does required checking what gloop still does.

**Practice item (AI-10): an inventory piped through `head` is not an inventory.** Count first, then read all of it. AI-1 required four axes; this ran them and then truncated the first.

### What the complete inventory found

`pkg/roster.Select` is a third plan-producing path, and the one that actually duplicates cadre — it reads a cadre-format roster and re-implements cadre's `keyword_groups` and `exclude_paths`.

**And it has already diverged.** `exclude_paths` here drops the whole route when any request file matches; cadre subtracts at the *file* level and the route keeps matching on other files. Verified in both sources. Given `[internal/api/handler.go, vendor/lib.go]` against `paths: ["**/*.go"]` and `exclude_paths: ["vendor/**"]`, cadre matches on `handler.go` and gloop drops the route.

`exclude_paths` polarity is **correction #2 in AC-07's own list** — the ultragoal had already named this rule as one that must not be lost, and a second implementation had already lost it.

### Documented rather than fixed, deliberately

Correcting the divergence would mean maintaining a faithful second implementation of cadre's routing indefinitely, which is what retiring the path exists to avoid. A silent fix would entrench the duplicate for another release cycle while looking like diligence.

The cost is real and stated: until removal lands, `roster plan` users get plans cadre would not produce. That is now said in the deprecation notice, the changelog and the roster guide — where a user of it will actually read it.

## T-06 — prose (gloop `2067025`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-07 | CP-3 | PASS | `go doc ./pkg/selector` leads with the deprecation and the replacement — observed from the tool's output, not the source, since pkg.go.dev renders the same thing. |
| AC-07 | CP-3 | PASS | README lists `pkg/govplan`, marks `pkg/selector` deprecated, and its headline feature line now says governed selection comes from cadre while gloop executes what it produces. |
| — | CP-3 | PASS | Build and full suite green. |

### The plan's cadre half did not exist

CP-2 said T-06 would update "cadre's `RUNBOOK.md` and the `run-agent-orchestration` skill where they describe gloop as selecting". **cadre makes no mention of gloop anywhere** — not in any `.md` or `.go` file. The task was written from an assumption, not a search.

Nothing was added there either. A pointer would describe an integration that is not wired: `govplan` can read a plan, but nothing pipes cadre's output into it. That belongs with the wiring, not ahead of it.

### A correction that closes a loop

`doc.go` said "the matched route dispatches its preset as the single primary role". It does not — further primary, reviewer and support presets are planned after it.

That single line is where this phase's recurring mischaracterisation came from. It was read early, believed, and repeated into the P3 finding and the ownership decision before `selector.go`'s own comment contradicted it. Both downstream documents were corrected earlier; the source is corrected now, so the next reader does not inherit it.

**Worth naming: the doc comment was wrong and the code was right, and every check that would have caught it was a code check.** Prose is not covered by the suite, and a package doc is the first thing a new reader trusts.

## CP-3v — fresh-context verification

Returned **FAIL:fixable** on three findings, all in prose rather than code. Fixed in gloop `fd05a32`.

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-06 | CP-3v | PASS | 11 tests pass. Corpus: 25 cases, 20 converted, 4 gated (all four risk routes — destructive, identity-privilege, production-deploy, sensitive-data), 1 unstaffed (needs-triage). Roles verified as exactly `Agents.Primary` then `Reviewers` then `Support`. |
| AC-07 | CP-3v | FAIL → fixed | Searched all 147 non-test files. Exactly three functions construct a `DispatchPlan`; two are deprecated and the third is the replacement. But `pkg/tenant`'s `RouteMatches` is an exported, unmarked route-matching path. |
| AC-07-doc | CP-3v | FAIL → fixed | `CHANGELOG.md` still claimed `catalog.MatchRoutes` would be removed, contradicting the source. `go doc ./pkg/roster` showed no deprecation at package level. |
| AC-regression | CP-3v | PASS | Both full suites green. |

### The changelog contradicted the code, and that is the same failure twice

`9fbcbff` un-deprecated `catalog.MatchRoutes` in the source and left the changelog entry saying it would be removed. A reader of one artifact and a reader of the other were told opposite things.

This is the second time in this ultragoal that a correction was applied to code and not to the prose describing it — the first was a commit message describing a file the commit did not contain. **Both were caught by a verifier, neither by a test**, because prose is not covered by any suite.

### On the tenant helper: exempt, and now it says so

The fix hint suggested deprecating it. It was documented as exempt instead, with the reasoning in the source: it returns route matches and nothing else — no plan, no disposition, no roles, no gates — over an engine that is itself staying. The distinction being drawn is **plan production**, not route matching. Deprecating an introspection helper because something it does not do moved elsewhere would be marking the wrong thing, which is exactly the error `9ce408b` made with `MatchRoutes`.

The fix hint on `pkg/roster` was also deviated from: it suggested a package-level deprecation, which would deprecate loading, validating and inspecting a roster in order to retire the planning path. The package doc names the deprecated method instead.

## CP-4 — integration against P1 and P2

**VERDICT PASS**, with one caveat worth more than the pass.

| INT | CP | Result | Observation |
|---|---|---|---|
| INT-1 | CP-4 | PASS | P1's fingerprint agreement holds. Both repositories' fixtures independently hashed: `sha256 cd832b3b…` on each. Byte-identical, verified outside the test harness. |
| INT-2 | CP-4 | PASS | Contract drift guards ran a real comparison, not the skip path. All three vendored contracts `diff`'d identical outside the harness. |
| INT-3 | CP-4 | PASS | cadre's full suite and all three generator checks current. P2's salvaged template survives P3 and is counted in the 321 role-metadata files. |
| INT-4 | CP-4 | PASS | gloop's two cross-repo guards ran and compared — confirmed `PASS` not `SKIP`, against real fixtures of 277 and 1,986 lines. |
| INT-5 | CP-4 | PASS with caveat | Pin `0.14.2`, tag `v0.14.2`, built binary reports `0.14.2`, window `[0.13.2, 1.0.0)`. All three agree, verified by independent build rather than by the test. |

### The caveat: a guard passing while checking the wrong artifact

`TestOurProviderBundleAcceptsTheKernelWeDependOn` resolves `agentic-sdlc` from `PATH` when `AGENTIC_SDLC_BIN` is unset. On this machine that is a pipx-installed **legacy Python CLI reporting 0.13.2**, not a build of the extracted kernel at 0.14.2. It passed only because 0.13.2 sits exactly on the window's inclusive minimum.

The environment note recording "installed 0.13.2, repository 0.14.2" was written in P1 and treated as trivia. It was not: it meant the guard had never exercised the kernel the repository depends on.

Fixed in cadre `13dd16a2` by making the guard log which binary and version answered. The check is still the right one — "would a consumer's installed kernel accept this bundle" is a question about what is installed — but a passing run is now legible, so a stale binary shadowing the name is visible rather than silent.

## CP-5 — acceptance, observed on the artifact

The pipeline run end to end for the first time: a live `cadre select` piped into gloop's `govplan`, not a vendored fixture. A throwaway program read stdin, parsed, converted, and printed; it was deleted afterwards and the tree left clean.

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-06 | CP-5 | PASS | `cadre select --task "add a new HTTP handler to the go service" --files internal/api/handler.go --classification internal` piped into gloop produced an execution plan: `status: pending`, `disposition: proceed`, roles led by `backend-engineer` and `go-service-implementer` as `role_type: primary`. Exit 0. |
| AC-06 | CP-5 | PASS | `--task "deploy to production the new release build" --files deploy/prod.yaml --classification confidential` → `REFUSED: govplan: the plan requires a human decision: 1 gate(s) on task local-2672a511813f must be decided by a named human first`. Exit 2, no plan emitted. |
| AC-06 | CP-5 | PASS | `--task "drop table sessions and delete namespace staging" --files db/migrations/003_drop.sql --classification confidential` → `REFUSED: … 2 gate(s) …`. Exit 2, no plan emitted. |

### Why this is different from what the tests proved

Every prior check ran against a fixture vendored from cadre. This is cadre's producer running live, its output crossing the repository boundary, and gloop refusing it — with the gates cadre's own risk rules fired for a production deployment and a destructive migration, not gates written into a test.

The refusal is also observable as a **process exit code**, not just a message: exit 2, nothing on stdout. A caller piping this into a runner gets nothing to run, which is the property the design chose over returning a plan with a blocked status.

Two commands that would deploy to production and drop a database table each produced no executable plan, because a human has not decided. That is the whole point of the phase, observed rather than asserted.
