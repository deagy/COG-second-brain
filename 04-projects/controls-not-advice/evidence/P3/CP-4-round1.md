# CP-4 integration verification — controls-not-advice P3 (AC-3, AC-6)

## Verdict: FAIL:fixable

Two of six integration checks found real breaks, both centered on `04-projects/harness/BACKLOG.md`'s AI-1 and AI-14 rows. AI-2/AI-6b/AI-7/AI-9 land cleanly; the backlog structure and CLAUDE.md/WORKFLOW.md additions are otherwise sound and non-duplicative; citations sampled all resolve; P4 has a real hook to use; AC-7 is not silently claimed.

## Check 1 — P3 advice text vs. P2 controls

AI-2, AI-9, AI-7, AI-6b: no contradiction. `CLAUDE.md:167-173` and `WORKFLOW.md:78-84` state each item's unobservability correctly and match P1's triage.

**AI-14 fails this check.** `CLAUDE.md:173`'s landed text ("Treat an environment note as a finding until shown otherwise... Most environment notes are not version-pair-shaped, which is why this stays judgment") makes no mention of AI-13 at all — that's actually *correct*, because P1's own post-P2 reconciliation (`evidence/P1/CP-3-triage.md`, "Reconciled after P2 built them") states AI-13 shipped narrower than AI-14's originating incident: "It also guarantees less than the retro's incident, which turned on an unlogged **version**, not an unlogged path." AI-14's originating instance ("installed kernel 0.13.2, repository 0.14.2") is a version mismatch; AI-13's built check (`toolchain_guards_test.go`) only guards a **discarded resolved path**. AI-13 does not cover AI-14's instance.

But `BACKLOG.md`'s AI-14 row was not corrected to match: it still reads "**advice** — `CLAUDE.md`. AI-13 covers its originating instance; strike that half when the coverage is demonstrated" — directly contradicting AI-13's own row two lines above it: "**control** — cadre `internal/cli/toolchain_guards_test.go`. Narrower than the retro incident: it guards the resolved path, not the version." Two adjacent rows in the same file assert opposite things about the same coverage question, and the false one (coverage exists, pending demonstration) is the one left standing. The P3 CP-2 plan (`evidence/P3/CP-2-plan.md:12`) explicitly planned to land AI-14 "with the note that AI-13's control covers its originating instance" — the build correctly dropped that note from CLAUDE.md when it turned out false, but nobody backported the correction into BACKLOG.md.

## Check 2 — backlog citations vs. reality (sample of 7)

| ID | Citation | File exists | Commit resolves |
|---|---|---|---|
| AI-3 | cadre `internal/cli/toolchain_guards_test.go` @ `fd2c2295` | yes | yes (commit) |
| AI-4 | `.claude/lib/spec-lint.sh` @ `f322c19` | yes | yes (commit) |
| AI-5 | `.claude/lib/phase-gates.sh` @ `181cecb` | yes | yes (commit) |
| AI-8 | `.claude/lib/evidence-lint.sh` @ `44af752` | yes | yes (commit) |
| AI-12 | gloop `internal/docguard/deprecation_parity_test.go` @ `0088da3` | yes | yes (commit) |
| AI-17 | cadre `internal/cli/duplicate_paragraphs_test.go` @ `32d863e1` | yes | yes (commit) |
| AI-15 | cadre `f378fee1` | — | yes (commit) |

All seven resolve. No falsified citation in this sample.

## Check 3 — CLAUDE.md coherence

New § "Before you assert it, check it" (`CLAUDE.md:167-173`) does not duplicate § Interaction (file-reading, answer-before-acting — different topic) or the existing "Verification means observing the artifact" bullet under § Verification Harness (`CLAUDE.md:32`). The two verification rules are complementary, not overlapping, and the new section says so explicitly: the harness rule requires an artifact to observe post-hoc; the new section's own framing is "each defect happens in a message rather than in a file... no artifact to inspect." No duplication or contradiction found. Diff confirmed purely additive (`git show 079618c -- CLAUDE.md WORKFLOW.md`): +9/-0 and +8/-0, no existing line touched.

## Check 4 — cross-phase traceability

P1's five `advice` items (AI-2, AI-6b, AI-7, AI-9, AI-14) are all landed by P3 in `CLAUDE.md` or `WORKFLOW.md`. P1's eight `control` ids (AI-1+AI-11 merged, AI-3, AI-4, AI-5, AI-8, AI-10, AI-12, AI-13) were all built in P2, and none is *additionally* landed as advice — **except AI-1**.

`BACKLOG.md`'s AI-1 row reads: "**advice** — landed in `.claude/skills/ultragoal/SKILL.md`; the structural half became a **control** (`evidence-lint.sh` axes check)" — primary label `advice`. AI-11's row for the *same merged item* reads: "**control** — merged with AI-1 as the fifth inventory axis" — primary label `control`. Same item, contradictory primary disposition in two rows of the same file.

