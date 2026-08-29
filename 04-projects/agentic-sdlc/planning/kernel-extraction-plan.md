---
type: "plan"
project: "agentic-sdlc"
title: "Extracting the lifecycle kernel from cadre"
status: "draft"
created: "2026-08-28"
source_repo: "~/sdk/cadre @ 180a00ca"
target_repo: "cadre-lifecycle (named in roster/RUNBOOK.md:823, not yet created)"
tags: ["#plan", "#agentic-sdlc", "#architecture"]
---

# Extracting the lifecycle kernel

The extraction is mostly already done. `internal/kernel` imports exactly one package outside itself, the ownership boundary is enforced by a test that predates this plan, and the distribution model already treats the kernel as an externally-versioned binary that consumers download. What remains is moving files, resolving one shared package, and splitting the release.

Facts below were read from `~/sdk/cadre` at `180a00ca` on 2026-08-28.

## Decide the scope first

There are two lifecycle components, not one, and the plan forks on which of them moves.

**`internal/kernel`** — 79 files, 16,857 non-test lines. Contracts, run-record validation, gate-authority semantics. Ships as `cmd/agentic-sdlc`.

**`internal/engine`** — 6,787 non-test lines across `runtime`, `state`, `executor`, `planning`, `service`, `githubapproval`, `gitlabissue`, `a2a`, `provider`. `cmd/agentic-sdlc-engine/main.go` opens with "drives a task through the G1-G10 lifecycle."

The kernel holds the contracts; the engine drives tasks through them. A lifecycle repository shipping contracts without the driver is half a product, which argues they move together. Against that, `kernel_boundary_test.go` deliberately lists `engine` among the roster-side packages that must ask rather than link, and the engine carries GitHub and GitLab integrations that are orchestration-flavoured.

**Recommendation: move the kernel alone first.** It is the piece with a single internal dependency and an already-separated distribution path. The engine's own coupling to the kernel is currently "ask, don't link", so it keeps working across a repository boundary unchanged — which means moving it later costs nothing that moving it now saves. Deciding both at once turns a mechanical move into a design argument.

## What moves

| Path | Size | Note |
|---|---|---|
| `internal/kernel/` | 79 files, 16,857 non-test lines | Imports only `internal/canonicaljson` |
| `cmd/agentic-sdlc/` | 1 file | Imports only `internal/kernel` |
| `kernel/` | README + `contracts/` (10 JSON schemas) | Source of truth for the contracts |
| `bin/agentic-sdlc` | 1 shell script | Same build-on-first-use wrapper shape as `bin/cadre` |

`internal/kernel/contracts/` is an embedded copy of `kernel/contracts/`, held in step by `TestEmbeddedContractsMatchTheSourceOfTruth`. Both sides move together and that test comes with them unchanged.

**Amended 2026-08-28 during the move.** This inventory missed a coupling. Four kernel tests read a provider bundle from the repository root — `TestTheKernelVersionIsInsideEveryProviderCompatibilityWindow`, `TestInitInitialisesIntoABlockedState`, `TestInitNeverOverwrites`, `TestADryRunWritesNothingAtAll`. `provider/` is cadre's role-catalog bundle (`agent-catalog.json`, `roles/`, `codex-agents/`, `profiles/`, `extensions/`), which cadre's README calls the bundle "contributed to the kernel". It is roster data flowing into the kernel and correctly does not move.

The consequence was a circularity invisible while both lived in one repository: the kernel's own suite could not pass without the roster's data. The kernel now carries a minimal fixture bundle under `internal/kernel/testdata/provider/` — a manifest, a wide compatibility window, an empty agent catalogue, one profile declaring the ten gates with no contributions. It exercises `LoadProvider`; it describes no real provider.

Three of those tests also named the profile `secure-cloud`, one of cadre's two profiles rather than a kernel concept. Left as a literal it would have reintroduced the same coupling as a string, so it is now a `fixtureProfile` constant.

`TestTheKernelVersionIsInsideEveryProviderCompatibilityWindow` is deliberately demoted. Its real guard was that a kernel whose version fell outside its own shipped bundle's window would refuse it; the kernel now ships no bundle. That guard belongs to the consumer, so cadre gains a test that its `provider/provider.json` window contains the kernel version it depends on, run against the released binary. Add it in T-03.

