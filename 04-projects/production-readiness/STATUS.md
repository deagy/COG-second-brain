# Production readiness — status ledger

North-star: cadre, the lifecycle kernel, recall and gloop each install from their own published artifacts, claim nothing they cannot keep, and record who actually did what.
Spec: 04-projects/production-readiness/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P1 · Overall: **in progress**

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | **done** | evidence/P0/ | 8 criteria, 5 phases, from a measured four-repository assessment |
| P1 | AC-1, AC-2, AC-3 | not started | evidence/P1/ | Licensing and identity. Legal before technical |
| P2 | AC-8 | not started | evidence/P2/ | `#249` and its stale issue body; the kernel's two release homes |
| P3 | AC-4 | not started | evidence/P3/ | Caller identity — derive the actor fields, or refuse |
| P4 | AC-5 | not started | evidence/P4/ | Refuse the absent capability where it is reached for |
| P5 | AC-6, AC-7 | not started | evidence/P5/ | Release all four, then prove a clean machine works |

## Open AC-n (no PASS row yet)
All eight. Nothing built.

## Decisions taken at charter

- **The bar is the daily driver**, not public OSS and not a client's data. One operator, running it every day.
- **gloop's public/internal question is P1's to settle on evidence**, not an input. What evidence would settle it: whether anything outside the author's control would ever import it, and whether the SDK framing is a plan or an aspiration. Nothing imports it today — not cadre, not recall, not the kernel.
- **Caller identity is being built, and the reason changed at charter.** With one operator there is nobody to impersonate, so this is not a defence against an adversary. What breaks without it is the evidence trail: a deletion record naming an actor nobody verified is a record of a string. That makes the target smaller than an auth system — derive from a source that already exists locally, refuse where none does.
- **Retention and erasure stay declared.** No third party's content enters the store. What changes is where the declaration lives.

## Next action (resume cold from here)

**P1 — licensing and identity.** Three tasks, so CP-4 is owed.

1. **Licence the lifecycle kernel.** It is public with no licence, which is all-rights-reserved by default, and cadre's generated installer downloads it by version (`internal/generators/plugin_generation.go:235`). An Apache-2.0 CLI currently ships an installer reaching for a dependency nobody may lawfully use. This is the single highest-leverage change in the goal and it is one file.
2. **Settle gloop.** Decide public or internal on the evidence above, then make its README true either way. Today it asserts MIT with no `LICENSE` file, and carries Go Report Card and pkg.go.dev badges while `pkg.go.dev/github.com/deagy/gloop` returns 404.
3. **Sweep the remaining licence claims** across all four, so AC-1 is checked against the whole set rather than the two known offenders.

If gloop is settled as internal, `AC-07b` of the closed repo-consolidation goal — removing the deprecated `selector.Select` and `roster.Select` — closes with it: nothing imports gloop, the only caller is its own CLI at `cmd/gloop/cmd/select.go:91`, and the deprecation notice has never shipped, living only in `[Unreleased]`.

## Watch for

**This goal is checkable almost entirely from a working checkout, which is the position that cannot see an installation defect.** Seven of the eight criteria can be satisfied without ever leaving a machine that has all four repositories present and built. AC-7 exists because of that, and it is last — so the temptation at the end will be to accept six months of green checks in place of one clean-machine install. This project has already recorded a guard that passed locally for months off a sibling checkout that exists on no runner.

The second risk is AC-4's wording. "Derived from a verifiable source" admits a weak reading: an environment variable the caller also sets is not verification. The criterion is met when the value cannot be chosen by the caller at the moment of the call, or the command says plainly that it was.
