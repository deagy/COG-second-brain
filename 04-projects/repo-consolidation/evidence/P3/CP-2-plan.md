# P3 — CP-2 plan: port orchestration to gloop

Covers AC-06 (gloop produces equivalent plans) and AC-07 (the corrections travelled).

## The four-axis inventory

Required by AI-1, which exists because P1 inventoried two axes and paid for it with three mid-execution discoveries. The four disagree so sharply here that any one of them alone would have produced a wrong plan.

### Axis 1 — what imports it

`internal/selector` is 4,502 non-test lines across 40 test files, and imports exactly two packages of its own: `internal/canonicaljson` and `internal/config`. Two non-test importers: `internal/orchestration/team_recipe_expand.go` and `internal/cli/select_go.go`.

By this axis the port looks about as clean as the kernel's was.

### Axis 2 — what names it in prose

`cadre select` is documented across `RUNBOOK.md`, the `run-agent-orchestration` skill and its references, and the generated plugin. Mechanical to update, and no reader of this axis learns anything the others do not.

### Axis 3 — what reads its data

**50 files reference `routing.json`. 46 reference `catalog.yaml`.**

That is twenty-five times the import surface, and the readers are not the selector's callers. `internal/generators` reads both heavily — `catalog_generation.go`, `generate_role_metadata.go`, `cline_tables.go`, `cline_port.go`, `role_metadata.go` — because plugin and role-metadata generation consume the same roster data selection does.

**This changes what P3 is.** `routing.json` and `catalog.yaml` are not the selector's private inputs; they are the role catalog, which the ownership decision already assigns as a data package consumed by several runtimes. Gloop takes the *selection logic*. The data stays where it is and gains a second consumer. Nothing about the fifty files moves.

Smaller data surfaces: `runner-capabilities.json` 11 files, `routing-overlay.json` 8, `roster.json` 5, `selection.schema.json` 5.

### Axis 4 — what models it as a releasable component

Nothing — and that is the finding.

`cadre select` is a **subcommand**, not a program. `internal/release`'s `Programs` list holds only `cadre` and `agentic-sdlc-engine`; the release gate watches only `plugin` and `cli`. So unlike the kernel, moving selection removes no release artifact.

But `selection.schema.json` **is** shipped, in three places: `roster/orchestration/` as source, the pip wheel's data directory, and `plugin/suite/`. It is closed (`additionalProperties: false`), vendored away from its producer, and guarded by `internal/orchestration/schema_release_drift_test.go`, which diffs it against its copy at the last `plugin-v*` release tag and fails when the emitted field set changes without a `schema_version` bump.

**That is the real risk in P3, and only axis 4 sees it.** If gloop becomes the producer of dispatch plans, `selection.schema.json` becomes a cross-repository contract exactly as the dispatch fingerprint did in P1 — a closed schema, pinned by consumers at whatever release they installed, with a producer that can no longer see them. P1's answer was a frozen fixture generated while both sides still agreed. P3 needs the equivalent before the producer moves.

## Tasks

| ID | Task | Covers | Gate |
|---|---|---|---|
| T-01 | Freeze the plan-shape agreement: a golden plan and its expected `schema_version`, generated from cadre's producer while it is still the only one, that both repositories validate against | AC-06 | internal |
| T-02 | Establish the golden corpus as the equivalence oracle — for each input, matched routes, workflow, required quality gates and human gates | AC-06 | internal |
| T-03 | Port the selection logic into gloop's `pkg/selector`, consuming the role catalog as external data rather than vendoring it | AC-06 | internal |
| T-04 | Carry the eight named corrections, each with a test that fails when its rule is removed | AC-07 | internal |
| T-05 | Decide `selection.schema.json`'s ownership and wire its drift guard across the boundary | AC-06 | internal |
| T-06 | Repoint cadre: `cadre select` delegates to or is replaced by gloop; prose and generated plugin updated | AC-06 | internal |

T-01 before T-03, for the same reason T-01 preceded T-02 in P1: an agreement fixture can only be generated while one side is still authoritative.

