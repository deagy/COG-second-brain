---
name: roster-dispatch
description: Dispatch a domain specialist from COG's vendored kadre roster. Resolves a role from catalog.yaml, loads its AGENT.md, computes the sandbox from the capability tier, spawns it through a sandboxed runner, writes a run-record (Change 4 AC-2/3), and routes the output to a different agent for peer review (AC-4).
---

# roster-dispatch: dispatch a kadre specialist

A skill that needs a Go implementation reviewed by someone who is not the author,
a technical write-up, or any bounded specialist work should resolve the right
role from the roster and dispatch it — not reuse a generalist. The roster
(`05-knowledge/cadre-roster/`) is the vendored source of truth for the ~159
specialists; this skill consumes it.

The dispatch is audited like any other COG work: the run-record (Change 1)
records which role executed under what sandbox, and the output is reviewed by a
different agent than the one that produced it.

## 0. WHEN TO USE THIS

Use it when the task is bounded enough to hand to a single specialist role — a
review, an implementation slice, a diagram, a write-up. Do not use it to replace
the lead's own reasoning or to fan out a whole project; route the work, do not
disappear into it.

## 1. RESOLVE THE ROLE

Ask the agent for a role id, or resolve one from a description.

```bash
# exact role id
bash .claude/lib/cadre-roster-resolve.sh <role-id>

# discover roles by phase + capability when no id is given
bash .claude/lib/cadre-roster-resolve.sh --list
```

The resolver prints `role_id`, `phase`, `capability`, `sandbox_mode`, `model`,
`codex_model`, `reasoning_effort`, and `definition` (the AGENT.md path). If the
role id is unknown it exits 1 — do not guess a role id, pick one from the list.

For the plan's illustrative use cases the real roster ids are:

| Intent in the plan        | Roster role id          | Capability      |
|---------------------------|-------------------------|-----------------|
| implement a code slice    | `application-engineer`  | code_author     |
| review Go implementation  | `code-reviewer`         | read_only       |
| architecture / design     | `cloud-architect`       | document_author |
| diagram / technical write | `architecture-diagram-author` | document_author |

## 2. LOAD THE ROLE DEFINITION

The resolver returns `definition`, a path relative to the roster root. Read it —
it is the role's AGENT.md and is the specialist's system prompt. Do not paraphrase
it; the specialist behaves according to what it says.

```bash
ROSTER=05-knowledge/cadre-roster
ROLE=<role-id>
DEF=$(bash .claude/lib/cadre-roster-resolve.sh --key definition "$ROLE")
cat "$ROSTER/$DEF"
```

## 3. COMPUTE THE SANDBOX

The capability tier fixes the sandbox; do not let the specialist write outside it.

| capability         | sandbox_mode    | tools the role may use                     |
|--------------------|-----------------|--------------------------------------------|
| `read_only`        | read-only       | Read, Grep, Glob                           |
| `document_author`  | workspace-write | Read, Grep, Glob, Bash, Edit, Write        |
| `code_author`      | workspace-write | Read, Grep, Glob, Bash, Edit, Write        |
| `test_author`      | workspace-write | Read, Grep, Glob, Bash, Edit, Write        |
| `environment_operator` | workspace-write | Read, Grep, Glob, Bash, Edit, Write    |

`read_only` is the hard case: the specialist may inspect but must not write. When
spawning via `spawn_agent` (Cline) rather than claude-code's PreToolUse hook,
enforce this as a behavioral contract in the task: the role reads and reports,
never edits. When dispatching through claude-code agent teams, the sandbox is
enforced natively by the runner (runner-capabilities.json, `capability_tiers`).

## 4. DISPATCH

Spawn the specialist as a sub-agent. Give it the AGENT.md (step 2) as its system
prompt and a single, bounded task. The specialist writes its output to a file and
returns only a short status + path — never the full output inline.

```bash
spawn_agent(
  systemPrompt="<contents of the role's AGENT.md>",
  task="<bounded task; reference the output file to write>",
)
```

Dispatch one specialist per call. If a task needs an accountable role plus a
supporting specialist, dispatch the accountable role first (it owns design and
scope), then the support role under it — the roster's model heuristic routes
bounded execution specialists to haiku and keeps the accountable role at the tier
of the work.

Set the model/effort to what the resolver reports (e.g. opus/high for
architecture and governance-judgment calls, sonnet/medium for build and review,
haiku/low for a single bounded slice). Do not upgrade the tier to get a "smarter"
answer — the tier is the blast-radius control, not a quality dial.


## 5. WRITE THE RUN-RECORD

Every dispatch writes a run-record so the execution is audited the same way COG's
own work is. It names the role and the sandbox (AC-3).

```bash
bash .claude/lib/cadre-dispatch-record.py \
  <role-id> <sandbox_mode> <model> <codex_model> <reasoning_effort> \
  <phase> <task-id> <baseline-revision> <run-dir>/run-record.json
```

Feed it the values the resolver printed (step 1) and a task id. Then validate:

```bash
bash .claude/lib/run-record-lint.sh <run-dir>   # must PASS
```

The run-record goes in the dispatch's run directory alongside the specialist's
output, so the audit trail lives with the work.

## 6. PEER-REVIEW (AC-4)

The specialist's output is not final until a different agent than the one that
produced it reviews it. The lead that dispatched the specialist cannot be the
reviewer — that is the peer-review property all four changes assume. Route the
output to another sub-agent (or yourself in a fresh context) with the output file
and what "done" means; the reviewer confirms or requests changes.

## 7. GATES AND FAIL-CLOSE

- If the roster drift check fails (`cadre-roster-drift.sh`), do not dispatch —
  re-vendor first. A stale roster is a stale org chart.
- If the role id is unknown, do not invent one. Pick from the list.
- If the run-record fails lint, do not mark the dispatch complete. Fix or
  re-generate it.
- A `read_only` specialist that writes is a sandbox violation — treat it as one.
