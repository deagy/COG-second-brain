---
type: knowledge
domain: technical
project: Secure Quantum Environment
topic: Three-Tier Quantum Network Architecture
created: 2026-08-28 11:16
last_updated: 2026-08-28
source: periodic-review
version: "1.0"
tags: ["#knowledge", "#secure-quantum-environment", "#architecture", "#zero-trust", "#governance"]
related:
  - 05-knowledge/product/secure-quantum-environment.md
  - 04-projects/secure-quantum-environment/braindumps/2026-08-28-ingress-governance-and-smokenet.md
---

# Three-Tier Quantum Network Architecture

## Overview
SQE's network is organized as three trusted layers — distribution, perimeter, core — with governance enforced at the boundaries between them. The design is a clean expression of zero-trust: verify and enforce at every layer boundary, least privilege, fail closed.

## Current State
- **Distribution** — the interface end users interact with; outermost layer.
- **Perimeter** — the boundary and translation point between core and the rest of the world.
- **Core** — central and most protective. Crown-jewels invariant: **data never leaves core.**

### Key Details
- **Governance-backed firewall:** ingress/egress is controlled by policy, not just connectivity. The recommendation is to **gate at layer boundaries, not per-system** — a governance firewall per layer edge is leaner and easier to audit than one per individual system.
- **Separation of concerns:** routing/orchestration, load balancing, and governance/policy enforcement have different failure modes, scaling needs, and update cadences — they should **not** be forced into one box just because they sit at the same physical ingress. Per-system load balancing is fine where horizontal scaling exists.
- **"Core never egresses data" should be structural**, not policy-only: the core should have no data-out path at all; only declassified/derived data crosses the perimeter. This is analogous to a trusted computing base / secure enclave (read-mostly on sensitive data, single audited declassification chokepoint at the perimeter).
- **Decision guidance:** decide per-layer vs. per-system gating only *after* the governance policy model (what is enforced, where, deny-default) is on paper.

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-08-28 | 1.0 | Initial entry from ingress-governance braindump and daily-brief impact analysis | Periodic review |

## Related
- [SQE overview](../product/secure-quantum-environment.md)
- [Original braindump](../../04-projects/secure-quantum-environment/braindumps/2026-08-28-ingress-governance-and-smokenet.md)

## Notes
- Open question: what CEO "Ray" meant by "ingress control" — a single gateway per layer, or one per system. Needs the source doc captured verbatim.

---

*Last updated: 2026-08-28 | Source: 04-projects/secure-quantum-environment braindumps + brief impact analysis*