## Baseline, measured 2026-08-28 at `180a00ca`

All five boundary tests pass: `TestNoRosterSidePackageImportsTheKernel`, `TestTheKernelDoesNotImportRosterSideCode`, `TestANeutralPackageStaysNeutral`, `TestTheKernelShipsAsItsOwnBinary`, `TestThisRepositoryRunsNoLifecycleOverlayOfItsOwn`.

Independently of the tests, exactly three files in the repository import `internal/kernel`:

- `cmd/agentic-sdlc/main.go` — the kernel's own binary, and the only non-test importer anywhere
- `internal/canonicaljson/agreement_test.go` — an external test package (`package canonicaljson_test`), compiled only for `go test` and linked into nothing
- `internal/kernel/kernel_boundary_test.go` — the guard itself

Zero roster-side imports. The boundary is not merely asserted; it is real at `180a00ca`.

## The agreement test is the hard problem

`internal/canonicaljson` is 217 lines used by both halves — five files in `internal/kernel`, plus `internal/selector/canonical.go` and `internal/engine/provider/provider.go`. Copying it into the kernel repository is the easy call, and the earlier framing of this section stopped there. The real problem is the test that sits on top of it.

`internal/canonicaljson/agreement_test.go` imports **both** `internal/kernel` and `internal/selector`. Its own comment states why, and why it lives where it does:

> The selector and the kernel must fingerprint a dispatch plan identically. This is not a style rule. `cadre select` writes a plan and stamps it with a fingerprint; `agentic-sdlc validate` recomputes that fingerprint from the plan's own content and rejects the plan if it differs. The two sides had already disagreed once, over whether `provenance` belongs in the hashed payload, and the consequence was total: the kernel rejected every plan the selector produced, and the error said the plan had been tampered with.
>
> The two implementations stay separate — each exclusion set is part of its own side's contract — so this test is the thing holding them together. It lives in neither package for that reason: put it in one and it becomes that side's opinion of itself.

After extraction, no repository can import both sides. The test cannot survive as written, and it is guarding a failure that has already happened once and was total when it did.

Two replacements, and both are needed:

**A golden fixture in each repository.** Freeze `planWithEverything()` — which deliberately carries all three excluded keys, because "a plan without them agrees trivially, which is how the original disagreement survived as long as it did" — together with its expected fingerprint. Each side tests its own implementation against the frozen pair. Either side changing its exclusion set moves its computed hash off the fixture and fails locally, without needing to see the other implementation. The fixture becomes the contract the prose currently describes.

**An end-to-end check in cadre's CI.** Generate a plan with `cadre select`, then run the released kernel's `agentic-sdlc validate` against it. This uses the shell-out coupling the boundary already permits, and it is the only check that proves the two agree in the versions actually shipped rather than in the versions each repository believes it is compatible with.

Publishing the fingerprint algorithm as a shared module would make both sides agree by construction, and it is ruled out by the design intent recorded above: the separation is deliberate, and each exclusion set belongs to its own side's contract.

## What stays, and how it keeps working

`kernel_boundary_test.go` permits exactly two couplings, and both survive a repository split by construction:

**Shelling out to the kernel CLI.** Already the distribution model. `internal/generators/plugin_generation.go` generates a shim that resolves `AGENTIC_SDLC_BIN` first and otherwise downloads the kernel by `AGENTIC_SDLC_VERSION`, failing with a message naming both options. Nothing about that changes when the source moves; it only becomes true rather than aspirational.

**Reading `kernel/contracts/*.json` as data.** This one needs work. After the move those files are not in cadre's tree, and two roster-side tests read them: `internal/selector/golden_corpus_test.go` and `internal/engine/enginecli/standalone_test.go`.

Vendor a copy into cadre with a drift check against the released kernel. That pattern already exists here — `internal/orchestration/schema_release_drift_test.go` diffs a committed schema against its copy at the last `plugin-v*` release tag, read with `git show`, and fails when they differ. Reuse its shape against the kernel's release tags. Fetching at test time would make the suite non-hermetic; shelling out would make a data read into a process dependency.

