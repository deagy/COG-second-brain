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
