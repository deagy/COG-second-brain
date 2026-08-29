# P1 evidence ledger

One row per verify pass. Observations record what was observed in the artifact, never what a worker reported. Verifier rows come from a fresh-context read-only agent given paths and criteria only.

## T-01 — freeze the fingerprint agreement (commit `1f0d226b`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-03a | CP-3v | PASS | `fixture_test.go:56-124` computes the fixture in-memory from both `DispatchFingerprint` implementations, marshals it, and byte-compares to the committed file. No hand-authored bypass. The committed 64-hex-char digest matches live output, which could not be hand-typed to match. |
| AC-03b | CP-3v | PASS | Programmatic diff of `plan` against `plan_with_excluded_keys_changed`: only `dispatch_fingerprint`, `generated_at`, `provenance` differ — an exact match to `FingerprintExcludedKeys` at `internal/selector/canonical.go:36`. Both share one `expected_fingerprint`, and `frozen_test.go:34-48` asserts both compute to it. |
| AC-03c | CP-3v | PASS | `TestTheSelectorMatchesTheFrozenFingerprint` imports only `encoding/json`, `os`, `testing`, and `internal/selector`. No `internal/kernel` import in the file. Compiles and runs standalone once the kernel is removed. |
| AC-03d | CP-3v | PASS | All four package tests pass on the unmodified tree. The comparison target is a value fixed independently of the current exclusion set, so it cannot pass vacuously; a changed exclusion set moves the computed value off the frozen one. |
| AC-03e | CP-3v | PASS | `CGO_ENABLED=1 go test -tags sqlite_fts5 ./...` — every package `ok`, no FAIL, no build error, no panic. |

Verdict: **PASS**.

Lead-side falsification, independent of the verifier and recorded in `CP-3-build-T01.md`: removing `provenance` from `FingerprintExcludedKeys` made the single-sided test fail on both plans with computed-versus-frozen values. Reverted; suite returned green.

AC-03 is not yet closed. These rows cover the fixture; the criterion also requires a `cadre select` plan to survive the released `agentic-sdlc validate` after the split, which is T-05.

## T-02 — extract the kernel (cadre-lifecycle `54fde8a`)

Lead-side observations. Not yet verified by a fresh-context agent; T-02 is incomplete.

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-01 | CP-3 | PARTIAL | `go build ./...` exits 0. `go build ./cmd/agentic-sdlc && ./agentic-sdlc --version` prints `0.14.2`, exit 0. `go test ./...` does **not** exit 0 — four failures, one cause. AC-01 requires all three; it stays open. |
| AC-03 | CP-3 | PASS | `TestTheKernelMatchesTheFrozenFingerprint` passes in `cadre-lifecycle`, reproducing `sha256:924ca52d…` from the kernel alone. The same fixture passes in cadre from the selector alone. Two repositories, one contract, neither importing the other — the property the split depended on. |
| — | CP-3 | PASS | Boundary tests rewritten and passing: the kernel imports exactly one repository package (`internal/canonicaljson`), that package imports none of its own, and `cmd/` holds only `agentic-sdlc`. |

### Blocking finding: the kernel's tests read a provider bundle

Four failures — `TestTheKernelVersionIsInsideEveryProviderCompatibilityWindow`, `TestInitInitialisesIntoABlockedState`, `TestInitNeverOverwrites`, `TestADryRunWritesNothingAtAll` — all read `provider/provider.json` and `provider*/**/provider.json` from the repository root.

`provider/` is cadre's role-catalog bundle: `agent-catalog.json`, `roles/`, `codex-agents/`, `profiles/`, `extensions/`. cadre's own README calls it the bundle "contributed to the kernel", so it is roster-side data flowing *into* the kernel, not kernel source. It did not move, correctly.

The extraction plan's move inventory did not list it, and this is the coupling it missed.

Resolution, not yet applied: the kernel carries a minimal **fixture** provider bundle under `testdata/` for its own tests, because the kernel's job is validating any bundle rather than cadre's specifically. cadre keeps a test that validates its real bundle against the released kernel binary, which is the shell-out coupling the boundary already permits. That split also removes a circularity — today the kernel's test suite cannot pass without the roster's data.