## AC-07's eight corrections

Each needs a test in gloop that fails when the rule is removed — mutation-verified, not merely present. Listed in `spec.md`; restated here with where each currently lives so the port can find them:

1. `workflow_shape` declaration guard — `internal/selector`'s `WorkflowShapeDeclarationTests` (#210: 86 routes fell through to `unclassified` by omission)
2. Overlay widen-only merge with `exclude_paths` immutability and its inverted polarity — `internal/selector/overlay.go`, `overlay_resolve_test.go`
3. `schema_version` increments on any emitted-field-set change — `internal/orchestration/schema_release_drift_test.go`
4. `undeclared_workflow_shape_routes` inside the `dispatch_fingerprint` payload — `internal/selector/canonical.go`
5. Finding capture accepts everything `finding.schema.json` declares — `40644827`
6. Envelope dispositions cover the run record's vocabulary — `1988b428`
7. Artifact manifest field set closed and documented — `1a301f38`
8. Denial records validate, including the objection case — `51be12bc`

Corrections 5-8 are in `internal/orchestration/final_handoff_capture.go`, which is the handoff seam rather than the selector. **Whether that seam moves with selection or stays is undecided** and is the first thing T-03 must settle: it is where every silent-drop defect in this project has been found.

## Risk carried into build

Gloop currently has no `*.schema.json` and no `jsonschema` dependency — its Go types are the contract, which is why it is structurally immune to the drift class that produced four defects in cadre. T-05 is where that immunity is either preserved by generating types from the schema, or lost by hand-maintaining a second representation.


---

# CP-2 plan, revised 2026-08-29 — compose rather than port

The plan above stands as the four-axis inventory and is still accurate about cadre. Its task list assumed a port, and reading gloop's selector showed there is nothing to port: see `CP-2-finding-gloop-selector.md`. cadre keeps governed selection; gloop owns execution beneath it; gloop's own route matching retires as the only real overlap.

## What changes

The original T-01 through T-06 assumed cadre's engine moves. It does not. T-01 survives — the conformance fixture is still the oracle, now for a *consumer* rather than a second producer — and the rest is replaced.

## Revised tasks

| ID | Task | Covers | Gate |
|---|---|---|---|
| ~~T-01~~ | ~~Freeze the plan-shape agreement~~ — **done**, cadre `984314fe` | AC-06 | done |
| T-02 | Define gloop's plan-ingest boundary: a type that reads cadre's dispatch plan, validating against `selection.schema.json` rather than re-deriving its shape | AC-06 | internal |
| T-03 | Map a governed plan's `agents` (primary, reviewers, support) onto gloop's `roles` and a stated execution `pattern`; decide what a `human_gates` entry does to execution | AC-06 | internal |
| T-04 | Prove equivalence across the golden corpus: for each of the 25 cases, cadre's plan in, an execution plan out, roles exactly the plan's agents | AC-06 | internal |
| T-05 | Retire gloop's `Select()` and `catalog.MatchRoutes`, and everything that existed only to feed them | AC-07 | internal |
| T-06 | Repoint prose in both repositories; amend the `run-agent-orchestration` skill where it describes gloop as selecting | AC-06 | internal |

## The question T-03 has to answer

A governed plan carries `human_gates` and `required_quality_gates`. Gloop's execution model has no concept of either. Composing them means deciding what an executor does when the plan it was handed says a human must approve before a step.

Three answers, and this is a design decision rather than a mapping: refuse to execute past the gate and return; execute up to the gate and park; or execute everything and report the gate as unmet. The first is the only one consistent with cadre's own rule that an agent may not proceed on presumed consent — but it is worth stating rather than assuming, because it makes gloop's executor gate-aware, which is a genuine widening of its scope.

## What is no longer in scope

The eight named corrections stay in cadre with their existing tests. AC-07 no longer asks whether they travelled; it asks that nothing else survives to compete with them. The handoff seam question from the original plan — whether `final_handoff_capture.go` moves — dissolves: nothing moves.
