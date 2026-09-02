# Verification — controls-not-advice P1 CP-3 triage, round 3 (re-check of three round-2 fixes)

Target: `/home/deagy/cog-second-brain/04-projects/controls-not-advice/evidence/P1/CP-3-triage.md` (current, post-fix)
Prior report: `04-projects/controls-not-advice/evidence/P1/CP-3v-round2.md`
Spec: `04-projects/controls-not-advice/spec.md`
Backlog: `04-projects/harness/BACKLOG.md`

## Fix 1 — AI-2 reverted from `control` to `advice`

CONFIRMED LANDED.

- Control table (triage.md:20-30): AI-2 does not appear. Rows present are AI-3, AI-5, AI-13, AI-1+AI-11, AI-4a, AI-4b, AI-8, AI-10, AI-12 — 9 rows, no AI-2.
- Advice table, triage.md:38: `| AI-2 | Verify a naming or destination target exists before putting the decision to the user | **Reverted from `control` after round 2.** The proposed evidence-doc lint fires only when the decision is recorded in a harness evidence file, and the originating defect was a plain chat proposal with no such artifact — so the check would never have caught the thing it was written for. Round 2 called this out as the one genuine over-correction, and it was: the control was promoted to answer a challenge, not because the observable reached the defect. Same limitation as AI-9 |`
- The reason states the mechanism (evidence-file-only trigger) and the mismatch against the originating defect (plain chat proposal) explicitly — not glossed as generic "behavioural." Matches round 2's finding almost verbatim.

## Fix 2 — AI-14 no longer claimed closed

CONFIRMED LANDED, with a caveat found under regression check.

- triage.md:43: `AI-14 | Treat an environment note as a finding until shown otherwise | ... **Not closed, and round 2 was right to refuse the closure round 1 claimed.** ... AI-13 is a P2 proposal today, and a closure pointing at an unbuilt artifact is exactly what AC-5 forbids. This row stays open as advice until AI-13 ships, then the covered half can be struck |`
  Explicitly states it cannot be closed against an unbuilt artifact — matches the task's required wording, not a gloss.
