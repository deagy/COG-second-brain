---
type: "decision"
project: "agentic-sdlc"
title: "Repository Ownership: which repo owns which concern"
status: "proposed"
created: "2026-08-28"
repos: ["~/sdk/cadre", "~/sdk/gloop", "~/sdk/recall", "~/agentic-lifecycle"]
source_braindump: "[[04-projects/agentic-sdlc/braindumps/braindump-2026-08-28-1928-scrapping-cadre-for-gloop-and-recall]]"
tags: ["#decision", "#agentic-sdlc", "#architecture"]
---

# Repository Ownership

Four repositories currently claim four concerns between them, most of them twice. Naming one owner per concern is an afternoon of decisions; every migration afterwards becomes mechanical rather than a judgment call. Nothing below requires a rewrite.

The rule being applied is the one three separate defects taught on 2026-08-28: **two authorities for one shape drift, and drift silently.** That held at file scale (`finding.schema.json` against a Go allowlist) and it holds at repository scale.

| Concern | Current claimants | Recommended owner | Confidence |
|---|---|---|---|
| Lifecycle contracts | `cadre/kernel/` (real), `agentic-lifecycle/schemas/` (template) | `cadre/kernel`, extracted to its own repo | high |
| Knowledge storage and retrieval | `cadre/internal/knowledge` (8,123 lines), `recall` (183 files) | `recall` | medium |
| Knowledge governance | `cadre/internal/knowledge/staged_*.go`, `recall/hitl` | separate concerns, do not merge | medium |
| Agent definitions | `cadre/roster` (159), `agentic-lifecycle/agents` (10), `gloop/pkg/roster` | `agentic-lifecycle`, as data | medium |
| Governed selection | `cadre/internal/selector` | `cadre` (with the catalog) | high |
| Execution orchestration | `gloop/pkg/selector`, `gloop/pkg/dispatch` | `gloop` | high |

## Lifecycle contracts

**Corrected 2026-08-28 after reading both.** The first draft of this document recommended `agentic-lifecycle` on the reasoning that portability is its stated purpose. Reading the two artifacts reverses it.

`agentic-lifecycle/schemas/run-record.yaml` is not a schema. It is an example document with placeholder values — `run_id: project-slug-date`, `project: project-name`, `objective: concise objective` — carrying no types, no required set, and no validation semantics. It is a starter template.

`cadre/kernel/contracts/run-record.schema.json` is titled "Portable authoritative Agentic SDLC run record". It declares 24 required fields, `additionalProperties: false`, and thirteen `$defs` — `identity`, `evidence`, `knowledge`, `artifactBinding`, `authorityRequirement`, `approval`, `finding`, `exception`, `invalidation`, `gate`, `impactItem`, `impactProfile`. Its `current_lifecycle_phase` enum is the exact ten-phase sequence from the 00:47 braindump, plus `build` and `feedback`.

They also do not model the same object. The template has `gates: {}`, `assumptions`, `unknowns`, `decisions`, `history`. The schema has `lifecycle_gates`, `specialist_attestations`, `re_entry_history`, `impact_profile`, `contract_digest`, `dispatch_binding_digest`, `provider_bindings`.

**The lifecycle kernel already is a separate thing, inside cadre, on purpose.** `cadre/kernel/README.md` describes a versioned lifecycle kernel shipped as its own Go binary from `cmd/agentic-sdlc`. `internal/kernel/kernel_boundary_test.go` enforces the ownership rule in its own words: "kernel/ owns lifecycle gate schemas, run-record validation and gate-authority semantics — permanently. roster/ supplies a role catalog and a provider profile *into* projects that adopt the kernel; it never becomes authoritative for another project's gate approvals. roster/ asks, the kernel answers." The test exists because a single Go module makes the boundary dissolvable in one import line, and `RUNBOOK.md:823` already names a "public `cadre-lifecycle` repo" as the extraction target.

So the two-repo boundary cadre asserts is between its own two halves, not between cadre and `agentic-lifecycle`. `agentic-lifecycle` is a third, less developed attempt at the same idea in Python, not the incumbent owner.

**Recommendation:** the kernel is the authority. Complete the extraction the boundary is already built for — `kernel/` plus `cmd/agentic-sdlc` become their own repository, which the boundary test has been preparing for and which removes the one-import-line risk permanently. `agentic-lifecycle` is then either retired or reduced to whatever its ten stage agents are worth on their own; its schemas are superseded.

## The diagnosis may have the halves swapped

Worth stating plainly, because it bears on the whole rewrite question. The braindump reads: "the agentic-sdlc portion I feel is half-baked and brittle."

The agentic-sdlc portion *is* the kernel. It is the most rigorous artifact in the four repositories: a closed schema with digests and thirteen definitions, a permanent ownership boundary with a test written specifically to survive a plausible refactor, and versioning rules with worked examples for each limb.

