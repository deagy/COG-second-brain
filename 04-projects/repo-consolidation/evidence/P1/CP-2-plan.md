# P1 — CP-2 plan: extract the lifecycle kernel

Covers AC-01, AC-02, AC-03, AC-04. Source: cadre @ `180a00ca`, baseline in `../../STATUS.md`.

## Tasks

| ID | Task | Covers | Gate |
|---|---|---|---|
| T-01 | Freeze the golden fingerprint fixture in cadre, while both implementations are importable | AC-03 | internal |
| T-02 | Create the kernel repository locally; move `internal/kernel/`, `cmd/agentic-sdlc/`, `kernel/`, `bin/agentic-sdlc`, and a copy of `internal/canonicaljson`; rewrite the module path | AC-01 | internal |
| T-03 | Vendor `kernel/contracts/*.json` back into cadre with a drift check; repoint the two roster-side tests that read them | AC-04 | internal |
| T-04 | Split the build and release: kernel targets leave cadre's `Makefile` and `release.yml` | AC-02 | internal |
| T-05 | Delete the kernel from cadre; add the end-to-end `cadre select` → `agentic-sdlc validate` check | AC-02, AC-03 | internal |
| T-06 | Push the kernel repository to a remote | AC-01 | **external — CP-6 review gate** |

T-01 must land before T-02. Every other ordering is as listed.

## Task detail

**T-01.** `internal/canonicaljson/agreement_test.go` runs `planWithEverything()` through `internal/kernel` and `internal/selector` and asserts identical fingerprints. Extract that plan and its computed fingerprint into a fixture both repositories can test against after the split. The fixture must be *generated* from the two agreeing implementations, not hand-written, or it records an assumption rather than an observation.

**T-02.** Module path changes, so every intra-kernel import is rewritten mechanically. `internal/canonicaljson` is copied rather than shared: 217 lines of pure function, guarded by the T-01 fixture. `kernel/contracts/` and `internal/kernel/contracts/` move together with `TestEmbeddedContractsMatchTheSourceOfTruth` unchanged.

**T-03.** Model the drift check on `internal/orchestration/schema_release_drift_test.go`, which already diffs a committed schema against its copy at the last release tag using `git show`. Roster-side readers to repoint: `internal/selector/golden_corpus_test.go`, `internal/engine/enginecli/standalone_test.go`.

**T-04.** cadre's `Makefile` builds `agentic-sdlc` for four platforms at `CGO_ENABLED=0` (lines 123-126); `release.yml` packages it. Those move. The engine's targets stay — `internal/engine` is out of P1 scope by decision.

**T-05.** Deletion is last so every prior step is verifiable against a working tree that still has both halves.

## Acceptance evidence to produce

| AC | Observation | Artifact |
|---|---|---|
| AC-01 | Clean clone: `go build ./...` and `go test ./...` exit 0; `bin/agentic-sdlc --version` prints | terminal capture |
| AC-02 | cadre: three paths absent; `CGO_ENABLED=1 go test -tags sqlite_fts5 ./...` green; all four `--check` generators current | terminal capture |
| AC-03 | Fixture test passes in both repositories; a `cadre select` plan is accepted by `agentic-sdlc validate` (exit 0) | plan file + exit status |
| AC-04 | `run-record` schema exists in the kernel repo only; cadre's vendored copy fails its drift check when hand-edited | drift test output, both states |

## Out of scope for P1

`internal/engine` (6,787 lines) stays in cadre. Its kernel coupling is already "ask, don't link", so it works unchanged across a repository boundary and moving it later costs nothing that moving it now saves.

## Risk carried into build

The fixture in T-01 is the only thing standing between the split and a silent fingerprint divergence — a failure that has occurred once and was total. If T-01 cannot produce a fixture from two agreeing implementations, P1 stops and escalates rather than proceeding.