Checked the cited landing: `.claude/skills/ultragoal/SKILL.md:202-205` contains "A port or extraction plan missing one of its five inventory axes... The check triggers on a plan naming its own axes" — this is the **control's own documentation** (predates P3; last touched by commit `44af752`, the evidence-lint build, not by P3's `079618c`). `git show 079618c --stat` confirms `.claude/skills/ultragoal/SKILL.md` was not touched by P3 at all. There is no distinct advice-shaped instruction anywhere in that file (`grep -i "inventory\|axis\|axes"` returns only the one control-description passage). P1's own tally (`evidence/P1/CP-3-triage.md`) explicitly says AI-1's residual note "is a note attached to a control, **not** a separate item, and is not counted in the advice column." BACKLOG.md's AI-1 row promotes that non-item to a primary `advice` disposition with a landing citation that, on inspection, cites the control's own text. This is a fabricated advice-landing and a cross-phase break: a P1 `control` item is now also carrying a P3 `advice` label.

## Check 5 — P4 hookability

`BACKLOG.md`'s new header (lines 5-13) states the vocabulary P4 needs: three disposition names, a "What closes it" column per disposition, and a stated reason-quality bar ("what a check would have to observe, and why that is unobservable... a cost argument must say so plainly"). `.claude/skills/retro/SKILL.md` does not yet reference this vocabulary (expected — that wiring is P4's job, not P3's), but the vocabulary now exists as a stable, named thing a retro instruction can point at. P3 gives P4 something concrete to hook into.

## Check 6 — traceability scope

`spec.md`'s traceability table lists AC-7 as `P4 | | pending` — untouched by P3. `STATUS.md` P3 row lists only `AC-3, AC-6`. `evidence/P3/CP-3-build.md` and `evidence/P3/CP-3v-round1.md` make no AC-7 claim. P3 does not silently claim AC-7.

---

VERDICT: FAIL:fixable
INTEGRATION_CLAIMS_CHECKED: 6
EVIDENCE:
EVIDENCE AC-3 | CP-4 | PASS | AI-2/AI-9/AI-7/AI-6b landed text matches P1 triage reasons, no contradiction with P2 controls | CLAUDE.md:167-173, WORKFLOW.md:78-84
EVIDENCE AC-3 | CP-4 | FAIL | AI-14's BACKLOG.md row claims AI-13 covers its originating instance; AI-13's own row and P1's post-P2 reconciliation say the opposite (guards path, not version) | 04-projects/harness/BACKLOG.md (AI-13, AI-14 rows), evidence/P1/CP-3-triage.md § Reconciled after P2 built them
EVIDENCE AC-6 | CP-4 | PASS | 7-citation sample (AI-3,4,5,8,12,17,15) all resolve to real files/commits in cadre, gloop, cog-second-brain | git cat-file -t checks above
EVIDENCE AC-6 | CP-4 | PASS | New CLAUDE.md section does not duplicate or contradict § Interaction or the harness's artifact-observation rule; diff purely additive | git show 079618c -- CLAUDE.md WORKFLOW.md
EVIDENCE AC-6 | CP-4 | FAIL | AI-1's row labels the item primary "advice" citing a landing in ultragoal/SKILL.md that is actually the control's own description (untouched by P3, no distinct advice text present); AI-11's row for the same merged item labels it "control" — contradictory within BACKLOG.md, and inconsistent with P1's tally which excluded this residual from the advice count | 04-projects/harness/BACKLOG.md (AI-1, AI-11 rows), .claude/skills/ultragoal/SKILL.md:202-205, evidence/P1/CP-3-triage.md § Tally
EVIDENCE AC-7 | CP-4 | PASS | BACKLOG.md header states a stable three-way vocabulary with per-disposition closure criteria; P4 has a concrete hook | 04-projects/harness/BACKLOG.md:5-13
EVIDENCE AC-7 | CP-4 | PASS | P3 evidence and traceability table claim only AC-3/AC-6; no silent AC-7 claim | spec.md traceability table, evidence/P3/CP-3-build.md, evidence/P3/CP-3v-round1.md
FAILURES:
- AI-14 | BACKLOG.md row asserts AI-13's control covers AI-14's originating instance | AI-13's own row and P1's reconciliation say it's narrower (path, not version) — the claim is false and needs to be struck from AI-14's row, not conditionally worded
- AI-1 | BACKLOG.md row primary-labels a P1/P2 `control` item as `advice` with a fabricated landing citation | ultragoal/SKILL.md:202-205 is the control's own text, untouched by P3; AI-11's row (same merged item) correctly says `control`; the two rows contradict each other
