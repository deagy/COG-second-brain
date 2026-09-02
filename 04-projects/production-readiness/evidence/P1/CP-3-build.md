# P1 — CP-3 build · AC-1, AC-2, AC-3

| Task | Outcome | Artifact |
|---|---|---|
| T-01 | Lifecycle kernel licensed Apache-2.0 | cadre-kernel `8da1b135`, CI run 33629166510 |
| T-02 | gloop settled **internal** by the user, on the evidence | recorded below |
| T-03 | gloop's README and docs made true; deprecated selectors removed | gloop `81b46e01`, CI run 33630353829 |
| T-04 | Licence claims swept across all four | recorded below |
| T-05 | Installer's fetch set enumerated and bounded | recorded below |

## T-01 — the kernel

Public with no `LICENSE`, which is all-rights-reserved by default, while cadre's generated shim downloads it by version at install time. Apache-2.0, matching the repository it was extracted from and the CLI that consumes it.

**Observed at the artifact rather than from the push:** `gh repo view deagy/cadre-kernel --json licenseInfo` now returns *Apache License 2.0*.

## T-05 — AC-2's set, bounded rather than assumed

AC-2 is a universal negative unless the set is named. Read out of `internal/generators/plugin_generation.go`, `install.sh` and `install.ps1`, the complete set of remote hosts the install path touches is:

- `github.com/deagy/cadre` — its own releases and install scripts. Apache-2.0.
- `github.com/deagy/cadre-kernel` — `releases/download/v$AGENTIC_SDLC_VERSION`. Apache-2.0 as of `8da1b135`.

**No third-party downloads at all.** The criterion is satisfiable rather than aspirational.

## T-04 — the sweep, and what it found that the assessment had not

| Repo | Carries | GitHub reports | Claims in its own docs |
|---|---|---|---|
| cadre | Apache-2.0 | Apache-2.0 | Apache-2.0 — consistent |
| cadre-kernel | Apache-2.0 | Apache-2.0 | none — consistent |
| recall | MIT | MIT | MIT — consistent |
| gloop | none | none | none, after T-03 |

recall's one BSD-3-Clause mention is a changelog note about a transitive dependency's licence and a `go-licenses` misclassification — correct, and not a claim about recall.

**The sweep's value was in gloop, where the badges were the visible defect and three more claims sat behind them:** the License section still read *"licensed under the MIT License — see the LICENSE file"*, linking a file that was never there, and two further links pointed at the same 404ing `pkg.go.dev` page. Fixing the two offenders the assessment named would have left all three.

## T-02 — gloop, settled internal

Evidence put to the user, each item falsifiable:

- Nothing imports it. Checked across cadre, recall and cadre-kernel.
- The only caller of the deprecated selectors was gloop's own CLI.
- The deprecation notice had never shipped — it lived only in `[Unreleased]`, 39 commits past `v0.2.0`.
- `pkg.go.dev/github.com/deagy/gloop` returned 404 while the README carried its badge.

**Due diligence before recommending, since publication is irreversible:** the one secret-shaped hit in 349 tracked files is a redaction *test fixture* (`sk-abc123…` → `sk-a****…`, asserting the logger masks keys). The only other exposure is local absolute paths in review docs and test fixtures — cosmetic, though they violate cadre's own "omit local paths by default" rule. Publishing would have been safe; the decision was made on audience, not risk.

**Consequence: repo-consolidation's `AC-07b` closes.** It was deferred there because removal needed a major release, and the release it was waiting for was a promise to nobody.

## What the removal actually cost

44 prose references across 10 files. The five dated review documents were left untouched — correcting a dated record falsifies it, the same principle that keeps `orchestration/runs/` out of cadre's drift guard.

**The claim that the five live documents were rewritten was false when first written here, and CP-3v caught it.** `docs/ROSTER.md` had its banner rewritten and not its body; `docs/ARCHITECTURE.md` and `docs/ROSTER_PEER_EXCHANGE.md` were never touched. Eight references survived across the three, including a worked example of a command that no longer exists. Finished in gloop `8c5e4a4`.

The claim came from having edited the files rather than from re-reading them — the same shape as the defect the sweep existed to remove, one level up.

**Two defects surfaced only by sweeping**, and one of them was mine:

- `gloop dispatch` has no `--provider`/`--model` flags. Those lived on the removed command. An edit repointing the README at `dispatch` **introduced a false claim**, caught by running `gloop dispatch --help` rather than trusting the edit. Both instances corrected to name where the pinning actually lives.
- The root command's own help still advertised `gloop select`, as did the roster command's long text and its examples — three places the README sweep would not have reached.

**`internal/docguard` caught two of these itself** — the deprecation-parity check added that morning, firing on its author's change — and exposed a gap in its own skip list: it recognised "not deprecated" as a correction but not "never deprecated", which says the same thing. Widened.

## Carried

Only recall gates on licences in CI, and even that runs `go-licenses check`, which validates *dependency* licences and would not have caught "this repository has no LICENSE". **Nothing in any of the four would have caught the kernel.** A control for AC-1's durability is a candidate, deliberately not built mid-phase.
