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

## After the escalation — the guard now generates the table instead of reading it

Round 3 returned FAIL:escalate. Three failures of AC-3b, and the pattern was one
shape each time: **silent omission**, with the absence looking exactly like coverage.
The doc was wrong; then the guard checked the name and not the row; then the guard's
parser skipped `` `dispatch <plan>` `` and `` `run <plan>` `` because they did not
match its regexp — the two rows the README's own prose singles out.

Put to the user under AI-18 rather than spent as a fourth attempt. They chose to
invert the direction, and that is what shipped:

`internal/docguard` **enumerates every subcommand from `gloop --help`, classifies
each by running it, renders the table, and asserts `README.md` contains that block.**
There is no parser to skip a row, no regexp to miss a placeholder, and no way for a
subcommand to be absent from both the doc and the check — the doc is derived, not
compared. A mismatch prints the block to paste in. The README says so, above the
table.

### It found three of my own errors before it passed once

1. **`config setup` and `config update` write to the config they are handed.** With
   one shared fixture pair they overwrote both files with identical content, after
   which every later subcommand saw two identical configs and read as *ignored*. The
   generated table came out with an **empty Honoured row** and I nearly believed it.
   Each subcommand now gets a fresh pair.
2. **Normalising the config path out of the output** erased the only signal the two
   writers give — `Wrote config to <path>` — and put them in the wrong bucket. A
   command that echoes the path it was handed *did* read the flag; that is what
   honoured means.
3. **`dispatch` and `run` cannot be classified this way at all**: both need a plan
   file and a reachable provider, and without those they fail identically whichever
   config they are handed. They are excluded — and the exclusion is *stated*, in a
   set the test reads, with an assertion that the README documents both separately.
   A stated omission is the opposite of the defect this phase exists to catch.

`TestTheHelpEnumerationIsComplete` guards what is left: a subcommand that stops being
listed in help would leave the table and the check together. It counts the
**arguments** to `AddCommand`, not the calls — `AddCommand` is variadic, and counting
calls gave 16 against 20 real subcommands, which is the same class of error as
everything else here: a number that looks like a check and measures the wrong thing.

Falsified three ways: a flipped row fails with the block to paste; deleting the
`dispatch`/`run` paragraph fails with *covered by nothing*; and hiding one command
from the help listing while leaving it registered fails with the count. **That last
mutation had to be placed twice** — the first attempt patched `help.go` and the test
stayed green, because `gloop handoff --help` is rendered by `root.go`. Two renderers,
which is the same duplication that produced `Usage: gloop gloop`.

## CP-3v round 4 — the generated table holds, and two things above it did not

Round 4 re-mutated all three earlier findings and each now fails correctly. It found
two more, both by building and running rather than by reading.

### A subcommand can be dispatchable without being registered

`execute()` special-cases `args[0] == "help"` before it consults `rootCmd.cmds`. The
verifier added a second such branch and produced a subcommand that **runs, silently
ignores `--config`, appears in no help output, and trips neither guard.** Confirmed
here by reproducing it: with the bypass in place, `TestTheConfigFlagTableMatchesTheBinary`
and `TestTheHelpEnumerationIsComplete` both still pass.

The generated table is complete for everything registered through `AddCommand`.
**"Registered through `AddCommand`" and "dispatchable" are not the same set**, and
nothing said so.

`TestDispatchHasNoUnlistedSpecialCase` now asserts that the only literal `execute()`
compares `args[0]` against is `help`, so a second branch means editing an allowlist.
Falsified with the verifier's own bypass, and again by renaming `execute` — which
fails with *is gone or renamed; this guard is checking nothing* rather than passing
over a function it can no longer find.

Its limit is stated in the test rather than left to be found: it reads source text,
and source text can be written a way a pattern does not see. It narrows the gap to *a
dispatch branch written unlike every existing one*, which is smaller than what it
replaces and is not zero.

### A third list of the providers, outside both checks

`README.md`'s `config.toml` example carries `# anthropic | google | mistral | http`
on its `name` line — four of the six `IsKnownProviderType` accepts, omitting `openai`
and `cohere`. Three lines above it sits the Multi-Provider bullet that
`TestTheProviderListNamesEveryProvider` already guarded, naming all six.

The guard looked at the bullet. A second enumeration of the same fact sat outside it,
in a fenced code block. **Two lists of one fact drift; three drift faster.** The
check now reads `IsKnownProviderType`'s own case clause and holds both lists to it.

## CP-3v round 5 — two false claims in live documents, and the class they belong to

Round 5 was told to separate a false claim in the documentation from a guard that
could be evaded by a change nobody has made, and to report the second as a note. It
did, and both of its failures are the first kind.

### The providers, a fourth time

