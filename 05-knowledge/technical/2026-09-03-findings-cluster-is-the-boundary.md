---
type: knowledge
domain: technical
project: cadre–COG Integration
topic: A Component That Draws Findings In Every Review Pass
created: 2026-09-03
last_updated: 2026-09-03
source: cadre/COG integration session — PR #1 review through PR #5 merge
version: "1.0"
tags: ["#knowledge", "#review", "#architecture", "#scoping"]
related:
  - plan/authority-gates.md
  - 05-knowledge/technical/2026-09-03-what-can-attest-a-human-decision.md
---

# A Component That Draws Findings In Every Review Pass

## Overview
Four high-effort review passes ran across two PRs in the cadre/COG integration. Findings clustered almost entirely in one change: Change 3 (mutation gates) produced findings in all four passes, including every high-severity one, while Changes 1 and 2 produced only mechanical defects that closed and stayed closed. Two of the later Change 3 findings were regressions introduced while fixing earlier Change 3 findings. Change 3 was withdrawn rather than patched a fifth time.

## Current State
- **The pattern, restated as a heuristic:** when a component generates findings in every review pass while its neighbours converge after one or two, the clustering itself is the finding — evidence the component's design is wrong at a level no further patch will fix, not evidence it needs more iterations. [Source: session, cadre/COG integration | 2026-09-03 | confidence: high]
- **Regressions from fixing findings are a stronger version of the same signal.** A component whose fixes introduce new findings of the same severity is not converging; each round narrows a specific defect while the underlying design keeps generating new instances of the same shape. [Source: session, cadre/COG integration | 2026-09-03 | confidence: high]
- **Precedent inside the same session.** The same reasoning had already removed a fourth planned change (Change 4) before this pattern was named for Change 3 — the clustering signal was acted on once by instinct before it was stated as a reusable rule.

### Key Details
- This is a scoping heuristic for review loops generally (harness-gated or not): a fixed iteration budget per finding treats every finding as independently fixable, but a component that is the sole source of findings across every pass is a different kind of signal than an isolated defect, and calls for a different response — split the component out, question its design, or withdraw it — rather than another fix-and-reverify cycle.
- Concretely, in this session: Change 3 was the mutation-gate/approval design examined in [[2026-09-03-what-can-attest-a-human-decision]]. The finding-clustering pattern and the structural defect it pointed at (an agent-attestable "human approval") are two different levels of the same conclusion — one is procedural (how to notice), the other is substantive (what was actually wrong).

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-09-03 | 1.0 | Initial entry from harvest staging, cadre/COG integration session | harvest-curator |

## Related
- [What can attest a human decision](./2026-09-03-what-can-attest-a-human-decision.md)
