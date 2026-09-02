# CP-4 round 2 — controls-not-advice P4 (AC-7), fix verification for commit 7ae3ca6

VERDICT: PASS
INTEGRATION_CLAIMS_CHECKED: 12

## 1. Author's path, traced end to end, all documented spellings

Wrote real rows into a scratch file with the same table shape as `04-projects/harness/BACKLOG.md` (`| ID | Action | Target file | Disposition |`), then ran `bash .claude/lib/backlog-lint.sh <file>` for real, not by re-reading the round-1 report's claim.

**Literal per-document rows** (`/tmp/.../task1-literal.md`): one `**control**` row shaped exactly like `retro-template.md:34`, one `**advice**` row shaped exactly like `retro-template.md:35` (citing `WORKFLOW.md`, satisfying the file-existence check) → `backlog-lint: every row carries a disposition.` exit 0.

**Every disposition spelling either document uses anywhere**, for both `control` and `advice` — plain (no decoration), backtick-only (`` `control` ``, SKILL.md:69/75, template:30), bold-only (`**control**`, template:34-35, SKILL.md:75), bold+backtick (`` **`control`** ``, SKILL.md:59-60,76) — 8 rows, one per combination:

```
backlog-lint: every row carries a disposition.
exit=0
```

All 8 pass. (Plain/undecorated is no longer literally instructed anywhere in the current docs — that was the old template's failure mode, removed in the fix — but I tested it anyway since the lint's own comment claims it treats decoration as irrelevant; it does.)

Grepped both documents for every remaining occurrence of `control|advice|landed` to confirm no fourth spelling was missed (`SKILL.md:59,60,62,69,75,76`; `retro-template.md:30,34,35`) — all four forms accounted for, none untested.

## 2. The normalisation did not weaken the check

Six bad rows, one file, run once:

```
AI-1  open                                          → "has no disposition"
AI-2  <empty disposition cell>                      → "has no disposition"
AI-3  controlled — some check                        → "has no disposition"
AI-4  advised — landed in WORKFLOW.md                 → "has no disposition"
AI-5  **control** — checked manually (no commit)      → "citing no commit and not marked unbuilt"
AI-6  **advice** — landed in `NOPE-DOES-NOT-EXIST.md`  → "has no disposition" (see note)
```
`backlog-lint: 6 row(s) do not say what kind of item they are.` exit 1 — all six caught.

Note on AI-6: the file-existence check (`does not exist`) only fires for a path matching `(CLAUDE|WORKFLOW|SKILL)\.md`, so a made-up name with no such suffix is instead caught one branch earlier, as "does not say where it landed" (the `named` capture is empty). Ran a second case to confirm the intended branch fires on its own terms: `**advice** — landed in `.claude/skills/nonexistent-skill/SKILL.md`` → `cites .claude/skills/nonexistent-skill/SKILL.md, which does not exist`, exit 1. Both are real rejections; the message differs by which regex trips first, not a gap.

`controlled` and `advised` are rejected because `sed -E 's/^[[:space:]]*([a-z]+).*/\1/'` captures the whole leading run of lowercase letters, not just a fixed-length prefix — `controlled` → `controlled`, which matches none of `control|advice|landed`. The word-boundary property survived the backtick/asterisk stripping; nothing in the fix loosened matching to a prefix test.

## 3. Live backlog: clean and untouched by the fix

`bash .claude/lib/backlog-lint.sh` (default path, live `04-projects/harness/BACKLOG.md`) → `backlog-lint: every row carries a disposition.` exit 0.

`git show 7ae3ca6 --stat` file list: `.claude/lib/backlog-lint.sh`, `.claude/skills/retro/SKILL.md`, `.claude/skills/retro/references/retro-template.md`, three `evidence/P4/*` files, `checkpoints.tsv`. `04-projects/harness/BACKLOG.md` is absent from that list — the string "backlog" appears only inside the commit message body and the diff hunk of `backlog-lint.sh`, never as a changed path. `git status --porcelain 04-projects/harness/BACKLOG.md` is empty. The fix was not made to pass by editing the live data it's supposed to check.

## 4. Round 1's other passes, re-run live (not re-read)

