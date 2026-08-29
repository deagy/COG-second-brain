# P3 — gloop's selector is not a second implementation of cadre's

Read before starting T-03, because the CP-2 plan called this phase a "port" without having looked at the destination.

## What gloop already has

`pkg/selector` and `pkg/roster`, 1,316 non-test lines. Its own doc comment states the design:

> It takes a SelectorRequest (task, files, tags) and a canonical `pkg/catalog.Catalog`, then produces a DispatchPlan. Route matching is implemented once, in `catalog.MatchRoutes`; the selector picks **the most-specific matching route** and converts it into a dispatch plan. The selector is a pure function.
>
> The matched route dispatches its preset as **the single primary role**. If no route matches, the plan has `DispatchDispositionReject`.

`types.DispatchPlan`: `task_id`, `task`, `files`, `status`, `disposition`, `roles` (ordered, with a `pattern` — sequential, fan-out), `created_at`, `metadata`. Disposition is `proceed | modify | reject`.

## What cadre's produces

Eighteen required fields: `schema_version`, `task_id`, `dispatch_fingerprint`, `generated_at`, `status`, `workflow`, `inputs`, `matched_routes`, `matched_risks`, `context_packs`, `agents` (primary / reviewers / support), `dispatch_disposition` (`staffed | advisory-only | no-agents-selected`, with a reason), `teams`, `lifecycle_tracking`, `required_quality_gates`, `ignored_quality_gates`, `human_gates`, `knowledge_context`.

## They are different artifacts, not two versions of one

Gloop's plan answers **"what should run, and in what order"**: an ordered role list with an execution pattern, ready to hand to a runner.

Cadre's answers **"what matched, what fired, and who must sign"**: every route that matched and why, which risk rules triggered, which quality gates are required and which were ignored, which human gates block, and a fingerprint proving the document matches its own content — versioned against a closed schema so a consumer pinned at an older release fails loudly rather than silently.

One is an execution plan. The other is a governed selection record. Gloop's has no concept of risk rules, quality gates, human gates, workflow shape, teams, context packs, routing overlays, fingerprints or schema versioning. Cadre's has no concept of an execution pattern.

Neither is a subset of the other, and the difference is not maturity. They were built for different jobs.

## What this does to the phase, and to the ownership decision

`repository-ownership-decision.md` assigns "selection and dispatch" to gloop on the reasoning that it is orchestration by definition. That reasoning conflated two things this reading separates:

- **Execution orchestration** — sequence roles, fan out, run them. Gloop's, and gloop is further along.
- **Governed selection** — decide what matched and what governs it, auditably. Cadre's, and it carries the eight corrections AC-07 names.

P3 as planned would move the second into the first. That is possible, but it is a product decision rather than a migration, and three shapes are available:

1. **Port governed selection into gloop.** Gloop gains both layers and becomes the single orchestrator. Largest change; gloop's plan type either absorbs eighteen fields or gains a second plan type beside its own.
2. **Keep them separate and compose.** Cadre selects and governs; gloop executes what cadre selected. Each keeps the artifact it was built for, and the seam is cadre's plan being gloop's input. Smallest change, but it leaves two repositories in the orchestration concern, which is what this ultragoal exists to remove.
3. **Gloop's selector becomes the execution layer beneath cadre's output.** Cadre's plan is the input to gloop's role sequencing, and gloop's own route matching retires. Middle-sized; resolves the duplication in the direction of cadre's governance rather than gloop's simplicity.

## The plan's own error, recorded

CP-2 called this a port and inventoried what cadre has, having never opened the destination. That is AI-1's failure one level up: the four-axis inventory was applied to the source and not to the target. **Adding a fifth axis: what does the destination already do?**


## Recommendation

**Shape 3: gloop's selector becomes the execution layer beneath cadre's output.**

Shape 2 — keep both and compose — is the smallest change and the only one that fails the north-star outright: it leaves two repositories owning the orchestration concern, which is the duplication this ultragoal exists to remove.

Shape 1 — port governed selection into gloop — resolves the duplication but in the wrong direction. Cadre's selection engine is 4,502 lines carrying eight named corrections, each of which encodes a defect somebody hit: routes falling through to `unclassified` by omission, an overlay rule whose polarity inverts, a schema version that must bump on any emitted-field change. Rewriting that into gloop's simpler model is where those get quietly dropped, and AC-07 exists precisely because that is the expected failure of a port.

Shape 3 keeps each side's artifact and retires only the overlap. Cadre's plan is the input; gloop's `Select()` and `catalog.MatchRoutes` retire; gloop's `roles`/`pattern`/execution machinery — which cadre has nothing equivalent to — becomes the layer beneath. The corrections stay where they were tested rather than being re-implemented.

It costs an amendment to `repository-ownership-decision.md`: "selection and dispatch → gloop" was one concern where there are two. Recognising a mis-drawn boundary is what this ultragoal should do; smuggling the split in without saying so is not.
