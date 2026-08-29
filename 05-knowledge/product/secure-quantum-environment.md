---
type: knowledge
domain: product
project: Secure Quantum Environment
topic: Secure Quantum Environment
created: 2026-08-28 11:15
last_updated: 2026-08-28
source: periodic-review
version: "1.0"
tags: ["#knowledge", "#secure-quantum-environment", "#project", "#pqc", "#qkd"]
related:
  - 05-knowledge/technical/three-tier-quantum-network-architecture.md
  - 05-knowledge/technical/post-quantum-cryptography-selection.md
  - 04-projects/secure-quantum-environment/PROJECT-OVERVIEW.md
---

# Secure Quantum Environment (SQE)

## Overview
Secure Quantum Environment is a work project to build a secure quantum environment on a varied network stack, combining post-quantum cryptography (PQC) with quantum key distribution (QKD). It is organized as a three-tier architecture (distribution → perimeter → core) with governance enforced at layer boundaries. The project is in early design/architecture phase; the overview doc is still a template with open questions.

## Current State
- **Owner/role:** Daniel is the tech lead of the SQE team (from the 2026-08-28 ingress governance braindump).
- **Architecture:** Three trusted layers — distribution (user-facing), perimeter (boundary/translation between core and rest), core (central, most protective; data never leaves).
- **Design philosophy:** Governance-backed ingress/egress firewall; verify and enforce at every layer boundary (zero-trust: least privilege, fail closed).
- **Reference architecture source:** Platform design documentation from the CEO, "Ray."
- **Regulatory driver:** HKMA Fintech 2030 quantum-readiness deadline (with a Quantum Preparedness Index) and the MAS+ABS ACT taskforce — this is SQE's "why now."

### Key Details
- **PQC reference algorithm:** ML-DSA-65 (NIST FIPS 204, Level 3), per the Safeheron×RFI pilot — treated as the reference point to reason against. Signature-size cost (~50× Ed25519) is a first-class design constraint.
- **Key model:** Non-custodial 2-of-2 MPC (from the Safeheron/RFI pilot) — separates key *ownership* (kept by each party) from *operational signing*.
- **OTP-throughput problem:** A container, "smokenet," uses one-time pads for obfuscation and appears to drag throughput. Benchmark is planned to isolate algorithm cost vs. interpreter cost before any rewrite.
- **Cross-project pattern:** "Governance at a boundary" recurs in the Agentic SDLC project (handoff/verification placement).

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-08-28 | 1.0 | Initial entry from project overview, ingress-governance braindump, daily-brief impact analysis, and Safeheron×RFI deep dive | Periodic review of 04-projects/secure-quantum-environment |

## Related
- [Three-tier quantum network architecture](../technical/three-tier-quantum-network-architecture.md)
- [PQC selection](../technical/post-quantum-cryptography-selection.md)
- [PROJECT-OVERVIEW](../../04-projects/secure-quantum-environment/PROJECT-OVERVIEW.md)

## Notes
- Open questions carried from PROJECT-OVERVIEW still need answers: where PQC and QKD overlap / each owns key material; what cannot be made crypto-agile; how quantum-safety is demonstrated to an auditor.
- The overview doc is still a template — specifics (vendors, exact PQC/hybrid modes, QKD termination point, compliance regime, uptime SLO) are not yet captured.

---

*Last updated: 2026-08-28 | Source: periodic review of 04-projects/secure-quantum-environment*
