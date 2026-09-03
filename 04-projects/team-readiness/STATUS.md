# Team readiness — status ledger

North-star: a colleague who has never seen these repositories can install cadre, the lifecycle kernel and recall unaided, learn from the documentation how the three fit together, and read a record of who did what that names a person the system actually verified.
Spec: 04-projects/team-readiness/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: all five complete · Overall: **done** — north-star gate PASS 2026-09-03

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | assessment.html | 9 criteria, 5 phases, from a clean-container install as a non-author |
| P1 | AC-1, AC-2, AC-3 | **done** | evidence/P1/ | CP-3v round 1 failed on this phase's own new file — `--root` not carried in the kernel README's example. CP-4 has run four rounds on one defect class |
| P2 | AC-4, AC-5 | **done** | evidence/P2/ | The overview page, the glossary, and a dead-path guard that scans every live document. Each CP-3v round found defects in the README blocks the round before had not compiled |
| P3 | AC-6 | **done** | evidence/P3/ | Three rounds, three distinct reasons the branch was unreachable: a config block nothing parsed, a credential that could not be persisted, a header the authenticator never read |
| P4 | AC-7, AC-9 | **done** | evidence/P4/ | Verified with 30+ real processes and deliberate namespace-escape attempts, both beyond what the implementation's own tests reach |
| P5 | AC-8 | **done** | evidence/P5/ | Absence confirmed independently through `recall store info`, not only through cadre's own search |

## Open AC-n (no PASS row yet)

None. All nine criteria carry a CP-3v PASS row from a fresh verifier working
against released artifacts rather than a checkout.

Releases the criteria are verified against: cadre `cli-v0.7.11`, recall
`v0.3.6`, cadre-kernel `v0.14.4`.

## Decisions taken at charter

- **The bar is colleagues on an internal team.** Real second users, trusted, inside the same company. Not anonymous internet users (no stability promise, no triage expectation), not customer or regulated data (deletion on request is in scope; legally-driven retention windows are not), and no uptime or support SLA.
- **The identity gap gets closed, not declared.** cadre will derive the recorded actor from `recall-server`'s authenticated subject rather than from a caller-supplied string. Chosen over the cheaper alternative — printing a warning that actor names are unverified — because the approval workflow is meant to be evidence, and a warning makes it honest without making it useful.
- **Documentation before code.** P1 and P2 ship before any integration work. It is days rather than weeks, it unblocks a colleague immediately, and it makes every later phase testable by someone who is not the author.
- **gloop is out of scope.** Nothing imports it and its coupling to cadre is a file, not a dependency. Whether to share it internally is a separate decision with three options recorded in `assessment.html`.

## Outcome

**North-star gate PASS, 2026-09-03**, all nine criteria verified by a fresh
verifier that read the spec and the evidence and re-observed three of them
against the live world — re-fetching cadre-kernel's README through the GitHub
API, listing recall `v0.3.6`'s assets, and downloading `cli-v0.7.12`,
checksumming it against the release's own `SHA256SUMS`, and running it.

Verified against cadre `cli-v0.7.12`, recall `v0.3.6`, cadre-kernel `v0.14.4`.
All three repositories green on their own runners at the commits the criteria
name. `phase-gates.sh`, `spec-lint.sh`, `evidence-lint.sh` and
`citation-lint.sh` all exit 0.

### The one criterion that is verified and not yet proven

AC-1's own wording makes the container run its automated substitute for a
person, and the spec says so: *the confirmation no automated check replaces.*
The row is correctly graded against the falsification test AC-1 states — a
container, the published artifacts, nothing supplied from outside the docs —
so this is not a misgraded row. But the north-star's plain sentence says *a
colleague installs unaided*, and no colleague has done it yet.

The gate said this without being asked to, which is the right instinct: a
criterion can be honestly satisfied and its north-star still be one step short.
**Handing the three repositories to an actual person and watching where they
stop is the operator's to schedule**, and it is the only remaining way to learn
what the container cannot tell us.

### Open for the operator

- `cli-v0.7.10` — a tag with no release behind it, created by hand before
  checking that cadre's workflow tags and publishes itself. `release-hygiene.sh`
  is red until it goes, and it is not being excepted, because an exception would
  file the mistake as a stated reason. `git -C ~/sdk/cadre push origin
  :refs/tags/cli-v0.7.10`. The gate judged it not a blocker: it gates none of
  the releases that actually shipped and were verified.
- Four scratch worktrees remain registered from earlier phases.

## Findings carried to the retro, not fixed in-phase

- **The two repositories check different things.** recall runs `golangci-lint`
  and `gofmt -s`; cadre ran neither `-s` nor a linter. A cadre file failed
  recall's build, and a doc comment describing the wrong function reached a
  push. cadre now checks `-s`; the linter gap remains.
- **recall's CI checks out `deagy/cadre` with no ref**, so a push to cadre can
  turn recall red without recall changing.
- **`GET /diagnostics` is unauthenticated and lists tenant namespaces.** Names,
  never content, and outside AC-7 — but it only became a question when P4 made
  multi-tenant use possible.
- **The id a colleague has is not the id `delete-ingested` wants**: `KS-…`
  against the corpus id `proposed-knowledge:KS-…`. The refusal is correct; the
  friction is first-hour, which is P1's subject.
- **`ingest`'s retirement message suggests `recall upload`**, a path whose
  content cannot later be deleted through cadre unless `knowledge init` ran
  before anything landed.

## Watch for

**AC-6's wording admits a weak reading, and the previous goal's equivalent criterion was nearly closed on one.** "Verified" is met when the value cannot be chosen by the caller at the moment of the call. `observed_actor` already exists, is already written beside every asserted name, and is consulted by no check — writing it in more places, or comparing two strings the caller supplied, would satisfy the sentence and not the criterion.

**Every phase from P3 owes a release before its criteria can be verified.** Verifying an installed-artifact criterion from a checkout is exactly the position this goal exists to leave, and the previous goal spent six container runs learning that a working checkout cannot see an installation defect.

**P1's real test is a person, and the harness cannot run it.** The container run is the substitute. Handing the three repositories to an actual colleague and watching where they stop is the confirmation, and it is the user's to schedule.

## Harness defects found while running the gates, for the retro

Four, all in the checking machinery rather than in the software under test.

- **`citation-lint` read every CI run id as a commit sha.** An eleven-digit
  decimal run id sits inside `[0-9a-f]{7,40}`, and the ultragoal skill requires
  run ids in the ledger, so the collision was guaranteed. It called four real
  run ids unresolvable commits. Now refused at the source: a run id has to say
  it is one.
- **`ci-status` and `release-hygiene` accepted a bare repository name.**
  `cadre` where `deagy/cadre` was meant 404s on every call, and `gh` writes the
  404 body to *stdout*, so the error JSON became the sha and passed the
  emptiness check. Three green, licensed repositories were reported as having
  no CI and no licence. Fail-closed, but with a false reason — which sends the
  reader to the runner instead of to the argument.
- **A hand-made tag defeats cadre's release workflow.** It tags and publishes
  itself when a version bump lands on main, and skips any version already
  tagged. `cli-v0.7.10` was created by hand and is now a tag with no release —
  exactly what `release-hygiene.sh` refuses. Removing it needs the operator.
- **`TestAStandaloneBinaryAnswersTheBasics` shells out to an untagged `go
  build`**, which cannot reuse the `sqlite_fts5` build cache the suite itself
  uses. On a cold cache that CGO build ran 8m49s and blew Go's default
  ten-minute package timeout; warm, the package finishes in 14s.
