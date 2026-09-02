# CP-4 integration verification — controls-not-advice P4 (AC-7)

VERDICT: FAIL:fixable
INTEGRATION_CLAIMS_CHECKED: 10

## 1. Does the retro skill's own instructions produce a row backlog-lint.sh accepts?

No. Traced the concrete case the brief asked for: writing the backlog row for the "row-versus-reality cross-check" carried out of P3 (`evidence/P4/CP-2-plan.md`'s "Not in scope" section, `evidence/P3/CP-5-acceptance.md:27`).

`backlog-lint.sh`'s case statement matches only the literal substrings `**control**`, `**advice**`, `**landed**` (bold, no backtick) — confirmed by reading the script and by the fact every real row in `BACKLOG.md` is written that way (e.g. `**control** — merged with AI-11`).

`retro/SKILL.md` teaches two different, and both wrong, forms:
- Phase 4 (`SKILL.md:59-60`): `**\`control\`**` / `**\`advice\`**` — bold *and* backtick.
- Phase 5 (`SKILL.md:69`): `` `control` `` / `` `control — unbuilt` `` — backtick, no bold.

`retro-template.md`'s own filled example row is a third form: `control — unbuilt | advice — <why no check reaches it>` — plain text, no bold, no backtick.

Built all three as real rows and ran the actual script:

```
Test A (template's literal style, plain):        AI-21 has no disposition — exit 1
Test B (SKILL.md Phase 4 literal style, **`x`**): AI-21 has no disposition — exit 1
Test C (BACKLOG.md's actual convention, **x**):   every row carries a disposition — exit 0
```

A retro author who fills the Disposition column exactly as the template shows them, or exactly as Phase 4's own prose renders, gets rejected by Phase 5's own lint command — for a reason neither document states (the required markdown is bold-without-backtick, discoverable only by imitating existing `BACKLOG.md` rows, which nothing in the skill instructs). This is the wiring gap CP-4 exists to catch: two artifacts built in the same phase (skill text, lint script) that don't agree with each other, verified only individually by CP-3v (which tested the script against synthetic rows it happened to format in the accepted convention, and against the already-correctly-formatted live `BACKLOG.md`) — never against the skill's own documented example.

## 2. Six-script matrix across the three goals

| Script | controls-not-advice | repo-consolidation | capability-parity |
|---|---|---|---|
| `phase-gates.sh` | exit 1 — P4 `NEVER RUN: CP-4 CP-5` | exit 1 — P1 missing CP-4, P2 missing CP-5, P5 missing CP-3v | exit 0 — clean |
| `evidence-lint.sh` | exit 0 — clean | exit 1 — `evidence/P3/CP-2-plan.md` missing the `destination-already-does` axis | exit 0 — clean |
| `spec-lint.sh` | exit 0 — clean | exit 0 — clean | exit 0 — clean |
| `backlog-lint.sh` | exit 0 — clean (single shared `BACKLOG.md`, not per-goal) | same file | same file |
| `ci-status.sh` | n/a — P4 touched only vault files, no external repo | ran against `~/sdk/cadre`, `~/sdk/gloop` (repos controls-not-advice P2's own controls shipped into): both `success`, exit 0 | not exercised — no claims checked here name a repo |
| `checkpoint.sh status` | `evidence/P4/evidence/checkpoints.tsv` → CP-2/CP-3/CP-3v PASS, matches `phase-gates.sh`'s "CP-4 CP-5 never run" exactly | — | — |

No two scripts disagreed or flagged the same artifact for contradictory reasons. `phase-gates.sh`'s controls-not-advice P4 finding ("CP-4 CP-5 never run") is simply this CP-4 run itself plus the not-yet-run CP-5 — expected, not a defect, and it will resolve once this verdict and CP-5 are recorded. repo-consolidation's `phase-gates.sh` and `evidence-lint.sh` findings are pre-existing state in a different, separately-tracked ultragoal (STATUS.md there records it "closing" with two criteria explicitly deferred as AC-07b/AC-10b) — not caused by, or a regression from, controls-not-advice P4's edits, which touched only `retro/SKILL.md`, `retro-template.md`, and `backlog-lint.sh`.

Independently reproduced rather than trusted: `git show 81ad9f5:04-projects/harness/BACKLOG.md | backlog-lint.sh -` on the pre-P1 state gives 14 findings, exit 1 — matches `CP-3v-round1.md`'s claim, re-verified myself rather than taken from the worker's own record.

## 3. Gate-story coherence

`ultragoal/SKILL.md` names `spec-lint.sh` at CP-1 (charter, skips already-`verified` rows so it can't cry wolf on shipped work) and `ci-status.sh`/`phase-gates.sh`/`evidence-lint.sh` at "before either gate" (per-phase CP-5 and north-star). `phase-gates.sh` only iterates `evidence/P*/` directories that already exist (`[ -d "$dir" ] || continue`), so it does not spuriously fail on phases that haven't started — no placement bug there.

`retro/SKILL.md` names `backlog-lint.sh` at Phase 5, with no argument — it lints the **entire shared** `04-projects/harness/BACKLOG.md`, not the rows the current retro author just added. Two consequences a retro author cannot fix from inside their own retro:
- Any pre-existing row from a different retro that becomes invalid later (most concretely: the `advice`-location check now `stat`s the cited file — `evidence/P4/CP-3-build.md`'s "Strengthened after CP-3v" section — so if a cited skill body or `CLAUDE.md` section is later renamed or removed, every subsequent retro's Phase 5 fails campaign-wide on a row that isn't theirs) blocks Phase 5 for everyone until someone fixes the old row.
- Neither `SKILL.md` nor the template says what to do if the check fails for a reason outside the row just written.

This is a real but lower-probability defect than #1 (it requires future drift; #1 fails today, on the very first attempt, using only the skill's own words).

## 4. Cross-phase closure

All 14 P1-dispositioned ids (AI-1..AI-14) trace to a P2 control or a P3 advice landing, none bare `open`: AI-1/AI-11 merged (evidence-lint.sh axes check, `44af752`), AI-3 (cadre `toolchain_guards_test.go`, `fd2c2295`), AI-4 (spec-lint.sh ×2, `f322c19`), AI-5 (phase-gates.sh, `181cecb`), AI-8 (evidence-lint.sh salvage, `44af752`), AI-10 (evidence-lint.sh inventory, `44af752`), AI-12 (gloop `deprecation_parity_test.go`, `0088da3`), AI-13 (cadre `toolchain_guards_test.go`, `fd2c2295`) = 9 controls, matching spec.md's phase table; AI-2, AI-6, AI-7, AI-9, AI-14 landed as advice in `CLAUDE.md`/`WORKFLOW.md` = 5, matching. No item falls through.

P4's mechanism would have caught P1's original problem: confirmed above by independent replay (14/14 bare-open rows flagged at commit `81ad9f5`), not merely by re-reading CP-3v's claim.

## 5. Carried limitations still visible, none quietly closed

All four checked and confirmed present at a location a reader would find, and absent from any later document claiming closure:
- **Verified-skip trusts a string** — `evidence/P2/CP-5-acceptance.md:25`, `evidence/P2/CP-3-build.md:60`. No P3 or P4 document claims this is fixed.
- **AI-13 narrower than its retro incident** (guards a path, not a version) — stated in `BACKLOG.md`'s own AI-13 row, `evidence/P2/CP-3-build.md` § Carried out of P2, and reaffirmed in `evidence/P3/CP-4-integration.md`. Consistent everywhere it's mentioned.
- **AI-14's version case uncovered** — `BACKLOG.md`'s AI-14 row explicitly: "Nothing covers the version case." (This was P3's own CP-4 FAIL:fixable finding — the row originally claimed the opposite and was corrected; the correction holds through P4.)
- **Row-versus-reality cross-check carried, not built** — stated in `evidence/P3/CP-5-acceptance.md:27`, restated in `evidence/P4/CP-2-plan.md` ("Not in scope") and `evidence/P4/CP-3-build.md` ("Shape is what this phase can afford"), and disclosed in `backlog-lint.sh`'s own header comment. P4 explicitly declines to close it rather than implying coverage.

## 6. Traceability

`spec.md`'s matrix and `STATUS.md`'s phase table agree with each other and with what P1-P3 actually verified (AC-1 through AC-6 all `verified`, each citing its phase's evidence). P4 claims AC-7 only, confirmed in both `CP-2-plan.md` and `CP-3-build.md` (already independently checked by CP-3v-round1.md point 6; spot-checked again here — no other AC-n appears).

One stale administrative note, already flagged non-blocking by CP-3v-round1.md and not re-raised as a new finding here: `STATUS.md`'s phase table still reads "P4 ... not started," though CP-2/CP-3/CP-3v evidence already exists. Will presumably resolve at CP-5/CP-6 close-out.

## EVIDENCE

EVIDENCE AC-7 | CP-4 | FAIL | `retro/SKILL.md` Phase 4 (`**\`control\`**`) and Phase 5 (`` `control` ``) and `retro-template.md`'s example row (`control — unbuilt`) all use markdown forms `backlog-lint.sh` rejects; only the undocumented bold-no-backtick form (`**control**`) used in existing `BACKLOG.md` rows passes | `.claude/skills/retro/SKILL.md:59-60,69`, `.claude/skills/retro/references/retro-template.md:33-34`, `.claude/lib/backlog-lint.sh` case statement, reproduced live with three test files (Tests A/B/C above)
EVIDENCE AC-7 | CP-4 | PASS | `phase-gates.sh` only walks existing `evidence/P*/` dirs, so its placement at "before either gate" in `ultragoal/SKILL.md` does not spuriously fail on unstarted future phases | `.claude/lib/phase-gates.sh` (`for dir in "$goal"/evidence/P*/; do [ -d "$dir" ] || continue`)
EVIDENCE AC-7 | CP-4 | PASS (with note) | `backlog-lint.sh` at retro-time lints the whole shared `BACKLOG.md`, not the current retro's new row; a future drift in an old row's cited file (now checked for existence) would block Phase 5 for an unrelated author, and neither `SKILL.md` nor the template says what to do about it | `.claude/skills/retro/SKILL.md` Phase 5, `.claude/lib/backlog-lint.sh` advice-location file-existence check
EVIDENCE AC-1..AC-7 | CP-4 | PASS | All 14 P1 dispositions trace to a P2 control or P3 advice landing; counts match spec.md's phase table (9 controls, 5 advice) | `04-projects/harness/BACKLOG.md` AI-1..AI-14 rows
EVIDENCE AC-7 | CP-4 | PASS | P4's mechanism catches P1's original defect — independently replayed (not trusted from CP-3v): `git show 81ad9f5:.../BACKLOG.md` piped into `backlog-lint.sh` → 14 findings, exit 1 | live command output, this session
EVIDENCE AC-2 | CP-4 | PASS | Carried limitation "verified-skip trusts a string" still stated, no later doc claims it fixed | `evidence/P2/CP-5-acceptance.md:25`
EVIDENCE AC-2 | CP-4 | PASS | AI-13/AI-14 coverage gap consistently stated across P2, P3, and BACKLOG.md itself | `04-projects/harness/BACKLOG.md` AI-13/AI-14 rows, `evidence/P3/CP-4-integration.md`
EVIDENCE AC-3 | CP-4 | PASS | Row-versus-reality cross-check consistently disclosed as carried, not built, through P3 and P4 | `evidence/P3/CP-5-acceptance.md:27`, `evidence/P4/CP-2-plan.md`, `.claude/lib/backlog-lint.sh:13-17`
EVIDENCE AC-1..AC-7 | CP-4 | PASS | spec.md matrix and STATUS.md phase table agree; P4 claims AC-7 only | `04-projects/controls-not-advice/spec.md` § Traceability, `STATUS.md` § Phases
EVIDENCE — | CP-4 | PASS | No two of the six harness scripts disagreed or flagged the same artifact for contradictory reasons, across all three goals tested | matrix in § 2 above

## FAILURES

- `.claude/skills/retro/SKILL.md` (Phase 4 and Phase 5) and `.claude/skills/retro/references/retro-template.md` teach disposition markdown that `backlog-lint.sh` rejects. A retro author following either document's literal wording produces a row that fails Phase 5's own lint command, on the very first attempt, for a formatting reason nothing in either document states. Reproduced live (Tests A and B above both exit 1; only the undocumented `**control**`/`**advice**`/`**landed**` bold-no-backtick form, Test C, passes). Fix is small: either loosen `backlog-lint.sh`'s regex to also accept the skill's own documented forms, or correct `SKILL.md`/`retro-template.md` to show the literal bold-no-backtick syntax the script actually requires (and make the two SKILL.md occurrences, which currently disagree with each other, agree).
