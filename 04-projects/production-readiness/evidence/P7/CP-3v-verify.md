# P7 — CP-3v / CP-5 independent verification (AC-8)

Fresh-context read-only verifier, given the criterion and the three clauses to check,
and told explicitly not to read any record of what the remediation was — verify the
world, not the story about it. **VERDICT: PASS. CLAIMS_CHECKED: 3.**

Two of its observations are stronger than the ones in `CP-5-acceptance.md`, which is
what a second pair of eyes is for:

- It **falsified the `#249` fix rather than running it**: in a scratch clone, removed
  the home-boundary guard from `internal/platform/paths.go` and saw
  `TestTheProjectWalkStopsBelowHome` fail with *"the walk reached the home directory
  and returned .../.agents/knowledge-store/config.json as project-local"* — the exact
  original defect — then restored and saw it pass. My own row cited the test's
  existence and P2's record.
- It read the **shim out of the published binary** rather than out of git. `strings`
  on the extracted `cli-v0.6.5` linux-amd64 asset carries the literal
  `BASE="https://github.com/deagy/cadre/releases/download/kernel-v$AGENTIC_SDLC_VERSION"`.
  My row inferred the same from `git show cli-v0.6.5^{commit}:...`. The binary is the
  artifact users run; the source at that tag is what it was built from.

EVIDENCE AC-8 | CP-3v | PASS | `998ad425` is an ancestor of HEAD `5c40d6ec`. In a scratch clone, removing the home-boundary guard from `internal/platform/paths.go` makes `TestTheProjectWalkStopsBelowHome` fail with the original defect's own symptom; `git checkout --` restores it and both tests pass. The test falsifies the fix rather than being cosmetically present | `/tmp/claude-1000/verify-ac8/cadre-check`, `internal/platform/paths.go`, `internal/platform/paths_test.go`
EVIDENCE AC-8 | CP-5 | PASS | `#249`'s body, fetched via the API, opens with a correction naming the deleted Python (`config.py`, `find_project_local_config`, `MAXIMUM_WALK_DEPTH`, the `python3 -c` reproduction) as code as it stood on 2026-08-07, cites the Go fix and its current equivalents, and corrects two substantive claims of the original report. A reader of the body alone would not take the named Python as current behaviour | `gh api repos/deagy/cadre/issues/249`
EVIDENCE AC-8 | CP-5 | PASS | One live release home. `deagy/cadre-kernel` holds three Release objects (`v0.14.2`–`v0.14.4`) whose assets fetch 200. `deagy/cadre` holds **no** Release object for any `kernel-v*` tag: the releases API returns 404 for all six, and every constructed asset URL 404s. The six git tags remain as bare tags with no Release and no working asset — dead history, not a second home | `gh api repos/deagy/{cadre,cadre-kernel}/releases`, `curl` on asset URLs
EVIDENCE | CP-3v | PASS | Recorded as context, not pass/fail: the eight published `cli-v0.5.0`–`cli-v0.6.5` binaries embed a shim whose kernel `BASE` is the now-empty `cadre` release path, read directly out of the extracted `cli-v0.6.5` linux-amd64 asset with `strings`. `cli-v0.7.x` and `main` point at `cadre-kernel`, which resolves 200. This is the cost accepted at CP-6 | `strings` on the extracted `cli-v0.6.5` binary
EVIDENCE | CP-3v | PASS | `agentic-sdlc-engine` (`cmd/agentic-sdlc-engine`, the G1–G10 task engine) is released as an asset inside `cadre`'s own `cli-v0.7.5`, and is a different component from the lifecycle kernel (`cmd/agentic-sdlc`, gate schemas and run-record validation) per its own doc comment. `cli-v0.7.5` carries no non-engine `agentic-sdlc-*` asset, so it does not constitute a second kernel release home. Checked because the names are one word apart | `deagy/cadre` `cli-v0.7.5` asset list, `cmd/agentic-sdlc-engine` doc comment
