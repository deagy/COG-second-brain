# AC-8 Verification Report

**VERDICT: PASS**

Artifact under test: /home/deagy/sdk/cadre @ 0f4bd58c7352b13a872896b1541492e127ec313d (working tree clean before and after verification). CI run 33635041600 independently re-checked: green, all 12 jobs passing (`gh run view 33635041600 -R deagy/cadre`). Build record `04-projects/production-readiness/evidence/P2/CP-3-build.md` checked as a claim, not trusted.

## 1. Defect reproduced-then-gone against the fixed binary — PASS

Built `/tmp/v8-cadre` from 0f4bd58c. Constructed fake `$HOME` with `.agents/knowledge-store/config.json` and a `.git`-free working dir beneath it.

- `HOME=<fake> /tmp/v8-cadre knowledge config` → `Config tier: global-fallback`.
- `HOME=<fake> KNOWLEDGE_STORE_HOME=/tmp/other-store-home-v8 /tmp/v8-cadre knowledge config` → store resolved to `/tmp/other-store-home-v8/store.db` (honoured, not silently ignored).
- Shared-function regression check: a genuine project-local `.agents/knowledge-store/config.json` below home, inside a `.git` project, still resolves `tier: project-local` with the correct store path.

## 2. Tests fail without the fix — PASS

Cloned to `/tmp/v8-clone` (scratch, `/home/deagy/sdk/cadre` untouched — confirmed via `git status --short` before and after). Removed the home-guard block (`internal/platform/paths.go:135-140`, the `if homeErr == nil && (current == home || isAncestorOf(current, home))` check) while keeping the file compiling (`home`/`homeErr` remain referenced earlier in the function).

```
=== RUN   TestTheProjectWalkStopsBelowHome
    paths_test.go:472: the walk reached the home directory and returned
        ".../.agents/knowledge-store/config.json" as project-local...
--- FAIL: TestTheProjectWalkStopsBelowHome (0.00s)
=== RUN   TestAProjectLocalFileBelowHomeIsStillFound
--- PASS: TestAProjectLocalFileBelowHomeIsStillFound (0.00s)
```

`git checkout -- internal/platform/paths.go` restored the guard; both tests then pass. Confirms the first test is falsified by removing exactly the control it claims to pin; the second is unaffected (as expected — it exercises the case the bound must not break).

## 3. Both stores share one walk — PASS

`grep -rn "FindFileAtProjectRoot"` (excluding tests) shows both call sites delegate directly, no separate walk logic:
- `internal/knowledge/config.go:239` → `return platform.FindFileAtProjectRoot(ProjectLocalRelativePath, start)`
- `internal/contextstore/config.go:140` → `return platform.FindFileAtProjectRoot(ProjectLocalRelativePath, start)`

Both `FindProjectLocalConfig` wrappers are one-line pass-throughs with no local `.git`/home logic of their own (read both files around the call sites). No other file implements a competing upward-walk for config discovery purposes.

## 4. Issue #249's record corrected — PASS

`gh issue view 249 -R deagy/cadre --json state,closedAt` → `"state":"CLOSED"`. The closing comment (read via `--comments`) states plainly which part is live ("the defect is real and reproduced... fixed in 998ad425") and which is stale ("Why it matters" no longer applies... filed against `roster/knowledge-store/src/config.py`, deleted by `b418031e`").

Independently checked the stale claim: `internal/cli/knowledge.go:389-392` shows `resolveRetrievalScope` is called unconditionally from `search` (line 540) with no tier branch around it — the function's own doc comment states "Unlike the Python CLI this gate is unconditional." Ran it directly:

- Non-git dir under fake home (global-fallback tier), unscoped `knowledge search --classification internal "test query"` → refused, exit 2, "source scope is required..."
- Git-project dir (project-local tier), same unscoped search → refused, exit 2, identical message.

Both tiers refuse identically, confirming the gate is not tier-conditional and the issue's stale claim (Python-only tier-gated bypass) does not apply to the Go binary.

## 5. One release home — PASS

`.github/workflows/release.yml` at 0f4bd58c: jobs are `changed`, `plugin`, `cli`, `cli-publish` — no `kernel` job. `changed` job outputs are `plugin` and `cli` only — no `kernel` output. No path trigger references `internal/kernel/provider.go` (that file does not exist in cadre: confirmed via `test -e`). Remaining `kernel` mentions in the file are explanatory comments about the split, not job/trigger wiring. `python3 -c "import yaml; yaml.safe_load(...)"` parses cleanly with the four jobs listed above — YAML valid, jobs intact.

cadre-kernel publishes independently: `gh repo view deagy/cadre-kernel` exists as a separate repo with its own `.github/workflows/release.yml`; `gh release list -R deagy/cadre-kernel` shows `v0.14.2` published there. cadre's generated installer resolves the kernel from cadre-kernel, not cadre: `internal/generators/plugin_generation.go:283` — `` `BASE="https://github.com/deagy/cadre-kernel/releases/download/v$AGENTIC_SDLC_VERSION"` `` — and line 2402 points users to `https://github.com/deagy/cadre-kernel` on install failure.

## 6. No regression — PASS

At 0f4bd58c (original repo, not the scratch clone):
- `go build ./...` → exit 0, no output.
- `go vet ./...` → exit 0, no output.
- `CGO_ENABLED=1 go test -tags sqlite_fts5 ./...` → every package `ok` (including `internal/platform`, `internal/knowledge`, `internal/contextstore`, `internal/cli`), no failures.

## Housekeeping

Scratch clone (`/tmp/v8-clone`) and fake-home fixtures deleted after use. `/home/deagy/sdk/cadre` confirmed clean (`git status --short` empty) before verification began and again after all steps completed.
