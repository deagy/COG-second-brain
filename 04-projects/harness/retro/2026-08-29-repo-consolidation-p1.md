# Retro: repo-consolidation / P1 — extract the lifecycle kernel

> Date: 2026-08-29 · Run: `04-projects/repo-consolidation/evidence/P1` · Lane: `full` · Outcome: shipped

## What happened

Froze the selector/kernel fingerprint agreement as a fixture while both implementations were still importable, moved `internal/kernel`, `cmd/agentic-sdlc`, `kernel/` and `bin/agentic-sdlc` into a new repository, vendored the contracts cadre's tests read back into cadre with a drift check, gave the kernel its own build and CI, deleted it from cadre, published `deagy/cadre-kernel` and released `v0.14.2`, then merged and pushed cadre with the kernel absent.

Six tasks. Two of them ran long: T-02 because the kernel's tests loaded cadre's real provider bundle, and T-05 because the deletion's blast radius was roughly four times what the plan estimated.

## Evidence quality

| AC | Had a PASS row | Observed the artifact | Notes |
|---|---|---|---|
| AC-01 | yes | yes — a **fresh clone from GitHub** built, tested green and printed `0.14.2`; separately, a **downloaded release asset** was unpacked and run | Not the push's return value, not the local tree |
| AC-02 | yes | yes — `kernel` and `internal/kernel` absent from the **published** tree via the GitHub contents API | Deliberately not checked against the local checkout, which would prove nothing about what shipped |
| AC-03 | yes | yes — a fresh-context verifier confirmed both fixtures byte-identical (`sha256 cd832b3b…`) and each repository reproducing the value from its own implementation alone | |
| AC-04 | yes | yes — drift check falsified in both directions: perturbing the vendored copy, and pointing it at a divergent source | Error names the resolved source, so it is provably not comparing cadre against itself |

No PASS rested on a worker's summary. Every one names a command and its output.

## What the gates caught

| CP | Verdict | What it caught, or why it was silent |
|---|---|---|
| CP-2 | PASS | Correctly identified T-01 as blocking T-02. That ordering was the single most important call in the phase — the fixture cannot be generated once the kernel leaves. |
| CP-3v (T-01) | PASS | Checked something the lead had not: that `bin/agentic-sdlc` is a shell wrapper rather than a checked-in compiled binary. |
| CP-3v (T-02) | FAIL:fixable | Correctly flagged that cadre still held the kernel and the two-implementation tests. Measured against the end state because it was given the extraction's context but not the task ordering — the right behaviour for a verifier. The lead's criterion wording ("cadre's imports the selector and NOT the kernel") was ambiguous and invited it. |
| CP-4 | **not run** | No prior phase to integrate against, but this was never decided — it was skipped by omission. See AI-5. |
| CP-5 | PASS | Both observations were artifact-level and neither was the obvious one. |
| CP-6 | PASS | Gated correctly. Two user decisions taken before anything left the machine: visibility, then the name. |

The most valuable gate was not a checkpoint. **cadre's own test suite caught five separate couplings the plan missed** — the provider bundle, the release program model, the release gate's watched components, the engine's kernel-root resolution, and the plugin generator's version shim — each failing with a message naming exactly what broke. And `gh repo create` refusing a name was the only thing standing between the session and pushing into an archived repository.

## Friction

- **Three inventory misses, one root cause.** The plan inventoried what *imported* the kernel and what *named* it in prose. It never inventoried what *read its data* or *modelled it as a component*. `provider/`, five contract readers where it named two, then the release model, release gate, engine kernel roots and version pin.
- **A misread citation propagated into three documents and a user-facing question.** `RUNBOOK.md:823` was cited as naming `cadre-lifecycle` the extraction target. The clause is about generated content leaking into a distribution repo. It reached the extraction plan, `STATUS.md`, and the visibility/name question put to the user.
- **A guard the lead wrote was environment-fragile.** The provider compatibility test fell back to building the kernel from a sibling checkout; it passed alone and failed in the full package run because another test narrows the environment for its own purposes. Caught only by running the whole package, not the targeted test.
- **Two spec defects.** AC-03 required acceptance by the *released* kernel, putting half a criterion after the push it depended on. AC-04 required "no third definition", which is P2's work. Both were written at charter and neither surfaced until the phase tried to close.
- **Two live kernel copies for about forty minutes**, with nothing checking they agreed, one of them published. Closed by T-05, but the window was real and the plan did not name it.

## Actions

| ID | Action | Target file | Status |
|---|---|---|---|
| AI-1 | Extraction and port plans must inventory four things, not two: what imports the code, what names it in prose, **what reads its data**, and **what models it as a releasable component**. P3 ports orchestration to gloop — a far larger surface — so this applies before that plan is written. | `04-projects/agentic-sdlc/planning/` (P3 plan, unwritten) | proposed |
| AI-2 | Before putting a naming or destination decision to the user, verify the target actually exists or is free. A citation about a name is not evidence the name is available. | working practice | proposed |
| AI-3 | A test that resolves external tooling must not depend on ambient environment that sibling tests mutate. Require an already-built artifact and skip, rather than building on demand. | working practice | proposed |
| AI-4 | When writing acceptance criteria, check each is satisfiable **within the phase that owns it**. Words like "released" and "no other definition exists" import dependencies on later phases. | `.claude/skills/ultragoal/SKILL.md` § Phase 0 | proposed |
| AI-5 | Decide whether CP-4 is meaningful for a first phase, or state that it begins at P2. It was skipped by omission here, which is the failure mode the harness exists to prevent. | `.claude/skills/ultragoal/SKILL.md` § phase loop | proposed |

## What worked, and is worth keeping

Generating the fixture from two live agreeing implementations rather than writing the expected value by hand. It recorded an observation instead of an assumption, and the falsification — dropping `provenance` from the selector's exclusion set — proved the surviving single-sided test detects a real contract change without seeing the other implementation. That property is the whole reason the split is safe.

Cutting the release before merging cadre. It surfaced that the plugin shim resolved kernels from a tag line that had ended, which merging first would have published.
