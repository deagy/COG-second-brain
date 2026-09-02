# Verification — controls-not-advice P1 CP-3 triage v2 (round 2)

Target: `04-projects/controls-not-advice/evidence/P1/CP-3-triage.md`
Spec: `04-projects/controls-not-advice/spec.md`
Challenge: `04-projects/controls-not-advice/evidence/P1/CP-3v-challenge-round1.md`

## AC-1 — every open item carries a disposition

PASS, with a labeling wrinkle noted under check 3.

All fourteen ids AI-1..AI-14 appear, each with a disposition and a stated reason:
control table (triage.md:20-31) covers AI-3, AI-5, AI-13, AI-1+AI-11, AI-4a, AI-4b, AI-8, AI-10, AI-12, AI-2. Advice table (triage.md:35-43) covers AI-6b, AI-7, AI-9, AI-1/AI-11 residual, AI-4 residual, AI-12 residual, AI-14. Landed section (triage.md:47) covers AI-6a. Cross-checked against `04-projects/harness/BACKLOG.md` rows AI-1..AI-14 (all `open`, matching spec.md:19-21's "fourteen open items" baseline; AI-15..AI-20 are pre-existing `done` rows from a different retro, correctly excluded). No id is bare.

EVIDENCE AC-1 | CP-3v | PASS | all 14 BACKLOG ids (AI-1..AI-14) appear with a disposition+reason in triage.md | 04-projects/harness/BACKLOG.md, 04-projects/controls-not-advice/evidence/P1/CP-3-triage.md:20-47

## AC-4 — split survived independent challenge

PASS.

Round 1 challenged seven items (all sections in CP-3v-challenge-round1.md marked CHALLENGED, excluding AI-6b which was UPHELD): AI-1+AI-11, AI-2, AI-4, AI-8, AI-10, AI-12, AI-14.

- AI-1+AI-11 — acted on: reclassified to `control` (heading-presence check), observable stated (triage.md:25). Matches round1's proposed observable near-verbatim.
- AI-2 — acted on: reclassified to `control` (triage.md:31), observable stated, self-flagged as weakest. (Substantive weakness of this observable is separate — see over-correction check 1.)
- AI-4 — acted on: split into AI-4a/AI-4b `control` (triage.md:26-27) exactly matching round1's two named observables (AC-03 circular verification, AC-04 universal-negative count), plus a residual kept `advice` (triage.md:41).
- AI-8 — acted on: reclassified to `control` (triage.md:28), observable is the working-tree-precondition round1 proposed.
- AI-10 — acted on: reclassified to `control`, scoped to `evidence/P*/` docs exactly as round1's "narrower scope" suggestion (triage.md:29).
- AI-12 — acted on: reclassified to `control` for the `// Deprecated:` tag mismatch (triage.md:30), residual ("general habit") kept advice (triage.md:42).
- AI-14 — answered: kept `advice`/folded, with a reason ("folded into AI-13... general epistemic stance stays advice") that engages round1's own specific conclusion for AI-14 nearly verbatim (round1: "the one concrete instance... already reduces to AI-13's mechanism, so it shouldn't have needed its own separate advice entry at all").

No challenged item was silently kept as advice without engaging the argument, and no item was reclassified without a stated observable.

EVIDENCE AC-4 | CP-3v | PASS | all 7 round-1-challenged items are either reclassified-with-observable or answered-with-engaged-reason | 04-projects/controls-not-advice/evidence/P1/CP-3v-challenge-round1.md, CP-3-triage.md:20-43

## AC-5 — nothing closed as superseded/landed/folded without evidence

FAIL:fixable.

**AI-6a — verified, solid.** `git log --oneline -1 6d09b29` → `6d09b29 docs(harvest): promote the session's verification lessons`, dated 2026-09-01. `git show 6d09b29 -- WORKFLOW.md` shows the diff inserting exactly the "Amending a gated criterion" section at the claimed location (hunk `@@ -69,6 +69,12 @@`, landing at WORKFLOW.md:72-76 in the current file, confirmed by direct read). Text matches the triage's characterization. Genuinely landed.

**AI-14 — not evidenced as a closure.** The triage tallies AI-14 under "landed/folded" (v2 count = 2, i.e. AI-6a + AI-14 — see check 3 below for how this is derived), but the artifact it's folded into, AI-13, is itself only a *proposed* `control` in this same P1 triage document (triage.md:22) — nothing has been built yet; P2 is where controls get built per spec.md:52 ("P2 | Build every `control`, falsified in both directions"). AC-5's own text requires "the artifact it targeted is shown to be gone or shipped" — AI-13 is neither gone nor shipped. The fold is a plan for future coverage, not evidence of present subsumption.

EVIDENCE AC-5 | CP-3v | PASS | AI-6a: WORKFLOW.md:72-76 added in commit 6d09b29, text matches triage's claim | `git show 6d09b29 -- WORKFLOW.md`
EVIDENCE AC-5 | CP-3v | FAIL | AI-14 tallied as folded/closed but its target (AI-13) is unbuilt — no shipped artifact to point to | CP-3-triage.md:43 vs :22 (AI-13 still `control`, not yet built), spec.md:52

## Check 1 — over-correction (7 new `control` items)

- **AI-1+AI-11** — real. Heading-presence + non-empty-content is a program-decidable check, and it targets the actual defect shape (the fifth axis heading was entirely absent for the destination repo, not partially filled) — matches round1's "missing axis, not badly filled" framing. Boundable, would fail on the originating defect.
- **AI-4a, AI-4b** — real. Both adopt round1's independently-verified observables (circular-verification-ordering grep, universal-negative count) which are the same shape as already-shipped mechanisms (`documented_verbs_test.go`, AC-7 drift guard, confirmed present at `/home/deagy/sdk/cadre/internal/cli/documented_verbs_test.go`). Solid.
- **AI-10** — real. Scoped to `evidence/P*/` markdown, regex-detectable (fenced pipeline into head/tail with no paired count). Matches round1's narrowing.
- **AI-12** — real, moderate confidence. `// Deprecated:` is a fixed Go doc-comment convention (mechanical on the source side); cross-referencing CHANGELOG/README prose for the same symbol's stated status is looser (free text) but bounded enough — same category as the already-shipped duplicate-paragraph/drift checks.
- **AI-8** — real, on close inspection. It only checks for the *precondition being quoted* (git status output present beside a retire/archive verdict), not that the precondition was substantively read — a check could in principle pass on boilerplate. But this matches the item's own scope: AI-8's originating defect (BACKLOG.md AI-8) was specifically "assess from working tree as well as history" — i.e. the omission of the git-status step, not the correctness of the resulting judgment. A check that fails when the step is skipped does fail on that specific originating defect. The residual (was the judgment correct given the quote) is properly left to advice (triage.md:28, "only the verdict is judgment"). Legitimate structural/residual split, same shape as the pre-existing AI-9 concession.
- **AI-2 — weak enough that it should not have been promoted as-is.** Self-described as weakest (triage.md:31, and again triage.md:39). The stated observable only fires "for harness runs" (triage.md:31's own words) — i.e. only when the naming decision is logged inside a CP-2/CP-3 evidence file. The actual originating defect (P1 retro, BACKLOG.md AI-2) occurred in an ordinary assistant message proposing `cadre-lifecycle` to the user, with no evidence-file artifact at all — exactly the scenario the triage itself says the check can't reach ("nothing lints a transcript"). A replay of the real originating defect (chat proposal, no harness evidence doc) would **not** trip this control; only a harness-internal proxy of it would. That fails the "would the check fail on the originating defect" test the task asked about. This reads as reclassification to satisfy the round-1 challenge's numeric pressure ("11-of-14 as advice is not defensible") rather than a control that actually closes the gap AI-2 names. Recommend: either narrow AI-2's `control` claim explicitly to "harness-evidence-logged naming decisions only" with the residual (ordinary chat proposals) staying `advice`, mirroring the AI-8/AI-9 structural-split pattern the rest of the document uses — or revert it to `advice` with AI-9's already-conceded reasoning ("no artifact to inspect" for the general case).

## Check 2 — the AI-14 fold

Not a clean subsumption, and it produces the tally inconsistency in check 3. Substantively, the fold argument (the one concrete AI-14 instance — a version-pair note filed as trivia — reduces to AI-13's not-yet-built "report which tool it resolved" mechanism) mirrors round1's own conclusion closely and isn't dishonest reasoning. But two problems:

1. It closes on an unbuilt artifact (AI-13 is `control`, proposed, not shipped — see AC-5 above).
2. The document's own tally recategorizes AI-14 from "advice" (where it's physically listed, triage.md:43) into "landed/folded" (triage.md:55), which is not what round1 recommended (round1 said AI-14 "stays advice... needs no separate row" — i.e. remain advice, not migrate to a closed category) and inflates the appearance of closure without a shipped artifact behind it.

Net effect: even if unintentional, the fold functions as a way to shrink the visible open-advice count by one and add a second entry to "landed/folded" — the exact incentive AC-4 (spec.md:45, "advice is the cheap disposition") warns about, just pointed at a different column than expected.

## Check 3 — arithmetic and completeness

FAIL:fixable — internal inconsistency in the tally (triage.md:51-55).

- Control table: 10 physical rows (triage.md:20-31), covering unique ids {AI-1,AI-2,AI-3,AI-4,AI-5,AI-8,AI-10,AI-11,AI-12,AI-13} = 10. Tally "control = 10" — correct.
- Advice table: 7 physical rows (triage.md:35-43): AI-6b, AI-7, AI-9, AI-1/AI-11 residual, AI-4 residual, AI-12 residual, AI-14. Tally "advice = 7 (three residuals of a control)" — correct as a literal row count of what's in that table, **including AI-14**.
- Landed section (triage.md:47): exactly **one** entry, AI-6a. Tally states "landed / folded = 2".

The "2" has no second row anywhere under a landed/folded heading — it can only be produced by also counting AI-14, which is simultaneously already counted inside the advice table's "7". That is the double-count the task asked to check for: AI-14 occupies a slot in both the advice column (7) and the landed/folded column (2), pushing the row-total from the true 18 (10+7+1) to an implied 19 (10+7+2). Fourteen base ids are still each represented somewhere (confirmed under AC-1), so no id is missing outright — the defect is specifically that one id (AI-14) is tallied twice across two mutually-exclusive disposition buckets, which either overstates "control" progress indirectly (by making the doc look like more items graduated past bare advice than actually did) or, read the other way, means the stated "7" advice figure is one too many if AI-14 is truly meant to be "folded" and not "advice."

Fix direction: pick one bucket for AI-14 and make the tally match the document body — either (a) leave AI-14 in the advice table as-is and set landed/folded = 1, or (b) move AI-14 physically out of the advice table into a "folded (pending AI-13)" note and set advice = 6, landed/folded = 2. Given AC-5's evidence requirement isn't met yet (AI-13 unbuilt), (a) is the defensible choice until P2 ships AI-13.

EVIDENCE AC-1/arithmetic | CP-3v | FAIL | tally cell "landed/folded = 2" has only 1 supporting row (AI-6a) in the document body; the second implied item (AI-14) is already counted in the "advice = 7" cell | CP-3-triage.md:43,47,51-55

## Check 4 — the self-assessment

PASS. "Not dishonesty in any individual reason — the challenge says so explicitly, and it is right" (triage.md:59) accurately reflects round1's own closing words: "the pattern here isn't that the individual reasons given are dishonest, it's that the same narrowing technique was applied inconsistently: used to rescue AI-3/AI-5 into control, withheld from items that would have required actually building something" (CP-3v-challenge-round1.md, Overall judgment section). The triage quotes this verdict near-verbatim earlier (triage.md:5-6) and its closing section's causal claim ("applied only where it was cheap... one had already been named as a control candidate before triage began, and the other would have meant building something") is a faithful restatement, not a softening. No evidence found that round1 used stronger language ("dishonest") anywhere else that the triage omits.

EVIDENCE self-assessment | CP-3v | PASS | triage's "not dishonesty" framing matches round1's own explicit wording verbatim | CP-3-triage.md:3-6,59-61 vs CP-3v-challenge-round1.md (Overall judgment)

## Independently re-verified technical claims

- AI-3 live defect: confirmed by direct read. `guard_binaries_test.go` guards only `git` via `exec.LookPath("git")` then `t.Skip`, later builds with `go build` and `t.Fatalf`s on failure with no prior `go` toolchain check — `/home/deagy/sdk/cadre/internal/generators/guard_binaries_test.go`. `packaged_selector_test.go` correctly loops `["git","go"]` and skips on either — `/home/deagy/sdk/cadre/internal/generators/packaged_selector_test.go:105-109`.
- AI-5 "correction to round 1": confirmed by direct read of `/home/deagy/cog-second-brain/.claude/lib/phase-gates.sh` — `required="CP-3 CP-3v CP-4 CP-5"` is applied uniformly with no task-count branching anywhere in the script. The triage's self-correction ("the script has no task-count logic... Round 1 said 'the control exists'; that overstated it") is accurate.

## Summary

| Criterion | Verdict |
|---|---|
| AC-1 | PASS |
| AC-4 | PASS |
| AC-5 | FAIL:fixable (AI-14 closure unevidenced — AI-13 unbuilt) |
| Check 1 (over-correction) | AI-2 should not have been promoted as-is (or needs explicit scope-narrowing); AI-1+11, AI-4a/b, AI-8, AI-10, AI-12 hold up |
| Check 2 (AI-14 fold) | Substance is defensible per round1, but the tally treats it as a closure it hasn't earned |
| Check 3 (arithmetic) | FAIL:fixable — AI-14 double-counted across advice(7) and landed/folded(2) |
| Check 4 (self-assessment) | PASS — accurate, not softened |
