# CP-4 integration verification — controls-not-advice P3, round 2 (AC-3, AC-6)

Confirms the two round-1 `FAIL:fixable` findings (AI-14, AI-1 rows in `04-projects/harness/BACKLOG.md`) are fixed by commit `9ee568b`, checks the fix introduced nothing new, and re-confirms round 1's passing checks. Read-only; repository confirmed clean (`git status --porcelain` empty) before and after.

## Check 1 — AI-14's row

`BACKLOG.md` AI-14 now reads: "**advice** — `CLAUDE.md`. AI-13 does **not** cover its originating instance: that turned on an unlogged *version*, and AI-13 guards a discarded *path*. Nothing covers the version case."

Cross-checked against all three other artifacts named in the task:

- **AI-13's own row** (`BACKLOG.md`): "**control** — cadre `internal/cli/toolchain_guards_test.go`. Narrower than the retro incident: it guards the resolved path, not the version." Agrees — path, not version.
- **CLAUDE.md landing** (`CLAUDE.md:173`, § Before you assert it, check it): "'Installed kernel 0.13.2, repository 0.14.2' was recorded as a curiosity. It was a guard checking the wrong artifact... Most environment notes are not version-pair-shaped, which is why this stays judgment." Makes no claim that AI-13 covers this instance — silent on AI-13 entirely, which is consistent with "not covered," not contradictory.
- **P2's `CP-3-build.md` § Carried out of P2**: "AI-13 guarantees less than its retro's incident... This control only guarantees a resolved *path* is not discarded for a project binary... It also guarantees less than the retro's incident, which turned on an unlogged **version**, not an unlogged path." Agrees exactly, same path/version framing.

All four now tell one consistent story: AI-13 guards a discarded resolved path; AI-14 originated from an unlogged version; the former does not cover the latter. No row asserts coverage that exists nowhere else.

## Check 2 — AI-1's row

`BACKLOG.md` AI-1 now reads: "**control** — merged with AI-11; `.claude/lib/evidence-lint.sh` axes check, commit `44af752`. Residual advice: the check reads whether an axis is present, never whether it was honestly investigated."

- Primary label is `control`, matching **AI-11's row** ("**control** — merged with AI-1 as the fifth inventory axis") — same merged item, same disposition, no contradiction.
- Citation resolves: `.claude/lib/evidence-lint.sh` exists (`ls -la` confirms, 5909 bytes, executable). `git cat-file -t 44af752` returns `commit`. `git log -1 --format='%H %ai' 44af752` resolves to `44af752e518674e9c918935303a618509b70b5ab 2026-09-01 20:19:45 -0700` — the evidence-lint build commit, consistent with AI-8's row citing the same file/commit for a different check in the same script.
- The old fabricated citation to `.claude/skills/ultragoal/SKILL.md` is gone from this row; grep of the current row text confirms no reference to that path remains.

## Check 3 — no new contradiction, whole-file pass

Re-ran the disposition-per-row count (`awk` over the table, stripping `**control**|**advice**|**landed**` tokens per row): all twenty rows carry exactly one disposition token, except AI-6 which carries two by design (`landed` + `advice`, documented in the row itself and in P1's tally as "the only id split across two dispositions"). No fourth label (`done`, `open`, etc.) present anywhere in the table.

Checked every row's citation against what P3 actually touched. `git show 079618c --stat` (P3's build commit) confirms P3 modified only `CLAUDE.md`, `WORKFLOW.md`, `BACKLOG.md`, and its own `evidence/P3/*` files — no skill body, no `.claude/lib/*` script. Every `advice` row's landing citation points into `CLAUDE.md` or `WORKFLOW.md` (AI-2, AI-6b, AI-7, AI-9, AI-14, AI-16, AI-18, AI-19, AI-20 — the latter four from a different retro/phase, landed at `closed-loop/SKILL.md` and `CLAUDE.md` respectively, none claim P3 provenance). No row claims a P3 landing in a file P3 did not touch.

`control — unbuilt` convention (added `fd6d621`, header line 15: "A `control` row cites where its check lives — a file, and a commit for anything shipped... Write `control — unbuilt` while it waits"): no row in the table currently reads `control — unbuilt`, so no direct usage to check for correctness. One pre-existing gap surfaces under the new rule though, not introduced by either fix commit: **AI-10**'s row reads "**control** — `.claude/lib/evidence-lint.sh`, scoped to evidence documents" — cites a file but no commit, despite the check being real and already shipped (confirmed by `grep -n "inventory" .claude/lib/evidence-lint.sh`, the `head`/`tail`-truncation check at lines 53–75, part of the same `44af752` build as AI-1 and AI-8). This doesn't misstate anything — the check exists — but it doesn't meet the letter of the newly-stated convention ("a commit for anything shipped") and isn't marked `unbuilt` either, so a reader applying the new rule strictly can't tell built from unbuilt on this row alone without cross-referencing AI-1/AI-8. Pre-existing (unchanged by both `9ee568b` and `fd6d621`, confirmed via `git show <commit> -- BACKLOG.md` diffs), not a contradiction, not blocking — flagged for a future backlog pass, not this round's fix scope.

