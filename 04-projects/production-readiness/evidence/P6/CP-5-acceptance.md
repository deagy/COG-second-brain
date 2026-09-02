# P6 — CP-5 acceptance · AC-3b

**EVIDENCE AC-3b | CP-5 | PASS** — every other claim in gloop's documentation holds
against the binary. Twenty-two false claims found and fixed, each confirmed by
running, compiling, or opening what it named. Artifacts: `CP-3v-round1.md` …
`CP-3v-round9.md`, `CP-4-integration.md`, `CP-4-round2.md`, gloop `1f37de4`.

**EVIDENCE — | CP-3v | PASS** — round 9, no new false claim across all six live
documents. **EVIDENCE — | CP-4 | PASS** — round 2, all three round-1 fixes verified by
mutation.

## What the criterion cost, and why that is the finding

Nine component rounds and two integration rounds. Rounds 1–7 each found several
falsehoods; round 8 found one; round 9 found none. **The criterion was written because
P1 hit two falsehoods it could not fix in its own phase. It turned out there were
twenty-two.**

The escalation is the centre of it. Three rounds failed on the same shape — a silent
omission, with the absence looking exactly like coverage — and each fix opened a new
surface for it. Under `AI-18` that went to the user rather than a fourth attempt, and
the method they chose changed the direction: **the guard now generates the `--config`
table from the binary and asserts the README contains it**, instead of parsing the
README and comparing. There is no parser left to skip a row.

## The one fact that drifted six times

Which providers exist, restated in six places and corrected across five rounds,
because each guard covered the list in front of it:

| Where | Found in |
|---|---|
| README's Multi-Provider bullet | round 5 |
| `config.toml`'s provider comment | round 5 |
| `docs/ARCHITECTURE.md`'s diagram | round 6 |
| `docs/ARCHITECTURE.md`'s package table | round 6 |
| README's own architecture diagram | round 7 |
| `docs/ROSTER.md`'s tier-pin rule | round 7, by the new guard, immediately |

It stopped when the guard began **finding** enumerations rather than naming them: any
block in a live document naming three or more providers must name all six, with the
set read from `IsKnownProviderType`. Adding a seventh provider now fails all seven
enumerations at once.

## What only running things could find

- **A build behind a tag nobody builds.** `go test -tags integration ./pkg/roster/`
  was given as an instruction in two documents and had not compiled for weeks — two
  test files still called a method removed with gloop's routing. Indistinguishable
  from a passing test.
- **An example nobody had compiled.** README's metrics sample named three methods
  that exist nowhere. Behind it, the checked-in mocks did not implement the interface
  they mock, and `.mockery.yaml` named two interfaces mockery warned about on every
  run while exiting zero.
- **A 16MB binary committed by the README's own build instruction.** `go build -o
  gloop ./cmd/gloop` writes into the `gloop/` package directory. I ran the documented
  command and it produced the defect.

## The one CP-4 found that nine component rounds could not

`TestDispatchHasNoUnlistedSpecialCase` — written in round 4 against a bypass a verifier
had demonstrated, falsified against that exact bypass — **was silently deleted two
commits later** by a scripted rewrite that sliced between two markers. Rounds 5 through
9 all passed, because each asked whether the guards that exist pass, and a guard that
no longer exists passes by not being there.

That is the phase's own subject turned back on the phase, and it is precisely what
CP-4 is for: no component round could see it, because each was looking at what was
there.

`TestTheGuardSetOnlyGrows` now names all twenty guards by hand. Deleting one has to be
a visible line in a diff — which the scripted rewrite was not.

## Twice, I fixed the citation instead of the concept

Round 7 quoted a paragraph of `docs/ROSTER.md`. I fixed the section its finding named
and left the paragraph the finding was about; round 8 found it still there. That is
`AI-16` — *enumerate by concept before editing* — and I wrote that rule.

The guards that came out of it check the **claim** rather than the section: any live
document, or the binary's own help, asserting that gloop selects or routes fails.
Which is how the last one was found: `gloop --help` opened with *"It provides
capabilities for selecting agents"* through all nine rounds, because no document
quotes it and every guard read documents.