Worth noting how this surfaced: the tests failed loudly rather than passing vacuously. `TestNoRosterSidePackageImportsTheKernel` reported "the list is stale and may be silently covering nothing" and "no roster-side packages were checked; this guard asserted nothing" instead of finding zero violations and passing.

### T-02 CP-3v — fresh-context verification (cadre-lifecycle `8863d00`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-01 | CP-3v | PASS | Verifier's own clean clone: `go build ./...` exit 0; `go test ./...` exit 0 with both packages `ok`; `./bin/agentic-sdlc --version` printed `0.14.2`, exit 0. It also confirmed `bin/agentic-sdlc` is a 3.2KB POSIX shell wrapper that builds on demand, not a checked-in compiled binary. |
| AC-03-cross | CP-3v | PASS on the substance | Both copies of `testdata/fingerprint-agreement.json` are byte-identical: `sha256 cd832b3b71d348f60de38094c770d32c0665745a7d4ef337c3a34202ab699603`, `expected_fingerprint sha256:924ca52daf…` in both. `cadre-lifecycle`'s `frozen_test.go` imports only its own kernel; the selector does not exist in that repository. cadre's `frozen_test.go` imports only the selector. |
| AC-boundary | CP-3v | PASS | Independent import dump of all 78 kernel `.go` files: exactly four (`echo.go`, `fingerprint.go`, `init.go`, `repair.go`) import a repository package, and all four import the same one. `canonicaljson.go` imports stdlib only. |
| AC-nocadre | CP-3v | PASS | Full-tree grep for `deagy/cadre/cli` returned zero hits, exit 1. |
| AC-fixture-honest | CP-3v | PASS | Fixture bundle is four files with an empty agent catalogue, against cadre's 1,421-line catalogue plus 159 `codex-agents/*.toml`. Kernel test code references only the local `testdata/provider` path. Confirmed not a copy. |

**Verdict returned: FAIL:fixable.**

The verifier's failure is factually correct and its scope is right: cadre still contains a full copy of `internal/kernel` and still runs `agreement_test.go` and `fixture_test.go`, which import both implementations and compare them in-process — the pattern the design says cannot exist after the split.

Two things about that finding, recorded so the verdict is not misread later.

**It is scheduled, not a defect.** T-05 deletes the kernel from cadre, sequenced last on purpose: "so every prior step is verifiable against a working tree that still has both halves." The verifier was given the extraction's context but not the task ordering, so it measured against the end state rather than T-02's. That is the correct behaviour for a verifier — it should not be told which failures to excuse — but the verdict is a statement about P1, not about T-02.

**The criterion wording was mine and it was ambiguous.** AC-03-cross said "cadre's imports the selector and NOT the kernel". I meant `frozen_test.go`; the verifier read it as the package, which is the stricter and more defensible reading. The FAIL follows from my phrasing, not from the work.

**A real risk it surfaced, which was not in the plan.** Two live copies of the kernel now exist — cadre's and cadre-lifecycle's, near byte-identical, differing only in import path — and nothing checks that they agree. Until T-05 deletes one, a change to either drifts silently. That is the same defect class this whole ultragoal exists to remove, temporarily reintroduced by the migration itself. It argues for keeping the window between T-02 and T-05 short, and for not treating cadre's copy as editable in the meantime.

## T-03 — vendor the contracts back into cadre (cadre `3df17e0c`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-04 | CP-3 | PARTIAL | `kernel-contracts/` holds the two contracts the roster side reads, with `TestVendoredKernelContractsMatchTheKernel` comparing them to the kernel's own copy. Falsified both ways: perturbing the vendored file fails naming the resolved source (`~/sdk/cadre-lifecycle/kernel/contracts`), and pointing `KERNEL_CONTRACTS_DIR` at a divergent source fails naming the file. AC-04 also requires no third definition to exist, which is P2's job. |
| — | CP-3 | PASS | Cadre's replacement for the guard the kernel lost: `TestOurProviderBundleAcceptsTheKernelWeDependOn` asks an installed kernel for its version and checks it against `provider/provider.json`'s window. Falsified by narrowing the window to exclude the reported version. |
| — | CP-3 | PASS | `CGO_ENABLED=1 go test -tags sqlite_fts5 ./...` green. |

### The plan undercounted again

