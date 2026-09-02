# North-star acceptance gate — `controls-not-advice`, round 2

Scope: verify commit `a88dd21` closed the round-1 caveat (AI-16/18/19/20 tagged
`advice` with only a landing location, no reason; AI-6's advice half had the
same gap). Read-only. `git status --porcelain` clean before and after this
pass; HEAD unchanged at `a88dd21`.

## 1. Every advice row now states a reason

Read all 20 rows of `04-projects/harness/BACKLOG.md` directly (not from the
round-1 report). Advice-dispositioned rows: AI-2, AI-6 (advice half), AI-7,
AI-9, AI-14, AI-16, AI-18, AI-19, AI-20.

| Row | States why (not just where)? | Quote |
|---|---|---|
| AI-2 | yes (pre-existing) | "No artifact: the defect is in a message to the user" |
| AI-6 | yes — **newly added** | "no syntactic pattern separates a generous reading from a correct one — the criterion is unedited and the verdict is a judgment, so the harness answers it structurally instead, with a verifier who did not write the thing being judged" |
| AI-7 | yes (pre-existing) | "A hook could enforce it; COG ships none, so this is a cost decision, not an impossibility" |
| AI-9 | yes (pre-existing) | "Scriptable, but nothing would invoke it: the defect is a reasoning step" |
| AI-14 | yes (pre-existing) | "AI-13 does not cover its originating instance... Nothing covers the version case" |
| AI-16 | yes — **newly added** | "Nothing observes an enumeration that was never run: a search scoped too narrowly leaves output that looks exactly like a complete one, and the missing hits are missing from the evidence too" |
| AI-18 | yes — **newly added** | "The retry count is observable, but the defect is the judgment that this attempt differs in kind from the last — and a worker who believes that will record it as a first attempt at a new method" |
| AI-19 | yes — **newly added** | "A hook could diff after every `git checkout --`; COG ships no hook infrastructure. A cost argument, like AI-7, and it closes with AI-7 if hooks ever arrive" |
| AI-20 | yes — **newly added** | "Same limitation as AI-19: a `PreToolUse` hook could inspect the command string, and there is no hook infrastructure to put it in" |

All 9 advice rows state a reason. No advice row still reads only a location.
`git show a88dd21 -- 04-projects/harness/BACKLOG.md` confirms exactly the AI-6,
AI-16, AI-18, AI-19, AI-20 lines were the ones edited — nothing else in the
table touched.

## 2. Reasons are real, not filler

Spot-checked distinctness: AI-2 ("no artifact exists yet"), AI-9 ("scriptable
but nothing invokes it — a reasoning-step defect"), AI-14 ("dependency gap:
AI-13 covers path, not version") are three different mechanisms sharing only
a common header framing in `CLAUDE.md`, not interchangeable text — confirms
round 1's AC-3 finding still holds for the untouched rows.

**AI-19/AI-20, scrutinized as instructed.** Both cite "COG ships no hook
infrastructure" as the closing cost argument — confirmed independently:
`grep -rn '"hooks"' .claude/settings*.json` → no matches (glob found no
settings file with a hooks key), and no `.claude/hooks` directory exists.
The claim is accurate, not asserted-but-unchecked.

Is the shared clause filler? No — each row names a **different hook shape**
before invoking the shared cause: AI-19's hypothetical is a **post-hoc diff**
("could diff after every `git checkout --`"); AI-20's is a **pre-execution
inspection** ("`PreToolUse` hook could inspect the command string"). These are
not the same check. What's genuinely shared is the higher-level fact (COG has
no hook infrastructure of either kind), which is also the fact AI-7 already
rested on before this commit — the three items are explicitly and honestly
coupled ("closes alongside AI-7 if hooks ever arrive") rather than silently
copy-pasted. This matches the backlog's own rule for cost arguments: state
the cost plainly rather than dressing it as impossibility. Verdict: legitimate
shared limitation, not a single excuse copied twice — the per-item mechanism
differs even though the closing cause is common.

