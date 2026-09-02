---
name: ultragoal
description: >
  Run a large, multi-session goal (e.g. shipping a whole side product) through the full V-model
  closed loop, one phase at a time, with cross-session state and a final
  north-star acceptance gate. Ultragoals never downgrade the lane: every
  phase runs CP-1→CP-6 with adversarial verification. Opt-in: invoke with
  /ultragoal or by calling something a long-running goal. Ordinary work does not
  run this.
---

# Ultragoal — the closed loop for goals too big to ship in one run

An **ultragoal** is the term for a north-star that spans many sessions: fork the repos, combine the strong parts, ship one product. A `/closed-loop` run is one task through the loop. An ultragoal is a *chain of phases*, each of which is its own full closed-loop run, tracked so any cold session can resume.

**Core rule (from dwarves-kit, adopted fully): the worker never grades its own homework, and wrongness compounds across sessions — so verify every phase, not just the end.**

## When to use

- `/ultragoal <name>` — resume or advance an existing ultragoal
- `/ultragoal new "<north-star>"` — charter a new one
- `/ultragoal status` — report all ultragoals from the registry
- Trigger phrases: "make this an ultragoal", "this is a long-running goal", "combine these into one product over time"

Do **not** use for single-run work (that is `/closed-loop`), and do not start one on a request that never asked for one. Rule of thumb: if it needs a phase decomposition and won't finish today, it is an ultragoal.

## Files (one goal = one folder)

| File | Role |
|---|---|
| `04-projects/harness/ultragoals.md` | Registry: every ultragoal, status, current phase |
| `04-projects/<goal>/spec.md` | Contract: north-star + `AC-n` acceptance criteria + phases `P0…Pn` + traceability matrix |
| `04-projects/<goal>/STATUS.md` | Living ledger: phase state, current phase, open `AC-n`, next action (resume from here) |
| `04-projects/<goal>/evidence/P<n>/` | Per-phase evidence bundle (ledger.md + CP-* files) |

Code, if any, lives outside the vault (e.g. `~/code/<goal>/`) — the spec/status/evidence stay in the vault.

## Phase 0 — Charter (`/ultragoal new`)

1. Interview the user for the **north-star** in one sentence (what "done" looks like).
2. Write `04-projects/<goal>/spec.md` from `../closed-loop/references/spec-template.md`:
   - North-star statement
   - Falsifiable `AC-n` acceptance criteria (these define done for the *whole* goal)
   - Phase decomposition `P0…Pn` — each phase is a shippable increment mapped to a subset of `AC-n`
   - Traceability matrix (`AC-n` ↔ phase ↔ status)
3. Create `STATUS.md` (see template below) and add a row to the registry.

Before recording CP-1, run the criteria past the two shapes that cannot be
satisfied inside the phase that owns them:

```bash
bash .claude/lib/spec-lint.sh 04-projects/<goal>
```

- **A criterion verified against a published artifact** depends on whichever
  phase publishes it. `AC-11` of the repo-consolidation goal read "accepted
  by an installed released kernel", and the release it needed came from a
  phase that had not run. The criterion was not wrong; it was unsatisfiable
  where it sat.
- **A universal negative** — "no third definition survives", "no X exists
  outside Y" — is a claim about everywhere, and can only be checked against a
  named, bounded set. `AC-05` asserted one, was closed on a filename search,
  and an executable implementation turned out to have survived in an
  archived-but-still-installable repository.

This is a charter-time check, and it skips any criterion the traceability
matrix records as `verified`: one that was satisfied has answered the
question by demonstration. Without that skip it fires forever on closed
goals — repo-consolidation's AC-05 and AC-11 read exactly as they did before
their amendment, because the amendment moved the criterion to a later phase
rather than rewording the row. A lint that cries wolf on shipped work gets
turned off, and then it is advice again.

Record: `bash .claude/lib/checkpoint.sh record 04-projects/<goal>/evidence/P0 CP-1 PASS "N criteria, M phases"`

