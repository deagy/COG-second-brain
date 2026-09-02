# CP-4 integration verification — production-readiness P2 (AC-8)

VERDICT: FAIL:fixable
INTEGRATION_CLAIMS_CHECKED: 6

## EVIDENCE

EVIDENCE AC-8 | CP-4 | PASS | The three callers CP-3v did not check (`internal/config/files.go` → `.agents/cadre.yaml`/`.json`, `internal/config/shared_overlay.go` → roster/shared overlay, `internal/cli/select_go.go` → routing-overlay.json) all resolve through the same `platform.FindFileAtProjectRoot` and none special-case `$HOME`; full suite (`CGO_ENABLED=1 go test ./...`, matching `validate.yml`'s `CGO_ENABLED=1 go test -tags sqlite_fts5 -race ./...`) is green including `internal/config`, `internal/knowledge`, `internal/contextstore`, `internal/cli`. A `CGO_ENABLED=0` run (this shell's default) fails 20 sqlite-backed tests with "Binary was compiled with 'CGO_ENABLED=0'" — an environment artifact, not a P2 regression; confirmed by re-running with `CGO_ENABLED=1`. | `/home/deagy/sdk/cadre` test run, `.github/workflows/validate.yml:199`

EVIDENCE AC-8 | CP-4 | PASS | P1's AC-2 evidence (`evidence/P1/CP-5-acceptance.md:5`) reads cadre's fetch set from `plugin_generation.go`/`install.sh`/`install.ps1` as `github.com/deagy/cadre` + `github.com/deagy/cadre-kernel`. That shim (`internal/generators/plugin_generation.go:283`) already pointed at `deagy/cadre-kernel/releases` before P2 touched anything. P2's removed `release.yml` kernel-publish job watched `internal/kernel/provider.go`, which the earlier kernel split (`11eefd47 WIP: delete the lifecycle kernel from cadre`) had already deleted from this repo — it was dead scaffolding, not what made P1's claim true. `cadre-kernel` independently carries `LICENSE` (Apache-2.0, `8da1b13`) and a published `v0.14.2` release. P1 and P2 are consistent. | `/home/deagy/sdk/cadre-kernel` (`git log`, `gh release list`), `/home/deagy/sdk/cadre` `internal/generators/plugin_generation.go:195-283`

EVIDENCE AC-8 | CP-4 | PASS | `.github/workflows/release.yml` parses (`yaml.safe_load`); jobs are exactly `changed`, `plugin`, `cli`, `cli-publish`; `needs:` graph is `plugin→changed`, `cli→changed`, `cli-publish→[changed, cli]` — no job references `needs.changed.outputs.kernel`, and the `changed` job's `outputs:` block no longer declares a `kernel` output. Job graph is intact for what it publishes. | `/home/deagy/sdk/cadre/.github/workflows/release.yml`

EVIDENCE AC-8 | CP-4 | PASS | Issue #249's closing claim — "the Go gate is unconditional... `internal/cli/knowledge.go:389`" — verified independently by reading `resolveRetrievalScope` (unconditional `len(sources)==0 && !allSources` check, no tier branch) and by building the binary and running `cadre knowledge search --classification public "q"` with no `--source`/`--all-sources`: refused identically (exit 2, same error text) both from a directory under a git-less `$HOME` (would have aliased to global-fallback pre-fix) and from a project-local `.git` directory. | `/home/deagy/sdk/cadre/internal/cli/knowledge.go:377-408`; live run of `/tmp/claude-1000/cadre-test`

EVIDENCE AC-8 | CP-4 | PASS | P2's traceability is correctly scoped: `evidence/P2/CP-2-plan.md` and `CP-3-build.md` map all four tasks (T-01..T-04) to AC-8 only; no AC-4/5/6/7/3b claim appears anywhere in P2's evidence. `spec.md`'s traceability matrix still lists AC-8 as "pending" (expected — CP-4/CP-5 for P2 haven't landed yet) and does not overclaim closure of any other AC. | `evidence/P2/CP-2-plan.md`, `evidence/P2/CP-3-build.md`, `spec.md:74-79`

EVIDENCE — | CP-4 | INFO | `STATUS.md` still reads "P2 ... not started" even though CP-2 and CP-3 have already passed per `evidence/P2/evidence/checkpoints.tsv` (`2026-09-02T13:02:22Z CP-2 PASS`, `2026-09-02T13:20:19Z CP-3 PASS`). Consistent with the normal lag of updating STATUS.md at phase-gate close rather than per-checkpoint; not itself a wiring defect, but will read stale until this CP-4 (and CP-5) land and STATUS.md is refreshed. | `STATUS.md`, `evidence/P2/evidence/checkpoints.tsv`

## Gate scripts (verbatim)

### ci-status.sh (cadre, cadre-kernel, recall, gloop)
```
deagy/cadre                  0f4bd58c  success run 33635041600
deagy/cadre-kernel           8da1b135  success run 33629166510
deagy/recall                 3ee2795f  success run 33537575047
deagy/gloop                  04c356ad  success run 33633218009
```
Exit 0. cadre's HEAD commit and CI run match the task's cited `0f4bd58c` / `33635041600`.

### phase-gates.sh 04-projects/production-readiness
```
P1     all required checkpoints recorded
P2     NEVER RUN: CP-3v CP-4 CP-5
P3     NEVER RUN: CP-3 CP-3v CP-4 CP-5

phase-gates: 2 phase(s) never ran a required checkpoint.
  An absent checkpoint is not a pass. It means the gate was never asked,
  which leaves the same evidence bundle behind as a clean run.
```
Exit 1.

### spec-lint.sh 04-projects/production-readiness
```
spec-lint: clean.
```
Exit 0.

### evidence-lint.sh 04-projects/production-readiness
```
evidence-lint: clean.
```
Exit 0.

### citation-lint.sh 04-projects/production-readiness
```
citation-lint: 10 commit citation(s), 5 vault path(s) checked.
citation-lint: every citation resolves.
```
Exit 0.

## FAILURES

- CP-3v-for-P2 | No CP-3v evidence exists for P2, contrary to the dispatch instruction that "CP-3v already passed per task." `evidence/P2/` contains only `CP-2-plan.md` and `CP-3-build.md`; `evidence/P2/evidence/checkpoints.tsv` has rows for CP-2 and CP-3 only (no CP-3v row); no `CP-3v-*.md` file exists under `evidence/P2/` (contrast P1, which has `CP-3v-round1/2/3.md`). `phase-gates.sh` independently confirms: `P2  NEVER RUN: CP-3v CP-4 CP-5`. Observed vs expected: expected a recorded CP-3v PASS row/artifact for P2 before CP-4 runs; observed none. This is a ledger/evidence-completeness gap, not a defect in the AC-8 fix itself — every substantive cross-task wiring check in this report passed. Fix: either locate and file the missing CP-3v evidence (if it was actually run) or run CP-3v for P2 and record it, then re-run phase-gates.sh to confirm clean before CP-5.

## Repository state (left clean)

All five repositories (`cadre`, `cadre-kernel`, `recall`, `gloop`, `cog-second-brain`) confirmed `nothing to commit, working tree clean` after this verification. No files were edited. Build artifacts (`/tmp/claude-1000/cadre-test`, scratch git-init directories under `/tmp/claude-1000/`) are outside all four repositories.
