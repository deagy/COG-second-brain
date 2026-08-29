---
type: knowledge
domain: technical
project: Secure Quantum Environment
topic: OTP Throughput & Smokenet
created: 2026-08-28 11:17
last_updated: 2026-08-28
source: periodic-review
version: "1.0"
tags: ["#knowledge", "#secure-quantum-environment", "#performance", "#otp", "#smokenet"]
related:
  - 05-knowledge/product/secure-quantum-environment.md
  - 05-knowledge/technical/post-quantum-cryptography-selection.md
  - 04-projects/secure-quantum-environment/braindumps/2026-08-28-ingress-governance-and-smokenet.md
---

# OTP Throughput & Smokenet

## Overview
Engineering concern about throughput when using one-time pads (OTP) for obfuscation — surfaced via an internal container, "smokenet," and resolved (so far) by reasoning against the real cost curve of strong crypto in production. The core question: is the throughput drag from the OTP algorithm itself or from the Python interpreter?

## Current State
- **smokenet:** a container recently received; uses **one-time pads for obfuscation**; appears to **massively drag throughput**; believed to be built in **Python**.
- **Working hypothesis:** the bottleneck is the **OTP algorithm, not Python.** OTP is information-theoretically secure but O(n) memory + O(n) bandwidth, and OTP-obfuscated data cannot be compressed or incrementally processed. For **bulk data**, OTP is the wrong tool — it shines for key material and small high-value secrets.
- **A Go/C++ rewrite would cut interpreter overhead but NOT the algorithmic cost.** So "rewrite for throughput" is likely moot; the benchmark must confirm the bottleneck first.
- **Cross-confirmation from PQC data:** the Safeheron/RFI pilot shows PQC signatures are ~50× Ed25519 in size — the drag lives in bytes-in-flight/verify/storage, not the language. Benchmark the real cost curve (signature bytes + verify CPU + storage), not "OTP vs. memcpy" in isolation.

### Key Details
- **Build vs. rewrite decision:** only reverse-engineer/smokenet-rebuild if the benchmark confirms the bottleneck is the language/runtime. If it's the algorithm, no rewrite fixes bulk-data throughput.
- **Go 1.27 context:** generic methods + `encoding/json/v2` are favorable *if* a rewrite happens for maintainability reasons — but is not itself a reason to rewrite now.
- **Cheap, high-signal test:** time a pure-OTP round-trip in Python vs. a trivial memcpy of the same volume to separate algorithm cost from interpreter cost.

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-08-28 | 1.0 | Initial entry from ingress-governance braindump and daily-brief impact analysis | Periodic review |

## Related
- [SQE overview](../product/secure-quantum-environment.md)
- [PQC selection (cost analog)](./post-quantum-cryptography-selection.md)
- [Original braindump](../../04-projects/secure-quantum-environment/braindumps/2026-08-28-ingress-governance-and-smokenet.md)

## Notes
- **Pending action:** run the benchmark; revisit the rewrite decision only after it confirms the bottleneck.
- smokenet is an internal tool evaluation, not a watched competitor — not added to the watchlist.

---

*Last updated: 2026-08-28 | Source: 04-projects/secure-quantum-environment braindumps + brief impact analysis*
