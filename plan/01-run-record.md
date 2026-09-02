---
type: plan
project: cog-cadre-integration
change: 01-run-record
created: 2026-09-02
depends_on: []
status: implemented
tags: ["#plan", "#run-record", "#provenance", "#shared-object"]
---

# Change 1 — Run-record as the shared object

## The change

Every harness run emits a run-record alongside its deliverable. COG already asks
for a citation on every durable note (`[Source: path | date | confidence]`), but
that is prose and it is checked by eye. The run-record is the machine-enforceable
version: one JSON object per run that captures who ran it, what objective it was
given, what phase it is in, what evidence backs it, what authority approved it,
what findings were raised, and what downstream knowledge it invalidated. It is the
object that makes COG's knowledge and cadre's execution share a single auditable
shape instead of two parallel claims.

The schema is already written. It is `cadre/kernel/contracts/run-record.schema.json`:
24 required fields, `additionalProperties: false`, thirteen `$defs` — identity,
evidence, knowledge, artifactBinding, authorityRequirement, approval, finding,
exception, invalidation, gate, impactItem, impactProfile — and a
`current_lifecycle_phase` enum built from the ten-phase sequence plus `build` and
`feedback`. This plan vendors that schema as COG's single source of truth; it does
not re-write it.

## Where it lands

- `05-knowledge/run-record.schema.json` — the vendored schema, copied from
  `cadre/kernel/contracts/`, marked with its origin revision and a drift note.
- `06-templates/run-record.template.json` — an annotated example a run fills in,
  so the shape is discoverable without opening the schema.
- `skills/closed-loop/SKILL.md` — Phase 7 gains a step: write the run-record for
  the run and mark the run incomplete without it.
- `WORKFLOW.md` — the File homes table gains a row; the Scope section gains one
  sentence that a harness run without a run-record is not a finished run.
- `.claude/lib/run-record-lint.sh` — validates a run-record against the schema and
  fails if the vendored copy has drifted from its stated origin.

## The COG-to-lifecycle phase mapping

The run-record enum is a software-lifecycle sequence. COG's V-model is a different
ordering, so the mapping is a decision to record, not an inheritance. The sensible
one:

- CP-0 intake → `intent`
- CP-1 spec → `requirements`
- CP-2 plan → `architecture-design` (the plan is the design of the work itself)
- CP-3 build → `build`
- CP-3v / CP-4 verify → `verification`
- CP-5 acceptance → `evidence`
- CP-6 ship → `release-readiness`
- CP-7 retro → `feedback`

This is the one place COG borrows the enum, and it should stay a mapping table in
one file, not a second implementation of the lifecycle.

## Acceptance criteria

- `AC-1` A run-record.json exists for the run under its run folder, and a harness
  run that produces no run-record fails the run's own completeness check.
- `AC-2` The run-record validates against the vendored schema with no schema edits.
- `AC-3` A drift check fails when the vendored schema is edited by hand away from
  its stated origin revision.
- `AC-4` The lint script is runnable today: `bash .claude/lib/run-record-lint.sh
  <run-dir>` exits 0 on a well-formed run-record and 1 otherwise.
- `AC-5` The phase mapping is recorded in exactly one file and referenced, not
  re-implemented, in the skill.

## Files touched

New: `05-knowledge/run-record.schema.json`, `06-templates/run-record.template.json`,
`.claude/lib/run-record-lint.sh`. Edited: `skills/closed-loop/SKILL.md`,
`WORKFLOW.md`.

## Risk

Low. The change is additive; existing COG files are not altered in behavior, only
annotated. The real risk is the one this whole plan is built to avoid: a second
claim on the run-record shape. The fix is structural — one vendored copy, one drift
check, and the schema is never re-declared in a skill or note. The lint script is
what makes the drift a failing test rather than a silent one.

## Unblock

The one decision needed before this can be built: confirm the run-record schema is
vendored from the current `cadre/kernel` revision and pin that revision in the
schema header. Everything downstream depends on that one copy being the source of

## Implementation (committed: 1d8966b)

Vendored the authoritative `cadre-kernel/kernel/contracts/run-record.schema.json`
(rev `d4fb0894`, sha256 `0a14c607`) as `05-knowledge/run-record.schema.json` — byte-for-byte,
no edits. Added `05-knowledge/run-record.provenance.json` (origin + the COG-CP→lifecycle
mapping in one place), `06-templates/run-record.template.json` (a valid, lint-fillable
example), and `.claude/lib/run-record-lint.sh` (schema validation via jsonschema draft
2020-12 + a sha256 drift check). `skills/closed-loop/SKILL.md` Phase 7 now emits a
lint-clean run-record for every harness run; `WORKFLOW.md` records the mapping and states
a run without a run-record is not finished.

AC-2/AC-3/AC-4 validated: the template and a real `cadre` run-record pass lint; a
hand-edited schema and a malformed record both fail. One correction from the plan: the
phase mapping uses the run-record enum's actual members (`architecture`, `verify`) rather
than the plan's shorthand (`architecture-design`, `verification`) — the shorthand would
not have validated.

truth.
