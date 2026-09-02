# P1 round 2 verification — post-fix `8c5e4a4a`

Scope: re-verify the round-1 defect (three live gloop docs still describing
removed commands in present tense) after commit `8c5e4a4a` "Finish the doc
sweep the last commit claimed to have finished."

## Verdict: round-1 defect NOT fully closed

`8c5e4a4a` fixed every line round 1 explicitly cited (6 of the "eight
references" the commit message claims), but a full re-read of the same
three documents — not grep against the old citations — finds two more
present-tense/stale claims the commit missed, one of them in the exact
document (`ARCHITECTURE.md`) the commit's own message says it finished.

## 1. Documents read in full — remaining defects

**`docs/ARCHITECTURE.md:13`** (untouched by the fix commit — diff only
touched line 81):

```
│   cmd/gloop: run, dispatch, select, status, config,         │
│              gate, handoff, setup                           │
```

Still lists `select` as a live `cmd/gloop` subcommand in the layers
diagram. Live `--help` (see §2) lists `config, dispatch, gate, handoff,
init, roster, run, session, status` — no `select`, and the diagram is
additionally stale in the other direction (`roster`, `session`, `init`
absent; `setup` — never a real subcommand name, `cmd/gloop/cmd/setup.go`
exists but is wired as `gloop init`, not `gloop setup`). This is the same
class of defect round 1 caught at line 81 of the same file, in a part of
the file the fix commit never touched.

**`docs/ROSTER.md:127-136`, "Tier pinning behavior"** (untouched by the fix
commit — not one of its diff hunks):

> A role's tier ... is looked up in `[roster.tiers]`; a request-level
> `--provider`/`--model` override takes precedence over the pin. When tier
> pins are configured but a selected role's tier has no pin ... the
> command prints a warning to stderr naming the tier...

Verified against code (`cmd/gloop/cmd/roster.go:373` `warnUnpinnedTiers`,
`roster_test.go:123-141`): the function exists and is unit-tested, but
`grep -rn 'Flags().String.*"provider"\|Flags().String.*"model"'
cmd/gloop/cmd/*.go` returns nothing — **no live gloop command defines a
`--provider` or `--model` flag**, and `warnUnpinnedTiers` has no caller
outside its own test file (`grep -rn "warnUnpinnedTiers" cmd/gloop/cmd/*.go`
→ definition + test only). Neither `gloop roster show --help` nor
`gloop roster validate --help` exposes these flags. The section describes,
in the present tense, a warning that no reachable code path can print
today — the flags "lived on the removed command," per the build record's
own language for the `dispatch` false claim, and this is a second surviving
instance of exactly that class.

**`docs/ROSTER.md`, `docs/ROSTER_PEER_EXCHANGE.md`** — otherwise clean on a
full read. No other present-tense reference to `gloop select`,
`gloop roster plan`, `selector.Select`, `roster.Select`, or `pkg/selector`
as a working thing. `ROSTER_PEER_EXCHANGE.md`'s "Files" table entry
`cmd/gloop/cmd/select.go | Verbose output of executed mode` (line 110) is
a historical implementation-log entry under a doc stamped
"Status: IMPLEMENTED (2026-08-22)" describing what was changed at that
date (predates the removal); not a present-tense claim, treated as
acceptable per the build record's stated policy of leaving dated records
alone. `pkg/roster/select.go` (line 107 of the same table) is real and
current (`ls pkg/roster/select.go` exists); `cmd/gloop/cmd/select.go`
(line 110) does not exist any more (`ls`: no such file) but the doc does
not claim it does — it is a changelog-style entry, not a usage
instruction.

## 2. Replacements checked for truth, not just difference

- `go run ./cmd/gloop --help` → `config, dispatch, gate, handoff, init,
  roster, run, session, status`. No `select`. (Confirms ARCHITECTURE.md:13
  is stale — see §1.)
- `go run ./cmd/gloop roster --help` → `show, validate`. No `plan`.
  States "Route selection and dispatch-plan generation are cadre's, not
  gloop's."
- `go run ./cmd/gloop dispatch --help` → no `--provider`/`--model` (build
  record's self-confessed fix confirmed live).
- **`cadre select` invocation ROSTER.md now suggests**: built cadre at
  `/tmp/pr-cadre` (`go build -o /tmp/pr-cadre ./cmd/cadre`, exit 0).
  `/tmp/pr-cadre select --help` confirms `--task` and `--files` both exist
  as real flags. ROSTER.md's example (`cadre select --task "..." --files
  "pkg/auth/*.go" > plan.json`) is accurate.
- Minor pre-existing residue, not introduced by this fix, not claimed
  fixed by the build record: `gloop --help`'s usage line reads
  `Usage: gloop gloop` (doubled), and its Examples section carries an
  orphaned `# Select agents for a task` header with no example beneath it
  — same defect round 1 already flagged as "not a false claim per se."
  Unchanged; noted for completeness only.

## 3. Nothing else broke

```
cd /home/deagy/sdk/gloop
go build ./...   # exit 0
go vet ./...     # exit 0
go test ./...    # exit 0, all ok or [no test files]
git status --porcelain   # empty, both before and after this read-only pass
```

## 4. Build record honesty — `CP-3-build.md` § "What the removal actually cost"

Read in full. Accurately states round 1's finding: "The claim that the
five live documents were rewritten was false when first written here, and
CP-3v caught it," names all three files, "Eight references survived
across the three, including a worked example of a command that no longer
exists," and attributes the root cause correctly ("The claim came from
having edited the files rather than from re-reading them — the same shape
as the defect the sweep existed to remove"). Not softened. It does not,
however, anticipate that the fix commit itself would repeat the pattern
once more (ARCHITECTURE.md:13) — reasonably, since that entry postdates
the build record.

## 5. Whole-repo re-check, AC-1 and AC-3

```
grep -rniE "mit license|apache-?2\.?0 license|licensed under|badge|go report card|pkg\.go\.dev" \
  /home/deagy/sdk/gloop --include="*.md"
```

Hits: `README.md:7` and `:65` — both narrate the historical removal /
state pkg.go.dev cannot index a private module (same as round 1, no
change). `docs/PHASE3-REVIEW.md:208-209` — "MIT license" describing
third-party deps `spf13/cobra`/`spf13/viper`, not a claim about gloop
itself (same shape as recall's cleared BSD-3-Clause dependency mention).
No licence claim about gloop itself, no badge markup, no `pkg.go.dev` link
anywhere in the repo's markdown. AC-1 and AC-3 (licence/badge portion)
remain clean.

## AC verdicts

- **AC-1 (no repo claims a licence it doesn't carry): PASS.** Unaffected
  by this fix; whole-repo re-sweep confirms no regression.
- **AC-2 (nothing installable resolves an unlicensed dependency): PASS.**
  Not in scope of this fix; not re-litigated (round 1's independent
  verification stands, untouched by `8c5e4a4a`).
- **AC-3 (gloop's self-description is true of gloop): FAIL:fixable.**
  README.md itself remains strictly true (as in round 1). But two more
  present-tense/stale claims survive elsewhere in the doc set the removal
  was supposed to have made consistent: `docs/ARCHITECTURE.md:13`'s
  diagram still lists `select` as a live subcommand, and
  `docs/ROSTER.md:127-136` still documents a `--provider`/`--model`
  override and stderr warning that no live command can trigger
  (`warnUnpinnedTiers` is dead code, uncalled outside its own test).

## Round-1 defect: genuinely closed?

**No, not fully.** The six specific lines round 1 cited are fixed and
verified accurate. But the task's own instruction — read the full
documents, not grep the prior citations — surfaces two further instances
of the identical failure mode in the identical two documents
(`ARCHITECTURE.md`, `ROSTER.md`) the fix commit's message claims to have
"finished." The commit is a genuine, correctly-scoped partial fix; it is
not evidence the underlying "edited without re-reading the whole file"
discipline gap has been closed, since it recurred inside the fix meant to
close it.

## FIX_HINTS

- `docs/ARCHITECTURE.md:13` — remove `select` from the CLI diagram; the
  diagram is already independently stale (missing `roster`, `session`,
  `init`; `setup` isn't a real subcommand name) so a full resync against
  `gloop --help`'s live command list, not a single-word edit, is the
  right fix.
- `docs/ROSTER.md:127-136` — either delete the `--provider`/`--model`
  tier-override paragraph (dead code, no live flag surface) or, if the
  intent is to keep `warnUnpinnedTiers` live, wire it to an actual flag
  and re-verify; as written it documents unreachable behavior.
