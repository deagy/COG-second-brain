# CP-4 integration verification — production-readiness P3 (AC-4)

Artifacts: `/home/deagy/sdk/cadre` at `4da28060` (CI run 33643385856, independently re-fetched green).
CP-3v: 4 rounds recorded (`evidence/P3/CP-3v-round1..4.md`), round 4 **PASS**, not re-verified here per dispatch instruction.
Scope of this report: cross-task wiring and global/cross-phase acceptance only.

## Verdict

**FAIL:fixable**

Every code-level integration check passed: dependency direction is sound, generated trees are idempotent and accurate, all three named read paths surface `observed_actor` correctly (or omit it symmetrically with pre-existing behavior), P3 touched zero files P1/P2's claims depend on, and full test suites plus CI status are green across all four repositories. The one failure is in the traceability documents themselves, not the code: `STATUS.md`'s per-phase table still reads P3 "not started" and its "Next action" section still tells a cold-resuming reader to do P1's licensing work — directly contradicting the same document's own header (`Overall: in progress`) and the six evidence files already on disk for P3 (CP-2 plan, CP-3 build, four CP-3v rounds, the last a clean PASS). This is what check 5 (traceability honesty) was for, and it fails.

## INTEGRATION_CLAIMS_CHECKED: 15

## EVIDENCE

