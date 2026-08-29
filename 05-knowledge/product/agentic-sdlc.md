---
type: knowledge
domain: product
project: Agentic SDLC
topic: Agentic SDLC
created: 2026-08-28 11:15
last_updated: 2026-08-28
source: periodic-review
version: "1.0"
tags: ["#knowledge", "#agentic-sdlc", "#project", "#agents"]
related:
  - 05-knowledge/technical/agentic-sdlc-governance.md
  - 04-projects/agentic-sdlc/PROJECT-OVERVIEW.md
---

# Agentic SDLC

## Overview
Agentic SDLC is a personal project to run a software development lifecycle driven by task dispatch to specialized agents (a go-implementer for Go, a code-reviewer, a system-architect, a technical-writer, etc.) rather than one generalist agent doing everything. The core non-negotiable principle: "a worker never grades its own homework" — output is verified by a fresh, independent context before it lands.

## Current State
- **Maturity is uneven across the two loops:**
  - **Phase-level loop** (intent → requirements → architecture-design → governance-data → security-crypto → verification → evidence → release-readiness → deployment-auth → runtime-conformance) maps onto gates G1–G10, each with a named deciding authority. This loop has strong governance: the phase-level amend loop is fully specified (failed gates return to the responsible artifact owner; material change invalidates that gate *and every dependent downstream gate*).
  - **Per-task verify loop** runs far more often and entirely without humans, but historically had the weaker rules. This is where the current design work is focused.
- **Built on the "cadre" suite** (`~/sdk/cadre` repo) — the roster of roles, workflows, and orchestration contracts.

### Key Details
- **Peer review as a structural property, not a role:** every agent's output should be checkable by another agent; no output is trusted because of who produced it.
- **Authority as a separate layer above review:** reviewers *find* things; authorities *decide what happens* (approve/deny). Denial must have teeth — it amends the loop.
- **G1–G10 deciding authorities:** G1 Product Owner; G2 Product Owner + Engineering Lead; G3 System Architect; G4 Governance Lead; G5 Security Lead; G6 Product Owner + Engineering Lead; G7 Release Owner; G8 Release Owner; G9 Release Authority; G10 Service Owner.

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-08-28 | 1.0 | Initial entry from project overview and peer-review/authority braindump | Periodic review of 04-projects/agentic-sdlc |

## Related
- [Per-task denial contract & governance](../technical/agentic-sdlc-governance.md)
- [PROJECT-OVERVIEW](../../04-projects/agentic-sdlc/PROJECT-OVERVIEW.md)

## Notes
- Open design questions still tracked: role granularity vs. dispatch overhead; who verifies output and how independence is enforced; context handoff size; what evidence the pipeline produces for human audit.
- Hierarchy (flat domain-scoped authorities vs. escalating chain) is undecided.

---

*Last updated: 2026-08-28 | Source: periodic review of 04-projects/agentic-sdlc*
