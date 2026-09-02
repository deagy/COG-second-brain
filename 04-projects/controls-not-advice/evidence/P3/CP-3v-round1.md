# Verification — controls-not-advice P3 (AC-3, AC-6)

## Verdict summary

- **AC-3**: PASS
- **AC-6**: PASS (one clarity note, not a fail)

## Per-item verdicts (the five advice items)

| ID | Home | Verdict | Evidence |
|---|---|---|---|
| AI-2 | `CLAUDE.md:171` (§ Before you assert it, check it) | PASS | "Verify a name or destination exists before putting the decision to the user. A citation about a name is not evidence the name is free. `cadre-lifecycle` was proposed as a repository name off a misread citation; `gh repo create` refusing it was the only thing standing between that session and pushing into an archived repository. The check is mechanical and already exists — it just ran too late to be a check." Specific incident (cadre-lifecycle), specific mechanism (check exists but fires after the message, not before). Matches P1 triage's round-2 correction that the evidence-doc lint proposal would never have caught a chat-only decision. |
| AI-9 | `CLAUDE.md:172` (same section) | PASS | "Check a repository's visibility before reasoning about who its documentation reaches. `gh repo view --json visibility` is one line. Nothing invokes it, because the defect is a reasoning step: an argument about what a document exposes, built on an assumption about who can read it." Different mechanism from AI-2 (nothing invokes an available one-liner, vs. a check that exists but is timed wrong) — not interchangeable. |
| AI-14 | `CLAUDE.md:173` (same section) | PASS | "'Installed kernel 0.13.2, repository 0.14.2' was recorded as a curiosity. It was a guard checking the wrong artifact. Most environment notes are not version-pair-shaped, which is why this stays judgment — but a note you cannot immediately explain is a finding you have not investigated yet." Names the exact originating quote; reason (most notes aren't version-pair-shaped, so no general pattern to check) is distinct from AI-2/AI-9. |
| AI-7 | `CLAUDE.md:156` (§ Git) | PASS — honest cost argument | "A `PreToolUse` hook could enforce this — COG ships no hook infrastructure, so this is a cost decision rather than an impossible one, and worth revisiting if hooks ever arrive for another reason." Explicitly says "cost decision... not an impossible one" — does not dress cost as infeasibility. This is exactly the failure mode the build record claims to avoid, and the text avoids it. |
| AI-6b | `WORKFLOW.md:78-84` (§ Reading a criterion you are about to be judged by) | PASS | "Where a criterion's literal and intended readings differ, the literal one governs... No check reaches this. The criterion is unedited, the verdict is a judgment, and nothing distinguishes a generous reading from a correct one syntactically." Carries its own incident (AC-04 archived-file defence, WORKFLOW.md:81-82). Reason names the specific unobservable (syntactic indistinguishability between generous/correct reading) — does not read as a copy of AI-2/AI-9/AI-14's "message not file" framing. |

All five are landed in `CLAUDE.md` or `WORKFLOW.md` (both loaded at session start per this repo's `CLAUDE.md` header), not only in the backlog. The backlog (`04-projects/harness/BACKLOG.md`) rows for these five point to the landed location and give a short paraphrase, consistent with the full text.

**Adversarial check on genericness**: AI-2/AI-9/AI-14 share one intro sentence ("each defect happens in a message rather than in a file... no artifact to inspect and no moment after the fact when a check could run") — this is deliberately shared per the build record's stated design (P1 triage: "AI-2, AI-9 and AI-14 share a section because they share a limitation, and the section says so once"). AC-3's bar is that *the reason* be item-specific, not that no framing sentence be shared. Each item's own bullet supplies a distinct incident and a distinct mechanism (timing-too-late vs. nothing-invokes-it vs. not-version-pair-shaped), and none of the three bullets would substitute for another without becoming false. Judged as satisfying "specific to that item, not a generic 'behavioural'."

## AC-6 — backlog header and rows

`04-projects/harness/BACKLOG.md`:
- Row count: **20** (`AI-1` … `AI-20`), confirmed by `grep -cE '^\| AI-'`.
- Disposition labels present: `**control**` (11 bold occurrences), `**advice**` (11), `**landed**` (3) — total exceeds 20 because two rows (AI-1, AI-6) legitimately carry two labels (a split item). No row lacks all three; `grep` for rows missing all three labels returned empty.
- No fourth label found: only bolded tokens in ID rows are `control`, `advice`, `landed`, and one unrelated `**concept**` (inside AI-16's action-item prose, not in the Disposition column).
- Header (`04-projects/harness/BACKLOG.md:5-13`) defines the three dispositions in a table (`control` / `advice` / `landed`), states what closes each, and states the reason-quality bar ("what a check would have to observe, and why that is unobservable... a cost argument must say so plainly").

**Substantive read**: a reader who has never seen this project can distinguish, per row, `control` (built check, evidence cited inline as file path + commit hash, e.g. AI-3: "cadre `internal/cli/toolchain_guards_test.go`, commit `fd2c2295`") from `advice` (a rule landed at a named file/section, e.g. AI-9: "`CLAUDE.md`. Scriptable, but nothing would invoke it") from `landed` (artifact named directly). This works for every row in the file today because P1/P2 already closed every `control` item (per spec.md, AC-2 is "verified" for all 9 controls) — there is currently no row sitting as bare `control` waiting to be built, so the file cannot be checked against that specific ambiguous case in its present state.

**Where the file is unclear**: the header's "What closes it" column states the closing *action* for `control` (build + falsify both directions) but does not state a *labeling convention* for a not-yet-closed control row (e.g., would a future unbuilt item read `control` with no evidence, or `control — pending`?). Today every `control` row happens to carry a commit hash inline, which functions as the completion signal, but that convention is inferred from the rows, not stated in the header. This is a minor gap, not a criterion failure — AC-6 asks whether the *current* file lets a reader distinguish unfixable (advice) from unbuilt (open/pending control), and no row in the file is currently in the "unbuilt control" state, so the ambiguity is latent rather than demonstrated.

## Six `done` rows — git history check

`git log --oneline -- 04-projects/harness/BACKLOG.md` shows commit `079618c` ("docs(harness): land the advice, and make the backlog say which is which") as the P3 edit. `git show 079618c -- 04-projects/harness/BACKLOG.md`:

- Old rows AI-1–AI-14: Status column read bare `open` (no label).
- Old rows AI-15: Status `done`. AI-16–AI-20: Status `**done** — <target/commit>`.
- New rows: AI-15 → `**landed** — CP-4 run, the AC-7 guard widened (cadre f378fee1), and phase-gates.sh added...`; AI-16 → `**advice** — landed at .claude/skills/closed-loop/SKILL.md § CP-3 Build`; AI-17 → `**control** — cadre internal/cli/duplicate_paragraphs_test.go, commit 32d863e1`; AI-18 → `**advice** — landed at .claude/skills/closed-loop/SKILL.md § CP-3v`; AI-19 → `**advice** — landed at .claude/skills/closed-loop/SKILL.md § After a revert`; AI-20 → `**advice** — landed at CLAUDE.md § Background commands`.

Confirmed: exactly six rows (AI-15–AI-20) carried `done`/`**done**` before this commit, all six were relabeled, and in every case the target/commit/file evidence already present in the old row is preserved verbatim in the new row — only the label word changed (`done` → `landed`/`advice`/`control`), plus AI-15/16 gained a short explanatory clause using the same facts. No substantive content (targets, commit hashes, descriptions) was altered. Matches the build record's claim exactly.

## Regression check — CLAUDE.md / WORKFLOW.md

`git show 079618c -- CLAUDE.md` and `-- WORKFLOW.md`: both diffs are purely additive (CLAUDE.md +9/-0 across two insertion points; WORKFLOW.md +8/-0 at one insertion point). No existing line was removed or altered. New CLAUDE.md content: one bullet appended to existing `### Git` list (line 156) and one new `### Before you assert it, check it` subsection inserted between `### Background commands` and `### Interaction`, both still nested correctly under `## Engineering Discipline — ALWAYS APPLY`. New WORKFLOW.md content: one new `### Reading a criterion you are about to be judged by` subsection inserted after the existing "Amending a gated criterion" rule, before `## Gate classes`. Structure and neighboring rules intact; nothing displaced or corrupted.

## Overall

AC-3: **PASS** — all five advice items found landed with file:line evidence, each reason is item-specific (distinct incident, distinct mechanism), AI-7 is an honest cost argument not dressed as impossibility.

AC-6: **PASS** — header defines and distinguishes all three dispositions, all 20 rows carry exactly one (or a legitimate split of two), no fourth label survives, six previously-`done` rows were relabeled with content preserved. Noted clarity gap: no explicit convention stated for how an *unclosed* `control` row would read, though none currently exists in the file to test against.
