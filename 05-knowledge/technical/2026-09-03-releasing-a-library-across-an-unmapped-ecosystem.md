---
type: knowledge
domain: technical
project: recall / cadre / gloop — cross-repo release audit
topic: Releasing A Library Across An Unmapped Ecosystem
created: 2026-09-03
last_updated: 2026-09-03
source: session — recall/cadre/gloop releases, conversation loader build
version: "1.0"
tags: ["#knowledge", "#release-engineering", "#ci", "#go"]
related:
  - 05-knowledge/technical/2026-09-01-github-actions-gotchas.md
  - 05-knowledge/technical/2026-09-01-recall-quirks.md
---

# Releasing A Library Across An Unmapped Ecosystem

## Overview
One release of `recall` touched three repos and surfaced two separate blind spots, both from the same cause: nobody had an accurate map, only memory of how it worked last time. Release mechanisms turned out to differ in all three repos, and the dependency graph among them was further out of date than assumed — `gloop` was four minors behind `recall`, crossing two breaking changes, found only by reading every `go.mod` under `~/sdk` rather than by asking "what depends on recall?"

## Current State
- **`recall` releases only through a manual tag-and-call, because a workflow-pushed tag triggers nothing.** Its `Tag release` `workflow_dispatch` pushes the tag and calls `release.yml` directly, because a ref pushed with the workflow's own `GITHUB_TOKEN` raises no further workflow event — GitHub suppresses that recursion by design. `v0.3.0` and `v0.3.1` were both tagged and published nothing before this was fixed; see [[2026-09-01-github-actions-gotchas]] for the underlying token-recursion mechanism. [Source: session, recall release audit | 2026-09-03 | confidence: high]
- **`cadre` releases automatically off `main`, with its version number duplicated in three places.** There is no tag workflow; `release.yml` fires when a version bump lands on `main`. The version string lives in `VERSION`, in `CADRE_CLI_VERSION` inside `plugin/bin/cadre`, and in the CHANGELOG heading — the third location was only findable by reading the previous release commit, not by reading any single spec or doc. [Source: session, cadre release audit | 2026-09-03 | confidence: high]
- **`gloop` has no release workflow at all.** Mixed annotated and lightweight tags, no GitHub Releases published, ever. Three repos in the same ecosystem, three different (or absent) mechanisms — assuming any one would generalize to the others was the actual mistake, not any single mechanism being wrong. [Source: session, gloop release audit | 2026-09-03 | confidence: high]
- **The import graph was also not what memory said.** Searching every `go.mod` under `~/sdk` — rather than asking "what depends on recall?" from memory — found `gloop` pinned at `recall v0.1.0`, four minors behind, crossing two breaking changes nobody had accounted for. [Source: session, gloop go.mod audit | 2026-09-03 | confidence: high]
- **The follow-on discipline once an importer is found:** check each breaking change against the importer's *actual* usage, not its theoretical exposure, and take a baseline test count before the bump so the after-count means something. `gloop` turned out unaffected by both breaking changes, but only because the specific paths those changes moved were ones it did not call — a conclusion that required checking, not assuming. [Source: session, gloop bump verification | 2026-09-03 | confidence: medium — verified for this bump only, not a general claim about gloop's exposure]

### Key Details
- **The shared cause:** in both blind spots, the accurate answer lived on disk (the workflow file, the `go.mod` pin) and the wrong answer lived in memory (how release usually works, what depends on what). The fix in both cases was the same move — read the actual file before acting, rather than pattern-matching from the last repo touched or the last time this was done.
- **Scope:** generalizes to any repo ecosystem with more than one release path or more than one internal consumer — enumerate both from disk before releasing, every time, rather than caching the answer from a previous release.

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-09-03 | 1.0 | Initial entry from harvest staging, recall/cadre/gloop release session (staging proposed 2026-09-04 for the two source items; corrected to session date 2026-09-03) | harvest-curator |

## Related
- [GitHub Actions failure modes](./2026-09-01-github-actions-gotchas.md)
- [recall chunking & similarity quirks](./2026-09-01-recall-quirks.md)
