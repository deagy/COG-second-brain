---
type: knowledge
domain: technical
project: (cross-project)
topic: GitHub Actions Failure Modes
created: 2026-09-01
last_updated: 2026-09-03
source: repo-consolidation P4/P5 session (recall CI turn-up)
version: "1.1"
tags: ["#knowledge", "#github-actions", "#ci", "#yaml"]
related:
  - 05-knowledge/technical/2026-09-01-verification-that-depends-on-the-room.md
  - 04-projects/repo-consolidation/evidence/P5/ledger.md
---

# GitHub Actions Failure Modes

## Overview
Three GitHub Actions failure modes hit while turning CI on for `recall` during the repo-consolidation session, each silent or misleadingly labeled rather than pointing clearly at its cause.

## Current State
- **An `env:` key with only comments under it is valid YAML with a null value, and GitHub's schema rejects it — the whole workflow fails to load.** Zero jobs run, zero seconds elapse, and the failure is attributed to the workflow file itself rather than to any job or step — easy to misdiagnose as "the workflow didn't trigger" rather than "the workflow didn't parse." [Source: [[04-projects/repo-consolidation/evidence/P5/ledger.md]] | 2026-09-01 | confidence: high]
- **`actions/setup-go` with `cache: true` fails with `tar: Cannot open: File exists`, per module, if anything populates `~/go/pkg/mod` before it runs.** A `go build`/`go test` step placed before a job's own `setup-go` step is enough — its own module downloads collide with the cache-restore untarring into the same directory. Fix: always run `setup-go` first in the job. [Source: [[04-projects/repo-consolidation/evidence/P5/ledger.md]] | 2026-09-01 | confidence: high]
- **A tag pushed by a workflow using the default `GITHUB_TOKEN` does not trigger other workflows.** A release job keyed on `push: tags` will not fire when the tag satisfying it was pushed by CI itself under the default token — GitHub suppresses event recursion from that token by design. `recall`'s `v0.3.0` tag was pushed this way; `release.yml` never ran, so no GitHub Release or platform binaries existed for that version, while `v0.2.0` (tagged by a person) released normally. Fix: a PAT/deploy key for the tagging step, or a separate manual/`workflow_run` trigger for the release job. [Source: [[04-projects/repo-consolidation/evidence/P4/CP-6-decisions.md]] | 2026-09-01 | confidence: high]
- **`gh pr view --json headRefOid,state` can serve stale data for seconds to a minute after a successful push or merge.** Observed on three separate occasions in the cadre/COG integration, including once reporting `OPEN` with `mergeCommit: null` for a PR that `gh pr merge` simultaneously reported as already merged. The view behind `gh pr view` is not read-your-writes consistent immediately after a mutating call. `git ls-remote origin refs/heads/<branch>` and `git merge-base --is-ancestor <sha> <branch>` are the authoritative checks — they hit git's own ref state, not a cached API view. [Source: session, cadre/COG integration | 2026-09-03 | confidence: high]

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-09-01 | 1.0 | Initial entry from repo-consolidation P4/P5 harvest staging | harvest-curator |
| 2026-09-03 | 1.1 | Added gh pr view staleness gotcha from cadre/COG integration | harvest-curator |

## Related
- [Verification that depends on the room](./2026-09-01-verification-that-depends-on-the-room.md)
