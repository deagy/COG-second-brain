# CP-4 round 2 — production-readiness P4 (AC-5)

Artifact: `/home/deagy/sdk/cadre` at `0e249942` (CI run 33648430913, independently
re-fetched via `gh run view --json headSha,conclusion,status` — headSha matches
`0e2499427b899940b5006be5adc0bbda106b4764` exactly, `conclusion: success`).
Round 1 report: `04-projects/production-readiness/evidence/P4/CP-4-round1.md`
(FAIL:fixable — pre-parse scan read a flag's value as a request).

## Verdict

**PASS**

Round 1's exact failing case now succeeds end to end against a real staged
record, and the reason is recorded verbatim in the deletion evidence. The
same tokens in flag position are still refused across six structural
variants and both dispatch routes — the fix narrowed the scan, it did not
disable it. Static enumeration of every `fs.Bool` declaration in the
`knowledge` namespace (`knowledge.go`, `knowledge_staged.go`) turns up
exactly the six flags in `booleanKnowledgeFlags` — nothing missing. A live
scratch-clone test with one entry deliberately removed confirmed the
claimed failure direction empirically: a missing boolean flag degrades a
real refusal to the Go parser's own "flag provided but not defined" error
(the pre-fix baseline), and never causes a legitimate value to be refused.
Four categories of ordinary values (spaced reason, empty string, a
single-dash non-flag value, a query containing "retention") all reach real
business validation, not the refusal. The `--` terminator still protects a
positional query containing `--retention-days`. Everything round 1 passed
still holds: `observed_actor` appears at every staged-lifecycle step
(`propose` → `show-staged` → `disposition-staged` → `delete-staged` →
`deletion-evidence-staged`) including under reasons that are the refused
words themselves, the drift guard passes, all three generated trees are
byte-identical, and traceability documents make no premature or expanded
claim.

## INTEGRATION_CLAIMS_CHECKED: 15

## EVIDENCE

EVIDENCE AC-5 | CP-4 | PASS | Round 1's exact case, reproduced against a real, newly-proposed staged record (`KS-20260902-cp-4-round-2-scratch-record-914c348bb8f9`): `cadre knowledge -config config.json delete-staged --id <id> --reason "--retention-days" --deleted-by t` returns exit 0 and `"status": "deleted"` — no longer refused. `deletion-evidence-staged --id <id>` shows `"reason": "--retention-days"` recorded verbatim. | live run against `/tmp/v5b-cadre` built from `0e249942`, scratch config under `/tmp/cp4r2-knowledge-test` (removed after use)
EVIDENCE AC-5 | CP-4 | PASS | Same-token-as-flag still refused, six variants, live: (1) first position — `knowledge --retention-days 30 search ...` refused exit 2; (2) after another flag's value — `search "x" --classification internal --retention-days 30` refused exit 2; (3) after a boolean flag — `search "x" --all-sources --trigger evilx` refused on `--trigger`, exit 2; (4) `--x=y` form — `--retention-days=30` refused exit 2; (5) single-dash form — `-retention-days 30` refused exit 2; (6) the staged dispatch route — `delete-staged --id KS-nonexistent --as-of 2026-01-01 --deleted-by t` refused on `--as-of`, exit 2, proving both `KnowledgeCmd` (`knowledge.go:128`) and `KnowledgeStagedCmd` (`knowledge_staged.go:88`) call the same tightened scan. | live runs, `/tmp/v5b-cadre`
EVIDENCE AC-5 | CP-4 | PASS | `booleanKnowledgeFlags` (`knowledge_absent_capability.go:55-58`: `all-sources`, `diverged-from-proposal`, `dry-run`, `json`, `reclaim`, `render-only`) is a complete enumeration of every `fs.Bool` declaration reachable from the two knowledge dispatch routes — `grep -rn "\.Bool(" internal/cli/knowledge.go internal/cli/knowledge_staged.go` finds exactly those six names (json/reclaim/all-sources/json/json/render-only/diverged-from-proposal/dry-run, deduplicated to 6) and no others; `context.go`'s boolean flags (`acknowledge-loss`, `acknowledge-commit`) belong to the separate `context` namespace the refusal deliberately excludes. Nothing missing. | `internal/cli/knowledge_absent_capability.go:55-58`; `grep -rn "\.Bool(" internal/cli/knowledge*.go`
EVIDENCE AC-5 | CP-4 | PASS | Claimed failure direction confirmed empirically in a scratch clone (`/tmp/cp4r2-cadre-scratch`, `all-sources` removed from `booleanKnowledgeFlags`, rebuilt, removed after use): `search --classification internal --all-sources --trigger evilx "some query"` on the scratch binary degrades to the real Go parser's own `flag provided but not defined: -trigger` (exit 2) — the exact pre-fix baseline behaviour, not a false refusal and not a silent success. The unmodified binary on the identical command correctly fires the `--trigger` absent-capability refusal. A legitimate `--all-sources` search with no following flag (`search --classification internal --all-sources "some query"`) on the scratch binary reaches real business logic (an embedder-identity error, exit 1) rather than being wrongly refused, confirming the direction is one-way: missing-from-list can only under-refuse, never over-refuse. | live runs against `/tmp/v5b-cadre-scratch` (built from a modified copy, not the tracked repo) and `/tmp/v5b-cadre`
EVIDENCE AC-5 | CP-4 | PASS | Ordinary (non-flag-shaped) values still work, four cases, live: spaced reason (`--reason "steward review complete, no longer needed"`) deletes cleanly; empty-string reason (`--reason ""`) correctly reaches real domain validation (`error: delete-staged requires --reason`, exit 1 — not the pre-parse refusal); a single-dash non-flag value (`--reason "-x"`) deletes cleanly; a query containing the word "retention" (`search --classification internal "what is our retention policy for staged records"`) reaches real scope validation (`source scope is required`, exit 2, not the absent-capability message). | live runs, `/tmp/v5b-cadre`, three real staged records proposed and deleted
EVIDENCE AC-5 | CP-4 | PASS | `--` terminator still protects a positional query: `search --classification internal --all-sources -- "--retention-days"` reaches real business logic (embedder-identity error, exit 1), not the refusal (would be exit 2). | live run, `/tmp/v5b-cadre`
EVIDENCE AC-5 | CP-4 | PASS | Full staged lifecycle composes with the fix and with P3's observed-actor plumbing: fresh binary from `0e249942`, real records proposed → `show-staged` (`observed_actor` present) → `disposition-staged --reason "--trigger"` (accepted; **not** refused — the fix covers this route's own free-text `--reason` too) → `show-staged` again shows `disposition_history[0].reason == "--trigger"` verbatim, with `observed_actor` on that history entry → `delete-staged --reason "--as-of" --authorized-by ...` (deleted, not refused) → `deletion-evidence-staged` shows `reason: "--as-of"`, `authorized_by`, and `observed_actor` all present. Every step distinct caller-asserted fields (`staged_by`/`decided_by`/`deleted_by`/`authorized_by`) from the constant `"observed_actor": "os:deagy git:daniel.eagy@sqs.world"`. | live runs, `/tmp/v5b-cadre`, `/tmp/cp4r2-knowledge-test`, cleaned up after
EVIDENCE AC-5 | CP-4 | PASS | Drift guard (`TestEveryDocumentedKnowledgeVerbIsAnswerable`) passes at `0e249942`. `git show --stat 0e249942` touches only `internal/cli/knowledge_absent_capability.go` and `internal/cli/knowledge_absent_capability_test.go` (36 + 39 lines added, 0 removed) — zero markdown, same structural argument as round 1 (the guard scans `roster/`, `.agents/skills/`, root markdown, `CHANGELOG.md`, never `.go` source). | `go test ./internal/cli/... -run TestEveryDocumentedKnowledgeVerbIsAnswerable -v` → PASS; `git show --stat 0e249942`
EVIDENCE AC-5 | CP-4 | PASS | All three generators produce empty diffs at `0e249942`: `generate-role-metadata`, `generate-plugin -output plugin`, `port-cline-agents -root cline-plugins -source plugin` — `git status --porcelain` empty before and after each, on the real repo. Correct: the fix touched only two `internal/cli/*.go` files, none of which feed any generator input root. | live run, `/home/deagy/sdk/cadre`, `git status --porcelain` empty throughout
EVIDENCE AC-5 | CP-4 | PASS | Traceability still scoped to AC-5: `grep -n "AC-6\|AC-7\|AC-3b\|AC-4\b" evidence/P4/*.md evidence/P4/evidence/*.tsv` returns only two hits, both quoting AC-4's own wording from a *prior* phase (P3) for context, not claiming P4 scope over it. `spec.md` (AC-5 row: "pending") and `STATUS.md` (P4: "not started") still correctly withhold closure — this report is P4's CP-4 round 2, CP-5 has not run. | `evidence/P4/*.md`; `spec.md:76`; `STATUS.md:14`
EVIDENCE AC-5 | CP-4 | PASS | Fix commit `0e249942` cites the exact CP-4 round-1 failure in its message and test names (`TestAValueThatLooksLikeARefusedFlagIsNotARequest`, `TestTheFlagItselfIsStillRefusedAfterTheValueFix`), both of which pass locally (`go test ./internal/cli/... -run '...' -v` → PASS, re-run independently, not trusted from the worker's own report). | `git show 0e249942`; `go test` output
EVIDENCE AC-5 | CP-4 | PASS | Harness controls, run verbatim against `04-projects/production-readiness` (below) — consistent with the expected state: CP-5 still not run, everything else clean. | see Harness controls section
EVIDENCE AC-5 | CP-4 | PASS | `ci-status.sh` over all four repositories, verbatim (below) — cadre's row matches the exact fix commit and the cited CI run. | see Harness controls section

## Harness controls (verbatim)

**`phase-gates.sh 04-projects/production-readiness`** (exit 1, expected — CP-5 has not run yet; CP-4 is recorded because round 1 ran, even though round 1's own status was FAIL):
```
P1     all required checkpoints recorded
P2     all required checkpoints recorded
P3     all required checkpoints recorded
P4     NEVER RUN: CP-5

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
citation-lint: 20 commit citation(s), 34 vault path(s) checked.
citation-lint: every citation resolves.
```

**`ci-status.sh` over all four repositories**:
```
deagy/cadre                  0e249942  success run 33648430913
deagy/cadre-kernel           8da1b135  success run 33629166510
deagy/recall                 3ee2795f  success run 33537575047
deagy/gloop                  04c356ad  success run 33633218009
```
cadre's row matches the claimed fix commit and CI run exactly.

## FAILURES

(none)

## Housekeeping

- `/home/deagy/sdk/cadre` left as found: `git status --porcelain` empty before and
  after. Binary built to `/tmp/v5b-cadre`, deleted after use.
- A separate scratch clone (`/tmp/cp4r2-cadre-scratch`, a full `cp -r` copy, not a
  worktree or clone of the tracked repo) was used only for the deliberately-broken
  boolean-list test in item 3; it and its binary (`/tmp/v5b-cadre-scratch`) were
  removed after use and never touched the tracked repo.
- `/home/deagy/cog-second-brain` left as found: read-only, no edits. The only
  untracked path under `04-projects/production-readiness/` (`evidence/P4/`) predates
  this session (it holds `CP-2-plan.md` through `CP-4-round1.md`, all read but not
  modified here).
- Scratch staged-record test directory (`/tmp/cp4r2-knowledge-test`, five real
  staged records exercised through propose/show-staged/disposition-staged/
  delete-staged/deletion-evidence-staged) created under `/tmp` and removed
  (`rm -rf`) before finishing.
