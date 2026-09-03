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
governance stack into COG's second-brain harness. This is a plan and the work to
implement it, living on the `plan/cadre-cog-integration-core` branch of this
worktree's repo. Changes 1–3 are implemented and committed there; Change 4 was
built, then descoped and removed — the table and the sequencing section below
record why. The worktree exists so the plan has an isolated place to live and so
file paths below resolve against a real checkout.

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

| # | Change | What it adds | Primary files | Risk | Status |
|---|---|---|---|---|---|
| 1 | Run-record as the shared object | Every harness run emits a run-record with auditable provenance | new schema + template, `closed-loop/SKILL.md`, `WORKFLOW.md`, new lint | low | implemented (`1d8966b`) |
| 2 | Per-task amend semantics | COG's CP-3v verify loop gets deny/re-entry teeth | `closed-loop/SKILL.md`, `task-verifier.md`, `checkpoint.sh`, `WORKFLOW.md` | low | implemented (`8a07f03`) |
| 3 | Gate the high-consequence mutations | External writes go through a named authority + explicit approval | four publishing skills + `worker-publisher` | medium | **on this branch — not ready** (see below) |
| 4 | Roster dispatch for specialized execution | — | — | high | **descoped** (see below) |

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
4. Roster dispatch — descoped. It was built (`a40c471`, `9b443bc`) and then
   removed, for a reason the build surfaced rather than a change of taste.

   The `cadre@cadre-team` plugin is installed user-scope and auto-updating, and
   it already exposes all 159 roles as named, dispatchable agents carrying their
   capability tier's tools. Comparing its `catalog.yaml` against the vendored
   copy gives 159 role ids on each side and an empty diff. So vendoring the
   roster into `05-knowledge/` produced a frozen second copy of a live one: the
   drift check would eventually fire because the *plugin* had moved, and the
   resolve/dispatch layer reimplemented a named dispatch the runner already
   does natively — `runner-capabilities.json` records
   `named_agent_dispatch_supported: true` for claude-code, and the skill had to
   be corrected during review for documenting codex's `spawn_agent` instead.

   The packaging boundary said the same thing independently: `FRAMEWORK_FILES`
   is a flat file list, so the 357-file roster cannot ship, and
   `/roster-dispatch` worked in exactly one checkout.

   This is the "two authorities for one shape" defect recorded in the
   2026-08-28 braindump, one level down. Nothing else depends on it — neither
   `run-record-lint.sh`, `checkpoint.sh` nor `closed-loop/SKILL.md` references
   the roster. If COG wants specialist dispatch, the cheap version calls the
   installed plugin by role name and writes a run-record; it needs no vendored
   copy.

### Change 3 — this branch, and what is still wrong with it

Gating the external mutations was built here and moved to `plan/cadre-cog-gates`
(at `5205029`) to be designed once rather than patched a fifth time. Four review
passes each found defects in it, including every high-severity finding across all
four; Changes 1 and 2 produced only mechanical defects that stayed closed.

The last pass found the reason the patching was not converging. The gate as built
did not gate anything:

- `content-factory` is "designed to run unattended on a schedule (nightly)", and
  the gate text instructed the *agent* to record the approval and then publish —
  the agent signing its own permission slip. `team-brief`'s Linear sync-back had
  the same shape.
- The check meant to catch that matched on gate number alone, so any prior G8 or
  G9 row satisfied the gate for an unrelated artifact. Demonstrated: a G8 row for
  a wiki page cleared a Slack post.
- The artifact it should have matched on is unknowable at approval time — a new
  page's URL is assigned by the server on POST, so "record the approval before
  the page is created" against `<page-url>` cannot be satisfied.

A control that looks like a control but passes unconditionally is worse than no
control, so it did not ship with Changes 1-2. This branch carries it for redesign.

One of the four is fixed here: `record_approval` now rejects any gate outside
G7/G8/G9, so a typo can no longer write a row that neither consumer will match.
The other three are open, and they are the design question, not a patch: who
records an approval so that it attests a human decision rather than the agent's own
intent; what durable identity it binds to, given the artifact URL does not exist
until after the mutation; and whether an unattended nightly pipeline may publish at
all. Answer those three and the check writes itself.

Until then the pre-existing discipline stands unchanged — `CLAUDE.md` § Skill
Post-Condition Rule already requires explicit approval before an external mutation
and observation of the artifact after it.

Each sub-plan below is self-contained: the change, the files it touches, the
acceptance criteria that define done, the risk, and the one decision that unblocks
it. Read `01-run-record.md` first; `02-per-task-amend.md` cross-references it.

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
  project's call. This plan consumes the outcome (the run-record schema) as it
  stands.
- No vendored roster. Specialist dispatch, if COG ever wants it, goes through
  the installed `cadre` plugin rather than a copy in the vault (see Change 4).
- No implementation. These documents specify what done looks like, not how each
  line is written.