- **Script-vs-script coherence, all three goals, rerun now**: `phase-gates.sh` — controls-not-advice: P4 `NEVER RUN: CP-5` (exit 1, expected — CP-5 hasn't run yet, and CP-4 now shows recorded since round 1's FAIL was logged to `checkpoints.tsv`); repo-consolidation: P1 missing CP-4, P2 missing CP-5, P5 missing CP-3v (exit 1, unchanged from round 1, pre-existing and out of this phase's scope); capability-parity: clean (exit 0). `evidence-lint.sh` — controls-not-advice clean, repo-consolidation 1 finding (`CP-2-plan.md` missing `destination-already-does` axis, same as round 1), capability-parity clean. `spec-lint.sh` — clean on all three (corrected the invocation to pass the goal directory, not a `spec.md` path directly, per the script's own usage comment; result matches round 1's claim). No two scripts disagreed or flagged the same artifact for contradictory reasons.
- **14/14 P1 dispositions trace to a P2/P3 outcome**: read `BACKLOG.md` AI-1..AI-14 directly. 9 `control` (AI-1/AI-11 merged, AI-3, AI-4 ×2, AI-5, AI-8, AI-10, AI-12, AI-13), 5 `advice` (AI-2, AI-6, AI-7, AI-9, AI-14) — same count as round 1, no bare `open`.
- **Four carried limitations, re-grepped at source**: "verified-skip trusts a string" present verbatim in `evidence/P2/CP-5-acceptance.md:25` and `CP-3-build.md:60`, no later doc claims it closed. AI-13/AI-14 path-vs-version gap consistent across `BACKLOG.md`, `evidence/P2/CP-3-build.md`, and `evidence/P3/CP-4-integration.md` (four independent statements, same framing). AI-14's "nothing covers the version case" stands unchanged in `BACKLOG.md:36`. Row-versus-reality cross-check still stated as carried-not-built in `evidence/P3/CP-5-acceptance.md:27` and `evidence/P4/CP-2-plan.md:32`. None of the four is claimed fixed anywhere in the P4 evidence added by this round's fix commit.

## 5. Judging the fix's direction

Liberalizing the lint rather than freezing the skill's prose to one markdown form is the right call, for a reason specific to this pair of artifacts: the lint's job is to check the *word*, and the skill's job is to use whatever emphasis reads best in three different rhetorical contexts (defining a term at first use, restating an instruction, giving a worked example). Those are legitimately different jobs — a definition list item earns bold for the term being defined; a table cell earns bold to make the column scannable; an inline reference earns a backtick because it's naming a value, not defining one. Forcing the skill's prose to match one literal string the script happens to grep for would have coupled documentation style to an implementation accident, and the next prose edit (a copyeditor bolding a word for emphasis, unaware a script parses it) would silently reopen the same gap. A script that reads the semantic content and ignores presentation is the more durable fix; a script that demands one exact rendering is a trap for the next writer.

The ambiguity the fix accepts in exchange is real but shallow: a future reader diffing `BACKLOG.md` sees `**control**` used consistently by every existing row (confirmed — grep shows zero rows in the live file use any other spelling), so there is a de facto canonical form already, and nothing in the fix disturbs it. The four-way acceptance is a permissiveness in the *checker*, not an instruction to *vary* the spelling; no document tells an author to pick one of four forms freely, and the skill and template both consistently render `**control**`/`**advice**` (bold, no backtick) at every point that shows a literal example row, matching the live backlog. The two prose references that still use a different decoration (`` `control` `` at SKILL.md:69, `` **`control`** `` at SKILL.md:59-60) are defining or restating the *word*, not showing a *row to copy* — an author copying the template's actual table row, which is the only place the skill shows a full disposition cell, lands on the same bold-only form the live data already uses. So yes: the template's example is unambiguous enough to serve as the canonical form, because it's the only literal row-shaped example in either document, and it already matches what every real row does. The residual four-way tolerance in the script is insurance against future prose drift, not a live source of confusion for today's author.

## EVIDENCE

EVIDENCE AC-7 | CP-4 | PASS | Two rows written exactly as `retro-template.md:34-35` shows (`**control**`, `**advice**` citing `WORKFLOW.md`) pass `backlog-lint.sh` on first attempt | live run, `/tmp/.../task1-literal.md`, exit 0
EVIDENCE AC-7 | CP-4 | PASS | All four disposition spellings used anywhere in `SKILL.md`/`retro-template.md` (plain, backtick, bold, bold+backtick) pass, for both `control` and `advice` | live run, `/tmp/.../task1-spellings.md`, exit 0; grep of both docs confirms no fifth spelling exists
EVIDENCE AC-7 | CP-4 | PASS | Lint still rejects bare `open`, an empty cell, `controlled`/`advised` (prefix-only match), an unbuilt `control` with no commit citation, and `advice` citing a nonexistent file — 6/6 caught in one run, plus a second targeted case isolating the file-existence branch specifically | live run, `/tmp/.../task2-bad.md` and `task2-bad2.md`, exit 1 both
EVIDENCE AC-7 | CP-4 | PASS | Live `04-projects/harness/BACKLOG.md` lints clean and was not touched by 7ae3ca6 | `bash .claude/lib/backlog-lint.sh` exit 0; `git show 7ae3ca6 --stat` file list; `git status --porcelain` empty
EVIDENCE — | CP-4 | PASS | No script-vs-script contradiction across `phase-gates.sh`/`evidence-lint.sh`/`spec-lint.sh`, all three goals, re-run live this round (not re-read from round 1) | live command output, this session
EVIDENCE AC-1..AC-7 | CP-4 | PASS | 14/14 P1 dispositions (9 control, 5 advice) still trace to a P2/P3 outcome, no bare `open` | `04-projects/harness/BACKLOG.md` AI-1..AI-14, read directly
EVIDENCE AC-2,AC-3 | CP-4 | PASS | All four carried limitations (verified-skip trusts a string; AI-13 narrower than its incident; AI-14 version case uncovered; row-versus-reality cross-check carried) still stated, none claimed closed by the fix commit's added evidence | `evidence/P2/CP-5-acceptance.md:25`, `CP-3-build.md:60`; `BACKLOG.md` AI-13/AI-14; `evidence/P3/CP-4-integration.md`; `evidence/P3/CP-5-acceptance.md:27`; `evidence/P4/CP-2-plan.md:32`
EVIDENCE AC-7 | CP-4 | PASS | Fix direction (liberalize the checker, not freeze the prose) is sound: the skill's three prose contexts legitimately use different emphasis, and the template's literal table row — the only full example either document shows — already matches the live backlog's sole convention (`**control**`/`**advice**`, bold-only), so the four-way tolerance is insurance against future drift, not a live ambiguity for today's author | `retro-template.md:34-35` vs. `BACKLOG.md` rows (identical convention); `SKILL.md:59-60,69,75-76` (three prose contexts, three renderings, none of them a row example)

## FAILURES

(none)
