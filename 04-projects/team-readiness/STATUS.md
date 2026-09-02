# Team readiness — status ledger

North-star: a colleague who has never seen these repositories can install cadre, the lifecycle kernel and recall unaided, learn from the documentation how the three fit together, and read a record of who did what that names a person the system actually verified.
Spec: 04-projects/team-readiness/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P1 · Overall: **in progress**

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | assessment.html | 9 criteria, 5 phases, from a clean-container install as a non-author plus live multi-user probing |
| P1 | AC-1, AC-2, AC-3 | **next** | evidence/P1/ | The first hour: prerequisites, the authentication path, front pages that route |
| P2 | AC-4, AC-5 | pending | evidence/P2/ | One document explaining the three, a glossary, and the 18 false claims corrected |
| P3 | AC-6 | pending | evidence/P3/ | Wire cadre to `recall-server`; the actor becomes an authenticated subject |
| P4 | AC-7, AC-9 | pending | evidence/P4/ | Two credentials on one store; concurrency that survives two processes |
| P5 | AC-8 | pending | evidence/P5/ | Deletion of ingested content, with evidence that outlives it |

## Open AC-n (no PASS row yet)

All nine. Nothing has been built yet — P0 measured, it did not fix.

## Decisions taken at charter

- **The bar is colleagues on an internal team.** Real second users, trusted, inside the same company. Not anonymous internet users (no stability promise, no triage expectation), not customer or regulated data (deletion on request is in scope; legally-driven retention windows are not), and no uptime or support SLA.
- **The identity gap gets closed, not declared.** cadre will derive the recorded actor from `recall-server`'s authenticated subject rather than from a caller-supplied string. Chosen over the cheaper alternative — printing a warning that actor names are unverified — because the approval workflow is meant to be evidence, and a warning makes it honest without making it useful.
- **Documentation before code.** P1 and P2 ship before any integration work. It is days rather than weeks, it unblocks a colleague immediately, and it makes every later phase testable by someone who is not the author.
- **gloop is out of scope.** Nothing imports it and its coupling to cadre is a file, not a dependency. Whether to share it internally is a separate decision with three options recorded in `assessment.html`.

## Next action (resume cold from here)

**P1, CP-2: plan the first hour.** The tasks are already named by P0's evidence and want decomposing into `T-nn` with AC mappings:

- The `claude` authentication step — document it, including whether a headless path exists. This is the one that stops a colleague dead, and if no headless path exists that is itself the finding to record rather than route around.
- Prerequisites stated before the command that needs them: `curl`, `git`, Python 3.10+, Go and its version, `PATH`, network egress.
- cadre's "Choose your path" table gains an install link; cadre-kernel gains a `README.md`; recall gains an installation section naming its released binaries.
- GitHub descriptions on cadre and recall — both blank today.

Working notes from P0 are `ready-install.md`, `ready-multiuser.md` and `ready-docs.md` in this folder; the synthesis a reader should start from is `assessment.html`.

## Watch for

**AC-6's wording admits a weak reading, and the previous goal's equivalent criterion was nearly closed on one.** "Verified" is met when the value cannot be chosen by the caller at the moment of the call. `observed_actor` already exists, is already written beside every asserted name, and is consulted by no check — writing it in more places, or comparing two strings the caller supplied, would satisfy the sentence and not the criterion.

**Every phase from P3 owes a release before its criteria can be verified.** Verifying an installed-artifact criterion from a checkout is exactly the position this goal exists to leave, and the previous goal spent six container runs learning that a working checkout cannot see an installation defect.

**P1's real test is a person, and the harness cannot run it.** The container run is the substitute. Handing the three repositories to an actual colleague and watching where they stop is the confirmation, and it is the user's to schedule.