EVIDENCE AC-4 | CP-4 | PASS | `internal/platform` (both `paths.go` and the new `identity.go`) imports only Go stdlib — confirmed by reading both files and by `go list -deps ./internal/platform/...` returning no `cadre/cli/internal/*` package. No cycle is possible: `internal/knowledge` importing `internal/platform` is one-directional. | `internal/platform/identity.go`, `internal/platform/paths.go`, `go list -deps` output
EVIDENCE AC-4 | CP-4 | PASS | No layering rule (test, lint, or doc) forbids `internal/knowledge` → `internal/platform`. This repo's actual boundary-test convention (`internal/contextstore/boundary_test.go`'s `TestNeitherStoreImportsTheOther`, and `cadre-kernel`'s `kernel_boundary_test.go`) guards two *different* boundaries — contextstore↔knowledge and kernel↔rest-of-cadre — neither names `internal/platform`. `.golangci.yml` carries no `depguard` rule. `CADRE_CLI_GO_ARCHITECTURE.md` is an explicitly self-disclaimed historical planning doc ("not this document's specific module layout, phasing, and dependency choices as independently approved"), not an enforced current-state boundary. | `internal/contextstore/boundary_test.go:79-96`; `/home/deagy/sdk/cadre-kernel/internal/kernel/kernel_boundary_test.go`; `.golangci.yml`; `CADRE_CLI_GO_ARCHITECTURE.md:13-16`
EVIDENCE AC-4 | CP-4 | PASS | The `internal/knowledge` → `internal/platform` dependency predates P3: `internal/knowledge/config.go:239` already called `platform.FindFileAtProjectRoot` before P3's first commit. P3 added a second use-site in the same already-importing file (`staged_store.go`), not a new cross-package edge. | `git show 0c5c50ae -- internal/knowledge/staged_store.go` (diff adds the import to a file whose sibling `config.go` already had it)
EVIDENCE AC-4 | CP-4 | PASS | P2's fix (`998ad425`, bounding `FindFileAtProjectRoot` below `$HOME`) touched only `paths.go`; P3's four commits touched only new files `identity.go`/`identity_test.go` in the same package. Zero line-level overlap. `go build ./...`, `go vet ./...` clean; `CGO_ENABLED=1 go test ./internal/platform/... ./internal/contextstore/... ./internal/generators/... ./internal/knowledge/...` all `ok`. | `git diff --stat 998ad425..4da28060 -- internal/platform/`
EVIDENCE AC-4 | CP-4 | PASS | Generated mirror `plugin/suite/roster/knowledge-store/SECURITY.md` matches `roster/knowledge-store/SECURITY.md` verbatim (diff shows only the 2-line generated-file banner). No `provider/` or `cline-plugins/` copy of `SECURITY.md` exists (`cline-plugins` only ports `agents/`+`skills/`, not roster docs — confirmed by design, not a gap). | `diff roster/knowledge-store/SECURITY.md plugin/suite/roster/knowledge-store/SECURITY.md`
EVIDENCE AC-4 | CP-4 | PASS | Regeneration is idempotent. Ran all three generators against clean `HEAD` (`git status --short` empty before): `cadre generate-role-metadata` (rewrote `catalog.yaml`, `provider/agent-catalog.json`, 318-file `provider/` bundle, `routing.json`), `cadre generate-plugin -output plugin` (646 files under `plugin/`), `cadre port-cline-agents -root cline-plugins -source plugin` (159 agents, 9 skills into `cline-plugins/cline-agents/`) — `git status --porcelain` returned empty after each. Note: `port-cline-agents` with no flags errors (`open cline-plugins/skills: no such file or directory`) because its default `--source` equals `--root`, not `plugin`; this is a pre-existing CLI usage quirk, not something P3 introduced or broke. | live run, `/home/deagy/sdk/cadre` `git status --porcelain` empty after each step
EVIDENCE AC-4 | CP-4 | PASS | `show-staged` surfaces `observed_actor` as a distinct top-level field beside `frontmatter.staged_by`, on a freshly built `4da28060` binary. | live run: `propose` → `show-staged` returned `"observed_actor": "os:deagy git:daniel.eagy@sqs.world"` distinct from `frontmatter.staged_by = "CP4-VERIFIER-CLAIMED-STAGER"`
EVIDENCE AC-4 | CP-4 | PASS | `delete-staged` and `deletion-evidence-staged` both surface `observed_actor` distinct from `deleted_by`/`authorized_by`. | live run: `delete-staged` output and `deletion-evidence-staged` JSON both carried `"observed_actor": "os:deagy git:daniel.eagy@sqs.world"` beside `"deleted_by": "CP4-VERIFIER-CLAIMED-DELETER"` and `"authorized_by": "Second Person Not At Keyboard"`
EVIDENCE AC-4 | CP-4 | PASS | `list-staged` does **not** surface `observed_actor` — but this is symmetric, pre-existing behavior, not a P3-introduced silent drop: `ListStagedRecords`'s SQL (`internal/knowledge/staged_store.go:334`) selects `id, status, content_digest, created_at, updated_at, frontmatter_json` and was never touched by any of P3's four commits; it never surfaced `staged_by` either, before or after. A summary listing omitting all actor fields uniformly is not the asymmetric "observed dropped, asserted kept" defect the task asked me to check for. | `internal/knowledge/staged_store.go:333-363`; live `list-staged` JSON (no actor fields at all, symmetric)
EVIDENCE AC-4 | CP-4 | PASS | P3's four commits (`b174bfea`, `bd8423aa`, `a4c4d984`, `4da28060`) touch zero files under `internal/generators/`, `internal/config/`, `internal/contextstore/`, `.github/workflows/`, or any `LICENSE*` file — the surfaces P1's licensing/installer claims and P2's config-walk/release-workflow claims depend on. P1's AC-2 (installer fetch set) and P2's AC-8 (config walk, release workflow) are unaffected by construction. | `git diff --stat b174bfea~1..4da28060 -- internal/generators/ internal/config/ internal/contextstore/ .github/workflows/ LICENSE '*LICENSE*'` (empty)
EVIDENCE AC-4 | CP-4 | PASS | Full relevant test suites green post-P3: `CGO_ENABLED=1 go test -tags sqlite_fts5 ./internal/platform/... ./internal/contextstore/... ./internal/generators/... ./internal/knowledge/...` all `ok`. `go build ./...`, `go vet ./...` clean. | live run, `/home/deagy/sdk/cadre` at `4da28060`
EVIDENCE AC-4 | CP-4 | PASS | `evidence/P3/evidence/checkpoints.tsv` matches the four `CP-3v-round*.md` files exactly: CP-2 PASS, CP-3 PASS, CP-3v FAIL (round 1: deletion-only coverage), FAIL (round 2: schema regression + import-staged gap), FAIL (round 3: `MigrateStagedRecords` legacy-store break), PASS (round 4: enumerated every consumer, no `SELECT *` remains). No discrepancy between ledger and round reports. | `evidence/P3/evidence/checkpoints.tsv` vs `evidence/P3/CP-3v-round1..4.md`
EVIDENCE AC-4 | CP-4 | PASS | P3's evidence never claims AC-5, AC-6, AC-7 or AC-3b. Every `EVIDENCE`/`FAILURES` row across all four CP-3v rounds is prefixed `AC-4`; the only other AC mentioned is AC-5, cited three times purely as interpretive precedent ("AC-5's explicit carve-out... a security document is not 'the command says plainly'") to resolve AC-4's own ambiguity — never asserted as satisfied. | `grep -n "AC-5\|AC-6\|AC-7\|AC-3b" evidence/P3/*.md`
EVIDENCE AC-4 | CP-4 | FAIL | `spec.md`'s traceability table and `STATUS.md`'s phase table both still read P3 "not started" / AC-4 "pending," and `STATUS.md`'s "Next action (resume cold from here)" section still directs a reader to do P1's licensing tasks — even though P1 and P2 are separately marked "done" two rows above, P3 has CP-2 (PASS), CP-3 (PASS) and four CP-3v rounds (last one PASS) already on disk, and `STATUS.md`'s own header two lines above the phase table says `Overall: in progress`. The phase-table row and the header contradict each other on the same document. | `spec.md:55,75`; `STATUS.md:13,19,28-36`
EVIDENCE AC-4 | CP-4 | PASS | Harness controls, run verbatim over `04-projects/production-readiness` (results below) and `ci-status.sh` over all four repositories (results below) — all consistent with actual state, no discrepancies found beyond the STATUS.md/spec.md staleness already flagged. | see Harness controls section

