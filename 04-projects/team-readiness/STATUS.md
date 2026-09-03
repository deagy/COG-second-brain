# Team readiness — status ledger

North-star: a colleague who has never seen these repositories can install cadre, the lifecycle kernel and recall unaided, learn from the documentation how the three fit together, and read a record of who did what that names a person the system actually verified.
Spec: 04-projects/team-readiness/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P1–P5 built; verification and gates in progress · Overall: **in progress**

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | assessment.html | 9 criteria, 5 phases, from a clean-container install as a non-author |
| P1 | AC-1, AC-2, AC-3 | **built, CP-3v PASS** | evidence/P1/ | CP-3v round 1 failed on this phase's own new file — `--root` not carried in the kernel README's example. CP-4 has run four rounds on one defect class |
| P2 | AC-4, AC-5 | **built, CP-3v PASS** | evidence/P2/ | The overview page, the glossary, and a dead-path guard that scans every live document. Each CP-3v round found defects in the README blocks the round before had not compiled |
| P3 | AC-6 | **built, CP-3v PASS** | evidence/P3/ | Three rounds, three distinct reasons the branch was unreachable: a config block nothing parsed, a credential that could not be persisted, a header the authenticator never read |
| P4 | AC-7, AC-9 | **built, CP-3v PASS** | evidence/P4/ | Verified with 30+ real processes and deliberate namespace-escape attempts, both beyond what the implementation's own tests reach |
| P5 | AC-8 | **built, CP-3v PASS** | evidence/P5/ | Absence confirmed independently through `recall store info`, not only through cadre's own search |

## Open AC-n (no PASS row yet)

None. All nine criteria carry a CP-3v PASS row from a fresh verifier working
against released artifacts rather than a checkout.

Releases the criteria are verified against: cadre `cli-v0.7.9`, recall
`v0.3.6`, cadre-kernel `v0.14.4`.

## Decisions taken at charter

- **The bar is colleagues on an internal team.** Real second users, trusted, inside the same company. Not anonymous internet users (no stability promise, no triage expectation), not customer or regulated data (deletion on request is in scope; legally-driven retention windows are not), and no uptime or support SLA.
- **The identity gap gets closed, not declared.** cadre will derive the recorded actor from `recall-server`'s authenticated subject rather than from a caller-supplied string. Chosen over the cheaper alternative — printing a warning that actor names are unverified — because the approval workflow is meant to be evidence, and a warning makes it honest without making it useful.
- **Documentation before code.** P1 and P2 ship before any integration work. It is days rather than weeks, it unblocks a colleague immediately, and it makes every later phase testable by someone who is not the author.
- **gloop is out of scope.** Nothing imports it and its coupling to cadre is a file, not a dependency. Whether to share it internally is a separate decision with three options recorded in `assessment.html`.

## Next action (resume cold from here)

**Round 2 of CP-4 for P3, P4 and P5**, against the release cut from cadre
`68095d81` (`cli-v0.7.10`). Round 1 returned FAIL:fixable on two cross-phase
findings; both are fixed and the fixes are falsified, but a fix verified by its
author is not verified.

Then: CP-6 per phase, CP-7 retro, and the north-star gate over all nine
criteria. CP-4 for P1 and P2 passed at round 2; CP-5 is recorded for all five
phases.

**This checkpoint was recorded as running when it had never been dispatched.**
`phase-gates.sh` caught it — three phases with no CP-4 row and no artifact. It
is the capability-parity failure repeated, and the reason the gate counts rows
rather than reading this file.

**Releases the criteria are verified against:** cadre `cli-v0.7.9`, recall
`v0.3.6`, cadre-kernel `v0.14.4`. Every phase from P3 cut one before its
criteria were checked, per the charter.

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
