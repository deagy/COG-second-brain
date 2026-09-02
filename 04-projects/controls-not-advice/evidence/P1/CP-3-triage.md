# P1 — CP-3 triage · fourteen items (v2, after the AC-4 challenge)

Round 1 classified eleven of fourteen as `advice`. An adversarial pass challenged seven of the eight it was asked to attack, and its central finding was correct:

> *"the same narrowing technique was applied inconsistently: used to rescue AI-3/AI-5 into `control`, withheld from items that would have required actually building something."*

That is what happened. Round 1 tested each item against its **generalized prose** and found it unmechanizable, except where a narrower checkable version was convenient to extract. Tested instead against the **actual originating defect**, most of them yield an observable. This version does that uniformly.

## The method round 1 applied unevenly

For each item, ask what the retro actually saw — not what the item's sentence generalizes to. Then split:

- the **structural** part, which a check can observe, and
- the **residual**, which needs judgment and stays advice.

Most items have both. Round 1 recorded only the residual and called the whole item advice.

## `control`

| ID | What the check observes | Where it lives | Fails when |
|---|---|---|---|
| AI-3 | A `*_test.go` invoking the Go toolchain without a preceding `exec.LookPath("go")` and skip | Test in `internal/generators/` | **Live defect:** `guard_binaries_test.go:71` guards only on `git`, then builds at :86 and `t.Fatalf`s at :89. `packaged_selector_test.go:105` guards both. Confirmed independently |
| AI-5 | A phase with no CP-4 row and no CP-4 evidence file | `phase-gates.sh` (built) | Bare absence. **Correction to round 1:** the script has no task-count logic, so "CP-4 owed when a phase has >1 task" is prose, not a gate. Round 1 said "the control exists"; that overstated it |
| AI-13 | A guard resolving an external tool that reports the path only on the failure branch | Test over the guard files | Every `LookPath` site today reports `t.Skipf("needs %s: %v")` on failure and nothing on success — a passing run never says which binary it checked |
| AI-1 + AI-11 | A port/extraction plan missing one of five required inventory headings, or with a heading and no content under it | CP-2 plan lint, sibling to `phase-gates.sh` | The originating defect was a **missing axis**, not a badly filled one: *"All four were run on cadre and none on gloop."* A structural absence is exactly what a structural check catches |
| AI-4a | An AC whose verification text names a network fetch of an artifact its own phase's CP-6 publishes, where that CP-6 has not recorded PASS | CP-1 spec lint at chartering | Circular verification ordering — AC-03's actual defect, mechanically detectable |
| AI-4b | A universal-negative AC ("no third definition exists") verified by counting definitions across the known repo set | CP-4 integration check | Count != 1. Identical in kind to the drift guard already shipped |
| AI-8 | A retire/archive verdict recorded in evidence with no `git status --porcelain` for that repository quoted beside it | Evidence-doc lint | The defect was not misjudging salvage value — it was judging it from committed state while *"209 lines sat uncommitted in the working tree, including the very artifact that turned out to be worth salvaging."* The precondition is observable; only the verdict is judgment. **Round 1's stated reason attacked a claim the item never made** |
| AI-10 | Inside `evidence/P*/` docs only: a `grep`/`rg`/`find` piped to `head`/`tail` with no paired total count for the same query | Evidence-doc lint | Round 1 evaluated only the *global* rule, where the false-positive rate is genuinely fatal, and never tried the scoped version. Scoped to inventory evidence, it does not touch ad hoc shell use |
| AI-12 | A symbol whose source `// Deprecated:` tag disagrees with what CHANGELOG or README says about its deprecation | `deprecated_symbols_test.go`, sibling to `documented_verbs_test.go` | The uncovered instance was `catalog.MatchRoutes`, un-deprecated in source while the changelog still scheduled its removal. `// Deprecated:` is a fixed convention, so this is syntactic |

## `advice` — with the reason