## Harness controls (verbatim)

**`phase-gates.sh 04-projects/production-readiness`** (exit 1, expected — CP-4/CP-5 for P3 have not run yet; this report is that CP-4):
```
P1     all required checkpoints recorded
P2     all required checkpoints recorded
P3     NEVER RUN: CP-4 CP-5

phase-gates: 1 phase(s) never ran a required checkpoint.
  An absent checkpoint is not a pass. It means the gate was never asked,
  which leaves the same evidence bundle behind as a clean run.
```

**`spec-lint.sh 04-projects/production-readiness`**:
```
spec-lint: clean.
```

**`evidence-lint.sh 04-projects/production-readiness`**:
```
evidence-lint: clean.
```

**`citation-lint.sh 04-projects/production-readiness`**:
```
citation-lint: 16 commit citation(s), 13 vault path(s) checked.
citation-lint: every citation resolves.
```

**`crossref-lint.sh`** (over the backlog):
```
crossref-lint: every cross-reference agrees with the row it names.
```

**`backlog-lint.sh`**:
```
backlog-lint: every row carries a disposition.
```

**`ci-status.sh`** over all four repositories:
```
deagy/cadre                  4da28060  success run 33643385856
deagy/cadre-kernel           8da1b135  success run 33629166510
deagy/recall                 3ee2795f  success run 33537575047
deagy/gloop                  04c356ad  success run 33633218009
```
cadre's row matches the claimed commit and CI run exactly.

## FAILURES

- Traceability honesty | `STATUS.md` phase table and `spec.md` traceability table must reflect what actually happened in the phase | `STATUS.md:13` reads P3 "not started" and `spec.md:75` reads AC-4 "pending," while `evidence/P3/` already holds CP-2 PASS, CP-3 PASS, and four CP-3v rounds (round 4 PASS, no failures) — and `STATUS.md`'s own header (`Current phase: P3 · Overall: in progress`) contradicts its own phase-table row two lines below. `STATUS.md`'s "Next action (resume cold from here)" section (lines 28-36) still describes P1's licensing tasks as next, though P1 is marked "done" in the same document.

## FIX_HINTS

- Update `STATUS.md`'s P3 row to "in progress" (or a state matching the convention P1/P2 used mid-phase, if one exists) with a note pointing at `evidence/P3/CP-3v-round4.md` (PASS) and that CP-4/CP-5 remain. Replace the "Next action" section with P3's actual remaining step (CP-5 acceptance, following this CP-4). Update `spec.md`'s traceability row for AC-4 similarly once CP-5 closes P3, consistent with how AC-3/AC-8 were marked "verified" only after their respective `CP-5-acceptance.md` files landed.

## Housekeeping

- `/home/deagy/cog-second-brain` and `/home/deagy/sdk/cadre` both left as found: no files edited or written by this verification (only reads, builds to `/tmp`, and generator runs whose output diffed to nothing). Scratch directories used and removed: `/tmp/claude-1000/pr-cp4-scratch`, `/tmp/claude-1000/pr-cp4-cadre` (binary).
- Pre-existing uncommitted files in `/home/deagy/cog-second-brain` (P3's own `CP-3-build.md`, `CP-3v-round1..4.md`, and `evidence/checkpoints.tsv`) were present before this verification started and were only read, not modified.
- Pre-existing git worktrees under `/home/deagy/sdk/cadre` from prior CP-3v rounds (`/tmp/v4b-oldcommit`, `/tmp/v4c-clone`, `/tmp/v4d-falsify`) were left in place, per this environment's destructive-action policy and per their own rounds' housekeeping notes — none created or touched by this report.
