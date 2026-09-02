# P6 — CP-3 build record · AC-3b

## T-01 · which documents are live, and the rule that decided it

23 documents under `docs/`, 8,060 lines, plus a 555-line `README.md`. Four are
live; the rest are records. **The exemption depends on the document saying so**,
not on the index saying it for them — P1's exemption of cadre's
`DESIGN-NOTES-deletion-and-retention.md` worked because that file opens with
"Nothing described here is currently implemented."

Not one of the 22 records said anything of the kind. Each carried a date, which is
not the same claim: a reader arriving at `docs/PHASE1-REVIEW.md` from a search sees a
dependency table asserting `github.com/spf13/cobra v1.8.x`. **There is no cobra in
`go.mod` and there never was.** That is unremarkable in a plan and false in a
description, and only a banner tells you which one you are holding.

All 22 now carry one, dated from their own last commit. `docs/README.md` names the
four live documents explicitly instead of saying "start with the spec", and two
guards hold the pair together: every non-live document carries the banner, and the
index's live list matches the test's. Falsified by stripping one banner and by
deleting one entry from the index.

## T-02 · what the binary said that the documents did not

### The `--config` contract, stated correctly on the fourth attempt

P1 deferred this here because the contract "resisted three attempts to state
correctly", one of which included **telling the user a verifier's finding was a false
positive when it was not** — my check grepped for a leading `Usage:` and read an
error as acceptance.

The README's own honest-deferral paragraph, written in P1, was itself wrong twice:

| It said | Measured |
|---|---|
| "`config` … reject[s] them outright" | `gloop config show --config <path>` reports that path, and the provider and model in it |
| "`dispatch` and `run` consume `--config` as their positional plan-file argument" | only when it *precedes* the plan file; after it, it is an ordinary flag |
| — | it omitted a third bucket entirely |

**The third bucket is the one that matters.** `status` and `handoff` accept
`--config` and silently drop it: `gloop status --config <valid path>` reports
`"configPath": null` and `"message": "no gloop config found"`. Not refused, not
honoured — ignored, with nothing said. A caller pointing at a config gets the default
one and no complaint.

The README now carries the three buckets as a table, each row with the command that
demonstrates it, and `TestTheConfigFlagTableMatchesTheBinary` runs every one. It also
asserts the README still quotes `failed to read plan file: open --config` verbatim,
so the claim stays tied to the message. Falsified in both directions.

### Three defects in the binary's own help text

No document sweep would have found these — they are strings in Go source:

- **`Usage: gloop gloop`**, and `Use "gloop gloop [command] --help"`. Every usage line
  was `"gloop " + c.Use`, which is right for a subcommand and wrong for the root,
  whose `Use` *is* `gloop`. **The first line the program prints about itself named a
  command that does not exist**, from four separate printers.
- **An example with no command.** The root's Examples opened with
  `# Select agents for a task` and a blank line. `gloop select` was removed in P1; the
  comment outlived it. An example with no command reads as a feature whose invocation
  you failed to find.
- **An error offering a removed command.** `gloop roster validate` with no roster said
  to try `gloop roster plan <roster> --task <task>` — also removed. A reader already
  stuck was sent somewhere that does not exist.

Four guards, each falsified by reintroducing its defect.

### `config show` contradicted itself inside one payload

`"configExists": false` beside `"message": "gloop config found but could not be
loaded"`, for a file plainly on disk. A caller reading the boolean was told the
opposite of the sentence next to it — and the same message appeared for a path with
no file at it at all. Three states now give three answers, and the load error is
included rather than swallowed.

