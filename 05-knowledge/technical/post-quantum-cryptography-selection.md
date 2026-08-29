---
type: knowledge
domain: technical
project: Secure Quantum Environment
topic: Post-Quantum Cryptography Selection
created: 2026-08-28 11:16
last_updated: 2026-08-28
source: periodic-review
version: "1.0"
tags: ["#knowledge", "#secure-quantum-environment", "#pqc", "#crypto-agility", "#safeheron"]
related:
  - 05-knowledge/product/secure-quantum-environment.md
  - 05-knowledge/technical/three-tier-quantum-network-architecture.md
  - 04-projects/secure-quantum-environment/resources/safeheron-rfi-pqc-pilot-deep-dive.md
---

# Post-Quantum Cryptography Selection

## Overview
Guidance for SQE's PQC algorithm and key-model choices, anchored on the one concrete public reference case available: the Safeheron × Responsible Fintech Institute (RFI) cross-regional PQC custody pilot. The headline takeaway: PQC selection is a migration + governance + signature-size problem, not merely an algorithm choice.

## Current State
- **Reference algorithm:** **ML-DSA-65** (NIST FIPS 204, NIST security Level 3) is the financial-grade industry pick, from the Safeheron/RFI pilot. Treat it as the reference point to reason against, not a surprise.
- **Signature-size cost is load-bearing:** ML-DSA-65 public key ≈ 1,952 B (vs. Ed25519's 32 B) and signature ≈ 3,308–3,309 B (vs. 64 B) — roughly **50×** Ed25519. This cost applies to serialization, storage, and gas, not just signing.
- **Key model:** **non-custodial 2-of-2 MPC** — separates key *ownership* (kept by each institution) from *operational signing* (shared). Labeled *tentative* in the pilot; not locked.
- **Partial migration is the norm:** NEAR left its validators on classical crypto. The parts with the highest cadence / trust requirements migrate last, if at all.

### Key Details
- **Verified against:** FIPS 204 / the `ml-dsa-65` crate constants and Connolly parameter table. Testing surface was wallet generation + on-chain transfer on the NEAR testnet.
- **Participants (multi-jurisdiction):** regulators ADGM, GFSO (Bhutan), MFSA (Phase 1 observers → Phase 2 governance); banks Bison Bank, DK Bank. Deliverables: research whitepaper + open-sourced Safeheron PQC protocol code.
- **Phasing that matters:** observers → governance workstream. This phased involvement is what turns a technical pilot into regulatory precedent; the cross-jurisdiction governance is the hard part.
- **Critical reading:** "Quantum-resistant NEAR testnet" overstates scope (only the user signing path); only two banks named; no performance numbers (latency/throughput) published yet — the whitepaper is the first real data to wait for.

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-08-28 | 1.0 | Initial entry from Safeheron×RFI deep dive and daily-brief impact analysis | Periodic review |

## Related
- [SQE overview](../product/secure-quantum-environment.md)
- [Three-tier architecture](./three-tier-quantum-network-architecture.md)
- [Original deep dive](../../04-projects/secure-quantum-environment/resources/safeheron-rfi-pqc-pilot-deep-dive.md)

## Notes
- Open question "what cannot be made crypto-agile?" has a real-world answer: high-cadence / high-trust parts migrate last.
- The 2030 regulatory clock (HKMA Quantum Preparedness Index / MAS+ABS ACT) is the concrete deadline to align the crypto-agility plan to.

---

*Last updated: 2026-08-28 | Source: Safeheron×RFI deep dive + 04-projects brief impact analysis*
