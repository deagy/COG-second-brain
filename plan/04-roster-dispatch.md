---
type: plan
project: cog-cadre-integration
change: 04-roster-dispatch
created: 2026-09-02
depends_on: ["01-run-record"]
status: implemented
tags: ["#plan", "#roster", "#dispatch", "#specialists"]
---

# Change 4 — Roster dispatch for specialized execution

## The change

COG's workers are generic — data-collector, researcher, file-ops, executor,
publisher. When a skill needs a Go implementation reviewed by someone who is not
the author, or a technical write-up, it currently reuses a generalist. This change
lets a skill resolve domain-specialist roles from the cadre roster (the 159-role
catalog — `application-engineer`, `code-reviewer`, `cloud-architect`,
`architecture-diagram-author`) and dispatch them through a sandboxed runner,
writing a run-record back so the execution is audited the same way COG's own work
is.

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
- A sandboxed dispatch path exists. The roster's `runner-capabilities.json`
  confirms the runner: claude-code agent teams dispatch a role as
  `agents:<role-id>` (or a project-local override) behind the
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` flag, with `native_workspace_isolation`
  of a worktree and a blocking `PreToolUse` hook that enforces the sandbox. The
  sandbox a role runs in is fixed by its `capability` tier in the catalog
  (`read_only` -> read-only; every authoring/operator tier -> workspace-write),
  which is exactly what the dispatch resolves. This was the gating dependency; it
  is now met.

Until both are true, change 4 is a description, not a build. It is listed so the
plan is complete and so the roster-vendoring work is visible as its prerequisite,
but it should not be started until change 1 has proven the vendoring-and-drift-check
pattern on the run-record schema.

## Where it lands

- `05-knowledge/cadre-roster/` — the vendored roster with its origin revision and
  drift check. DONE (AC-1); see `PROVENANCE.md`.
- The dispatch path — `roster-dispatch` skill (`.claude/skills/roster-dispatch/`),
  which resolves a role, loads its `AGENT.md`, computes the sandbox, dispatches it,
  writes a run-record, and routes the output to a different agent for review. The
  resolver (``.claude/lib/cadre-roster-resolve.sh``) and run-record generator
  (`.claude/lib/cadre-dispatch-record.py``) are its two library helpers.
- The run-record (change 1) records which role executed the work and under what
  sandbox — the audit trail that makes roster dispatch no less auditable than COG's
  own agents.

## Acceptance criteria

- `AC-1` The roster is vendored in-vault with a drift check that fails on an
  out-of-date copy. (Prerequisite; not a change to COG itself.) **DONE** —
  `05-knowledge/cadre-roster/` with `.claude/lib/cadre-roster-drift.sh`.
- `AC-2` A skill can resolve a named role from the roster and dispatch it through a
  sandboxed runner. (Depends on AC-1 and a confirmed runner.) **DONE** — the
  `roster-dispatch` skill resolves a role via `cadre-roster-resolve.sh`, which
  reports the sandbox mode fixed by the role's `capability` tier, and dispatches it
  through the confirmed runner (claude-code agent teams, gated by a `read_only` /
  workspace-write sandbox).
- `AC-3` The dispatch writes a run-record naming the role and the sandbox. **DONE**
  — `cadre-dispatch-record.py` emits a schema-valid run-record (validated by
  `run-record-lint.sh`) whose `scope`, specialist attestation, and build/verify
  gates name the dispatched role and its sandbox.
- `AC-4` A dispatched specialist's output is reviewable by a different agent than
  the one that produced it — the same peer-review property the other three changes
  assume. **DONE** — the skill routes the output to a different agent for review;
  the lead that dispatched the specialist cannot be the reviewer.

## Files touched

- `.claude/skills/roster-dispatch/SKILL.md` — the dispatch skill (AC-2/3/4).
- `.claude/lib/cadre-roster-resolve.sh` — resolve a role from the catalog; prints
  the sandbox mode, model/effort, and AGENT.md path (`--list`, `--key` helpers).
- `.claude/lib/cadre-dispatch-record.py` — emit a schema-valid run-record naming
  the dispatched role and sandbox.
- `05-knowledge/cadre-roster/` — the vendored roster (AC-1, prerequisite).

## Risk

Low now that the prerequisites are met: the roster is vendored and drift-checked,
and the runner (claude-code agent teams) is confirmed in `runner-capabilities.json`.
The remaining risk is operational, not architectural — a `read_only` specialist
dispatched through `spawn_agent` (Cline) instead of claude-code's native
`PreToolUse` hook is gated by a behavioral contract, not a hard tool block, so the
skill fails closed by treating a `read_only` write as a sandbox violation.

## Unblock

Unblocked. The roster is vendored in-vault (AC-1) and the sandboxed runner is
confirmed in `runner-capabilities.json`; change 4 is built, not just documented.

## Implementation (committed on plan/cadre-cog-integration)

AC-1 done. Vendored `cadre/roster` at revision `5c40d6ec` into
`05-knowledge/cadre-roster/` (356 files) — self-contained, since `roster.json`
declares its own layout (`catalog`, `routing`, `role_root`, `shared_policy_root`).
Drift check: `.claude/lib/cadre-roster-drift.sh` recomputes the combined sha256 of
every file and compares it to `.claude/lib/cadre-roster.manifest.sha256`; verified
PASS on a clean copy and FAIL on an injected tamper file. `PROVENANCE.md` records
the source, revision, digest, and re-vendoring steps.

AC-2 done. `roster-dispatch` skill resolves a role via
`cadre-roster-resolve.sh`, which reads `catalog.yaml` and prints the role's
`capability`-derived `sandbox_mode` (read-only vs workspace-write, per
`runner-capabilities.json` `capability_tiers`), model, codex model, reasoning
effort, and the AGENT.md path. The skill loads the AGENT.md, dispatches the role
through the confirmed runner (claude-code agent teams behind
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, sandbox enforced by the runner's
`PreToolUse` hook, or a behavioral contract under Cline's `spawn_agent`), and
routes the output to a different agent for review.

AC-3 done. `cadre-dispatch-record.py` emits a schema-valid run-record (v2) that
names the dispatched role and sandbox in `scope`, the specialist attestation, and
the build/verify gates; it maps the catalog phase onto the schema's agentic-sdlc
lifecycle enum and validates clean under `run-record-lint.sh`.

AC-4 done. The skill routes the output to a different agent than the one that
produced it; the dispatching lead cannot be the reviewer.