## Sequence

1. ~~**Prove the boundary holds today.**~~ Done — see Baseline above. Five tests pass, three importing files, zero roster-side imports.

2. **Replace the agreement test before moving anything.** Land the golden fixture in cadre while both implementations are still importable, so the frozen fingerprint is generated from two sides that currently agree rather than reconstructed afterwards. This is the step that must not be deferred: once the kernel moves, the ability to produce that fixture from live code is gone.

3. **Copy `canonicaljson` into the kernel repository.** A shared module for 217 lines of pure function costs more coordination than the duplication risks, and the fixture from step 2 is what guards the divergence.

4. **Create the repository and move.** `internal/kernel/`, `cmd/agentic-sdlc/`, `kernel/`, `bin/agentic-sdlc`, plus the `canonicaljson` copy. New module path; rewrite imports mechanically. Verification: the kernel's own suite passes standalone, and `bin/agentic-sdlc --version` builds and runs from a clean checkout.

5. **Vendor the contracts back into cadre with a drift check.** Point the two roster-side tests at the vendored copy. Verification: both tests pass, and the drift check fails when the vendored copy is edited by hand.

6. **Split the build and release.** Cadre's `Makefile` builds `agentic-sdlc` for four platforms at `CGO_ENABLED=0` (lines 123-126) and the engine for three at `CGO_ENABLED=1`; `.github/workflows/release.yml` packages both. The kernel's targets move to the new repository's release; cadre's keep only what it still ships.

7. **Delete from cadre and re-verify.** Add the end-to-end `cadre select` → `agentic-sdlc validate` check to CI here. Full suite under the real invocation — `CGO_ENABLED=1 go test -tags sqlite_fts5 ./...` — plus `generate-plugin --check`, `generate-role-metadata --check`, and `generate-authority-aides --check`. An integrated `cadre select` run should still enrich with lifecycle gates via the downloaded or `AGENTIC_SDLC_BIN`-resolved kernel; that is the end-to-end acceptance, and it is the one thing no unit test covers.

## Risks

**Version coupling becomes real.** Today cadre and the kernel move together. After the split, cadre pins a kernel version and a contract change becomes a two-repository release. The existing `schema_version` discipline — every change to an emitted field set increments, with the drift check enforcing it — is what makes this survivable, and it has to extend across the boundary rather than stopping at it.

**16,857 lines is not a small move.** The relocation is mechanical, but the CI and release split is not, and step 5 is where an extraction like this usually stalls.

**The engine's status stays unresolved.** Moving the kernel alone is the right call, but it leaves a lifecycle driver in the orchestration repository, which will read as wrong to the next person and invite a second argument. Write the reasoning down where they will find it.

## Open questions

- Does `internal/engine` follow later, and if so on what trigger?
- Where does the golden fingerprint fixture physically live so both repositories read the same bytes — vendored in each, or published as a release artifact from one?
- **What is the kernel repository called?** Reopened. `cadre-lifecycle` is taken: `deagy/cadre-lifecycle` exists, is public, and is **archived** as of 2026-08-07. It was the generated plugin distribution — its `cadre-ref.txt` reads "The deagy/cadre revision this repository's generated content corresponds to", and its final release is titled "v0.11.0 — final release, marketplace moved to deagy/cadre". Reusing a retired distribution repo's name for the lifecycle kernel would mislead anyone who saw the first one.

  `RUNBOOK.md:823` was cited in this plan as naming the extraction target. It does not. The full clause is "propagating into generated role wrappers or the public `cadre-lifecycle` repo" — it is about generated content leaking into that distribution repo. **Misread, and the misreading reached this plan, `repo-consolidation/STATUS.md`, and the question put to the user.** Corrected 2026-08-28.

  `agentic-sdlc` remains available as a repository name but collides with unrelated third-party software on PyPI, which `kernel/README.md` already records as a hazard.
- Do the 159 roles ship from cadre, from the kernel repository, or from neither? The kernel README says roster "supplies a role catalog and a provider profile *into* projects that adopt the kernel", which makes the catalog cadre's to publish, but a project adopting only the kernel then gets no roles.