`docs/ARCHITECTURE.md` listed five provider runtimes in two places, omitting cohere.
That is the **fourth** enumeration of the same fact to drift: the Multi-Provider
bullet, the `config.toml` comment, and now the architecture diagram and its package
table. Each was corrected the round after the previous one, because each guard
covered the list in front of it.

### A code sample that never compiled

`README.md`'s Metrics & Monitoring block called `logging.NewMetricsCollector()` with
no argument and three methods — `RecordCounter`, `RecordHistogram`, `RecordGauge` —
**that exist nowhere in the tree**. The real API is
`NewMetricsCollector(config *MetricsCollectorConfig)` and
`IncrementCounter`/`ObserveHistogram`/`SetGauge`, each taking a labels map.

The verifier found it by compiling the snippet and reading four errors. Nothing in
this repository had ever compiled it.

### The guard that closes the class, and what it found immediately

`TestEveryGoSampleInTheLiveDocsIsAccountedFor` takes every fenced Go block in the live
documents and puts each in one of four sets — **compiled** against this module,
**quoted** from a named source file and compared to it, a **whole file** compiled as
written, or **illustrative**. A block in none of them fails the test naming its first
line. Compiling every block is not possible: an interface excerpt naming `Provider`
and `Message` unqualified only compiles inside the package that defines them, so
those are checked line by line against their source instead.

Falsified three ways: restoring `RecordCounter` fails with the compiler's own message,
an unaccounted-for block fails naming it, and altering a quoted declaration fails
naming the line and the file it is not in.

**It found two more defects on its first green-ish run**, neither of which any reading
would have caught:

- `docs/MOCKERY_INTEGRATION.md`'s example called `mocks.NewMockAgentProvider` and
  `runtime.AgentResponse`, neither of which exists — and once corrected, it still did
  not compile, because **the checked-in mocks were stale**: `MockProvider.Complete`
  took two arguments where `types.Provider.Complete` takes three, so the mock did not
  implement the interface it mocks. Regenerated.
- `.mockery.yaml` named `AgentProvider` and `TokenCounter` under `pkg/runtime`.
  Neither is there; `TokenCounter` lives in `pkg/types` and `AgentProvider` does not
  exist at all. **mockery warned `no such interface` on every run and exited zero**,
  so the config named two interfaces it could not find and nothing said so louder than
  a log line. Both fixed, and mockery now resolves every interface it is given.

A documented example that has never been compiled is a claim nobody has checked, and
this one was wrong in three separate ways at once.

## CP-3v round 6 — four more, all in categories no guard read

Round 6 swept the live documents exhaustively and found four false claims, every
one of them outside what the existing guards look at:

| Claim | Reality |
|---|---|
| `go test ./pkg/streaming/...` | `pkg/streaming` was deleted; the command fails outright |
| Roadmap: *Support for additional providers (Cohere, etc.)* unchecked | Cohere ships, and the Features list three lines above says so — a document contradicting itself |
| `go doc ./...`, twice | not valid `go doc` syntax; it takes one package or symbol |
| `MOCKERY_INTEGRATION.md`'s yaml block and mocks list | still naming `AgentProvider`, `StreamProvider`, `StreamCallback` — none exist — and `TokenCounter` under the wrong package |

The last is the sharpest: **that file was fixed in round 5 and left wrong in two
sibling places in the same file**, because the compile guard reads ` ```go ` fences
and those two are yaml and a bullet list.

Two new guards, one per class:

- `TestTheMockeryDocMatchesTheMockeryConfig` holds the document's mocks list to
  `test/mocks/` in both directions, and every interface and package its yaml block
  names to `.mockery.yaml`.
- `TestEveryGoToolingCommandInTheLiveDocsRuns` **runs** every `go doc`, `go vet`,
  `go build` and `go list` the live documents give, and resolves the packages every
  `go test` names. A command in a document is an instruction, and an instruction that
  errors is a false claim about the repository.

### The command guard did not cover its own defect, and the falsification said so

Its first version scanned lines *beginning* with `go `. Both `go doc ./...` mentions
sit inside backticks in a prose bullet, so it read neither — **it passed when I put
the defect back.** It now reads inline spans too.

Then it caught two things I had just written: a placeholder `go doc ./pkg/<package>`,
which is a template rather than an instruction and is skipped by shape; and my own
sentence *"`go doc` takes one package or symbol"*, which is prose naming the tool and
not a command to run. Inline spans with no argument are mentions; a fenced line always
is not.

Three rounds in a row now, the falsification has found the guard weaker than it
looked. Writing the check is not the work; running it against its own defect is.

## CP-3v round 7 — the categories nobody had checked

Round 7 was told to stop checking guards and start enumerating **kinds of claim**,
then check each kind. It found four, in four categories no round had touched:

| Claim | Reality |
|---|---|
| README's own architecture diagram | its "Agent Providers" box names three of six, dropping OpenAI and Cohere |
| *A dispatch plan looks like:* | the ```json block carries three shell-style `#` comments, so copying it produces a parse error |
| `docs/ROSTER.md` § Matching semantics, and `metadata.matched_routes` | describes route matching gloop no longer does, and a metadata key that exists nowhere in the tree — contradicting the file's own removal banner three paragraphs above |
| `go test -tags integration ./pkg/roster/`, given in two documents | does not compile: two test files still called `Roster.Select`, removed weeks ago |

