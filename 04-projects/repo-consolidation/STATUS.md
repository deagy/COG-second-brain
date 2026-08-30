# Repository consolidation — status ledger

North-star: every concern has exactly one owning repository, and the losing implementations are deleted or archived rather than left running.
Spec: 04-projects/repo-consolidation/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P4 · Overall: in-progress

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | done | evidence/P0/ | Charter + boundary baseline measured at cadre `180a00ca` |
| P1 | AC-01,02,03,04 | **done** | evidence/P1/ | Kernel published and released; cadre merged and pushed. All four AC verified. Retro: harness/retro/2026-08-29-repo-consolidation-p1.md |
| P2 | AC-05 | **done** | evidence/P2/ | Archived; intent-brief template salvaged into cadre. Retro: harness/retro/2026-08-29-repo-consolidation-p2.md |
| P3 | AC-06,07 | **done** | evidence/P3/ | Composed rather than ported. CP-3v/CP-4/CP-5 all passed. Retro: harness/retro/2026-08-29-repo-consolidation-p3.md |
| P4 | AC-08 | not started | — | Knowledge store: cadre's or recall's, not both |
| P5 | AC-09,10 | not started | — | Catalog home and cadre's remainder |

## Open AC-n (no PASS row yet)
- AC-01 through AC-04 — **all closed**, each with an artifact-level observation. See `evidence/P1/ledger.md`.
- AC-11 — the end-to-end pipeline run. Split out of AC-03 in the 2026-08-28 spec amendment and assigned to P5, where an installed, released, provider-wired kernel exists
- AC-01 through AC-07 — **all closed**, each with an artifact-level observation.
- AC-07b — removing gloop's deprecated selectors, deferred to its next major.
- AC-08 — P4. AC-09, AC-10, AC-11 — P5.
- AC-05 through AC-10 — phases not started

## P0 baseline (measured 2026-08-28, cadre @ 180a00ca)
- All five boundary tests pass: `TestNoRosterSidePackageImportsTheKernel`, `TestTheKernelDoesNotImportRosterSideCode`, `TestANeutralPackageStaysNeutral`, `TestTheKernelShipsAsItsOwnBinary`, `TestThisRepositoryRunsNoLifecycleOverlayOfItsOwn`
- Independent import audit: exactly three files import `internal/kernel` — `cmd/agentic-sdlc/main.go` (only non-test importer), `internal/canonicaljson/agreement_test.go` (external test package), `internal/kernel/kernel_boundary_test.go`
- Zero roster-side imports. `internal/kernel` imports only `internal/canonicaljson`
- Move inventory: `internal/kernel/` 79 files / 16,857 non-test lines; `cmd/agentic-sdlc/` 1 file; `kernel/` README + 10 JSON contracts; `bin/agentic-sdlc`
- Distribution already assumes separation: `plugin_generation.go` emits a shim resolving `AGENTIC_SDLC_BIN`, else downloading by `AGENTIC_SDLC_VERSION`

## Next action (resume cold from here)

**P4 — the knowledge store: cadre's or recall's, not both.** Closes AC-08.

It has a prerequisite recorded at charter and still unmet: **recall's parity is unverified.** cadre's `internal/knowledge` does exact-match classification filtering, source scoping by repository slug with a canonical-path-hash fallback, audit metadata on retrieval, and a shared-global-store fallback for projects with no partition of their own. Whether recall covers those decides the phase.

Read recall before planning P4. AI-11 exists because P3 was planned as a port against a destination nobody had opened, and P4's destination is a 183-file platform.

Read `04-projects/harness/BACKLOG.md` first: fourteen action items now, four of them from P3.

## Repositories
## Repositories
## Repositories
## Repositories
## Repositories
## Repositories
## Repositories
## Repositories
## Repositories
## Repositories
## Repositories
## Repositories
## Repositories
## Repositories
## Repositories
## Repositories
- `~/sdk/cadre` @ `1ed3169a` on `main` — **merged and pushed**. Kernel absent from the published tree
- `~/sdk/cadre-kernel` @ `24ec47c` on `main` — **https://github.com/deagy/cadre-kernel** (public), released `v0.14.2` with five platform archives
