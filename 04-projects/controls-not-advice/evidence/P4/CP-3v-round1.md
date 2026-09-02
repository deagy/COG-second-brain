# AC-7 verification — controls-not-advice P4

VERDICT: PASS
LANE: full
CLAIMS_CHECKED: 6

## 1. Question asked at write time, not recalled later

`.claude/skills/retro/SKILL.md:55-64` (Phase 4) now reads "Action items get IDs (`AI-01`…) **and a disposition**" and asks inline "**can a check observe this defect?**" with the control/advice branches spelled out. Phase 5 (`SKILL.md:69`) requires "Every row carries its disposition — never a bare `open`" and pipes to `backlog-lint.sh`. `references/retro-template.md:29-34` replaced the old `Status` column with `Disposition`, with a filled example row (`control — unbuilt | advice — <why...>`) rather than the old `proposed` placeholder. A retro author fills this table during Phase 4, i.e. at write time — there is no path in the skill that lets someone finish Phase 4 with a bare `open` row and only get caught at Phase 5, since the template itself has no `open`/`proposed` cell left to leave blank-shaped.

## 2. backlog-lint.sh, both directions, against real git history

Current `04-projects/harness/BACKLOG.md`: `bash .claude/lib/backlog-lint.sh` → `backlog-lint: every row carries a disposition.` exit 0. Confirmed live.

Historical replays (`git show <sha>:...BACKLOG.md` piped into the same script):

| Commit | Build record's claim | Reproduced |
|---|---|---|
| `81ad9f5` | "14 bare open rows → 14 findings, exit 1" | Confirmed: 14 findings (AI-1..AI-14, all "has no disposition"), exit 1 |
| `079618c` | "after convention written, before citations completed → 4 findings, exit 1 (three uncited controls and one more)" | Confirmed: 4 findings, exit 1 — AI-1, AI-10, AI-13, AI-17, all "control citing no commit and not marked unbuilt" |
| "six rows labelled `done`" | "20 findings, exit 1" | The count is correct but the commit I was pointed at (`5a73393`) is the wrong one — it has only **one** `done` row (AI-15), not six, though it does score 20 findings/exit 1 (19 bare `open` + 1 unrecognized `done`). The commit that actually carries six `done` rows (AI-15–AI-20) is **`d188941`**, one step later in the same file's history — verified: 20 findings, exit 1, same as claimed. Note this is a mismatch in the SHA I was given to check, not a claim the build record itself made — `evidence/P4/CP-3-build.md` never cites commit hashes for these three rows, only descriptions and counts, and all three counts/exit-codes check out once matched to the right commit. |

## 3. Trivial satisfiability — adversarial rows

Built six adversarial rows in a scratch file and ran the same script:

- `**control**` with no substance → **caught** ("citing no commit and not marked unbuilt").
- `**advice** — see random-notes/NOT-READ.md` (file not read at session start) → **caught** ("does not say where it landed").
- `**advice** — see some/random/path/NOT-A-REAL-SKILL.md` (fabricated path, contains the literal substring `SKILL.md` but is not an actual skill file) → **slipped through**. The check is `grep -qE 'CLAUDE\.md|WORKFLOW\.md|SKILL\.md|landed'` — a bare substring match, not a check that the named file exists or is one of the skill/CLAUDE.md/WORKFLOW.md files actually loaded at session start.
- `**control** — unbuilt` written for something already built → **slipped through**, exactly as documented (shape, not truth).
- `**control** — \`deadbee\`` (nonexistent commit) and `**control** — .claude/lib/does-not-exist.sh, commit \`abcdef1\`` (nonexistent file) → **slipped through**, exactly as documented.

Judgment: the check is strict enough to kill the two failure modes it names in its own header (bare `open`, and a `control`/`advice` with no citation at all) and is not pure theatre — it demonstrably rejects the laziest version of each row. It is loose on content-truth exactly where it says it is loose (control file/commit existence), which is disclosed. The one gap not explicitly named anywhere (header, plan, or build record) is that the *advice*-location check is equally a bare substring match — a fabricated filename merely containing "SKILL.md" passes. This is a narrower instance of the same disclosed "shape not truth" limitation, not a new undisclosed failure mode, so I read it as covered in spirit though not enumerated by example the way the control-side looseness is.