| ID | Rule | Why the residual needs judgment |
|---|---|---|
| AI-6b | Where a criterion's literal and intended readings differ, the literal one governs | **Upheld by the challenge, the only one.** No syntactic pattern separates a literal from a generous reading. The *amendment* case is controlled by `WORKFLOW.md:72`; what remains is a judgment inherent to any verifier role. The residual is thin |
| AI-7 | Never put a file write and the commit describing it in one compound command | Mechanizable by a PreToolUse hook, and COG ships no hook infrastructure. That is a cost argument about introducing hooks for one rule, and it is recorded as a cost argument rather than a feasibility one |
| AI-2 | Verify a naming or destination target exists before putting the decision to the user | **Reverted from `control` after round 2.** The proposed evidence-doc lint fires only when the decision is recorded in a harness evidence file, and the originating defect was a plain chat proposal with no such artifact — so the check would never have caught the thing it was written for. Round 2 called this out as the one genuine over-correction, and it was: the control was promoted to answer a challenge, not because the observable reached the defect. Same limitation as AI-9 |
| AI-9 | Check repository visibility before reasoning about who documentation reaches | `gh repo view --json visibility` is one line; nothing would invoke it, because the defect is a reasoning step with no artifact. AI-2 shares this limitation exactly, and round 2 reverted its control for that reason — a lint over evidence files cannot reach a decision that was only ever spoken |
| AI-1/AI-11 residual | A dishonest inventory — real headings, wrong conclusions | The structural check cannot read whether an axis was actually investigated |
| AI-4 residual | The general "satisfiable within its own phase" rule beyond the two named shapes | Requires understanding what a phase does |
| AI-12 residual | The general habit of finding a correction's prose twin | Needs semantic understanding of what the correction meant |
| AI-14 | Treat an environment note as a finding until shown otherwise | The general epistemic stance cannot be checked: most environment notes are not version-pair-shaped. **Not closed, and round 2 was right to refuse the closure round 1 claimed.** The originating instance — *"installed kernel 0.13.2, repository 0.14.2"* filed as trivia — is the retro-side twin of AI-13, so AI-13's control will cover that instance *once it is built*. AI-13 is a P2 proposal today, and a closure pointing at an unbuilt artifact is exactly what AC-5 forbids. This row stays open as advice until AI-13 ships, then the covered half can be struck |

## Landed

**AI-6a** — `WORKFLOW.md:72-76`, added in commit `6d09b29` on 2026-09-01. The challenge confirmed the landing is honest and that splitting AI-6 into a landed half and a carried half is a genuine decomposition of two failure modes, not padding.

## Tally

Counted by original backlog id, so nothing appears twice. AI-1 and AI-11 are one merged item; AI-4 yields two checks from one id; AI-6 is the only id split across two dispositions.

| Disposition | ids | Which |
|---|---|---|
| `control` | 9 | AI-1+AI-11 (merged), AI-3, AI-4, AI-5, AI-8, AI-10, AI-12, AI-13 |
| `advice` | 5 | AI-2, AI-6b, AI-7, AI-9, AI-14 |
| landed | 1 | AI-6a |

AI-6 appears in two rows because it was two rules under one id, so the ids total fourteen. Three of the controls also carry a residual advice note (AI-1+AI-11, AI-4, AI-12); those are notes attached to a control, **not** separate items, and are not counted in the advice column. Round 1's tally said "landed / folded = 2" and counted AI-14 in both that cell and the advice column.

## What round 1 got wrong, stated plainly

Not dishonesty in any individual reason — the challenge says so explicitly, and it is right. The failure was that **the narrowing move was available to every item and applied only where it was cheap.** AI-3's prose was unmechanizable and a checkable half was extracted from it; AI-8's prose was unmechanizable and no attempt was made. The difference between them was not feasibility. It was that one had already been named as a control candidate before triage began, and the other would have meant building something.

The spec predicted this in AC-4's own wording — *"`advice` is the cheap disposition and the lead is the one doing the classifying"* — and the prediction was accurate about the very phase that wrote it.