It named two roster-side readers of `kernel/contracts`. There are five: `internal/selector/golden_corpus_test.go`, `internal/selector/humangates_test.go`, `internal/engine/export/export_test.go`, `internal/engine/planning/planning_test.go`, `internal/engine/contracts/contracts_test.go`. The two it named turned out to be comment references, not reads. Second inventory miss in this phase, after `provider/`.

### A fragility the full suite caught in my own test

The compatibility guard first fell back to building the kernel from the sibling checkout on demand. It passed in isolation and failed in the full package run with `exit status 1`: another test in `internal/orchestration` narrows the environment for its own purposes, the wrapper lost its Go toolchain, and the failure surfaced as an error from a command unrelated to the test that broke it.

A guard whose result depends on which other tests ran is worse than one that skips, because it fails for reasons that are not about the thing it guards. It now requires an already-built binary — which is the honest subject anyway, since the question is whether a consumer's installed kernel would accept the bundle.

### Environment note

The installed kernel on this machine is `~/.local/bin/agentic-sdlc` at **0.13.2**, while the extracted repository is at **0.14.2**. Cadre's window is `[0.13.2, 1.0.0)` so both pass, but the guard is currently checking the older one. Worth knowing before T-06 publishes anything.

## T-04 — the kernel's build and CI (cadre-lifecycle `df306e1`)

| AC | CP | Result | Observation |
|---|---|---|---|
| — | CP-3 | PASS | `make build` produces a binary reporting `0.14.2`. `make cross-build` produces all five platform binaries from this one host. `make clean` removes them. |
| — | CP-3 | PASS | `CI=true go test ./...` green, so guards written to skip locally and fail under CI do not silently pass there. |

### The kernel is cgo-free, and that does not follow it out of cadre

`go mod tidy` dropped three direct dependencies inherited from the copied `go.mod`: `mattn/go-sqlite3`, `modelcontextprotocol/go-sdk`, `gopkg.in/yaml.v3`. Two remain, and neither needs a C toolchain.

Verified rather than assumed: `CGO_ENABLED=0 go build ./cmd/agentic-sdlc` produces a binary that runs and reports `0.14.2`, and all five cross-build targets compile from a single host.

This is the fragility that stays behind. cadre's knowledge store links sqlite through cgo, which is why `bin/cadre` builds cgo-first and retries without, why a `CGO_ENABLED=0` build there links cleanly and then fails at runtime on every `cadre knowledge` call, and why a bare `go test ./...` in cadre fails three packages until you use the repo's real invocation. The kernel never had that problem — it inherited the dependency list that implied it, and tidying removed it.

### Cadre's half of T-04 was deliberately moved

The plan put cadre's `Makefile` and `release.yml` removals here. They go with T-05's source deletion instead, so that no commit leaves cadre holding kernel source it has no way to build. Sequencing change, not a scope change.

## T-05 — delete from cadre — **INCOMPLETE, ESCALATED** (cadre `11eefd47`)

AC-02 requires the three paths absent *and* the full suite green. The paths are gone; the suite is not green. No PASS row.

### Verified before deleting
File-by-file comparison of `internal/kernel` against the extracted copy: all 84 files present, plus the four fixture files added there. Only four files differed beyond the import path, and those are exactly the four deliberately edited during T-02. Nothing was lost.

### Done
Deleted `internal/kernel/`, `cmd/agentic-sdlc/`, `kernel/`, `bin/agentic-sdlc`, and the two canonicaljson tests that import the kernel; `frozen_test.go` made self-contained and passing as the surviving half. Kernel build target and cross-build legs out of the `Makefile`; `kernel-publish` job out of `release.yml`; kernel dropped from `internal/release`'s program list and the release gate's watched components. Three contracts vendored to `kernel-contracts/`, seven readers repointed. Fixture kernel root built for the engine's tests from the vendored contracts plus this repository's own provider defaults.

Green: `internal/cli`, `internal/release`, `internal/orchestration`, `internal/selector`, `internal/canonicaljson`, `internal/engine/{contracts,state,validate,enginecli}`.

### Red — four packages
- `internal/engine/provider` — `TestKernelVersionMatchesTheKernel` compares cadre's provider version against a kernel that is no longer in the tree
- `internal/engine/runtime`, `internal/engine/service` — planning against shipped contracts
- `internal/generators` — the packaged distribution still names removed lifecycle paths (`TestNothingInTheDistributionNamesARemovedLifecyclePath`, `TestEveryRelativeLinkInTheDistributionResolves`, `TestGeneratePluginPackage`)