- "Landed" section (triage.md:45-47) now names only AI-6a; AI-14 is not present there.
- AC-5 ("nothing closed as superseded/landed without evidence") re-checked for every item claimed landed/closed:
  - AI-6a is the only remaining landed claim. Re-verified independently against WORKFLOW.md (not just re-reading round 2's claim): `git log --oneline -1 6d09b29` → `6d09b29 docs(harvest): promote the session's verification lessons`. `git show 6d09b29 -- WORKFLOW.md` shows the exact insertion (`### Amending a gated criterion` + two paragraphs) landing after the evidence-row-contract section. Live file confirmed: `grep -n "Amending a gated criterion" WORKFLOW.md` → `72:### Amending a gated criterion`, matching the triage's cited `WORKFLOW.md:72-76`. Content ("A criterion may be amended only *before* it is gated...") matches AI-6's original clause "...or rewrite the criterion before the phase closes" — the amendment/rewrite half of AI-6, distinct from AI-6b's literal-vs-intended judgment half. Genuinely landed, correctly the only landed row.
  - No other row anywhere in the document claims landed/closed/superseded status besides AI-6a. AC-5 is satisfied for every item claimed landed or closed.

EVIDENCE AC-5 | CP-3v | PASS | AI-6a is the sole landed claim, independently re-verified at WORKFLOW.md:72 against commit 6d09b29; AI-14 no longer claimed closed and its row states the AI-13-unbuilt reason explicitly | WORKFLOW.md:72, `git show 6d09b29 -- WORKFLOW.md`, CP-3-triage.md:38,43,45-47

## Fix 3 — tally no longer double-counts

CONFIRMED FIXED, arithmetic is internally consistent.

Physical rows counted directly in the document:
- Control table (triage.md:20-30): 9 rows → unique original ids {AI-1, AI-3, AI-4, AI-5, AI-8, AI-10, AI-11, AI-12, AI-13} = 9 ids. Tally cell "control | 9" (triage.md:55) — matches.
- Advice table (triage.md:35-42): 8 physical rows (AI-6b, AI-7, AI-2, AI-9, AI-1/AI-11 residual, AI-4 residual, AI-12 residual, AI-14), but 3 are residual notes attached to an already-counted control id (AI-1/AI-11, AI-4, AI-12) and explicitly excluded from the advice count by the document's own text (triage.md:59: "those are notes attached to a control, not separate items, and are not counted in the advice column"). Remaining distinct ids: {AI-2, AI-6(b), AI-7, AI-9, AI-14} = 5. Tally cell "advice | 5" (triage.md:56) — matches, and lists exactly those five: `AI-2, AI-6b, AI-7, AI-9, AI-14`.
- Landed section (triage.md:45-47): 1 row, AI-6a. Tally cell "landed | 1" (triage.md:57) — matches; no second phantom row.
- Total distinct original backlog ids covered: control{AI-1,3,4,5,8,10,11,12,13}=9 ∪ advice{AI-2,6,7,9,14}=5, with AI-6's two halves (AI-6a landed, AI-6b advice) both mapping to the single id AI-6 — union is exactly {AI-1..AI-14} = 14, all of BACKLOG.md's AI-1–AI-14 accounted for once each. Cell sum (9+5+1=15) minus the deliberate double-count of AI-6 (counted once in advice as AI-6b, once in landed as AI-6a) = 14, which the document states explicitly (triage.md:59: "AI-6 appears in two rows because it was two rules under one id, so the ids total fourteen"). AI-14 is no longer counted in two disposition buckets — it appears only in the advice table/column now, resolving round 2's specific complaint.
- AI-6 split honesty, checked against BACKLOG.md's original AI-6 text (BACKLOG.md:12): *"Where a criterion's literal and intended readings differ, the literal one governs, or rewrite the criterion before the phase closes. Never read generously in your own favour at gate time."* This does contain two distinguishable rules: an amendment/rewrite-before-close mechanism (→ AI-6a, landed at WORKFLOW.md:72, "Amending a gated criterion") and a literal-vs-intended-reading judgment call at gate time (→ AI-6b, kept advice, triage.md:36, "no syntactic pattern separates a literal from a generous reading"). The split maps cleanly onto the two clauses in the original sentence; not a fabricated division.

EVIDENCE AC-1/tally | CP-3v | PASS | control=9, advice=5, landed=1 physical/logical rows match their stated tallies; union of ids = all 14 BACKLOG ids exactly once, with AI-6 the sole declared exception (split across advice+landed, as stated); AI-14 no longer double-counted | CP-3-triage.md:20-30,35-43,45-47,53-59; BACKLOG.md:7-20

## Regression check — control count 10→9, and stale AI-2 references

**Named observable, all 9 remaining controls: PASS.** Every row in the control table (triage.md:20-30) carries a filled "What the check observes" cell: AI-3 (LookPath/go-toolchain guard), AI-5 (missing CP-4 row/evidence), AI-13 (LookPath success-branch silence), AI-1+AI-11 (missing/empty inventory heading), AI-4a (circular verification-fetch ordering), AI-4b (universal-negative count ≠ 1), AI-8 (missing `git status --porcelain` beside a retire/archive verdict), AI-10 (piped grep/rg/find with no paired count, scoped to `evidence/P*/`), AI-12 (`// Deprecated:` tag vs CHANGELOG/README mismatch). None is blank or vague ("behavioural", "judgment") — all nine remain genuinely structural observables.

**Stale cross-reference found: FAIL.** AI-9's row (triage.md:39) reads: `Same limitation as AI-2, which is why AI-2's control is the weakest on that list`. This sentence was written when AI-2 was still classified `control` (the weakest of the ten). After the AI-2 revert, AI-2 no longer has a control at all — it is now `advice` in its entirety (triage.md:38, tally triage.md:56). AI-9's phrase "AI-2's control is the weakest on that list" is now factually wrong on its face: there is no surviving "AI-2 control" to be weakest among; the comparison list it refers to (the control table) no longer contains AI-2. A reader hitting AI-9's row in isolation would believe AI-2 still carries a (weak) control, directly contradicting AI-2's own row two lines above and the tally. This is exactly the kind of second-order staleness the task asked to check for, and it was introduced (or rather, left unrepaired) by the AI-2 fix.

No other reference to "AI-2" exists in the document besides its own row (triage.md:38), the AI-9 row (triage.md:39), and the tally (triage.md:56) — the tally is correct (AI-2 listed only under advice). No other stale numeric reference to the old control-count-of-10 was found elsewhere in the document (checked full-file grep for "10").

EVIDENCE regression | CP-3v | PASS | all 9 remaining control rows carry a named, non-vague observable | CP-3-triage.md:20-30
EVIDENCE regression | CP-3v | FAIL | AI-9's row still says "AI-2's control is the weakest on that list" — stale, since AI-2 no longer has any control after the revert | CP-3-triage.md:39 vs :38,56

## Summary

| Criterion | Verdict | Note |
|---|---|---|
| AC-1 | PASS | All 14 ids carry a disposition+reason; tally arithmetic now internally consistent and traces to physical rows |
| AC-4 | PASS (carried from round 2, unaffected by these fixes) | Not re-litigated this round; no fix touched AC-4's substance |
| AC-5 | PASS | AI-6a re-verified independently against WORKFLOW.md:72 and commit 6d09b29; AI-14 no longer claimed closed; no other landed/closed claim exists |

Regression: FAIL:fixable — AI-9's reason (triage.md:39) still refers to "AI-2's control," which no longer exists after the AI-2 revert to advice. One-line edit needed: rephrase to something like "Same limitation as AI-2, whose proposed control was reverted for the same reason" or "...which is why AI-2's control was the weakest before it was reverted." This does not affect AC-1/AC-4/AC-5 pass/fail (AI-9 itself is correctly classified and its own reasoning is otherwise sound) but is a real internal-consistency defect the task explicitly asked to surface.

FIX_HINTS:
- AI-9 (triage.md:39) | stale present-tense reference to a control AI-2 no longer has | Reword to past tense / reflect the revert, e.g. "Same limitation as AI-2, whose proposed control was reverted for it" — no other row needs touching.