**The guard's own first fixture was invalid** and I nearly shipped it: `provider =
"anthropic"` is a string where the loader wants a table, so the "valid" case was a
second malformed one and the test would have asserted nothing about the honoured
path. It now fails loudly if its own fixture does not load. That is the same shape as
P5's `TestDispatchSDLC_UsesInTreeFallback`, which passed for months against a path the
repository had stopped having.

### One omission

`README.md`'s Multi-Provider bullet named five providers; `pkg/runtime/registry.go`
builds six. Cohere shipped and the sentence describing what gloop supports did not
change. Nothing about the README looked wrong, which is why nothing prompted a
reread — so the guard reads the registry's imports instead.

## What held

`docs/ARCHITECTURE.md`'s paths, `docs/ROSTER.md` (its removed-command mentions are all
in a "Removed" note P1 wrote), every symbol in `docs/ROSTER_PEER_EXCHANGE.md`, the
plugin interface, all three web-UI endpoints and four session methods, all eight
documented metrics, and the entire `config.toml` example — written to a file and
loaded by the binary, with a malformed value confirmed rejected so that a clean load
means the keys are actually read.

## CP-3v round 1 — FAIL:fixable, 19 claims, and it was the fifth wrong statement

The verifier ran every bucket rather than reading the table, and found that
**`handoff` is not one bucket**: `handoff list` ignores `--config`; `handoff get`
and `handoff prune` refuse it. The table said `handoff`.

**Every one of the five wrong statements of this contract generalised the same
way** — from a subcommand that was checked to the command it sits under. The
buckets are a property of the subcommand. That sentence is now the first line of
the section, because the shape of the error is more useful than the corrections.

My own guard could not have caught it: it tested one subcommand per command, so
`handoff list` stood in for `handoff`. It now classifies thirteen subcommands
individually, and the matcher accepts `unexpected argument` alongside `usage:` and
`unknown flag` — `handoff prune` refuses with that wording, and a matcher missing it
would have read the refusal as acceptance. **That is precisely how an earlier check
on this same contract came to call a real finding a false positive.**

### The coverage check I added was itself too weak, and the falsification caught it

I added an assertion that the README names every subcommand the test classifies, and
falsified it by deleting `handoff prune` from the table. **It passed.** The name
appears elsewhere in the README — `gloop handoff prune --max-age 720h` sits in the
examples block — and the check searched the whole file.

Scoped to the table's own text it now fails on that deletion, and fails again if the
table heading is renamed rather than passing over a table it can no longer find.

A guard that matches anywhere matches the wrong thing. It took a falsification to
see it, which is the argument for falsifying every guard rather than the ones that
look risky.

## CP-3v round 2 — the same defect, one level down again

Round 2 found that my coverage check verified a subcommand's **name** appeared in
the table and never which **row** it sat under. Moving `handoff prune` from Rejected
to Ignored — a claim the binary contradicts — left the test green.

That is this phase's own subject, two levels deep: a document making a false claim, a
guard that reads the document without checking the claim, and a falsification of that
guard that only exercised deletion rather than misplacement.

The guard now **parses each row's bucket label and compares it to a classification it
derives by running the command.** Rejection is a message; honoured versus ignored is
whether two configs differing in one value produce two different outputs — a test
that needs no knowledge of what any particular command does with the file. It also
fails on a subcommand named in the table that it cannot invoke, so a row can never be
unchecked.

Round 2's other two findings, both correct and both fixed: `gate approve`,
`gate reject`, `gate skip` and `session delete` were absent from the table entirely,
and the build record's "thirteen subcommands" overstated a guard that behaviourally
exercised twelve. The table now names eighteen and the count is produced by the loop
rather than asserted in prose.

### The stronger guard immediately accused the README, and the README was right

Its first run reported `config update` as ignored while the table said honoured. It
was the **invocation** that was wrong: `config update` fails argument validation
before it ever looks at `--config`, so the probe compared two identical error
messages. Given all three required fields and a set key variable, it writes to
exactly the path it is handed.

**A weak probe is indistinguishable from a false claim**, and the difference is
whether you check before believing the tool you just built. This is the fourth time
in this goal that a fixture, not the subject, was the thing that was wrong.

Falsified three ways: round 2's exact bucket flip, a flip in the other direction, and
a row naming a subcommand the test cannot run.