The last is the sharpest of the whole phase. **A build failure behind a tag nobody
builds is indistinguishable from a passing test** — the same shape as a tag with no
release behind it, and as a documented example nobody compiled. Both files were fixed:
the contract test now checks the property that survives (every route's roles resolve),
and the peer-exchange end-to-end builds its plan directly instead of selecting one, so
it **left the tag entirely and runs in the ordinary suite**. Peer exchange is gloop's;
selection is not.

`TestEveryBuildTagStillCompiles` vets every tag any test file declares, discovering
them from the tree. Falsified by putting the removed call back — and the same run
shows untagged `go vet ./...` staying silent on it, which is the gap it closes.

### The provider list, for the fifth and sixth time

README's diagram was the fifth place this fact had drifted. So the guard stopped
naming places: **any blank-line-delimited block in a live document naming three or
more providers must name all of them**, with the set read from
`IsKnownProviderType`.

It found a sixth on its first run — `docs/ROSTER.md`'s tier-pin validation rule —
and adding a seventh provider to the type list now fails all seven enumerations at
once.

Getting the span right took two attempts. A line-at-a-time scan read each row of the
ASCII box as a pair; a fixed-width window read a fragment of the box as an incomplete
list and reported the box against itself. A block is what a reader sees as one list.

## CP-3v round 8 — one finding, and it was mine

Round 8 swept the categories round 7 had not reached — `make` targets, environment
variables, HTTP endpoints, config keys, cross-document links, counts, defaults,
refusals, paths — and found **one** false claim.

It was in `docs/ROSTER.md`, four lines below the removal banner:

> Gloop can select roles from an external agent roster … instead of (or in place
> of) its bundled preset catalog.

**Round 7 quoted that paragraph.** I read its finding, fixed the *Matching
semantics* section and the `matched_routes` sentence it named, and left the
paragraph the finding had been about. The file went on contradicting its own banner,
its own rewritten section, and `gloop roster --help`.

That is AI-16 exactly: *enumerate by concept before editing*. I have now made that
error twice in the same file, in consecutive rounds, having written the rule myself.

So the guard checks the claim rather than the section: **any live document asserting
that gloop selects, matches or routes fails**, unless the sentence sits in a removal
note — where saying it *used to* is the point. Falsified with round 8's exact
sentence.

`TestNoLiveDocumentTableRepeatsARow` came from round 8's one note: README's package
table had two `pkg/govplan/` rows with different wording. Not false, but two answers
to one question, which is this phase's subject with the clock not yet started.

## CP-3v round 9 — PASS

An end-to-end sweep of all six live documents found **no new false claim**. Round 8's
fixes hold under mutation; the full suite, both `go vet` configurations and a
`CGO_ENABLED=0` build are green.

Two residue notes, neither a documentation falsehood. One was worth acting on anyway:

**The binary's own `--help` said gloop selects agents.** `Gloop is a comprehensive
CLI tool … It provides capabilities for **selecting agents**, dispatching plans …` —
the first sentence the program says about itself, wrong through all nine rounds,
because no document quotes it and every guard read documents.

Corrected, and `TestNoLiveDocumentClaimsGloopSelects` now reads the binary's help
alongside the documents. Two things had to widen for it to catch the real sentence,
and **falsifying against a paraphrase would have hidden both**: the claim sits over a
hundred characters from its subject and uses a gerund, so the old ±40-character window
and short verb list missed it. It is now falsified against the original string
verbatim.

Round 9's other note also landed: the disclaimer that excuses a match must sit *near*
it. A long line could carry both a claim and an unrelated "removed" and be excused —
and the sentence this guard was written for names the `cadre-roster` repository two
clauses after claiming gloop selects.

## AC-3b, decided

Nine rounds. Rounds 1–7 each found several false claims; round 8 found one, and that
one was a sentence round 7 had quoted without flagging; round 9 found none.

**Twenty-one false claims in gloop's documentation, every one now fixed and each
confirmed by running, compiling, or opening what it named.** Fourteen guards, every
one falsified by reintroducing the defect it catches.

Six of those claims were the same fact — which providers exist — restated in six
places and corrected in five separate rounds, because each guard covered the list in
front of it. That stopped when the guard began *finding* enumerations instead of
naming them, and it found the sixth immediately.
