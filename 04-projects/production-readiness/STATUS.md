# Production readiness — status ledger

North-star: cadre, the lifecycle kernel, recall and gloop each install from their own published artifacts, claim nothing they cannot keep, and record who actually did what.
Spec: 04-projects/production-readiness/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P5 · Overall: **in progress**

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | evidence/P0/ | 8 criteria, 5 phases, from a measured four-repository assessment |
| P1 | AC-1, AC-2, AC-3 | **done** | evidence/P1/ | Kernel licensed; gloop settled internal and made true; AC-07b closed. 3 CP-3v rounds + 1 CP-4 |
| P2 | AC-8 | **done** | evidence/P2/ | `#249` fixed with 2 falsified tests and its record corrected; kernel release husk removed |
| P3 | AC-4 | **done** | evidence/P3/ | Observed-beside-asserted on all four actor sites. **4 CP-3v rounds**, three failures from one root cause: a column addition's blast radius |
| P4 | AC-5 | **done** | evidence/P4/ | ~15 reach-paths refuse by name. CP-4 caught the refusal reading a flag's value as a request |
| P5 | AC-6, AC-7 | not started | evidence/P5/ | Release all four, then prove a clean machine works |
| P6 | AC-3b | not started | evidence/P6/ | Audit gloop's docs claim by claim against the binary |

## Open AC-n (no PASS row yet)
AC-6 and AC-7 (P5), AC-3b (P6). AC-1, AC-2, AC-3 closed at P1; AC-8 at P2; AC-4 at P3; AC-5 at P4.

## Decisions taken at charter

- **The bar is the daily driver**, not public OSS and not a client's data. One operator, running it every day.
- **gloop's public/internal question is P1's to settle on evidence**, not an input. What evidence would settle it: whether anything outside the author's control would ever import it, and whether the SDK framing is a plan or an aspiration. Nothing imports it today — not cadre, not recall, not the kernel.
- **Caller identity is being built, and the reason changed at charter.** With one operator there is nobody to impersonate, so this is not a defence against an adversary. What breaks without it is the evidence trail: a deletion record naming an actor nobody verified is a record of a string. That makes the target smaller than an auth system — derive from a source that already exists locally, refuse where none does.
- **Retention and erasure stay declared.** No third party's content enters the store. What changes is where the declaration lives.

## Next action (resume cold from here)

**P5 is at CP-5 PASS, awaiting CP-3v round 2 and CP-4.** Both verifiers are
dispatched. When they return: merge their rows into `evidence/P5/ledger.md`, mark P5
done, then P6.

Releases: cadre `cli-v0.7.5` / `plugin-v0.24.5`, cadre-kernel `v0.14.4`, recall
`v0.3.3`, gloop none by decision. All at `HEAD`, all runs green.

**AC-7 took six container runs and each one moved the failure.** The defects, in
order found: `install.sh` refuses with no AI runner on PATH; every kernel release
since the extraction wrote `SHA256SUMS` the install shim could not match, so
`cadre sdlc` could never install a kernel; `install.sh`'s `cadre` needed a Go
toolchain its own instructions never mention; no `linux/arm64` CLI was published,
and the diagnostic named `linux/arm64` among the platforms it covers; `cadre sdlc`
could not find the kernel the installer had just cached, through four separate
resolvers; and `cadre doctor` reported no kernel while `cadre sdlc` ran one.

**P6 is AC-3b** — a claim-by-claim audit of gloop's documentation against the binary.
Two findings already gathered, from `gloop --help` at `3715bef`: its usage line reads
`Usage: gloop gloop`, and its Examples block opens with `# Select agents for a task`
followed by no command — `gloop select` was removed in P1 and the comment survived.
Scope: `README.md` is 555 lines and `docs/` is 8,060 across 23 files, most of them
dated phase reviews, so the phase's first job is deciding which are live documents
and which are records — the exemption class P1 applied to cadre's
`DESIGN-NOTES-deletion-and-retention.md`.

Then the north-star gate over all nine criteria, `report.html`, and CP-7.

**Housekeeping the workspace guard refuses to do for me:** four scratch worktrees
from earlier phases are still registered — `/tmp/claude-1000/redcheck`,
`/tmp/v4b-oldcommit`, `/tmp/v4c-clone`, `/tmp/v4d-falsify`. The last two carry a
deliberate falsification mutation in `internal/knowledge/staged_db.go`, already
recorded in P3's evidence. `git worktree remove` is blocked as a destructive
git-metadata operation, so they need removing by hand.

## Watch for

**This goal is checkable almost entirely from a working checkout, which is the position that cannot see an installation defect.** Seven of the eight criteria can be satisfied without ever leaving a machine that has all four repositories present and built. AC-7 exists because of that, and it is last — so the temptation at the end will be to accept six months of green checks in place of one clean-machine install. This project has already recorded a guard that passed locally for months off a sibling checkout that exists on no runner.

The second risk is AC-4's wording. "Derived from a verifiable source" admits a weak reading: an environment variable the caller also sets is not verification. The criterion is met when the value cannot be chosen by the caller at the moment of the call, or the command says plainly that it was.
