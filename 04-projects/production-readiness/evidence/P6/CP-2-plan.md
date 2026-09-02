# P6 — CP-2 plan · AC-3b

Every other claim in gloop's documentation holds against the binary.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | Classify every tracked markdown as live or record, on evidence | AC-3b |
| T-02 | Audit the live set claim by claim against a built binary | AC-3b |
| T-03 | Fix what is false; where a claim is aspiration, say so in the document | AC-3b |

Three tasks, so CP-4 is owed.

## The scoping problem, and the evidence that settles it

`README.md` is 555 lines and `docs/` is 8,060 across 23 files. Auditing all of it
against the binary is not the criterion — AC-3b says gloop's *documentation* holds,
and a dated review of a phase that shipped in August is a record of what was decided,
not a claim about what runs now. P1 applied exactly this exemption to cadre's
`DESIGN-NOTES-deletion-and-retention.md`, which opens by saying nothing in it is
implemented.

**`docs/README.md` classifies them itself**, and that is evidence rather than my
judgement:

- *Core* — the spec, the requirements map, the architecture guide. It says "start
  with" these.
- *Rosters* — `ROSTER.md`, `ROSTER_PEER_EXCHANGE.md`.
- *Plans and summaries* — the enhancement plan, two implementation plans, two phase
  summaries.
- *Phase reviews* — "Historical review documents with workable chunk breakdowns,
  **kept for traceability**".
- *Tooling* — `MOCKERY_INTEGRATION.md`.

### Live, and therefore in scope

| File | Lines | Why live |
|---|---|---|
| `README.md` | 555 | the front door |
| `docs/README.md` | 44 | the index, and it makes claims about what each file is |
| `docs/ARCHITECTURE.md` | 95 | "how the system fits together", present tense |
| `docs/ROSTER.md` | 263 | documents a shipped feature's format and commands |
| `docs/ROSTER_PEER_EXCHANGE.md` | 179 | same |
| `docs/MOCKERY_INTEGRATION.md` | 147 | tells a developer how to run a tool |
| `CHANGELOG.md` `[Unreleased]` | — | describes current behaviour, not history |

### Records, and therefore exempt — but only if they say so

The five phase reviews and six Phase-3 enhancement designs are dated and the index
calls them historical. **The exemption depends on the document itself saying it**, not
on the index saying it for them. P1's exemption worked because
`DESIGN-NOTES-deletion-and-retention.md` opens with "Nothing described here is
currently implemented." A reader who arrives at `PHASE3-E4-RATE-LIMITING.md` from a
search engine sees no such line. **T-01 checks each for a self-declaration and treats
its absence as a finding, not as a pass.**

### Two the index does not mention at all

`docs/CODE-REVIEW.md`, `docs/HYGIENE-FIX-PLAN.md` and
`docs/PLANNING/01-requirements.md` are referenced by nothing. Unlinked, undated and
unsuperseded is the exact shape of `RELEASE_NOTES_PHASE4.md`, which P1 of the
preceding ultragoal found declaring a retention capability COMPLETE two hours before
the commit that deleted it.

## What is already known, from the binary rather than the docs

Run at gloop `3715bef`:

- **`Usage: gloop gloop`** — the program name is doubled in its own usage line, and
  again in `Use "gloop gloop [command] --help"`.
- **An example with no command.** The Examples block opens with
  `# Select agents for a task` followed by a blank line. `gloop select` was removed in
  P1; the comment survived and its command did not. AC-3 covered live *documents*
  describing the removed commands. This is the binary's own help text, which no
  document sweep would have read.

## What P1 already found and deferred here

Round 3 of P1's CP-3v found two falsehoods that predate this goal: the docs claim a
cobra CLI where none exists, and the `--config` contract is documented wrongly in a
way that **resisted three attempts to state correctly**. That last one is the reason
AC-3b exists as its own criterion rather than a footnote — I got it wrong three times,
including once by telling the user a verifier's finding was a false positive when it
was not, because my test grepped for a leading `Usage:` and read
`Error: unknown gate subcommand` as acceptance.

So `--config` is not audited by reading. **Every claim about it gets run.**

## Method

Build the binary first, then read each live document with it open. For every claim
that names a command, a flag, a file, a config key or an env var: run it. Where a
claim cannot be run — an architectural statement, a design rationale — trace it to the
code that implements it and cite the file.

A claim that turns out to be aspiration is not automatically a defect. It is a defect
*when the document presents it as current*. The fix is then either to make it true or
to say plainly that it is not, in the document — the same disposition P1 reached for
gloop's licence and badges, where the answer was to delete rather than to make true,
because the evidence said nobody was on the other end of the promise.

## Not in this phase

The eleven phase reviews and enhancement designs, beyond checking each says what it
is. Rewriting a dated record to match today's code destroys the record.
