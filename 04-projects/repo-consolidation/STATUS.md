# Repository consolidation — status ledger

North-star: every concern has exactly one owning repository, and the losing implementations are deleted or archived rather than left running.
Spec: 04-projects/repo-consolidation/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P4 · Overall: **AC-08 closed** — T-01..T-06 done, CP-4 passed after three fixes; P5 next

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | done | evidence/P0/ | Charter + boundary baseline measured at cadre `180a00ca` |
| P1 | AC-01,02,03,04 | **done** | evidence/P1/ | Kernel published and released; cadre merged and pushed. All four AC verified. Retro: harness/retro/2026-08-29-repo-consolidation-p1.md |
| P2 | AC-05 | **done** | evidence/P2/ | Archived; intent-brief template salvaged into cadre. Retro: harness/retro/2026-08-29-repo-consolidation-p2.md |
| P3 | AC-06,07 | **done** | evidence/P3/ | Composed rather than ported. CP-3v/CP-4/CP-5 all passed. Retro: harness/retro/2026-08-29-repo-consolidation-p3.md |
| P4 | AC-08 | **done** | evidence/P4/ | Engine deleted, retrieval governed over recall `v0.3.1`. CP-3v on T-04 and T-05, CP-4 across the phase. Three CP-4 defects found and fixed. Pushed `f578a0b4`. |
| P5 | AC-09,10 | not started | — | Catalog home and cadre's remainder |

## Open AC-n (no PASS row yet)
- AC-01 through AC-07 — **all closed**, each with an artifact-level observation. See `evidence/P1/ledger.md` and the P2/P3 ledgers.
- AC-07b — removing gloop's deprecated selectors, deferred to its next major.
- AC-08 — **closed**. T-01..T-06 all carry PASS rows, and CP-4 verified the phase end to end after three defects it found were fixed.
- AC-09, AC-10 — P5, not started.
- AC-11 — the end-to-end pipeline run. Split out of AC-03 in the 2026-08-28 spec amendment and assigned to P5, where an installed, released, provider-wired kernel exists.

## P0 baseline (measured 2026-08-28, cadre @ 180a00ca)
- All five boundary tests pass: `TestNoRosterSidePackageImportsTheKernel`, `TestTheKernelDoesNotImportRosterSideCode`, `TestANeutralPackageStaysNeutral`, `TestTheKernelShipsAsItsOwnBinary`, `TestThisRepositoryRunsNoLifecycleOverlayOfItsOwn`
- Independent import audit: exactly three files import `internal/kernel` — `cmd/agentic-sdlc/main.go` (only non-test importer), `internal/canonicaljson/agreement_test.go` (external test package), `internal/kernel/kernel_boundary_test.go`
- Zero roster-side imports. `internal/kernel` imports only `internal/canonicaljson`
- Move inventory: `internal/kernel/` 79 files / 16,857 non-test lines; `cmd/agentic-sdlc/` 1 file; `kernel/` README + 10 JSON contracts; `bin/agentic-sdlc`
- Distribution already assumes separation: `plugin_generation.go` emits a shim resolving `AGENTIC_SDLC_BIN`, else downloading by `AGENTIC_SDLC_VERSION`

## Next action (resume cold from here)

**AC-08 is closed and P4 is done.** cadre owns no retrieval engine. `cadre knowledge search` runs over a recall store behind `recall/govern` v0.3.1, the six refusals hold at the command line, the staged-record workflow has its own pure-Go database, and `ingest-accepted` writes to recall through the same governed view the read path uses. Evidence: `evidence/P4/CP-4-integration.md` and the per-task acceptance files.

**P5 is next**: AC-09 and AC-10 — the catalog home, and what remains of cadre. AC-11's end-to-end pipeline run belongs there too.

**Three things P4 opened that P5 has to answer:**
- **Deletion by retention window, classification, source or age no longer exists** and cannot be rebuilt over recall's interface. `roster/knowledge-store/SECURITY.md` describes a `delete-ingested` verb with deletion evidence that the Go CLI never shipped, so policy was ahead of implementation before this and is further ahead now. Either recall grows metadata-scoped deletion, or the policy is rewritten to describe what exists.
- **`recall upload` cannot feed cadre's default config.** recall embeds with `mock`/`openai`/`cohere`/`ollama`/`onnx`; cadre's default is `local-hashing`. cadre refuses a mismatched store rather than mis-searching it, but the documented quickstart needs both sides on the same real embedder. The durable fix is recall recording embedder identity in the store, which turns cadre's check from an assertion into a verification.
- **`ingest-accepted` writes under a fixed `proposed-knowledge` source**, not the `source_scope` an operator declares. Documented rather than changed: making the declared scope the retrieval source is a staging-contract decision.

Also worth carrying: a whitespace-only query passes `govern`'s exact empty check and produces a score-0 result with an audit row. Behaviour faithfully inherited from the deleted engine, so not a regression — but it belongs in recall's `govern`, not in a ledger note.

Unpushed: none.

## Repositories
- `~/sdk/cadre` @ `f578a0b4` on `main` — **pushed**. Kernel absent from the published tree; knowledge engine deleted
- `~/sdk/cadre-kernel` @ `24ec47c` on `main` — **https://github.com/deagy/cadre-kernel** (public), released `v0.14.2` with five platform archives
- `~/sdk/recall` @ `2c00c05` on `main` — **https://github.com/deagy/recall** (public), tagged `v0.3.1`, CI green including the cross-repo contract guard. Still no GitHub Release for either tag: `tag.yml` pushes with `GITHUB_TOKEN`, which does not fire `release.yml`. recall's own defect, no effect on cadre — module consumers resolve from the tag through the proxy