## 4. Falsification stated honestly, not implied

Plan (`CP-2-plan.md`): "A skill patch with no check behind it" would falsify the phase — T-04 delivers `backlog-lint.sh`, so this branch didn't happen. Plan also: "a check that only validates shape... is a limitation to state rather than imply." Confirmed both the script header (`.claude/lib/backlog-lint.sh:13-17`, "This is a shape check and says so...") and the build record (`CP-3-build.md`, "## What this check does not do, stated rather than implied") state this explicitly and match each other's wording almost verbatim (the AI-14/AI-1 P3 examples appear in both).

## 5. No regression in retro skill

`git diff HEAD~1 -- .claude/skills/retro/SKILL.md .claude/skills/retro/references/retro-template.md .claude/lib/backlog-lint.sh` (HEAD is `223c00b`, the only commit touching these paths since `623ed00`): backlog-lint.sh is new; SKILL.md changes are pure insertions into Phase 4 and one added line + fenced command in Phase 5, nothing removed; retro-template.md renames one column header (`Status` → `Disposition`) and replaces the placeholder example row — the rest of the template is untouched. `git status --porcelain` on those three paths is clean (already committed). No displaced instructions.

## 6. Scope

`CP-2-plan.md` and `CP-3-build.md` both name AC-7 only, throughout. No other AC-n appears in either file.

## EVIDENCE

EVIDENCE AC-7 | CP-3v | PASS | Phase 4 asks the disposition question inline; template's Actions table has no bare-`open`-shaped cell left | `.claude/skills/retro/SKILL.md:55-64`, `.claude/skills/retro/references/retro-template.md:29-34`
EVIDENCE AC-7 | CP-3v | PASS | Live run: `bash .claude/lib/backlog-lint.sh` on current BACKLOG.md → exit 0 | terminal output above
EVIDENCE AC-7 | CP-3v | PASS | `81ad9f5` and `079618c` replays match build record's counts/exit codes exactly | `/tmp/bl-81ad9f5.md`, `/tmp/bl-079618c.md`
EVIDENCE AC-7 | CP-3v | PASS (with note) | "six done rows" claim (20 findings/exit 1) is true, but at `d188941`, not the `5a73393` I was pointed to (which has 1 done row, not 6) — a mismatch in my own instructions, not in the build record, which cites no SHAs | `/tmp/bl-5a73393.md`, `/tmp/bl-d188941.md`
EVIDENCE AC-7 | CP-3v | PASS (with note) | Adversarial rows: bare `**control**` and location-less `**advice**` both caught; fabricated-path advice, `control — unbuilt` on a built item, and nonexistent commit/file all slip through as documented | `/tmp/bl-test-adversarial.md`
EVIDENCE AC-7 | CP-3v | PASS | Header and build record both state the shape-only limitation explicitly | `.claude/lib/backlog-lint.sh:13-17`, `evidence/P4/CP-3-build.md` § "What this check does not do"
EVIDENCE AC-7 | CP-3v | PASS | Retro skill edits are additive only, nothing displaced | `git diff HEAD~1 -- .claude/skills/retro/SKILL.md .claude/skills/retro/references/retro-template.md`
EVIDENCE AC-7 | CP-3v | PASS | P4 evidence claims AC-7 only | `evidence/P4/CP-2-plan.md`, `evidence/P4/CP-3-build.md`

## FAILURES

None blocking. Two non-blocking observations:

- The advice-location check (`grep -qE 'CLAUDE\.md|WORKFLOW\.md|SKILL\.md|landed'`) is a bare substring match, not a real-file check — a fabricated filename containing "SKILL.md" passes. Not separately disclosed from the general "shape not truth" limitation, though it is a narrower instance of it.
- `04-projects/controls-not-advice/STATUS.md` still says "Current phase: P4 ... not started" — stale relative to the CP-2/CP-3 evidence that now exists. Administrative, not an AC-7 substance issue; will presumably be updated at CP-5/acceptance close-out.

## FIX_HINTS

Not applicable (PASS). If tightening is wanted later: extend the advice-location regex to require the cited path actually resolve to a tracked file, or at minimum require it start with `.claude/skills/` / equal `CLAUDE.md` / `WORKFLOW.md` rather than matching the substring anywhere in the row.