## The phase loop (every phase, no lane downgrade)

Each phase runs the **full** closed loop. Do not shortcut with `tiny`. Ultragoals are `full` lane by construction.

```
select next phase from STATUS.md
        │
        ▼
CP-2 PLAN     tasks for this phase ↔ AC-n   → evidence/P<n>/CP-2-plan.md
        │
        ▼
CP-3 BUILD    worker implements (traced to AC-n); returns paths only
        │
        ▼
CP-3v VERIFY  task-verifier (fresh context, read-only) → evidence rows per AC-n
        │       ├── FAIL:fixable → fix-agent (max 2) → re-verify
        │       └── FAIL:escalate → stop, escalate to the user
        ▼
CP-4 INTEGRATE  integration-verifier → does this phase wire correctly with prior phases?
        │        (always run for ultragoals — cross-phase regression is the main risk)
        ▼
CP-5 ACCEPT   observe the artifact (curl / screenshot / re-fetch), not the tool return
        │       EVIDENCE AC-n | CP-5 | PASS | <observation> | <artifact>
        ▼
CP-6 SHIP     external mutation? → Review Gate: you approve. Internal? → auto.
        │
        ▼
update STATUS.md (phase → done, advance current phase, log open AC-n)
        │
        ▼
CP-7 RETRO    /retro 04-projects/<goal>/evidence/P<n>  → harvest + STATUS
```

Merge every verifier's `EVIDENCE` rows into `evidence/P<n>/ledger.md`.

## The two acceptance gates

1. **Per-phase (CP-5):** every `AC-n` this phase claims has a PASS row before the phase is marked done.
2. **North-star (final):** before the ultragoal is declared complete, spawn a fresh-context verifier whose only job is to check the spec matrix — **every** `AC-n` across all phases has ≥1 PASS evidence row. Any `AC-n` without one is a gap, not a ship. This is the ultragoal-level analogue of CP-5.

### Before either gate: the repositories must be green on their own runners

```bash
bash .claude/lib/ci-status.sh <each repo the trail makes claims about>
```

Non-zero means a phase cannot be marked done. A commit with no run, or a run
still in progress, is not green either — absence of a check is not a pass.

**This is a gate rather than advice because it has already failed silently.**
The repo-consolidation ultragoal recorded "full suite green" for AC-02 at a
commit whose runner was red, and stayed wrong for nine more pushes; two of its
three repositories were red for months, each because a cross-repository guard
built to refuse to skip under CI had been given no way to run. Every one
passed locally off a sibling checkout that exists on a developer machine and
never on a runner.

Pointed at that commit today, this check reports
`FAILED validate run 33235161357` and exits 1.

**A local test exit code is evidence about a laptop.** Write the run id into
the ledger, not the word "green".

**Cutting a release is the same check, one step earlier.** In most of these
repositories the release job and the validate job trigger on the same push and
neither waits for the other, so a release can publish from a commit whose suite
is failing — `cli-v0.7.0` and `plugin-v0.24.0` both did. Run `ci-status.sh`
against the commit *before* tagging it, not only before the gate.

The release job could require the validate run's conclusion, and that is a cost
decision rather than an impossibility: it serialises every release behind a full
matrix. Until someone decides that trade is worth it, this is a step you run.

### And every phase must have been asked its gates

```bash
bash .claude/lib/phase-gates.sh 04-projects/<goal>
```

Non-zero means a phase never ran a required checkpoint, or ran one without
recording it. Neither is a pass.

**This is a gate rather than advice because it, too, has already failed
silently.** The capability-parity ultragoal shipped all five phases and
passed two north-star gates without ever running CP-4. Nothing noticed: the
gates check acceptance criteria and CI, and a checkpoint that was never run
leaves no failing artifact behind — only an absent row, which is
indistinguishable from a row nobody thought to look for.

