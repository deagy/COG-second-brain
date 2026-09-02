# P5 — CP-2 plan · AC-6, AC-7

Release all four, then prove a clean machine reaches a working state.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | Kernel: put the licence in the archive, then release from HEAD | AC-6, AC-2 (re-check) |
| T-02 | recall: find why two tags published nothing, fix it, release | AC-6 |
| T-03 | cadre: release the CLI and the plugin from HEAD | AC-6 |
| T-04 | gloop: settle its release story on evidence — cut one, or state the reason in the repo | AC-6 |
| T-05 | Install into a container that has none of the four, run the two commands | AC-7 |
| T-06 | Publish `linux/arm64` again — added mid-phase, see below | AC-7 |
| T-07 | Make `cadre sdlc` find the kernel a plugin install produces | AC-7 |

Five tasks planned, seven run, so CP-4 is owed.

**T-06 and T-07 were not planned.** Each came from running T-05 and reading what
it said, and each moved the failure one step further along the install rather than
resolving it — which is what a criterion tested end to end does, and what six
months of green component checks had not.

T-05's first clean install produced a `cadre` that
could not obtain a binary for aarch64 Linux, which is the architecture this
project is written on. The exclusion was deliberate and documented, and its
recorded reason — "either a native arm64 runner or a cross toolchain" — had
expired. Added rather than deferred because AC-7 is not satisfiable on this
machine without it, and because the criterion's whole point is the machine that
has nothing.

## What measuring first already found

Measured at `cadre 0e249942`, `cadre-kernel 8da1b13`, `recall 3ee2795`, `gloop 04c356a`:

| | latest tag | commits ahead | published release |
|---|---|---|---|
| cadre | `cli-v0.6.5` (Aug 19) | 55 | yes |
| cadre-kernel | `v0.14.2` | 2 | yes |
| recall | `v0.3.1` | 1 | **no — v0.3.0 and v0.3.1 both published nothing** |
| gloop | `v0.2.0` (Aug 20) | 44 | **no release, ever; no release workflow** |

Two defects nobody had looked for, and both are the same shape as the ones this
project keeps finding: **a success that produced nothing.**

### recall's tags fire no release

`tag.yml` computes the next version and pushes an annotated tag. `release.yml`
triggers on `push: tags: v*`. Run 33516573140 ("Tag release") reports success
and the tag exists — and no Release run followed it, for either v0.3.0 or
v0.3.1. v0.2.0 has one, because that tag was pushed by hand.

A tag pushed using the workflow's own `GITHUB_TOKEN` does not trigger further
workflows. So the automated path silently stops one step short of the thing it
exists to do, and the operator sees a green check either way.

`v0.3.0`'s own CI run failed as well (33466261336). The tag was cut regardless,
because `tag.yml` gates on nothing.

### The kernel's archive would still carry no licence

P1 carried forward that `v0.14.2` predates the licence commit, and I wrote in
STATUS that P5 need only re-cut. **That was wrong, and reading the workflow is
what corrected it.** `release.yml` builds each platform and runs
`tar czf ... "$binary"` — the archive contains one file. A re-cut from HEAD
publishes an archive with no licence text in it either. The fix is the packaging
step, not the tag.

## Order, and why

The kernel first: cadre's generated installer resolves it by version, so a cadre
release pinning an unreleased kernel is a broken install. recall and gloop are
independent of both. T-05 is last because it is the only task that consumes what
the others publish.

## AC-6 says "or a stated reason", and that is the clause to watch

Three of the four have unreleased commits for ordinary reasons — the work of
this goal. gloop is the one where "a stated reason" is tempting as the whole
answer, because it is private, nothing imports it, and it has no release
workflow to fix.

Evidence first, decision after: gloop's README documents
`go install github.com/deagy/gloop/cmd/gloop@latest`, which resolves through the
public module proxy. Whether that works against a private repository is a fact,
not a judgement — **run it in the container before deciding**. If the documented
install does not work, a stated reason is not enough; the claim is the defect
and AC-1's shape (nothing claims what it cannot keep) already applies to it.

## AC-7's falsification, in the spec's own words

*Declaring it done from a developer machine.* This machine has all four
repositories at `~/sdk`, a Go toolchain, a warm module cache and a
`~/.cadre` that install.sh will happily update in place instead of creating.
Every one of those makes a broken install look fine.

So T-05 runs in `docker run --rm` from a base image, with no bind mount of
`~/sdk`, no `~/.cadre`, and no Go toolchain unless the documented install
installs one. The two commands come from the criterion verbatim:
`cadre sdlc --version` and `cadre knowledge search`.

`cadre sdlc` reaches the kernel, so it fails if T-01's release is wrong.
`cadre knowledge search` reaches the store, so it fails if P3's and P4's work
does not survive packaging. The criterion picked two commands that cross the
whole goal, and that is why it is the only one an outside party could run.

## Not in this phase

Gating a release on the licence being in the artifact, or on a tag having
produced one, are both controls this phase's findings suggest. Neither is built
mid-phase — the retro decides, so a control lands with a named observable
rather than as a reflex.