### Why this stopped rather than continued

The plan estimated two roster-side contract readers. There were seven. Beyond them the release program model, the release gate's watched components, the engine's kernel-root resolution, and the provider version coupling each held the kernel in a way the inventory did not predict — **four separate discoveries after the deletion began**, each found by a guard failing rather than by reading ahead.

That pattern is informative rather than alarming: cadre's tests are unusually good at naming exactly what broke, which is why every step so far has been mechanical. But a phase whose scope quadruples mid-execution, in a real repository, is a decision point rather than a thing to push through. Everything is on an unmerged branch and nothing has been pushed.

### The three inventory misses, for the retro
1. `provider/` — the kernel's tests loaded cadre's real role-catalog bundle (found at T-02)
2. Five contract readers the plan did not name, then two more (found at T-03 and T-05)
3. The release model, release gate, engine kernel-root and provider version couplings (found at T-05)

All three are the same failure: the plan inventoried what *imported* the kernel and what *named* it in prose, and never inventoried what *read its data* or *modelled it as a component*.

## T-05 — completed (cadre `dd521e6f`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-02 | CP-3 | PASS | `internal/kernel/`, `cmd/agentic-sdlc/` and `kernel/` are absent. `CGO_ENABLED=1 go test -tags sqlite_fts5 ./...` green across every package. `generate-plugin --check`, `generate-role-metadata --check` and `generate-authority-aides --check` all report current. |
| AC-03 | CP-3 | PARTIAL | The fixture half is met and independently verified: byte-identical fixtures, `sha256 cd832b3b…`, each repository reproducing `sha256:924ca52daf…` from its own implementation alone. The end-to-end half is blocked — see below. |

### What the last four packages needed

`internal/engine/{runtime,service,enginecli}` all resolved contracts from a kernel *installation* root. `internal/engine/kernelfixture` now builds that shape from the vendored contracts plus this repository's own provider defaults, so the tests need neither a kernel installed nor a duplicate of the deleted `kernel/contracts/` path.

`internal/engine/provider`'s `KernelVersion` stopped being a mirror and became a **pin**. Its guard read the kernel's source, which worked while the kernel was here. Reading whatever kernel is installed instead would be worse — an older binary on one machine is an environment fact, not a repository defect. The check is now that the pin sits inside cadre's own provider window, which is the failure that bit twice in the Python: the engine believed 0.13.0 while the bundle required 0.13.2, so loading this repository's own provider failed. Falsified by reproducing exactly that.

`internal/generators` was the same root cause nine times: plugin generation shelled out to `./cmd/agentic-sdlc --version` to stamp the kernel version into each plugin's download shim. It reads the pin now. The original reasoning — that parsing a constant would be a second reader free to drift from the binary — held while the binary was in-tree. The risk moved rather than vanished: it was a stale binary, and it is now a pin that could name a version nobody released.

### AC-03 has an ordering dependency I wrote and did not notice

AC-03 reads: "A plan from `cadre select` is accepted by the **released** `agentic-sdlc validate` (exit 0)". There is no released kernel — releasing requires pushing, which is T-06, which comes after T-05. The criterion cannot be met in the phase that was supposed to meet it.

Attempted against a locally built kernel anyway, and it needs more than a binary: `cadre select --root` requires a git repository, and the kernel refuses `--profile secure-cloud` because a standalone kernel carries only its fixture profile and must be pointed at a provider bundle. A real end-to-end run means wiring an installed kernel to cadre's provider bundle — integration setup, not a smoke check.

Recorded rather than faked. The property AC-03 exists to protect — that the two sides fingerprint identically — is proven by the frozen fixture on both sides and confirmed byte-identical by a fresh-context verifier. What is unproven is that the whole pipeline runs, and that belongs after T-06.

## T-06 — published (cadre-kernel `a188b58`) — CP-6 approved, CP-5 observed

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-01 | CP-5 | PASS | Observed on the artifact rather than the tool return. `git ls-remote https://github.com/deagy/cadre-kernel main` → `a188b589dc37854c98570ba3df378662ff5609a7`, identical to local HEAD. A **fresh clone from GitHub** builds (`go build ./...`), tests green (both packages `ok`), and `./bin/agentic-sdlc --version` prints `0.14.2`. |