CP-4 is not a formality. In the preceding ultragoal it ran five times and
found recall's CI red on the tag its own criterion pinned, silent corpus
corruption on store upgrade, cadre and gloop red since the commits their
criteria cited, a criterion closed against an implementation that was still
installable, and a stale interpreter shadowing the kernel on PATH. Every one
was a cross-phase defect that the per-phase component checks had already
passed over.

**When is CP-4 owed?** Whenever the phase's plan names more than one task.

CP-4 verifies that separately-built things work together. A phase with a
single task has nothing to integrate with itself, and demanding one there
produces a ritual `SKIP` that means nothing. A phase with two or more tasks
owes it whatever its number — including a first phase, because two tasks can
disagree with each other before any later phase exists. That is the answer to
a question that sat open in the backlog for four days while the next
ultragoal skipped CP-4 in all five of its phases.

`phase-gates.sh` reads the count from the phase's own `CP-2-plan.md`,
counting distinct `T-nn` identifiers. A phase with no plan, or a plan naming
no tasks, is treated as owing CP-4: an absent decomposition is not evidence
there was only one thing to do.

The script distinguishes two failures, because they need different fixes: a
checkpoint with neither a row nor an evidence file was **never asked**; one
with an artifact but no row **ran unrecorded**, which means the work was done
and the trail cannot be queried for it. A deliberate skip is recorded as
`SKIP` with its reason — an auditable decision, unlike an absence.

### And the evidence has to survive reading

```bash
bash .claude/lib/evidence-lint.sh 04-projects/<goal>
```

Three properties of an evidence bundle, each from a defect that already got
through:

- **An enumeration piped through `head` with no total beside it.** A P3
  inventory reported eleven matches from `grep ... | head -10` when the real
  count was thirty-one, and two production callers sat below the cut. A list
  truncated at ten looks exactly like a list of ten; nothing in the output
  says which it is.
- **A retire or archive verdict with no working-tree state recorded.** A
  repository was assessed for salvage from committed state alone while 209
  uncommitted lines sat in the tree, including the one artifact worth
  keeping. The verdict is judgment; looking before judging is not.
- **A port or extraction plan missing one of its five inventory axes.** The
  originating defect was an absent axis rather than a badly filled one: four
  were run against the source and none asked what the destination already
  does. The check triggers on a plan naming its own axes, because that is
  what such plans do and a self-declaration can be forgotten — which is the
  same omission it exists to catch.

### And the repositories have to be honest about what they publish

```bash
bash .claude/lib/release-hygiene.sh <each repo the trail makes claims about>
```

Two properties, both found by a person looking rather than by a check:

- **A tag with no release behind it.** recall carried `v0.3.0`, `v0.3.1` and
  `v0.3.2` — three tags whose pipeline published nothing, for two reasons at
  once: a tag pushed with the workflow's own `GITHUB_TOKEN` triggers no
  further workflow, and the release job lacked a checkout its fail-closed
  contract guard needed. A tag with no release looks exactly like a tag whose
  release you have not looked for yet.
- **A repository carrying no licence of its own.** Nothing in any of the four
  gates on it, and recall's `go-licenses` checks *dependency* licences and
  would not notice. The lifecycle kernel was public and unlicensed while
  cadre's installer fetched it by version.

Exceptions are legitimate and each one carries its reason in the script.
A stale exception — a tag that no longer exists, a licence exception for a
repository that has since acquired one — is a failure, not a no-op. An
exception list nobody prunes grows until it covers the next real defect,
and every entry still reads as deliberate.

### And the citations have to resolve

```bash
bash .claude/lib/citation-lint.sh 04-projects/<goal>
```

Every `cadre \`sha\``-style commit citation is resolved in the repository it
names, and every vault-relative path is opened. An evidence trail whose
commits do not resolve is a trail to nowhere, and it fails quietly: a
plausible sha invites no scrutiny.

It checks the reference, not the claim around it. A row saying a control
guards X, citing a test that exists and guards Y, passes — and that is where
most of this harness's found defects have actually lived, so treat a clean
run as evidence about references and nothing more.

