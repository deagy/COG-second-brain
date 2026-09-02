# P2 round 2 — read-only re-verification of the spec-lint verified-skip fix (AC-2, AI-4a/AI-4b)

**Verdict: AC-2 PASS** (this round; scoped to the round-1 defect on AI-4a/AI-4b). All other 7 controls confirmed unregressed. Repo and all touched trees left clean.

## 1. Passing direction on real artifacts

```
$ bash .claude/lib/spec-lint.sh 04-projects/repo-consolidation
spec-lint: clean.        EXIT=0

$ bash .claude/lib/spec-lint.sh 04-projects/capability-parity
spec-lint: clean.        EXIT=0

$ bash .claude/lib/spec-lint.sh 04-projects/controls-not-advice
spec-lint: clean.        EXIT=0
```

All three real, current goal specs now pass clean. This is the exact claim round 1 found unrun ("passes on: criteria naming the publishing phase" was never demonstrated against real data) — now demonstrated against all three live goals, not a fixture.

## 2. Failing direction still works, on the historical spec

`git show 3a08861:04-projects/repo-consolidation/spec.md` was written to a scratch dir (`/tmp/claude-1000/scratch-p2/goalA/spec.md`) with `s/| *verified *|/| pending |/`. (Note: in this pre-amendment commit AC-05 and AC-11 already read `pending`, not `verified` — there was nothing to launder there; the sed is a no-op on those two rows but confirms no row silently reads `verified`.)

```
$ bash .claude/lib/spec-lint.sh /tmp/claude-1000/scratch-p2/goalA
.../spec.md:29  AC-05 asserts a universal negative with no bounded set to check it against
    clause: no `run-record` definition exists outside the kernel
.../spec.md:35  AC-11 verified against a published artifact, and no line says which phase publishes it
spec-lint: 2 finding(s).   EXIT=1
```

Both fire, matching round 1's report of the pre-fix commit exactly.

Then reworded in place:
- AC-05: appended `, counted across the four known repositories by grep` to the unbounded clause (bounded set named).
- AC-11: replaced `an installed released kernel's` with `the kernel's ... built from source in a clean clone` (removed the release/registry dependency entirely, no phase-naming crutch needed since the "released" trigger words are gone).

```
$ bash .claude/lib/spec-lint.sh /tmp/claude-1000/scratch-p2/goalA
spec-lint: clean.   EXIT=0
```

Goes clean once genuinely discharged. The failing direction is real, not disabled by the fix.

## 3. Is the skip too broad?

Constructed a minimal spec (`/tmp/claude-1000/scratch-p2/goalB/spec.md`) with one criterion that is maximally unsatisfiable-in-phase (`installed released kernel from the registry; no other definition survives anywhere`) but whose traceability row reads `verified`:

```
$ bash .claude/lib/spec-lint.sh /tmp/claude-1000/scratch-p2/goalB
spec-lint: clean.   EXIT=0
```

Confirmed: the check goes silent on a criterion that is still, by its own wording, unsatisfiable-in-phase, purely because its traceability row says `verified`. This is a real hole — the fix trusts the literal string, not an audit of whether the row is honestly stamped.

**Judgment.** The skip is principled as a *charter-time* device — it stops the check crying wolf on genuinely-closed work whose AC-table prose was never reworded (exactly round 1's finding) — but it is only as sound as the discipline that writes `verified` in the first place. Nothing in `spec-lint.sh` cross-checks the traceability row against independent closure evidence; that job belongs to CP-5 acceptance / CP-3v, external to this script. If a row is stamped `verified` before the criterion is genuinely satisfied (self-graded, premature), the hole in item 3 opens for real, on a live goal, silently.

**Does this occur in practice today?** Checked `controls-not-advice/spec.md` and `STATUS.md`:
- STATUS.md: P1 **done**, P2 **not started** (current).
- spec.md traceability: AC-1, AC-4, AC-5 = `verified` (all P1, the done phase); AC-2, AC-3, AC-6, AC-7 = `pending` (P2–P4, not-started/in-progress phases).

`verified` rows correspond exactly to the one completed phase; no row is marked `verified` while its owning phase is still open. So the hole from item 3 is **real in principle but not currently manifesting** in any of the three goals checked in item 1 (all three came back clean with zero findings, i.e. no verified row anywhere is currently carrying unsatisfiable wording). Worth a follow-up note (e.g. a future check that a `verified` traceability row's evidence column is non-empty), but it is not a defect against AC-2's stated bar for AI-4a/AI-4b, which only requires both directions demonstrated on the check's own defect — which they are.

## 4. Other seven controls unregressed

```
cadre:  go test -count=1 -run 'TestAToolchainInvocationIsGuarded|TestAResolvedToolIsNamed' ./internal/cli/
        ok  	github.com/deagy/cadre/cli/internal/cli	0.086s   EXIT=0

gloop:  go test -count=1 ./internal/docguard/
        ok  	github.com/deagy/gloop/internal/docguard	0.024s   EXIT=0

evidence-lint.sh:
  repo-consolidation   -> 1 finding (P3/CP-2-plan.md missing destination-already-does axis)  EXIT=1
  capability-parity    -> clean   EXIT=0
  controls-not-advice  -> clean   EXIT=0

phase-gates.sh:
  repo-consolidation   -> P1 NEVER RUN: CP-4; P2 NEVER RUN: CP-5; P5 NEVER RUN: CP-3v   EXIT=1
  capability-parity    -> all phases recorded   EXIT=0
  controls-not-advice  -> P2 NEVER RUN: CP-4 CP-5   EXIT=1
```

All outputs match round 1's report verbatim (same findings, same lines, same phases). The repo-consolidation evidence-lint/phase-gates findings and the controls-not-advice P2 phase-gates finding are pre-existing, expected states (historical P3 evidence superseded by P4; P2 genuinely not-started) — unrelated to the spec-lint change, which touches only `spec-lint.sh`. No regression in the other seven controls.

## 5. CP-3-build.md honesty check

`evidence/P2/CP-3-build.md` § "The one claim CP-3v caught" states plainly: *"The first build record said AI-4a and AI-4b passed on 'criteria naming the publishing phase.' **That was never run against anything.**"* — and goes on to describe verification firing identically on the current, shipped spec as on the pre-amendment commit, because the amendment moved AC-11 to a later phase without rewording the row.

This matches round 1's finding without softening: round 1 said the "passes on" evidence was "a synthetic/described case, not an observed one" and that current repo-consolidation/spec.md "still fires identically to the pre-fix commit 3a08861." CP-3-build.md does not hedge, minimize, or reframe this as a lesser issue — it calls it out as the inverse of AC-2's own stated failure mode ("a check seen only passing is not evidence... here a check was claimed passing on evidence that did not exist") and states plainly both are "the same error." Accurate and unsoftened.

## Repository cleanliness

`git status --porcelain` clean in `/home/deagy/cog-second-brain`, `/home/deagy/sdk/cadre`, `/home/deagy/sdk/gloop` after all commands. No files edited; only scratch copies under `/tmp/claude-1000/scratch-p2/` were created/modified.
