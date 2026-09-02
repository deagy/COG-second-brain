# P2 — CP-3 build · AC-8

| Task | Outcome | Artifact |
|---|---|---|
| T-01 | `#249` fixed: the project walk stops below `$HOME` | cadre `998ad425` |
| T-02 | Two tests, falsified against the unfixed walk | `internal/platform/paths_test.go` |
| T-03 | The issue's record corrected, then closed | [#249 comment](https://github.com/deagy/cadre/issues/249#issuecomment-5510137370) |
| T-04 | The kernel's second release home retired | cadre `0f4bd58c` |

## T-01 — the cause was not what the issue said

The issue blames the ordering: the candidate is stat'd before the `.git` boundary is tested. **The ordering is correct.** Checking a directory for the file and *then* stopping if that directory is the project root is exactly right — reversing it would miss a config at the project root itself.

The real defect is that the `.git` boundary only exists when a project root does. With no `.git` anywhere in the ancestry there is nothing to stop the walk, so it climbs to `$HOME`, where `~/.agents/<store>/config.json` is the **global** store's own configuration. The two tiers then alias: the same directory answers to both depending only on where the caller stood.

The fix bounds the walk at or above home. A project cannot be `$HOME`, so that costs nothing and removes the aliasing rather than narrowing it.

Reproduced before and after, on the exact shape the issue describes:

| | before | after |
|---|---|---|
| tier reported | `project-local` | `global-fallback` |
| store resolved | the global store's database | the one `KNOWLEDGE_STORE_HOME` names |
| `KNOWLEDGE_STORE_HOME` | silently ignored | honoured |

A genuine project-local config below home is still found, and behaviour inside a git project is unchanged.

## T-02 — the test the issue asked for

The issue closes with *"No test pins the current behaviour."* Two now do, and **both were falsified before being counted**: removing the guard fails `TestTheProjectWalkStopsBelowHome`; restoring it passes. The second test pins the case the bound could have broken.

One fix covers both stores — they share `platform.FindFileAtProjectRoot`, and the context store's exposure was latent only because `cadre context init` creates a database and not a config file.

## T-03 — half the issue had aged out

Filed 2026-08-12 against `roster/knowledge-store/src/config.py`; `b418031e` deleted that file the next day. Its core defect survived the rewrite. **Its stated consequence did not.**

It argues the scope gates are bypassed, because in Python they keyed on `tier == TIER_GLOBAL_FALLBACK`. The Go gate is unconditional, and `internal/cli/knowledge.go:389` says why deliberately — *"weakening the CLI to match Python would require weakening the library, in the one direction this store must never fail."* Confirmed by running it: an unscoped search is refused from both tiers.

Correcting that is part of closing the defect. Left standing, the next reader either hunts a bypass that does not exist or stops trusting the issue.

## T-04 — a husk, not a competing publisher

The expectation was two publishing paths that could drift. What was actually there:

- a path trigger on `internal/kernel/provider.go`, a file the split moved out — so it watched something that cannot change here;
- a `kernel` output on the `changed` job that nothing sets and nothing consumes;
- the comment block explaining the kernel publish job, orphaned at end-of-file after the job left;
- a comment in the CLI job comparing its four platforms to "the kernel still publishes five";
- a header citing `internal/kernel/kernel_boundary_test.go`, which lives in cadre-kernel.

The job had gone with the kernel; the scaffolding stayed. A reader following the old text would have gone looking for a job, an output and a test in the wrong repository.

## What this phase did not do

The kernel's published `v0.14.2` still predates its licence commit, so the tarball an installer downloads carries no licence text. Carried from P1 and owned by P5, which re-cuts.