AI-6, AI-16, AI-18 reasons are each self-contained mechanisms (hermeneutic
judgment / never-run enumeration / retry-count-vs-judgment) that do not
resemble each other or any other row's reason — no interchangeability found.

## 3. Reasons travelled to where the rules live

`.claude/skills/closed-loop/SKILL.md`:
- § CP-3 Build (AI-16), line ~78: "No check reaches this one, and the reason
  is worth stating: **nothing observes an enumeration that was never run.**
  A search scoped too narrowly produces output indistinguishable from a
  complete one, and the hits it missed are missing from the evidence as
  well."
- § CP-3v (AI-18), line ~109: "The retry count is observable; the judgment
  is not. A worker convinced this attempt differs in kind from the last will
  record it as a first attempt at a new method, and the count will agree
  with them."
- § After a revert (AI-19), line ~157: "A hook could diff after every `git
  checkout --` and refuse the surprise. COG ships no hook infrastructure, so
  this is a cost argument rather than an impossibility — the same one that
  keeps the write-and-commit rule in `CLAUDE.md` § Git out of a check, and
  both close together if hooks ever arrive for another reason."

`CLAUDE.md` § Background commands (AI-20), line 166: "No check reaches
these: a `PreToolUse` hook could inspect the command string before it runs,
and COG ships no hook infrastructure. A cost argument, not an impossibility,
and it closes alongside the write-and-commit rule above if hooks ever
arrive."

All four confirmed present verbatim (or near-verbatim paraphrase) at the
cited locations, matching `git show a88dd21` diffs exactly. AC-3's
"reason lives with the rule" bar is met for all four.

## 4. Nothing regressed

`bash .claude/lib/backlog-lint.sh` → `backlog-lint: every row carries a
disposition.` exit 0.

`git show a88dd21 --stat` touched exactly 4 files: `.claude/skills/closed-loop/SKILL.md`
(+15), `04-projects/controls-not-advice/evidence/northstar-gate-round1.md`
(new file, the round-1 report archived as evidence, +72), `04-projects/harness/BACKLOG.md`
(+5/-5), `CLAUDE.md` (+1). No lint script (`backlog-lint.sh` or others) is in
the diff — none was edited to pass. No existing check text was weakened; all
diffs are additive (new sentences appended to existing bullets/table cells).

## 5. North-star claim, unqualified, all 20 rows

Every row is one of: `control` with a citation (AI-1, 3, 4, 5, 8, 10, 11, 12,
13, 17 — 10 rows), `landed` with cited evidence (AI-6a half, AI-15 — cite
commits/files), or `advice` with a stated reason (AI-2, 6b, 7, 9, 14, 16, 18,
19, 20 — 9 rows). No row reads bare `open`; no advice row states only a
location. Cross-checked against `backlog-lint.sh` (mechanical: every row has
*a* disposition) plus manual reading of the reason clause on every advice
row (the bar `backlog-lint.sh` does not itself enforce).

No row found that falsifies the sentence "every open retro action is either
a mechanical check that fails on its own defect, or is recorded as advice
with a stated reason it cannot be one." AI-16/18/19/20/6b — the round-1
gap — now carry reasons that name what a check would have to observe and
why that's unobservable (or, for the cost-argument rows, why it's not worth
building given stated infrastructure absence, per the backlog's own rule for
cost arguments).

## Overall verdict: COMPLETE

The north-star is now literally true of the whole 20-row `BACKLOG.md`, not
just the goal's original 14-item slice. Commit `a88dd21` closed exactly the
round-1 caveat: AI-6, AI-16, AI-18, AI-19, AI-20 each gained an item-specific
reason in the backlog and in the document holding the rule; the reasons are
independently confirmed non-interchangeable (including the AI-19/AI-20
shared-cost-cause pairing, which is a legitimate shared limitation with
distinct per-item mechanisms, not a copied excuse); `backlog-lint.sh` still
passes; the diff touched only the four expected files and weakened no check.
