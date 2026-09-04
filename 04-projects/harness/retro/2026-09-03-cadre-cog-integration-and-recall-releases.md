# Retro: cadre/COG integration review → recall v0.4.0/v0.5.0 → chat-export loader

> Date: 2026-09-03 · Run: none · Lane: none · Outcome: shipped

## What happened

Opened as "review PR #1", a cadre/COG integration branch with no review comments on it. Four high-effort review passes across two PRs closed 49 findings; Change 4 (a vendored 159-role roster) and Change 3 (mutation gates) were withdrawn rather than fixed, and Changes 1–2 shipped. A two-sentence braindump then started a second chain: tracing recall's ingest path found a silent data-loss hazard, a failing test proved it, and the fix released as `recall v0.4.0`, then `v0.5.0` after the conversation loader landed — propagated to `cadre cli-v0.7.13` and `gloop v0.3.0`. Two harvests produced six knowledge notes and two `CLAUDE.md` patches.

## The gates were never armed

`verification_harness: off`; no `/closed-loop` or `/ultragoal` was invoked. There is no run directory, no spec with `AC-n` for the shipped work, and zero `loop-ledger` rows for this session — today's 43 `checkpoint-ledger` rows belong to the earlier team-readiness ultragoal and to scratchpad tests of `checkpoint.sh` itself. So the checkpoint audit and the evidence-quality table have nothing to audit, and inventing rows for them would be the exact failure the harness exists to prevent.

**What substituted for the gates, and how it did:**

| Substitute | Verdict | What it caught |
|---|---|---|
| `/code-review` × 4 | caught the most | Every high-severity finding, including two the previous pass had introduced. Also the gate ladder being off by one against cadre's kernel, which no test would have seen |
| Mutation checks | caught real gaps | Killed 6 of 7 mutations across three commits; the survivor exposed an untested branch rather than a weak assertion |
| Artifact verification | caught two silent failures | A merge GitHub never recorded, and the habit of confirming a Release published rather than trusting a green run |
| A spec written before code | caught a design error | Writing SPEC-002 invalidated a claim two braindump entries had made about the loader seam |

The thing worth noting: **nothing here is a gate.** All four are practices a person chose to run. The work shipped to three repositories and cut three releases with no blocking check anywhere in the path.

## Friction

- Three defects were instructions written for a future agent and never executed — a fold into a schema that rejects it, a mapping from a TSV that cannot fill it, a `grep` that matches on the wrong field. All survived review as prose.
- Two of my own fixes introduced the next pass's findings. Fixing an exit-code contradiction moved it to the wrong code; narrowing an over-claim left one of the two remaining claims still false.
- `gh pr merge` half-succeeded — merge commit created, PR never marked merged — and I had run it with `>/dev/null 2>&1`, discarding the only signal.
- `go test` served a cached result during a mutation check, so a mutation appeared to survive that had never run.
- A compound shell command containing a blocked verb was rejected wholesale; the commit earlier in the chain never ran, and the symptom looked like a failed commit.
- A gate registry was designed across four passes without reading `MY-INTEGRATIONS.md`. Three of its five rows gated Disabled services; both Active ones were absent.

## Actions

| ID | Action | Target file | Disposition |
|---|---|---|---|
| AI-39 | A skill step that documents a mapping *into* a schema should carry a fixture that executes the mapping and lints the result. Both Phase 7 folds were schema-invalid and both passed review as prose. | `.claude/skills/closed-loop/SKILL.md` § Phase 7 | **control — unbuilt** — observable: a fixture run that performs the documented fold against the vendored schema and fails on a validation error. The instruction is prose, but its output is a JSON document a linter already exists for (`run-record-lint.sh`) |
| AI-40 | Any document that names an external integration should be checkable against `MY-INTEGRATIONS.md`. | `.claude/lib/` (new), `plan/**`, `.claude/skills/**` | **control — unbuilt** — observable: grep the integration names out of `MY-INTEGRATIONS.md`, then flag any doc naming one listed Disabled, or any Active one absent from a registry that claims completeness. The gate registry's inversion was mechanically visible for four passes |
| AI-41 | A mutation check must defeat the test cache, or it is not evidence. | `.claude/skills/mutation-verify/SKILL.md` | **advice** — landed in `CLAUDE.md` § Verification Harness; note at `05-knowledge/technical/2026-09-03-a-surviving-mutation-is-a-question.md`. Nothing observes that a given `go test` invocation is part of a mutation check; the runner cannot know the intent, and a lint over skill bodies for a missing `-count=1` would fire on every ordinary test example |
| AI-42 | Do not chain a state-changing command with one that may be policy-blocked. A blocked verb rejects the whole compound, and nothing earlier in it runs. | working practice | **advice** — landed in `CLAUDE.md` § Engineering Discipline. The hook names the offending verb but not that the command was rejected entire; from the transcript "the commit failed" and "the commit never ran" are indistinguishable. `git log -1` after any block is the recovery, not a prevention |
| AI-43 | A fix that closes a review finding is itself unreviewed. Two of four passes found a defect the previous pass's fix introduced. | working practice | **advice** — landed in `CLAUDE.md` § Verification Harness. No check reaches it: the defect is that a *correction* was trusted more than the original, and correctness of a fix is exactly what a review pass is for. The cost argument is real though — each extra pass found something, and the fourth found two high-severity items in code the third had written |
| AI-44 | Work that ships to three repositories and cuts three releases ran with no lane, no spec and no gate. Either that is fine and the harness's scope is narrower than it reads, or the trigger is wrong. | `WORKFLOW.md` § Scope, `CLAUDE.md` § Verification Harness | **advice** — landed in `WORKFLOW.md` § Scope. A scoping decision, not a defect; a check cannot decide whether a session *should* have been a harness run. Recorded so the question is answerable next time rather than re-derived |
