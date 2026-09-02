# Controls, not advice — status ledger

North-star: every open retro action is either a mechanical check that fails on its own defect, or is recorded as advice with a stated reason it cannot be one.
Spec: 04-projects/controls-not-advice/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P2 · Overall: **in progress**

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | evidence/P0/ | 7 criteria, 4 phases, from a 14-item baseline |
| P1 | AC-1, AC-4, AC-5 | **done** | evidence/P1/ | 9 control, 5 advice, 1 landed. Three CP-3v rounds: under-classified, then over-corrected, then clean. CP-4 PASS |
| P2 | AC-2 | not started | evidence/P2/ | Build every `control`, falsified both directions |
| P3 | AC-3, AC-6 | not started | evidence/P3/ | Land every `advice` item where it loads |
| P4 | AC-7 | not started | evidence/P4/ | The disposition question becomes part of writing an action item |

## Open AC-n (no PASS row yet)
AC-2 (P2), AC-3 and AC-6 (P3), AC-7 (P4). AC-1, AC-4 and AC-5 closed at P1.

## Next action (resume cold from here)

**P2 — build the nine controls, each falsified in both directions.** The dispositions and their observables are in `evidence/P1/CP-3-triage.md`; build from that table, not from the original backlog wording, which is what round 1 got wrong.

Order them by whether the defect is already live in the tree, because those can be falsified against a real instance rather than an injected one:

1. **AI-3** — a test invoking the Go toolchain without a preceding `LookPath("go")`. Live defect at `internal/generators/guard_binaries_test.go:71`, which guards only on `git`, builds at :86 and `t.Fatalf`s at :89. `packaged_selector_test.go:105` does it correctly, so the fix has a model in the same package.
2. **AI-13** — every `LookPath` site reports the resolved path only on the failure branch, so a passing run never says which binary it checked. Fix the guards first, then the check that keeps them honest.
3. **AI-12** — `deprecated_symbols_test.go`: a `// Deprecated:` tag in source disagreeing with CHANGELOG or README.
4. **AI-8, AI-10** — evidence-doc lints over `04-projects/**`. CP-4 confirmed these are distinct checks; whether they share one file is a P2 decision.
5. **AI-1+AI-11** — port/extraction plan headings lint.
6. **AI-4a, AI-4b** — the circular-verification-ordering spec lint, and the universal-negative count check.
7. **AI-5** — encode the task-count rule, or record why `phase-gates.sh` cannot.

## Watch for## Watch for

That prediction was correct, and P1 failed on it twice in opposite directions before passing.

Round 1 under-classified — eleven of fourteen as advice — because the narrowing move that turns unmechanizable prose into a checkable half was applied only where it was cheap. Round 2 then over-corrected under criticism: AI-2 was promoted to `control` on an observable that, by its own caveat in the same row, could not reach the defect it was written for, and AI-14 was closed against an artifact that does not exist yet.

The lesson for P2 is the same in both directions: **classify against what the retro actually saw, not against the item's sentence and not against the last piece of feedback received.**

P2 has its own version of this. A control that is built but never invoked is advice with extra steps, and nine controls is enough that at least one will be tempting to declare done on the strength of the file existing. Each needs falsifying in both directions — the defect reintroduced and the check seen failing.
