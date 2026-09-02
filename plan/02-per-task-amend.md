---
type: plan
project: cog-cadre-integration
change: 02-per-task-amend
created: 2026-09-02
depends_on: ["01-run-record"]
status: draft
tags: ["#plan", "#amend-semantics", "#deny", "#verify-loop"]
---

# Change 2 — Per-task amend semantics

## The change

COG's per-task verify loop (CP-3v) gets the amend and deny semantics that cadre
already specifies at the phase level but lacks at this level. Today the loop is a
retry loop: `task-verifier` runs, `FAIL:fixable` spawns `fix-agent` (max 2), then
re-verify, `FAIL:escalate` stops. That is a bound on attempts, not a bound on
amends, and a denial that does not change what the pipeline does next is
decoration. The three phase-level rules port down cleanly:

- **Earliest-affected re-entry.** A denial names the earliest step the task must
  re-enter from, not "start over." This is `cadre/workflows/new-service.md:39`: a
  failed gate returns to the responsible artifact owner and names the earliest
  required re-entry gate.
- **Invalidation cascade.** A material change invalidates that criterion and every
  downstream criterion that depended on it. `failed gates invalidate that gate and
  every dependent downstream gate` is the phase-level rule; the per-task analogue
  is that a fix to AC-03 re-verifies AC-03 and everything AC-03 feeds, not just
  AC-03.
- **Reviewer becomes author on re-review.** The agent that made the amend cannot
  be the one who signs off the re-review. This is the "cannot lift its own block"
  rule from cadre's `halt-authority`, and it is the whole point of the fresh-
  context verifier.

The two rules neither loop currently has — and the braindumps flag as the actual
gap — are a bound on amend cycles and a defined terminal state when the bound is
hit. The current `retry < 2` is an attempt cap wearing an amend cap's clothes. The
change makes it explicit: a maximum number of amend cycles, and a terminal
`escalate` state with emitted telemetry when the bound is reached.

## Where it lands

- `skills/closed-loop/SKILL.md` Phase 4 — replace the bare retry loop with the
  deny/re-entry contract: on `FAIL:fixable`, the fix must state which criteria it
  amends and which downstream criteria it invalidates; the re-review is performed
  by a different agent than the one that amended; after the amend bound, `FAIL:escalate`.
- `.claude/agents/task-verifier.md` — the output contract gains two fields: an
  `INVALIDATED` list (criteria invalidated by the observed change) and a `RE_ENTRY`
  pointer (earliest step to re-enter from on denial). The verdict block already has
  room; this extends it without restructuring.
- `.claude/lib/checkpoint.sh` — `record` gains a `re-entry` kind that appends to a
  run's `re_entry_history`, mirroring the run-record's `re_entry_history` def.
- `WORKFLOW.md` — the checkpoint table and the per-task loop description state the
  amend bound, the invalidation rule, and the terminal escalate.

## Acceptance criteria

- `AC-1` A `FAIL:fixable` verdict that does not name the criteria it amends and the
  criteria it invalidates is treated as incomplete, not as a pass.
- `AC-2` The agent that performed an amend cannot be the verifier on that amend's
  re-review; the verifier must be a different agent context.
- `AC-3` A material amend invalidates every downstream criterion it feeds; the loop
  re-verifies the amended criterion and its dependents, and the run-record's
  `invalidation` binding records which ones.
- `AC-4` After the amend bound (a specific number, decided in this change) the loop
  reaches a terminal `FAIL:escalate` with a telemetry row, and does not loop again.
- `AC-5` A denial that does not change the next pipeline step fails the change —
  tested by a denial that is recorded but produces no re-entry, which must not be
  a pass.

## Files touched

Edited: `skills/closed-loop/SKILL.md`, `.claude/agents/task-verifier.md`,
`.claude/lib/checkpoint.sh`, `WORKFLOW.md`. No new files.

## Risk

Low-to-medium for behavior, low for blast radius. The change is contained to the
verify loop, which is opt-in and only runs inside a harness run. The risk is not
correctness of the loop but over-application: if the amend semantics are too
aggressive they could turn ordinary fixable failures into escalations. The bound
on amend cycles is the release valve, and the number should be set from what the
phase-level loop already does (the braindumps cite `shared/library-standards.yaml`
for the amend-bound shape) rather than invented here. The other risk is the
"reviewer becomes author" rule colliding with COG's current single-agent default:
in solo mode there is no second agent to re-review. The change must define what a
re-review means when one agent does everything — e.g. a fresh read of the
deliverable against the criterion after a window, or a forced re-spawn — and say so
explicitly rather than assuming a team-mode second agent always exists.

## Unblock

Decide the amend-bound number and the solo-mode re-review definition. Both come
from reading what cadre already does at the phase level; neither should be guessed.
The run-record scaffold (change 1) must exist so `re_entry_history` has a place to
land.