Repository: `https://github.com/deagy/cadre-kernel`, public, `main`.

### The name, and a citation I got wrong

`cadre-lifecycle` was the working name for four tasks. It is taken: `deagy/cadre-lifecycle` exists, is public, and has been **archived since 2026-08-07**. It was the generated plugin distribution — `cadre-ref.txt` names the `deagy/cadre` revision its content was generated from, and its final release reads "v0.11.0 — final release, marketplace moved to deagy/cadre". `gh repo create` refusing the name is the only reason this was found before a push.

The plan and this ultragoal's STATUS both cited `RUNBOOK.md:823` as naming `cadre-lifecycle` the extraction target. It does not. The clause is "propagating into generated role wrappers or the public `cadre-lifecycle` repo" — about generated content leaking into that distribution repo. Misread, and the misreading reached the plan, STATUS, and the question put to the user. Corrected in both documents.

`cadre-kernel` is what the thing is called throughout cadre's own source: `internal/kernel`, `kernel/contracts`, `kernelVersionFile`. `agentic-sdlc` stays the binary name — what consumers already set `AGENTIC_SDLC_BIN` to — and was not taken as the repository name because `kernel/README.md` records that `agentic-sdlc` on PyPI is unrelated third-party software.

### Before publishing

A credential scan and a `/home/deagy` path scan over the whole tree both came back empty. The module path was rewritten from `cadre-lifecycle` to `cadre-kernel` before the first push, so no published commit ever carried the wrong module name. cadre's drift check now resolves the renamed sibling and still passes non-vacuously — cadre's own `kernel/contracts` is deleted, so the sibling is the only candidate it can be reading.

## P1 status: two criteria cannot close in this phase

- **AC-03** — the fixture half is proven and independently verified. The end-to-end half needs a *released* kernel plus an installed kernel wired to cadre's provider bundle. Releasing is downstream of this push; the wiring is integration setup.
- **AC-04** — the vendored copies and their drift check exist. "No third definition" also requires `agentic-lifecycle`'s schemas to go, which is P2.

Both are dependencies the phase decomposition did not surface when the spec was written: AC-04 spans P1 and P2 by construction, and AC-03's wording (`released`) puts half of it after T-06 rather than inside it.

## Release and merge — CP-6 approved, CP-5 observed

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-01 | CP-5 | PASS | `v0.14.2` published at `deagy/cadre-kernel` by its own workflow: five platform archives plus `SHA256SUMS`. Verified by downloading `agentic-sdlc-v0.14.2-linux-arm64.tar.gz` from the release and running it — reports `0.14.2`, the version its name promises. |
| AC-02 | CP-5 | PASS | cadre `main` at `1ed3169a`, pushed and confirmed by `git ls-remote`. `kernel` and `internal/kernel` both absent from the **published** tree, checked against the GitHub contents API rather than the local checkout. Full suite green and all three generator checks current on the merged tree before pushing. |

### The shim would have kept working, and still had to move

cadre's lifecycle plugin resolves a kernel by version from a hardcoded release base. It pointed at this repository's `kernel-v` tags, and those still resolve — `kernel-v0.14.2` is published on cadre and returns 200, so nothing was broken.

But cadre no longer builds the kernel, so that tag line stops at the last version it published. A plugin generated tomorrow would resolve a version that only ever existed in the old home. The shim now points at `deagy/cadre-kernel`'s `v*` tags, archive names unchanged since it resolves them by name, and the URL the generated shim builds for `v0.14.2` linux-arm64 was verified to return 200.

Found only because the release was cut before the merge. Merging first would have published a cadre whose plugins fetched from a line that had ended.

### Ordering that mattered

Release before merge, so cadre never landed pinning a kernel version with no release behind it. `provider.KernelVersion = "0.14.2"` now names a version that exists as a published artifact.

## P1 — all six tasks complete

AC-01 and AC-02 closed with observed evidence. AC-03's end-to-end half is now **unblocked** rather than met: a released kernel exists, so the run is possible, but it still needs an installed kernel wired to cadre's provider bundle. AC-04 still needs P2.
