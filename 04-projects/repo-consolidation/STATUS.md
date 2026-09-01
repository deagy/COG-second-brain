# Repository consolidation — status ledger

North-star: every concern has exactly one owning repository, and the losing implementations are deleted or archived rather than left running.
Spec: 04-projects/repo-consolidation/spec.md · Registry: 04-projects/harness/ultragoals.md
Current phase: P5 · Overall: **closing** — 9 of 11 criteria verified; AC-07 and AC-10 open with their work tracked as AC-07b and AC-10b

## Phases
| Phase | AC covered | State | Evidence | Notes |
|---|---|---|---|---|
| P0 | — | done | evidence/P0/ | Charter + boundary baseline measured at cadre `180a00ca` |
| P1 | AC-01,02,03,04 | **done** | evidence/P1/ | Kernel published and released; cadre merged and pushed. All four AC verified. Retro: harness/retro/2026-08-29-repo-consolidation-p1.md |
| P2 | AC-05 | **done** | evidence/P2/ | Archived; intent-brief template salvaged into cadre. Retro: harness/retro/2026-08-29-repo-consolidation-p2.md |
| P3 | AC-06,07 | **done** | evidence/P3/ | Composed rather than ported. CP-3v/CP-4/CP-5 all passed. Retro: harness/retro/2026-08-29-repo-consolidation-p3.md |
| P4 | AC-08 | **done** | evidence/P4/ | Engine deleted, retrieval governed over recall `v0.3.1`. CP-3v on T-04 and T-05, CP-4 across the phase. Three CP-4 defects found and fixed. Pushed `f578a0b4`. |
| P5 | AC-09,10,11 | **done** | evidence/P5/ | Pipeline verified end to end against the released kernel. North-star gate failed the *trail*: CI red in two repositories since the commits their criteria cite, AC-05 closed on a filename search, AC-10 amended at its own gate. All repaired. Retro: harness/retro/2026-09-01-repo-consolidation-p5.md |

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

**Nine of eleven criteria verified.** Two are open, both with their work tracked rather than dissolved:

- **AC-07** — pending. `selector.Select` and `roster.Select` carry their markers; removal completes at gloop's next major as **AC-07b**. Its wording was corrected 2026-09-01: `catalog.MatchRoutes` left scope (gloop's CHANGELOG retracts its deprecation in public) and the amendment's claim that gloop is "MIT-licensed, on pkg.go.dev" was false — it is private and unlicensed.
- **AC-10** — open. The reading holds: cadre spawns agent CLIs, gloop drives LLM endpoints, only `runner="api"` overlaps. **AC-10b** carries the resolution — gloop gains containment for its tool executor (path confinement, command allowlist, untrusted-brief fence), and cadre's `api_runner_*.go` retires onto it. That is the AC-08 shape: port the requirement, do not keep two implementations.

**One item is the user's**, and it is a live north-star failure rather than a nuisance: a pipx-installed Python `agentic-sdlc 0.13.2` is the only `agentic-sdlc` on this machine's PATH, and the kernel that owns that concern is not installed at all.

cadre's side of it is closed (`23fe930a`). The compatibility floor was `0.13.2` while cadre-kernel has released exactly one version, `v0.14.2` — so the stale kernel satisfied `--require-sdlc` by sitting exactly on the inclusive minimum. The floor is now tied to the pin, two tests hold it there (one of which the code already claimed existed), and `cadre doctor` reports which kernel answers, at what version, and what else on PATH is behind it.

The consequence is deliberate: a pre-port kernel is now **refused** by the compatibility guard rather than silently accepted, so `go test ./internal/orchestration/` fails on this machine until the binary is replaced. (`generate-plugin` is *not* affected — an earlier note here said it was, from one unisolated observation that does not reproduce.) Replacing the binary is worth doing regardless:

```sh
pipx uninstall agentic-sdlc
gh release download v0.14.2 --repo deagy/cadre-kernel \
  --pattern "agentic-sdlc-v0.14.2-linux-arm64.tar.gz" --pattern SHA256SUMS -D /tmp/k
cd /tmp/k && sha256sum -c --ignore-missing SHA256SUMS \
  && tar xzf agentic-sdlc-v0.14.2-linux-arm64.tar.gz \
  && install -m755 agentic-sdlc ~/.local/bin/agentic-sdlc
```

**What this phase changed about the trail itself.** cadre and gloop had been red on every push since their consolidation work began — cadre since the exact commit its AC-02 row cites as "full suite green". Both are green now, with the guards executing rather than skipping, and AC-02 is restated against run `33534720412`. Four criteria in this trail had rested on local exit codes; two were false where it counted.

Before the next ultragoal: **a claim of "green" cites a run ID or it is not evidence**, and the harness should read CI rather than only running tests. Both are in the P5 retro's actions.

Unpushed: none.

**CI on every owned repository's HEAD, cited rather than asserted:**

| Repo | HEAD | Run | Conclusion |
|---|---|---|---|
| cadre | `23fe930a` | `33540445520` | success |
| recall | `3ee2795` | `33537575047` | success |
| gloop | `b3e32c8` | `33532899185` | success |
| cadre-kernel | `e53c9bb` | — | docs-only commit |

Recorded this way deliberately. The first action out of P5's retro is that a claim of "green" cites a run ID or it is not evidence, and this trail spent five phases proving why.

## Repositories
- `~/sdk/cadre` @ `23fe930a` on `main` — **pushed, CI green**. Kernel absent from the published tree; knowledge engine deleted
- `~/sdk/cadre-kernel` @ `24ec47c` on `main` — **https://github.com/deagy/cadre-kernel** (public), released `v0.14.2` with five platform archives
- `~/sdk/recall` @ `3ee2795` on `main` — **https://github.com/deagy/recall** (public), tagged `v0.3.1`, CI green including the cross-repo contract guard. Still no GitHub Release for either tag: `tag.yml` pushes with `GITHUB_TOKEN`, which does not fire `release.yml`. recall's own defect, no effect on cadre — module consumers resolve from the tag through the proxy
