---
name: closed-loop
description: >
  Run one task through the V-model verification loop: CP-2 plan → CP-3 build →
  CP-3v component verify → CP-4 integration verify (full lane) → CP-5 acceptance.
  The worker never grades its own homework; evidence rows trace back to AC-n.
  Opt-in: invoke with /closed-loop or by asking for the closed loop, proper
  verification, or an evidence trail. Ordinary work does not run this.
---

# Closed-loop execute (V-model right arm)

Mechanical verification pipeline. Every verify step emits **evidence rows** tied to acceptance criterion IDs (`AC-n`).

## When to use

The harness is opt-in. Run it when:

- Invoked as `/closed-loop <task>` or `/closed-loop <spec-path>`.
- The user asks for the closed loop, proper verification, or an evidence trail.
- `verification_harness: on` in `00-inbox/MY-PROFILE.md` and this is a build task.
- Another skill that declares a `normal`+ lane reaches its verify step.

Do **not** run it on a request that did not ask for it. Notes, briefs, research, drafts, and ordinary edits are not harness runs, and a checkpoint ledger on those is pure overhead.

## Phase 0 — Lane + run folder

```bash
bash .claude/lib/lane-classify.sh explain "<task>"
bash .claude/lib/checkpoint.sh init 04-projects/harness/runs/<YYYY-MM-DD-HHmm>
```

| Lane | Checkpoints |
|---|---|
| `tiny` | CP-3 → CP-5 (if mutating) |
| `normal` | CP-1 → CP-2 → CP-3 → CP-3v → CP-5 |
| `full` | + CP-4 + claim-verifier + CP-6 |
| `bug` | root-cause ledger (CP-0) before CP-3 |

Record: `checkpoint.sh record <run-dir> CP-0 PASS|SKIP "<lane>"`

## Phase 1 — CP-1 Spec (acceptance criteria)

If spec exists, use its `## Acceptance criteria` + traceability matrix. Else write:

`04-projects/harness/runs/<id>/criteria.md` using `references/spec-template.md` (criteria + matrix sections only).

Each criterion: **falsifiable** + `AC-n` ID + verify method.

Record: `checkpoint.sh record <run-dir> CP-1 PASS "N criteria"`

## Phase 2 — CP-2 Plan

Map tasks → AC IDs in `evidence/CP-2-plan.md`. Update matrix status to `pending`.

Record: `checkpoint.sh record <run-dir> CP-2 PASS`

## Phase 3 — CP-3 Build

Worker implements. Returns deliverable path only.

**When a criterion says *every* file, build the enumeration before editing
anything, and enumerate by capability concept rather than by identifier.**

Doing it the other way round — fixing the locations a report named, then
believing the set was covered — failed three verification rounds in a row.
The third failure is the instructive one: the enumeration was real, but it
matched removed *verb names*, and the remaining defects asserted the
capabilities without naming any command ("TTL-based expiration", "the store
does have deletion capability"). No name-based search could have reached
them. Search for what the capability *is*, then confirm the count is zero by
re-running the same enumeration — not by rereading the files you edited.

Two mechanical habits, because careful reading demonstrably did not
substitute for either: check every occurrence in a file rather than the
first, and check for near-duplicate paragraphs, where one of a pair is stale.

## Phase 4 — CP-3v Component verify

```
retry=0
loop:
  spawn task-verifier (fresh context, read-only)
  merge EVIDENCE rows into evidence/ledger.md
  if PASS → break
  if FAIL:escalate → record CP-3v FAIL, escalate
  if FAIL:fixable && retry < 2 → fix-agent → retry++
  else → escalate
```

**The budget is two attempts, and it is not yours to extend.** The tempting
argument on a third failure is that the method has materially changed, so
this attempt is different in kind rather than a repeat. That argument was
made three times in one phase and was not baseless — each new method did
find defects the last one could not have. It was still the wrong call,
because it is the worker's own assessment of the worker's own work, which is
the judgment this budget exists to distrust.

On a third failure of the same criterion, stop and put it to the user:
name the pattern across the failures, propose the new method, and let them
decide whether to spend the attempt. That costs one message. Self-authorising
the attempt costs a round, and the round after it if you are wrong again.

Copy verifier EVIDENCE rows into `evidence/CP-3v-component.md`.

Record: `checkpoint.sh record <run-dir> CP-3v PASS|FAIL`

## Phase 5 — CP-4 Integration verify (`full` or multi-task)

Spawn `integration-verifier` (read-only). Append rows to ledger.

Skip for single-task `normal`.

Record: `checkpoint.sh record <run-dir> CP-4 PASS|SKIP`

## Phase 6 — CP-5 Acceptance (post-condition)

**If the run touched a repository with CI, check its runner before anything else:**

```bash
bash .claude/lib/ci-status.sh <repo>
```

A green local suite says nothing about the pushed commit. This has produced a
false PASS row in a real evidence trail — recorded from a local exit code
while the runner had been red since that same commit. Cite the run id.

For each mutation, observe artifact (curl, screenshot, re-fetch). Emit:

`EVIDENCE AC-n | CP-5 | PASS | <observation> | <artifact>`

**UI/UX flow changes:** the post-condition is *visual*. Screenshot every meaningful state with whatever browser tooling the environment has, then read the image and confirm no overflow, misalignment, clipping, wrong color, or broken responsive layout before PASS. The Observation must describe what you saw; the artifact is the screenshot/GIF in `evidence/`. Fix any visual defect and re-capture. See CLAUDE.md → Visual Verification.

Write `evidence/CP-5-acceptance.md`. **Traceability closure**: every AC in matrix has ≥1 PASS row in ledger.

Record: `checkpoint.sh record <run-dir> CP-5 PASS|FAIL`

### After a revert

`git checkout -- <file>` restores the file to HEAD, not to the state you
had in mind. If you reverted a probe, an injected test defect, or a bad
edit, and that file also held uncommitted work you meant to keep, the
revert took both. Diff against HEAD and confirm what survived before
continuing — a revert you believe happened is not a revert you observed.
This has already silently discarded three real edits in one session, one
commit after the rule was written down.

## Phase 7 — Record + handoff

- Append to `.claude/logs/loop-ledger.tsv`
- Update spec traceability matrix statuses to `verified`
- **`full` lane / big task:** generate an HTML rollup from `references/report-template.html` → `04-projects/harness/runs/<id>/report.html`, filled from `criteria.md` + `evidence/ledger.md` (criteria, AC traceability, verifier verdicts, post-condition observations). Self-contained; `SendUserFile` it or publish as an Artifact. Skip for `normal`/`tiny`.
- Suggest `/retro <run-dir>` for CP-7

## Integration

| Skill | Lane | CP-4 |
|---|---|---|
| `ultragoal` | `full` per phase (never downgraded) | integration-verifier + north-star acceptance |
| `team-brief` | full | claim-verifier |
| `comprehensive-analysis`, `auto-research` | full | claim-verifier on cited claims |
| `content-factory` | normal | skip |
| `review-cockpit` | normal | skip; CP-6 is the user's approval per card |

## Escalation template

```
ESCALATED — <task>
Lane: <lane> | Last CP: <CP-n>
Evidence bundle: 04-projects/harness/runs/<id>/evidence/
Open AC IDs: <list without PASS rows>
Decision needed: <one question>
```