The brittleness actually found on 2026-08-28 was entirely in the other half. All three defects were in `internal/orchestration/final_handoff_capture.go` — roster-side orchestration, not lifecycle. The seam that kept failing is where agent output enters the store, which is orchestration's job.

That does not make the judgment wrong; the felt experience of brittleness is evidence about something. But it is worth checking whether what feels half-baked is the lifecycle *model* or the orchestration that surrounds it, because the two point at opposite decisions. If it is the model, extraction is wasted effort. If it is the orchestration, then gloop is already the answer and the kernel should be preserved rather than rebuilt.

## Knowledge storage and retrieval

`recall` owns it, with a caveat that has to be checked before committing.

Three reasons. It uses `modernc.org/sqlite`, pure Go, which removes the cgo degradation path cadre works around in `bin/cadre` — a `CGO_ENABLED=0` build of cadre links cleanly and then fails at runtime on every `cadre knowledge` call, with nothing warning at build time. It is a library by construction, where cadre's store is embedded in a CLI. And it carries 162 test files against 183 sources, a ratio cadre's store does not match.

The caveat: **parity is unverified.** cadre's store does exact-match classification filtering, source scoping by repository slug with a canonical-path-hash fallback, audit metadata on retrieval, and a shared-global-store fallback for projects without their own partition. Whether recall covers those is unknown and has to be established before deleting anything.

A separate observation worth weighing. cadre's store carries `sharding.go`, `federation.go`, `rebalancing.go`, `disaster_recovery.go`, and `database_repair.go`. Those are capabilities a single-operator knowledge store does not need, and their presence is evidence the component grew past its purpose. recall has `distributed/` and `analytics/`, so it is not obviously immune to the same. Whichever survives, the question of how much of it is load-bearing is worth asking once.

## Knowledge governance

These are two different things and merging them would be a mistake.

cadre's `staged_*.go` implements separation of duties: `propose` writes only a `proposed` record and refuses one arriving dispositioned, `disposition-staged` refuses a `decided_by` equal to `staged_by`, `import-staged` refuses a self-approved record regardless of authorization, and `ingest-accepted` re-checks the stager/decider match. Four checks on four verbs, because staging is a door agents may open themselves.

recall's `hitl` implements active learning: `ReviewQueue`, `ReviewItem`, `Candidate`, `Annotation`, `AnnotationStore`. It exists to improve retrieval quality by getting humans to label things.

One is about authority, the other about accuracy. Keep both. The authority half is lifecycle semantics — who may approve what — so it belongs conceptually with `agentic-lifecycle` even though it is implemented against whatever store survives.

## `agentic-lifecycle`, retired

**Decided 2026-08-29.** Archived. Nothing survives as code; one idea survives as a note.

Its two schemas are placeholder templates rather than contracts. `run-record.yaml` carries literal example values (`run_id: project-slug-date`) with no types and no required set, against the kernel's 24-required-field closed schema with thirteen `$defs`. `gate-result.yaml` is the same shape (`gate: G1`, `owner: agent-id`), and the kernel already models gate results in `run-record.schema.json`'s `$defs.gate` plus `internal/kernel/gateissues_run.go`. Neither is a loss.

Nine of its ten agents have a cadre counterpart with stronger authority rules — `intent-owner` against `product-owner-aide` at G1, `solution-architect` against `system-architect-aide` at G3, `security-reviewer` against `security-lead-aide` at G5, `release-manager` against the release aides at G7–G9. The difference is authority, not coverage: a stage agent "owns decisions and evidence for a phase", while an aide is forbidden from making, implying or recording the decision it prepares a package for and must name a human. Two answers to one question, and cadre's carries the constraints.

### What survives, and why as a note rather than a role

`lifecycle-coordinator` was the tenth, and the only one with no clean counterpart. It names five outputs — dispatch plan, consolidated gate results, invalidation records, escalations, and runtime feedback — and cadre has every one, deliberately split:

| Its output | Cadre's owner |
|---|---|
| Dispatch plan | `cadre select`, machinery rather than a role |
| Consolidated gate results | `approval-router`, bound to an authority matrix it may not edit |
| Gate sequencing | `phase-gate`, which blocks a phase transition but not work within a phase |
| Invalidation records | the kernel's gate-invalidation and re-entry semantics |
| Escalations | `escalation-policy.md` and `halt-authority`, which may not lift its own halt |

That split is the separation-of-duties principle running through the whole roster, and a single role holding all five concentrates what those splits exist to prevent. It also has a price: `catalog.schema.json` closes `phase` to thirteen values and `capability` to five, neither including `orchestration` or `workflow_coordination`, and that schema is vendored into the pip wheel and the plugin distribution — so adding the role is a versioned contract change consumers absorb, for one role.

