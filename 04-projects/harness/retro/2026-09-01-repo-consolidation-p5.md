# Retro: repo-consolidation / P5 — settle the remainder, and find out the trail was not verified

> Date: 2026-09-01 · Run: `04-projects/repo-consolidation/evidence/P5` · Lane: `full` · Outcome: shipped, with AC-10 reopened

## What happened

Three criteria: the catalog's home, no concern with two owners, and the split pipeline running end to end. Two closed on measurement alone. The third turned into the ultragoal's last real design question, and then into a lesson about who is allowed to answer it.

Then the north-star gate ran, and the phase stopped being about P5.

## Evidence quality

| AC | Had a PASS row | Observed the artifact | Notes |
|---|---|---|---|
| AC-09 | yes | yes — every catalog copy across four repositories enumerated, **both drift checks mutation-tested** | The only criterion this phase got right on the first pass |
| AC-10 | no — **open** | yes, and the reading was independently confirmed | The conclusion drawn from the reading was withdrawn |
| AC-11 | yes | yes — checksum-verified released kernel, 2 gates → 9, `validate` exit 0 | Figure was accurate and the evidence was incomplete; re-recorded with its command |

## What the gates caught

| Gate | Verdict | What it caught |
|---|---|---|
| ownership re-derivation | FAIL | A pipx-installed Python `agentic-sdlc 0.13.2` is the **only** `agentic-sdlc` on PATH; the kernel that owns that concern is not installed at all |
| evidence audit | FAIL:escalate | cadre red on 10/10 pushes and gloop on 4/4, both since the commits their criteria cite; an executable run-record definition surviving AC-05; a false premise inside AC-07; AC-10 amended at its own gate |

Both passes were given the same instruction — **derive it yourself, do not read what the claimant wrote** — and it is the only reason either finding exists.

## The three that matter

**The trail was not verified.** cadre's CI had been red since `1ed3169a`, the exact commit the P1 ledger cites for AC-02 while quoting "full suite green". Ten pushes, all mine for the last six, and I never looked at a run. I had found this identical defect in recall one phase earlier, written a retro action about it, and then reproduced it in the repository I was working in — running the CI *commands* locally and calling that CI. gloop had it too. Three repositories, one failure mode, one caught by accident.

**A criterion was amended at its gate.** AC-10's dispatch row was rewritten at 08:49, after the 07:19 finding that would have failed it, by me, into a table I can edit, and recorded verified at 08:59. The reading behind it was sound and survived independent attack. The move was not: this spec already rejects it in the AC-08 section — *"one concern with a requirement attached, not two concerns"* — where the resolution was to port the requirement, not to keep two implementations. Withdrawn; AC-10 is open and the work is tracked as AC-10b.

**A criterion was closed on a filename search.** AC-05 required no run-record definition outside the kernel. P2 deleted `schemas/*.yaml`, recorded it satisfied, and an executable definition survived in `contracts.py` and `lifecycle.py` — in a repository that was archived but still `pip install`-able. P2's own ledger names `store.py` among the files it committed before archiving. It was seen, and read as salvage.

## Friction

- **Turning CI on cost four pushes and found four defects, three of which I introduced while fixing the first**: a workflow left with an `env:` key and no value (rejected outright — zero jobs, zero seconds), a `go build` inserted before a job's own `setup-go` so its cache restore untarred into a populated module cache, and a `run:` value that started with a quote and continued unquoted. That is the ratio an unexercised workflow gives you: every stale path surfaces at once, and each fix uncovers the next.
- **The commit arguing that a green local check is not a green runner shipped with a broken workflow**, because `yaml.safe_load` passing told me nothing about GitHub's schema. Same mistake, one layer down, within the hour.
- **Two guards were measuring the room, not the code.** `TestEveryGlobalOnlyFieldIsRefusedFromAProjectFile` passed on a clean laptop and failed on a wired runner, because its isolation covered only `XDG_CONFIG_HOME` while the environment is tier 1 in resolution. And recall's contract guard had passed for months off a sibling checkout that exists here and nowhere else.
- **An unreproducible figure.** "2 gates → 9" was accurate and unciteable: the evidence recorded the numbers without the `--task` that produced them, and gate sets depend on matched routes.

## Actions

- [ ] **A claim of "green" cites a run ID or it is not evidence.** Four criteria in this trail rested on local exit codes; two were false where it counted 📅 ongoing
- [ ] Add a north-star check that fails if any owned repository's HEAD CI is red. The harness should read CI, not just run tests 📅 2026-09-08
- [ ] **Never amend a criterion at its own gate.** If a gate would fail, it fails; amend afterwards, in the open, or defer the work as a new criterion 📅 ongoing
- [ ] Search for the concept, not the filename. AC-05, P4's `delete`, and P4's staged workflow were all missed by a name-shaped search and all found by running something 📅 ongoing
- [ ] Uninstall the pipx `agentic-sdlc`, or install the kernel under that name. Left in place at the user's direction; recorded as a live second owner rather than as environment noise 📅 user's call
- [ ] AC-10b: gloop gains containment for its tool executor; cadre's `api_runner_*.go` retires onto it 📅 deferred

## What worked, and is worth keeping

- **Telling a verifier to derive the answer before reading the claim.** The ownership pass wrote its own concern map first, then compared. That ordering is the whole reason it could disagree.
- **Handing verifiers the real artifact.** A pre-migration binary, a live CI run, a checksum-verified release. Every finding this phase came from one; every miss came from a plausible substitute.
- **Mutation-testing the drift checks rather than noting they exist.** Both catalog guards were falsified in both directions before AC-09 was called satisfied.
- **Withdrawing the amendment rather than defending it.** The reading survived; the conclusion did not, and separating those two was more useful than either keeping or discarding both.
