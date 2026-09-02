---
type: plan
project: cog-cadre-integration
created: 2026-09-02
status: draft
tags: ["#plan", "#integration", "#cadre", "#cog", "#harness"]
---

# Plan: agentic-lifecycle + cadre in conjunction with COG

## What this is

Four contained changes that wire the cadre/agentic-lifecycle execution and
governance stack into COG's second-brain harness. This is a plan, not the
change. Nothing here is implemented; the worktree exists so the plan has an
isolated place to live and so file paths below resolve against a real checkout.

The composition the four changes assume:

- COG is the remember / decide / intel layer. It holds long-term human memory,
  personal context, knowledge capture and consolidation, and intelligence
  gathering. It answers what is worth doing and why, and it records what it
  learned.
- cadre / agentic-lifecycle is the execute / govern / verify layer. It dispatches
  to domain specialists (the 159-role roster), runs a lifecycle with gates,
  sandboxes dispatch with an authorization model, and produces an evidence chain
  a human can audit. It answers how to build something correctly.
- The run-record is the object that flows between them. It is the one place the
  two loops share a single shape.

Both sides already implement the same non-negotiable rule — a worker never grades
its own homework — independently. COG does it as a V-model harness with fresh
read-only verifiers; cadre does it as peer-review-as-structural-property plus
G1-G10 gates with named human authorities. The point of this work is to stop both
from re-deriving it from scratch, and to give them one auditable object.

## Why not the whole lifecycle

The ten-phase G1-G10 sequence is governance for shipping software: intent,
requirements, architecture, security-crypto, deployment-auth, runtime-conformance.
COG's tasks are knowledge work, not a release. Routing every braindump through ten
human authorities would destroy COG's value, which is low-friction capture. The
lifecycle applies only where the cost of a wrong external mutation is high, or
where knowledge other people will rely on is written. The four changes below are
the seams where that applies; they are not an attempt to make COG an SDLC.

There is also a nuance worth stating so the plan does not inherit an error.
"agentic-lifecycle + cadre" is not one clean thing. The architecture in the
agentic-sdlc project is splitting across four repositories: `cadre/kernel` owns
the lifecycle contracts, `recall` the knowledge store, `gloop` the LLM tool-call
loop, `cadre` the roster and sandboxed dispatch. The `agentic-lifecycle` Python
repo is mostly a starter template — its `run-record.yaml` is an example document
with placeholder values, not a schema. The authoritative lifecycle contract is
`cadre/kernel/contracts/run-record.schema.json`, 24 required fields and thirteen
`$defs`. This plan targets that schema, not the Python package.

## The four changes

| # | Change | What it adds | Primary files | Risk |
|---|---|---|---|---|
| 1 | Run-record as the shared object | Every harness run emits a run-record with auditable provenance | new schema + template, `closed-loop/SKILL.md`, `WORKFLOW.md`, new lint | low |
| 2 | Per-task amend semantics | COG's CP-3v verify loop gets deny/re-entry teeth | `closed-loop/SKILL.md`, `task-verifier.md`, `checkpoint.sh`, `WORKFLOW.md` | low |
| 3 | Gate the high-consequence mutations | External writes go through a named authority + explicit approval | `publish-to-confluence`, `team-brief`, `content-factory` skills | medium |
| 4 | Roster dispatch for specialized execution | Skills resolve domain specialists from the roster and dispatch them | worker-executor / new skill; roster vendored first | high |

## Sequencing

Order by value-to-risk, with the run-record scaffolded first because it is the
foundation everything else reads, even though its full wiring comes later.

1. Run-record scaffold — schema, template, drift check, and the rule that a run
   without one is incomplete. Standalone and additive; existing COG files do not
   change. This is the shared object, so it unblocks 2 and 3.
2. Per-task amend semantics — the largest behavior change of the four, but
   contained to the verify loop COG already has. Highest value per line of code.
   Depends on the run-record only for `re_entry_history`.
3. Gate the high-consequence mutations — touches three skills and needs an
   authority mapping decided up front. Depends on the run-record for the approval
   trail.
4. Roster dispatch — most speculative, and it depends on the roster being
   available in-vault before anything else. Last, and gated on that dependency.

Each sub-plan below is self-contained: the change, the files it touches, the
acceptance criteria that define done, the risk, and the one decision that unblocks
it. Read `01-run-record.md` first; the others cross-reference it.

## The rule that governs all four

Three defects on 2026-08-28 taught one thing and it applies at this scale too:
two authorities for one shape drift, and drift silently. It held at file scale
(`finding.schema.json` against a Go allowlist) and it holds here. Every change
below names one owner for each shape it introduces, and where a shape already
exists the change vendors it from that owner with a drift check rather than
re-declaring it. The run-record schema has one source of truth. The amend
semantics live in one skill. The authority mapping is one registry. Nothing
below creates a second claim.

## What is out of scope

- No porting of the full G1-G10 lifecycle onto COG.
- No change to COG's capture-loop speed or its low-friction braindumps.
- No decision on the four-repository split itself; that is the agentic-sdlc
  project's call. This plan consumes the outcome (the run-record schema, the
  roster) as it stands.
- No implementation. These documents specify what done looks like, not how each
  line is written.
