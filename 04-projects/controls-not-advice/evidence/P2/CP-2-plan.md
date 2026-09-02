# P2 — CP-2 plan · AC-2

**AC-2:** every `control` item has a check that fails on its own defect. The defect is reintroduced and the check fails; removed, and it passes. Both directions demonstrated, output recorded. A check seen only passing is not evidence.

## The nine, by home

Two homes, because the defects live in two places. Checks about cadre's own code are Go tests in cadre; checks about harness evidence are scripts in `.claude/lib/` beside `phase-gates.sh` and `ci-status.sh`.

| # | ID | Check | Home |
|---|---|---|---|
| 1 | AI-3 | A `*_test.go` invoking the Go toolchain with no preceding `LookPath("go")` guard | cadre `internal/cli/` |
| 2 | AI-13 | A `LookPath` site that reports the resolved path only on the failure branch | cadre `internal/cli/` |
| 3 | AI-12 | A `// Deprecated:` tag in source disagreeing with CHANGELOG/README | cadre `internal/cli/` |
| 4 | AI-8 | A retire/archive verdict in evidence with no working-tree state quoted | `.claude/lib/evidence-lint.sh` |
| 5 | AI-10 | An inventory piped to `head` in evidence with no paired total count | `.claude/lib/evidence-lint.sh` |
| 6 | AI-1+AI-11 | A port/extraction plan missing one of five inventory headings | `.claude/lib/evidence-lint.sh` |
| 7 | AI-4a | An AC whose verification fetches an artifact its own phase has not yet shipped | `.claude/lib/spec-lint.sh` |
| 8 | AI-4b | A universal-negative AC with no count-based verification | `.claude/lib/spec-lint.sh` |
| 9 | AI-5 | The task-count rule for when CP-4 is owed | `phase-gates.sh`, or recorded as unencodable |

CP-4 confirmed AI-8 and AI-10 are distinct checks. They share a file because both read evidence markdown; sharing a file is not sharing a check, and each is falsified separately.

## Order

Live defects first, so the first falsification is against a real instance rather than an injected one:

1. **AI-3** — `guard_binaries_test.go:71` guards only on `git`, builds at :86, `t.Fatalf`s at :89
2. **AI-13** — every `LookPath` site reports only on failure
3. Then AI-12, the evidence lints, the spec lints, and AI-5 last

## What falsification means here, stated before building

For each control, both directions recorded with actual output:

- **Fails on its defect** — for AI-3 and AI-13 the defect is already in the tree, so the check must fail on the current state before anything is fixed. For the rest, reintroduce the originating defect from its retro and observe the failure.
- **Passes when the defect is gone** — after the fix, and on the clean tree.

A check whose only evidence is a green run has not been falsified, and does not close its row.

## The failure mode this phase is prone to

**A control that is built but never invoked is advice with extra steps.** Nine is enough that at least one will be tempting to call done because the file exists. Every check here must be reachable by something that already runs: a Go test in a package CI runs, or a script the ultragoal skill's gate section names. A script in `.claude/lib/` that nothing calls is not a control, and if one ends up that way it is recorded as advice, not as a control that happens to be unwired.

## Not in scope

Landing the five advice items — that is P3. Changing any disposition — P1 closed those, and reopening one here would be the phase grading its own predecessor.
