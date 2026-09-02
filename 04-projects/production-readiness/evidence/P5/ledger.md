# P5 — evidence ledger · AC-6, AC-7

Merged from CP-3v, CP-4 and CP-5. Rows are appended as each verifier reports.

## Releases cut in this phase

| Repository | Release | Verified how |
|---|---|---|
| cadre-kernel | `v0.14.3` | archive downloaded, `LICENSE` present, binary reports `0.14.3`, checksum matched by hand |
| cadre-kernel | `v0.14.4` | `SHA256SUMS` carries bare names; archive carries `LICENSE`; binary reports `0.14.4` |
| recall | `v0.3.3` | 13 assets; `recall-0.3.3-linux-arm64` downloaded and run, reports `recall version v0.3.3` |
| cadre | `cli-v0.7.0`, `plugin-v0.24.0` | published from a commit whose `validate` was red — superseded below |
| cadre | `cli-v0.7.1`, `plugin-v0.24.1` | see CP-5 |
| gloop | none, by decision | reason recorded in the repository's own README, not only here |

## AC-6, measured (2026-09-02)

Published releases, from `gh release list` rather than `git tag`:

| Repository | Releases that exist |
|---|---|
| cadre | `cli-v0.7.x`, `plugin-v0.24.x`, and the historical lines below them |
| cadre-kernel | `v0.14.4`, `v0.14.3`, `v0.14.2` |
| recall | `v0.3.3`, `v0.2.0`, `v0.1.0` |
| gloop | none |

**A tag is not a release, and this phase turned on the difference.** recall carries
tags `v0.3.0`, `v0.3.1` and `v0.3.2` with no release behind any of them. Measuring
AC-6 with `git describe` would have reported recall released at `v0.3.1` and hidden
the defect the criterion exists to catch.

## CP-3v

**Round 1 — FAIL:fixable, 15 claims.** `CP-3v-round1.md`. Found T-08 independently by
reproducing `install.sh`'s own sequence with Go stripped from PATH, and stated the
defect better than the build record had: *the new tests only exercise
`PackagedKernelShim` as a Go function with a hand-supplied repoRoot — none exercise
what value the shell launcher actually passes on the no-Go path.*

**Round 2 — PASS, 17 claims.** `CP-3v-round2.md`. Reproduced round 1's failing
sequence at `cli-v0.7.5`: `cadre sdlc --version` prints `0.14.4` at exit 0, with no
`.cadre-build-cache` created — proof the Go path was never used and the fallback is
what answered. Every new guard falsified by mutation, none by failing to compile.

It also caught a measurement trap the phase would otherwise have carried: **`git
rev-parse cli-v0.7.5` returns the annotated tag's own object SHA, not the commit.**
Without `^{commit}` the comparison reads as a gap between the release and `HEAD` when
there is none — which is exactly what round 1's AC-6 FAIL was measuring at the moment
the phase was still moving.

## CP-4 — PASS, 17 claims

`CP-4-integration.md`. It ran its own container rather than reading the phase's log,
and confirmed the cross-phase properties the criterion does not name: P2's marker
walk does not alias the global store, P3's `observed_actor` populates in the
installed binary, and P4's flag-name-versus-value distinction holds at exit 2 versus
exit 1. Kernel version agreement across five sources, the shim's matcher against the
real `SHA256SUMS`, recall's fail-closed-contract checkout and gloop's vendored-fixture
guard all check out against live green runs.

### The finding, and what was done about it

**Five superseded cadre releases were still live, unmarked and pinnable**, and each
was broken in its own way rather than merely missing a later improvement:

| Release | What is wrong with it |
|---|---|
| `cli-v0.7.0` | cannot resolve a kernel at all; published from a red `validate` |
| `cli-v0.7.1` | no `linux/arm64` CLI binary, and the message names `linux/arm64` |
| `cli-v0.7.2` | the kernel fallback is not reached on the toolchain-less path |
| `cli-v0.7.3` | same, for the packaged launcher |
| `cli-v0.7.4` | works, but `cadre doctor` misdiagnoses it |

`docs/INSTALL.md` invites pinning by tag — *"If your policy requires a pinned
source, append `@<tag>` … and own keeping it current"* — and GitHub marks nothing.

All five, the five matching `plugin-v0.24.x`, and kernel `v0.14.2` and `v0.14.3` are
now **pre-releases with a note saying what is wrong and where the fix is**.
Re-fetched and confirmed: `gh release list` shows `Pre-release` on each, and the
warning is the first line of each body.

The kernel pair matters beyond tidiness: `v0.14.2`'s archives carry no licence text
at all, and `v0.14.3`'s checksums cannot be matched by the shim that installs it. A
release nobody can install, left looking installable, is the same shape as a tag with
no release behind it — the defect this phase opened by finding.
