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

**An exclusion carries its own expiry, so write the reason next to it.**
`linux/arm64` was excluded from a platform list because it "needs either a native
arm64 runner or a cross toolchain". The runner arrived; the reason lapsed and the
exclusion did not, and a clean-machine install found it by having no binary to
fetch. No check can evaluate whether a prose reason still holds — but a bare
entry in a list of unsupported things outlives its justification invisibly,
whereas a stated reason can at least be read and found spent.

No check reaches this one, and the reason is worth stating: **nothing
observes an enumeration that was never run.** A search scoped too narrowly
produces output indistinguishable from a complete one, and the hits it
missed are missing from the evidence as well.

**A guard that parses a document to check it will keep disagreeing with the
document.** Generate the expected block from the source of truth and assert
the document contains it, verbatim.

gloop's `--config` table resisted three attempts written the other way round.
Each attempt parsed the README's table and each disagreed for a new reason:
one accused the README where the README was right (`config update` fails
argument validation before it ever reads `--config`), one searched the whole
file instead of the table so deleting a row left it green, one shared a
fixture between subcommands that overwrote the evidence it existed to read.
The fourth attempt enumerated the subcommands from the binary, classified
each by running it, rendered the table, and asserted the README contained
that block. The failure mode left over — the binary silently dropping a
subcommand from help — is a different check, against the dispatcher's own
registry.

The direction is the design decision, and no check observes it: a guard
pointed the wrong way is a working guard that happens to be wrong. What
signals it is three rounds failing on the same shape, which is what
`AI-18`'s escalation is for.

## Phase 4 — CP-3v Component verify

```
AMEND_BOUND=3
attempt=0
loop:
  spawn task-verifier (fresh context, read-only) — the re-reviewer must be a
  different context than the one that made the prior amend (reviewer becomes author)
  merge EVIDENCE rows into evidence/ledger.md
  if PASS → break
  if FAIL:escalate → record CP-3v FAIL, escalate
  if FAIL:fixable:
    attempt++
    if attempt > AMEND_BOUND → record terminal FAIL:escalate telemetry row, escalate
    record re-entry: checkpoint.sh record_reentry <run-dir> <attempt> "<reentry>" "<invalidates>" "<reason>"
    fix-agent applies the amend, stating which criteria it amends and which
    downstream criteria it invalidates (invalidation cascade) → loop
  else → escalate
```

**The budget is three attempts, and it is not yours to extend.** The tempting
argument on a fourth failure is that the method has materially changed, so
this attempt is different in kind rather than a repeat. That argument was
made three times in one phase and was not baseless — each new method did
find defects the last one could not have. It was still the wrong call,
because it is the worker's own assessment of the worker's own work, which is
the judgment this budget exists to distrust.

On a fourth failure of the same criterion, stop and put it to the user:
name the pattern across the failures, propose the new method, and let them
decide whether to spend the attempt. That costs one message. Self-authorising
the attempt costs a round, and the round after it if you are wrong again.

The amend count is observable; the judgment is not. A worker convinced this
attempt differs in kind from the last will record it as a first attempt at a
new method, and the count will agree with them.

### Mutate before believing a green test, and mutate more than once

A test that passes under the mutation it exists to catch is worse than no test:
it advertises a guarantee it does not check, and the next person reads the green
as coverage.

The `mutation-verify` skill exists for this. What failed in the team-readiness
goal was invoking it. A contention test written to prove deletion evidence
survives a lock race passed with its retry budget reverted, passed again with
the retry removed altogether, and then failed on unmodified code — three results
that cannot all be about the same property.

**The inconsistency is the finding.** Chasing why the mutations were
indistinguishable is what exposed the real defect: a `CREATE TABLE IF NOT
EXISTS` running before the INSERT was absorbing the contention, so which
statement failed depended on whether an earlier command had created the table.
One mutation would have hidden that. Two disagreeing mutations could not.

No check reaches this. Which mutation is meaningful *is* the claim the test
makes, so a program deciding that would already know what the test is for.

### A retry budget that a blocking call has already spent buys nothing

Before adding an application-level retry, check what the layer beneath already
waits for. SQLite's connection string carried `busy_timeout(5000)` and the
retry loop's deadline was the same five seconds, so the driver consumed the
entire budget inside the first `Exec` and the loop found its deadline expired
before its first check. The retry ran exactly once, which is not a retry.

Where a driver already waits, the application budget has to *exceed* the
driver's or it is decoration. And a budget is a claim about how much patience
the failure deserves: a write that can be re-run needs less than one that
happens after an irreversible mutation, where "try again" is not available.

### A fixture can destroy the evidence it exists to produce

Two shapes, both of which passed and meant nothing:

- **A fixture shared across subcommands.** One pair of files reused for
  `config setup` and `config update`; the second run overwrote the first, and the
  result was an empty row that read as a clean negative finding.
- **A normaliser applied to the output.** Path normalisation erased the config
  writers' only signal — the line `Wrote config to <path>` — so the test saw
  nothing where the thing it was checking for had been.

At the moment a check could look, an erased signal and a legitimately empty result
are the same value. What separates them is falsifying the *absence*: make the thing
appear, and confirm the check now sees it. That is CP-3v's existing discipline
pointed at a negative result instead of a positive one.

Related, and not fixable by a check: **a fixture can agree with the code and not
with the repository.** A test built its fake binary at a path the production code
read and the checkout never had; the two moved together through a refactor and
neither moved with the repository, so the test passed for as long as the code was
wrong in the same direction. Asserting that every in-tree path a resolver names
exists in a real checkout would be wrong more often than right — most are
legitimately absent until something creates them — so this stays a thing to look
for rather than a rule to enforce.

### When you built a check *and* a document telling people to satisfy it

Test the pair, not each half. Write the artifact the document instructs —
literally, following its own words — and run the check on it.

A check verified against inputs you formatted yourself proves the check
works. It proves nothing about whether anyone reading the instructions will
produce those inputs. `retro/SKILL.md` taught three spellings of a
disposition and the lint accepted a fourth, so an author following the
skill failed on their first attempt, for a convention stated nowhere. Both
halves were individually correct and independently verified; the defect
lived only at the join.

No check reaches this one. At authoring time there is no artifact to compare
against — the defect is that two artifacts were never brought together, and
nothing can observe that until someone does it.

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

**Observe the class of artifact the criterion names, and prefer the observation
that can say no.** Two failures, both from the same run:

- A criterion read "the lifecycle kernel has one release *home*, not two." The
  phase checked that the publishing *workflow* no longer targeted the second one
  and recorded PASS. Six phases later the north-star gate found six releases with
  downloadable assets still served from it. A workflow that has stopped publishing
  and a repository that serves nothing are indistinguishable from inside the
  workflow file, and nothing in that phase left it. If the criterion names a
  published thing, the evidence has to be the published thing.
- The gate that caught it cited `curl` on `.../releases/tag/<tag>` returning **200**
  as proof the release was live. That URL returns 200 for a bare git tag with no
  release behind it — it did so afterwards, with the releases deleted. Where an
  API can answer the question directly, an HTML page answering a nearby question
  is not the observation to cite. The verdict was right and the citation was weak,
  which is the combination nobody re-reads.

Write `evidence/CP-5-acceptance.md`. **Traceability closure**: every AC in matrix has ≥1 PASS row in ledger.

Record: `checkpoint.sh record <run-dir> CP-5 PASS|FAIL`

### Falsifying a check

Assert the injection landed before running the check. A `sed` that errors, a
`str.replace` whose target moved, a heredoc into a path that does not
exist — each leaves the check running against an unmodified file and
reporting a clean pass, which reads exactly like the check being correct.

That has now happened twice in one session, once reporting three consecutive
false passes. A falsification that cannot fail is the same defect as a guard
that cannot fail, one level up, and it is the more dangerous of the two
because it certifies the other.

### After a revert

`git checkout -- <file>` restores the file to HEAD, not to the state you
had in mind. If you reverted a probe, an injected test defect, or a bad
edit, and that file also held uncommitted work you meant to keep, the
revert took both. Diff against HEAD and confirm what survived before
continuing — a revert you believe happened is not a revert you observed.
This has already silently discarded three real edits in one session, one
commit after the rule was written down.

A hook could diff after every `git checkout --` and refuse the surprise.
COG ships no hook infrastructure, so this is a cost argument rather than an
impossibility — the same one that keeps the write-and-commit rule in
`CLAUDE.md` § Git out of a check, and both close together if hooks ever
arrive for another reason.

## Phase 7 — Record + handoff

- Append to `.claude/logs/loop-ledger.tsv`
- Update spec traceability matrix statuses to `verified`
- **Write the run-record.** Emit `04-projects/harness/runs/<id>/run-record.json` — the machine-enforceable provenance for this run (who ran it, what objective it was given, its current lifecycle phase, the evidence that backs it, what authority approved it, what findings were raised, what it invalidated). Map the V-model checkpoints to the run-record `current_lifecycle_phase` enum via the single source of truth in `05-knowledge/run-record.provenance.json` (CP-0 `intent` → CP-7 `feedback`); reference that mapping, do not re-type the enum. Lint it before finishing: `bash .claude/lib/run-record-lint.sh 04-projects/harness/runs/<id>` must exit 0. **A harness run with no lint-clean run-record is not a finished run.**
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