**The thing worth keeping is what the role's existence reveals:** those five functions are one *concern* even though cadre owns them in five places. Nothing in cadre says so. A reader meeting `approval-router` and `phase-gate` separately has no reason to see them as parts of one job, which is how a sixth part gets added somewhere else without anyone noticing the seam. Recorded here rather than implemented, because the distribution is correct and only the map was missing.

This also survives P3: when gloop takes dispatch, the first row moves and the other four do not, and that asymmetry is easier to reason about with the concern named than without.

## Agent definitions

`agentic-lifecycle` owns them, as data rather than code.

They are markdown, YAML, and a catalog schema. Nothing about them needs a runtime, and coupling them to one is what makes them hard to keep — which matters, because the definitions are the part of cadre with the most proven value. Audited on 2026-08-28: the eight authority aides are uniform and cover G1–G10 with no gate unassigned, `halt-authority` carries a genuine independence rule, and `approval-router` is bound to a matrix it may not edit.

`agentic-lifecycle` is the right home because it already owns the accountability model those roles are written against, and it already carries `agents/` and `routing.yaml`.

The unresolved part is 10 against 159. `agentic-lifecycle`'s README describes a layered model — "stage agents own decisions and evidence for a phase; optional technology" specialists supply implementation — which reads as two layers of one design rather than two competing catalogs. If that holds, both survive at different layers and the only genuine collision is cadre's eight `*-aide` roles, which prepare gate decision packages, against `agentic-lifecycle`'s stage agents, which own decisions and evidence for a phase. Those two overlap directly and one of them has to go.

## Selection and dispatch — amended: it is two concerns

**Amended 2026-08-29.** This section originally assigned "selection and dispatch" to gloop on the reasoning that it is orchestration by definition. Reading gloop's selector showed the concern was drawn wrong.

Gloop's `pkg/selector` produces an **execution plan**: ordered roles with a sequential or fan-out pattern, disposition `proceed | modify | reject`, ready to hand a runner. It matches a route and plans that route's primary, reviewer and support presets. (An earlier draft of this section said it plans a single primary role, taken from `doc.go`; `selector.go`'s own comment is more complete. Corrected 2026-08-29 — the difference between the two engines is governance, not capability.)

cadre's produces a **governed selection record**: every route that matched and why, which risk rules fired, required *and ignored* quality gates, human gates, teams, context packs, lifecycle tracking, a fingerprint proving the document matches its own content, all against a closed schema versioned so a consumer pinned at an older release fails loudly.

Neither is a subset of the other, and the difference is not maturity. Gloop has no concept of risk rules, quality gates, human gates, workflow shape, overlays, fingerprints or schema versioning. cadre has no concept of an execution pattern.

**So: cadre owns governed selection, gloop owns execution beneath it.** cadre's plan is gloop's input. Gloop's own route matching — `Select()` and `catalog.MatchRoutes` — retires, because that is the only genuine overlap.

The alternative considered and rejected was porting cadre's engine into gloop. cadre's selection is 4,502 lines carrying eight named corrections, each encoding a defect somebody hit: 86 routes falling through to `unclassified` by omission, an overlay rule whose polarity inverts, a schema version that must bump on any change to the emitted field set. A rewrite into a simpler model is exactly where those get dropped silently, and they are worth more than the tidiness of one repository owning both layers.

Splitting a concern in two is not a retreat from the north-star. The north-star says every concern has one owner; it does not say the original list of concerns was drawn correctly. This one was not.

## What is left of cadre## What is left of cadre

Packaging, plugin generation, the Cline and Codex ports, and the CLI that wires the other three together. That is a real component and nothing else claims it — but it is a much smaller question than "scrap or keep", and it only becomes answerable after the four decisions above.

## Open questions

- Does `recall` cover cadre's classification filtering, source scoping, audit metadata, and shared-global-store fallback? Unverified, and it gates the storage decision.
- Are the 10 stage agents and the 159 specialists two layers or two competitors? Needs both catalogs read side by side.
- Does `gloop/pkg/selector` already model routing overlays, team recipes, and `workflow_shape`, or would those be a port?
- Is `agentic-lifecycle` worth keeping at all once its schemas are superseded, or are its ten stage agents the only salvage?
- Does "half-baked and brittle" describe the lifecycle model or the orchestration around it? The two point at opposite decisions, and the evidence so far points at orchestration.

## Why this is the first move

Four substantial, actively-developed repositories solving four overlapping problems is itself the signal. Each was likely started because the previous felt wrong in a specific way, and each rebuilt more than the part that was wrong. A fifth start inherits the pattern. Deciding ownership is what breaks it, and unlike a rewrite it costs an afternoon.
