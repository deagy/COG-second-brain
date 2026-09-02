# Production readiness — status ledger

North-star: cadre, the lifecycle kernel, recall and gloop each install from their own published artifacts, claim nothing they cannot keep, and record who actually did what.
Spec: 04-projects/production-readiness/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P7 closed, north-star gate re-run pending · Overall: **in progress**

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | evidence/P0/ | 8 criteria, 5 phases, from a measured four-repository assessment |
| P1 | AC-1, AC-2, AC-3 | **done** | evidence/P1/ | Kernel licensed; gloop settled internal and made true; AC-07b closed. 3 CP-3v rounds + 1 CP-4 |
| P2 | AC-8 | **done, but wrong** | evidence/P2/ | `#249` fixed with 2 falsified tests. Its other two claims were false: the issue *body* was never edited (only a closing comment), and "kernel release husk removed" meant the publishing job, not the six live releases. Reopened at the gate, closed in P7 |
| P3 | AC-4 | **done** | evidence/P3/ | Observed-beside-asserted on all four actor sites. **4 CP-3v rounds**, three failures from one root cause: a column addition's blast radius |
| P4 | AC-5 | **done** | evidence/P4/ | ~15 reach-paths refuse by name. CP-4 caught the refusal reading a flag's value as a request |
| P5 | AC-6, AC-7 | **done** | evidence/P5/ | Nine tasks for five planned. Six container runs, each moving the failure. CP-3v round 2 and CP-4 both PASS |
| P6 | AC-3b | **done** | evidence/P6/ | 22 false claims, 20 guards. Nine CP-3v rounds, an escalation the user resolved, and CP-4 found a guard that had been silently deleted |
| P7 | AC-8 (reopened) | **done** | evidence/P7/ | Opened by the north-star gate's FAIL. `#249`'s body corrected; six `kernel-v*` releases deleted from `deagy/cadre`, tags kept. CP-4 then found nine live documents still installing the kernel from the retired home |

## Open AC-n (no PASS row yet)

None — but AC-8's history is the thing to read here, not its current state. It carried
a PASS row from P2 for six phases while two of its three clauses were false, and the
north-star gate is what found that. Its PASS now rests on P7's evidence: the `#249`
body re-fetched after editing, the releases API returning zero kernel releases in
`deagy/cadre` against `cadre-kernel` serving `v0.14.4` at 200, and a fresh verifier
that falsified the fix by removing the guard and watching the original defect return.

The other eight carry PASS rows: AC-1, AC-2, AC-3 at P1; AC-4 at P3; AC-5 at P4;
AC-6 and AC-7 at P5; AC-3b at P6.

## Decisions taken at charter

- **The bar is the daily driver**, not public OSS and not a client's data. One operator, running it every day.
- **gloop's public/internal question is P1's to settle on evidence**, not an input. What evidence would settle it: whether anything outside the author's control would ever import it, and whether the SDK framing is a plan or an aspiration. Nothing imports it today — not cadre, not recall, not the kernel.
- **Caller identity is being built, and the reason changed at charter.** With one operator there is nobody to impersonate, so this is not a defence against an adversary. What breaks without it is the evidence trail: a deletion record naming an actor nobody verified is a record of a string. That makes the target smaller than an auth system — derive from a source that already exists locally, refuse where none does.
- **Retention and erasure stay declared.** No third party's content enters the store. What changes is where the declaration lives.

## Next action (resume cold from here)

**Waiting on cadre CI for `cd836b95`** (validate run 33675564709, pending at the time
of writing). When it is green, re-run the north-star gate over all nine criteria with
a fresh verifier, then CP-7 is already written
(`04-projects/harness/retro/2026-09-02-production-readiness.md`).

Releases: cadre `cli-v0.7.5` / `plugin-v0.24.5`, cadre-kernel `v0.14.4`, recall
`v0.3.3`, gloop none by decision. `cd836b95` is a documentation commit on top of
`cli-v0.7.5` and does not need a new release to satisfy AC-6, which admits "a stated
reason" — but that reason has to be stated at the gate, not assumed.

**What P7 was, in one paragraph.** The north-star gate failed AC-8 six phases after P2
closed it. P2 had verified that `release.yml` no longer publishes kernel releases; the
criterion is about the kernel having one release *home*, which is a claim about the
artifacts. Six were still live and downloadable. P2 had likewise read a closing
*comment* on `#249` as the issue body being corrected — the body had never been edited,
and a comment and an edit look identical to anyone reading the thread top to bottom.
Both are the same defect: the check observed something narrower than the criterion
named. Deleting the releases went to the user at CP-6, because it is irreversible and
breaks the kernel fetch of eight published CLI releases (`cli-v0.5.0`–`cli-v0.6.5`,
confirmed by reading the shim out of the extracted `cli-v0.6.5` binary with `strings`).
They chose deletion, tags kept.

**Housekeeping the workspace guard refuses to do for me:** four scratch worktrees from
earlier phases are still registered — `/tmp/claude-1000/redcheck`, `/tmp/v4b-oldcommit`,
`/tmp/v4c-clone`, `/tmp/v4d-falsify`. The last two carry a deliberate falsification
mutation in `internal/knowledge/staged_db.go`, already recorded in P3's evidence.
`git worktree remove` is blocked as a destructive git-metadata operation, so they need
removing by hand.

## Watch for

**This goal is checkable almost entirely from a working checkout, which is the position that cannot see an installation defect.** Seven of the eight criteria can be satisfied without ever leaving a machine that has all four repositories present and built. AC-7 exists because of that, and it is last — so the temptation at the end will be to accept six months of green checks in place of one clean-machine install. This project has already recorded a guard that passed locally for months off a sibling checkout that exists on no runner.

The second risk is AC-4's wording. "Derived from a verifiable source" admits a weak reading: an environment variable the caller also sets is not verification. The criterion is met when the value cannot be chosen by the caller at the moment of the call, or the command says plainly that it was.