```
North-star acceptance:
  read spec.md matrix (all AC-n)
  read every evidence/P*/ledger.md
  for each AC-n: assert ≥1 PASS row exists, artifact re-observed
  any miss → list open AC-n, STATUS stays "in progress", do NOT declare done
```

## The HTML report (regenerate at every phase gate + final)

Every ultragoal carries a single self-contained HTML report that **covers everything**: north-star, live status, all phases, the full `AC-n` traceability table with pass/open/fail, evidence rows per phase (with screenshots embedded as `data:` URIs), and the open-items / next-action block. It is the human-readable face of the evidence ledger.

- **Template:** `../closed-loop/references/report-template.html` (theme-aware, rows-not-cards). Copy it, then fill every `{{token}}` and `<!-- FILL -->` / `<!-- REPEAT -->` block from `spec.md` + `STATUS.md` + `evidence/P*/`. You fill it by editing; do not build a parser.
- **Deliverable path:** `04-projects/<goal>/report.html`. One file, overwritten each phase (it always reflects current truth).
- **When:** regenerate at each phase gate (CP-6) and again at final north-star acceptance. The final report must show every `AC-n` with a PASS row — if any pill is `open`, the goal is not done.
- **Self-contained only:** inline everything, embed screenshots as `data:` URIs, so it also works when published as an Artifact (external hosts are blocked). Before publishing as an Artifact, load the `artifact-design` skill.
- **Surface it:** `SendUserFile 04-projects/<goal>/report.html` (display: render) so the user can open it, or publish via `Artifact` for a shareable link.

## STATUS.md template

```markdown
# <Goal> — status ledger

North-star: <one sentence>
Spec: 04-projects/<goal>/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P<n> · Overall: <not-started|in-progress|blocked|done>

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | AC-1,AC-2 | done | evidence/P0/ | <one line> |
| P1 | AC-3 | in-progress | evidence/P1/ | <what's left> |

## Open AC-n (no PASS row yet)
- AC-3 — <why still open>

## Next action (resume cold from here)
<the single next concrete step + any user-gated decision waiting>
```

## Resuming cold (most common entry)

`/ultragoal <name>` with no other context:
1. Read `04-projects/<goal>/STATUS.md` → "Next action" and "Open AC-n".
2. Read the spec's phase for the current phase only (progressive disclosure).
3. Run the phase loop for the current phase.
4. Never re-do a phase already marked `done` unless integration verify caught a regression.

## Rules

- **Never downgrade the lane.** Even a one-line phase inside an ultragoal runs CP-3v + CP-4. The point is compounding correctness.
- **UI/UX phases verify visually.** If a phase touches a UI/UX flow, capture rendered evidence with browser-harness (`evidence_shot` / `FlowRecorder.save_gif` / `pixel_diff`), read the image, fix any visual defect, and re-capture — do not accept a DOM check. Media lands in `evidence/P<n>/` and feeds `report.html`. See CLAUDE.md → Visual Verification.
- **Fresh-context verifiers.** `task-verifier`, `integration-verifier`, north-star verifier get paths only — never paste worker output in (CLAUDE.md fresh-context isolation).
- **Read-only verifiers.** They cannot edit files or mutate external state.
- **Gate all external.** Any publish / deploy / push waits at CP-6 for the user (Review Gate = your approval).
- **One STATUS.md is the source of truth** for where the goal stands. Update it at the end of every phase or it drifts.
- Model routing per CLAUDE.md: Sonnet workers build/collect/verify; Opus lead reasons, decomposes, synthesizes.

## Escalation template

```
ULTRAGOAL ESCALATED — <goal> / P<n>
Last CP: <CP-id> | Open AC: <list without PASS rows>
Evidence: 04-projects/<goal>/evidence/P<n>/
Decision needed: <one question>
```

## Registered ultragoals

Live list: `04-projects/harness/ultragoals.md`. Each ultragoal gets its own `04-projects/<goal>/` folder holding `spec.md`, `STATUS.md`, `evidence/`, and `report.html`.
