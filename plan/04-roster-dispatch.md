---
type: plan
project: cog-cadre-integration
change: 04-roster-dispatch
created: 2026-09-02
depends_on: ["01-run-record"]
status: partially implemented
tags: ["#plan", "#roster", "#dispatch", "#specialists"]
---

# Change 4 — Roster dispatch for specialized execution

## The change

COG's workers are generic — data-collector, researcher, file-ops, executor,
publisher. When a skill needs a Go implementation reviewed by someone who is not
the author, or a technical write-up, it currently reuses a generalist. This change
lets a skill resolve domain-specialist roles from the cadre roster (the 159-role
catalog — go-implementer, code-reviewer, system-architect, technical-writer) and
dispatch them through a sandboxed runner, writing a run-record back so the
execution is audited the same way COG's own work is.

The roster is the one asset the agentic-sdlc braindumps say is worth keeping
verbatim. It already exists; this change consumes it.

## Why this is last, and why it is gated

This is the most speculative change and it carries a hard external dependency that
the other three do not: the roster and a sandboxed runner must be present in-vault
before anything here can run. Two things have to be true first:

- The roster is vendored into the vault with a drift check against its origin the
  way change 1 vendors the schema. **DONE (AC-1):** vendored at
  `05-knowledge/cadre-roster/` from `cadre/roster` at revision `5c40d6ec`, with
  `.claude/lib/cadre-roster-drift.sh` and a recorded combined digest in
  `.claude/lib/cadre-roster.manifest.sha256`. The package is self-contained —
  `roster.json` declares its own layout — so the copy stands on its own and the
  drift check fails on any hand-edit.
- A sandboxed dispatch path exists. The agentic-sdlc project notes that cadre's
  sandboxed dispatch (resolve role, compute sandbox, gate writes behind a token,
  spawn an agent CLI) and gloop's LLM tool-call loop are separate concerns, and the
  roster's execution orchestration is not yet fully settled in-vault. There is no
  confirmed in-vault runner to dispatch through.

Until both are true, change 4 is a description, not a build. It is listed so the
plan is complete and so the roster-vendoring work is visible as its prerequisite,
but it should not be started until change 1 has proven the vendoring-and-drift-check
pattern on the run-record schema.

## Where it lands

- `05-knowledge/cadre-roster/` — the vendored roster with its origin revision and
  drift check. DONE (AC-1); see `PROVENANCE.md`.
- A dispatch path — most likely an extension to `worker-executor` or a small new
  skill that resolves a role from the roster, computes a sandbox, and runs it. The
  shape is undecided pending the roster-vendoring decision.
- The run-record (change 1) records which role executed the work and under what
  sandbox — the audit trail that makes roster dispatch no less auditable than COG's
  own agents.

## Acceptance criteria

- `AC-1` The roster is vendored in-vault with a drift check that fails on an
  out-of-date copy. (Prerequisite; not a change to COG itself.) **DONE** —
  `05-knowledge/cadre-roster/` with `.claude/lib/cadre-roster-drift.sh`.
- `AC-2` A skill can resolve a named role from the roster and dispatch it through a
  sandboxed runner. (Depends on AC-1 and a confirmed runner.) **PENDING** — no
  sandboxed runner is confirmed in-vault yet.
- `AC-3` The dispatch writes a run-record naming the role and the sandbox.
- `AC-4` A dispatched specialist's output is reviewable by a different agent than
  the one that produced it — the same peer-review property the other three changes
  assume.

## Files touched

Depends entirely on the roster-vendoring decision. Likely new:
`05-knowledge/roster/`. Likely edited: `worker-executor.md` or a new skill entry.

## Risk

High, primarily from the external dependency and the fact that the execution
orchestration concern is not yet settled in the agentic-sdlc project. The change
itself is low-complexity once the prerequisites exist; the risk is starting it
before the roster and runner are available, which would produce a plan that cannot
run. It is gated on change 1 succeeding as the vendoring reference.

## Unblock

Confirm the roster is vendored in-vault and a sandboxed runner exists. Both are
decisions outside this vault. Until then change 4 is documentation of a dependency,
not work to do.

## Implementation (committed on plan/cadre-cog-integration)

AC-1 done. Vendored `cadre/roster` at revision `5c40d6ec` into
`05-knowledge/cadre-roster/` (356 files) — self-contained, since `roster.json`
declares its own layout (`catalog`, `routing`, `role_root`, `shared_policy_root`).
Drift check: `.claude/lib/cadre-roster-drift.sh` recomputes the combined sha256 of
every file and compares it to `.claude/lib/cadre-roster.manifest.sha256`; verified
PASS on a clean copy and FAIL on an injected tamper file. `PROVENANCE.md` records
the source, revision, digest, and re-vendoring steps.

AC-2/AC-3/AC-4 pending. The dispatch behavior needs a confirmed sandboxed runner;
cadre's sandboxed dispatch and gloop's tool-call loop are separate concerns and
neither is confirmed as an in-vault runner. Until one is, change 4 is the
roster-vendoring prerequisite (done) plus a description of the dispatch skill
(not built).

not work to do.