## Check 4 — the residual-advice note on AI-1

Row text: "the check reads whether an axis is present, never whether it was honestly investigated." Read `.claude/lib/evidence-lint.sh` lines 96–113 (the axes check): it greps for a heading pattern (`^#+ .*axis|[a-z]+-axis inventory`) to confirm the document is inventory-shaped, then checks for the presence of expected axis headings/content, emitting a note when one is `missing`. It is a structural/presence test — no lexical or semantic check of whether the content under a present axis reflects real investigation. Matches the row's claim exactly, and matches P1's own framing in `CP-3-triage.md` line 40: "AI-1/AI-11 residual | A dishonest inventory — real headings, wrong conclusions | The structural check cannot read whether an axis was actually investigated." Three-way agreement (BACKLOG.md row, live script behavior, P1 triage).

## Check 5 — round 1's passes still hold

- **AI-2, AI-7, AI-9** landings intact and unchanged in `CLAUDE.md` (§ Before you assert it, check it, lines 171–173; § Git line 156).
- **AI-6b** landing intact and unchanged in `WORKFLOW.md` § Reading a criterion you are about to be judged by (lines 78–82).
- Neither fix commit (`9ee568b`, `fd6d621`) touched `CLAUDE.md` or `WORKFLOW.md` — both diffs are `BACKLOG.md` plus their own evidence files, confirmed by `git show --stat` on both commits.
- Disposition-per-row count (Check 3 above) confirms exactly one label per row throughout, no fourth label reintroduced.

---

VERDICT: PASS
INTEGRATION_CLAIMS_CHECKED: 5
EVIDENCE:
EVIDENCE AC-3 | CP-4 | PASS | AI-14's row now says AI-13 does not cover its instance (path vs. version); agrees with AI-13's own row, CLAUDE.md:173, and P2's CP-3-build.md § Carried out of P2 | 04-projects/harness/BACKLOG.md (AI-13, AI-14), CLAUDE.md:173, evidence/P2/CP-3-build.md § Carried out of P2
EVIDENCE AC-6 | CP-4 | PASS | AI-1's row now reads control, agrees with AI-11's row for the same merged item; citation `.claude/lib/evidence-lint.sh` @ 44af752 resolves (file exists, `git cat-file -t` returns commit) | 04-projects/harness/BACKLOG.md (AI-1, AI-11), .claude/lib/evidence-lint.sh, git cat-file -t 44af752
EVIDENCE AC-6 | CP-4 | PASS | Whole-table re-check: exactly one disposition token per row (AI-6 intentionally two), no fourth label; every advice landing citation points into a file P3 actually touched (079618c --stat: CLAUDE.md, WORKFLOW.md only) | 04-projects/harness/BACKLOG.md, git show 079618c --stat
EVIDENCE AC-6 | CP-4 | PASS | AI-1's residual-advice note ("reads whether an axis is present, never whether it was honestly investigated") matches evidence-lint.sh's actual axes check (presence/structural test, lines 96-113) and P1's own framing | .claude/lib/evidence-lint.sh:96-113, evidence/P1/CP-3-triage.md line 40
EVIDENCE AC-3/AC-6 | CP-4 | PASS | AI-2/AI-7/AI-9/AI-6b landings unchanged and intact; both fix commits touched only BACKLOG.md and their own evidence files, not CLAUDE.md/WORKFLOW.md | CLAUDE.md:156,171-173, WORKFLOW.md:78-82, git show --stat 9ee568b fd6d621
FAILURES:
(none blocking; one pre-existing, non-blocking gap noted below, unrelated to the two fixes under review)
- AI-10 | control row cites a file but no commit, despite the check being real and shipped at 44af752 (same build as AI-1/AI-8) | new header convention (fd6d621) calls for "a commit for anything shipped" on every control row; AI-10 predates both fix commits and is unchanged by them — not a contradiction, but does not meet the letter of the new rule and isn't marked unbuilt either; worth a follow-up backlog edit, not a blocker for this round
