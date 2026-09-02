# Production readiness — status ledger

North-star: cadre, the lifecycle kernel, recall and gloop each install from their own published artifacts, claim nothing they cannot keep, and record who actually did what.
Spec: 04-projects/production-readiness/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P4 · Overall: **in progress**

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | evidence/P0/ | 8 criteria, 5 phases, from a measured four-repository assessment |
| P1 | AC-1, AC-2, AC-3 | **done** | evidence/P1/ | Kernel licensed; gloop settled internal and made true; AC-07b closed. 3 CP-3v rounds + 1 CP-4 |
| P2 | AC-8 | **done** | evidence/P2/ | `#249` fixed with 2 falsified tests and its record corrected; kernel release husk removed |
| P3 | AC-4 | **done** | evidence/P3/ | Observed-beside-asserted on all four actor sites. **4 CP-3v rounds**, three failures from one root cause: a column addition's blast radius |
| P4 | AC-5 | not started | evidence/P4/ | Refuse the absent capability where it is reached for |
| P5 | AC-6, AC-7 | not started | evidence/P5/ | Release all four, then prove a clean machine works |
| P6 | AC-3b | not started | evidence/P6/ | Audit gloop's docs claim by claim against the binary |

## Open AC-n (no PASS row yet)
AC-5 (P4), AC-6 and AC-7 (P5), AC-3b (P6). AC-1, AC-2, AC-3 closed at P1; AC-8 at P2; AC-4 at P3.

## Decisions taken at charter

- **The bar is the daily driver**, not public OSS and not a client's data. One operator, running it every day.
- **gloop's public/internal question is P1's to settle on evidence**, not an input. What evidence would settle it: whether anything outside the author's control would ever import it, and whether the SDK framing is a plan or an aspiration. Nothing imports it today — not cadre, not recall, not the kernel.
- **Caller identity is being built, and the reason changed at charter.** With one operator there is nobody to impersonate, so this is not a defence against an adversary. What breaks without it is the evidence trail: a deletion record naming an actor nobody verified is a record of a string. That makes the target smaller than an auth system — derive from a source that already exists locally, refuse where none does.
- **Retention and erasure stay declared.** No third party's content enters the store. What changes is where the declaration lives.

## Next action (resume cold from here)

**P4 — refuse the absent capability where it is reached for (AC-5).**

Retention and erasure of ingested content do not exist, and `capability-parity` closed that honestly by *declaring* it across every document that touches it. AC-5 asks for one thing more: **the refusal has to happen at the point of use, not only in `SECURITY.md`.**

That wording is load-bearing and was decided against this project once already — CP-3v round 1 of P3 used it to rule that prose about `staged_by` and `decided_by` could not satisfy AC-4. The same standard applies here to the phase that owns the sentence.

What to build: a retention or erasure request reaching the CLI is refused by name, saying the capability was removed in `b418031e`, never rebuilt, and that content now lives in a recall store whose CLI exposes no delete. Falsified by running the command and reading what it says, not by grepping for the string.

## Watch for

**This goal is checkable almost entirely from a working checkout, which is the position that cannot see an installation defect.** Seven of the eight criteria can be satisfied without ever leaving a machine that has all four repositories present and built. AC-7 exists because of that, and it is last — so the temptation at the end will be to accept six months of green checks in place of one clean-machine install. This project has already recorded a guard that passed locally for months off a sibling checkout that exists on no runner.

The second risk is AC-4's wording. "Derived from a verifiable source" admits a weak reading: an environment variable the caller also sets is not verification. The criterion is met when the value cannot be chosen by the caller at the moment of the call, or the command says plainly that it was.
