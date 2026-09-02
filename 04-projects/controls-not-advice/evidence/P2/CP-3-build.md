# P2 — CP-3 build · nine controls

Each check is falsified in both directions. Where the originating defect still existed, it was used as the test subject; where it had been fixed, the historical wording was recovered from git rather than invented.

| # | ID | Check | Home | Fails on | Passes on |
|---|---|---|---|---|---|
| 1 | AI-3 | A test invoking the Go toolchain that reaches `t.Fatal` when it is absent | cadre `internal/cli/toolchain_guards_test.go` | 3 live defects: `guard_binaries_test.go:86`, `standalone_test.go:45`, `resolve_shared_integration_test.go:32` | after the fixes; injected unguarded call fails |
| 2 | AI-13 | A project binary resolved and assigned to `_` | same file | injected discard of `agentic-sdlc` | clean tree — the originating site already logs (`provider_compatibility_test.go:133`) |
| 3 | AI-12 | `// Deprecated:` in source disagreeing with prose | gloop `internal/docguard/` | restoring the original `catalog.MatchRoutes` removal claim | clean tree; a marked-but-unannounced symbol also fails |
| 4 | AI-10 | An enumeration piped to `head` with no total | `.claude/lib/evidence-lint.sh` | fixture reproducing the P3 T-05 inventory | same command with `wc -l` beside it |
| 5 | AI-8 | A retire verdict with no working-tree state | same script | the historical verdict text, "Nothing survives as code" | the same verdict with `git status --porcelain` quoted |
| 6 | AI-1+AI-11 | A port plan missing one of five inventory axes | same script | repo-consolidation P3's plan — four axes, missing "what the destination already does" | P4's plan, written after AI-11 added the fifth |
| 7 | AI-4a | A criterion verified against a published artifact | `.claude/lib/spec-lint.sh` | AC-11 at `3a08861` with its traceability set to pending: "an installed released kernel" | the same spec with "released" removed; and every current spec |
| 8 | AI-4b | A universal negative with no bounded set | same script | AC-05's clause "no `run-record` definition exists outside the kernel", traceability pending | the same clause rewritten to "in exactly one of the four known repositories, counted by grep" |
| 9 | AI-5 | CP-4 owed when a phase names more than one task | `.claude/lib/phase-gates.sh` | fixture: two tasks, no CP-4 row | one task, no CP-4 row — and it says why |

Items 6 and 8 are falsified against **real history** rather than fixtures: P3-versus-P4 is the same check's own before-and-after, and AC-05/AC-11 are recovered from the spec's first commit.

## Every check is invoked by something that already runs

The plan said a control nothing invokes is advice with extra steps, and that any ending up that way would be recorded as advice. None did:

- 1, 2 → `go test ./...` in cadre, which CI runs
- 3 → `go test ./...` in gloop, which CI runs
- 4, 5, 6 → `evidence-lint.sh`, wired into the ultragoal north-star gate
- 7, 8 → `spec-lint.sh`, wired at CP-1 in the ultragoal skill
- 9 → `phase-gates.sh`, already in the north-star gate

## The one claim CP-3v caught, and what it cost

The first build record said AI-4a and AI-4b passed on "criteria naming the publishing phase." **That was never run against anything.** Verification pointed the check at the artifact it should most obviously pass on — repo-consolidation's own shipped, closed spec — and it fired identically to the pre-amendment version, because the amendment moved AC-11 to a later phase rather than rewording the row.

A check that fires forever on shipped work is one that gets turned off, and then it is advice again. The fix is principled rather than a threshold tweak: **a criterion the traceability matrix records as `verified` has answered this question by demonstration.** It *was* satisfied where it sat, so asking whether it could be is moot. Both checks now skip verified criteria, and the failing direction is reproduced by taking the same historical spec with its traceability set to `pending` — a charter-time spec, which is what the check is for.

This is the inverse of the failure AC-2 is written against. The criterion says a check seen only passing is not evidence; here a check was *claimed* passing on evidence that did not exist. Both are the same error — asserting a direction without running it — and only one of them is spelled out in the criterion.

## What building them changed about the classification

Two dispositions did not survive contact with the code, and both are recorded rather than quietly adjusted:

- **AI-3's rule was narrower than the check that replaced it.** "Never build on demand inside a package whose other tests narrow the environment" cannot be checked — nothing determines what a sibling test narrows. The property that survives is that the toolchain's absence must skip.
- **AI-13's rule would have forced thirteen cosmetic edits.** Requiring every resolved tool to be logged is wrong: which `git` you found does not matter. Which `agentic-sdlc` you found is the whole question, and that is the defect the item came from.

## Seven bugs, each found by running a check rather than reading it

Recorded because the pattern is consistent: every one passed review and failed on contact with a real artifact.

1. Demanding `exec.LookPath` treated run-then-skip as a defect — three false positives.
2. Exempting a file that resolved *any* tool exempted the one known defect, which resolves `git` and runs `go`.
3. The axes check triggered on the phrase "port plan"; the originating plan never calls itself one, so it would never have fired. Real inventory plans name their axes.
4. The `data-readers` pattern missed "what reads its data" — the actual heading — flagging two plans that had the axis.
5. The inventory check counted findings inside a pipeline subshell, printed a defect, and exited 0.
6. `${row##*|*|}` is greedy and left the verify column empty, silently disabling the universal-negative check entirely.
7. `tr ';' '\n' | while read` dropped the final clause — which was the unbounded one.

And an eighth, in `phase-gates.sh`: `grep` exits 1 on no match, and under `set -e` with `pipefail` that killed the script mid-goal, printing one phase and returning non-zero. Indistinguishable from a real finding, on two goals that were clean.
