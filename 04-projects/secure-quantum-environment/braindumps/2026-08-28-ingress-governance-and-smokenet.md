---
type: braindump
project: Secure Quantum Environment
created: 2026-08-28
tags: ["#braindump", "#architecture", "#governance", "#ingress", "#smokenet", "#performance"]
domain: professional + project
---

# Braindump — Ingress/Governance Design & smokenet Performance

## Raw capture (lightly cleaned, structure preserved)
- At **SQS**, I'm the tech lead of my team.
- Thinking about platform design based on documentation from the CEO, **Ray**.
- Core question: do we need a **router / orchestrator / load-balancer at the ingress of each system** in the stack?
- Stack is **3 layers**: distribution, perimeter, core.
  - **Core** — central, most protective. *Data never leaves.*
  - **Perimeter** — boundary & translation point between core and the rest.
  - **Distribution** — interface end users interact with.
- Each layer interconnected; idea of an **ingress/egress blocker based on governance** — a **governance-backed firewall**.
- Separately: investigating **smokenet** (container recently received).
  - Uses **one-time pads for obfuscation** — elegant, but appears to **massively drag throughput**.
  - Appears built in **Python**. Considering **reverse-engineering + rebuilding** in **Go** (or **C++**) for performance.

## Themes
1. **Layered trust boundary** — where does enforcement live in a 3-tier stack?
2. **Governance at the edge** — policy as a first-class ingress/egress control.
3. **Throughput vs. security primitive** — OTP is secure but expensive; is the cost algorithmic or just the language?
4. **Build vs. rewrite** — reverse-engineer smokenet vs. find/adopt something leaner.

## Open Questions
- [ ] What did **Ray** actually mean by ingress controls — a single gateway per layer, or one per system? (Get the source doc.)
- [ ] Is governance enforcement a **per-layer** concern or a **per-system** concern? These have very different scaling/failure profiles.
- [ ] Do we conflate three different jobs into one "ingress component": (a) **routing/orchestration**, (b) **load balancing**, (c) **governance/policy enforcement**?
- [ ] How do we make "data never leaves core" **structural** (no outbound data path out of core) rather than just a policy we hope is enforced?
- [ ] Is smokenet's throughput drag from the **OTP algorithm itself** or from the **Python interpreter**? (Cheap to test — see action items.)
- [ ] Rewrite in Go/C++, or is OTP the wrong primitive for bulk data regardless of language?

## Decisions / Considerations
- **Lean toward gating at layer boundaries, not per-system.** A governance firewall per individual system is heavy and hard to keep consistent; a policy enforcement point per layer edge is leaner and easier to audit. Per-system load balancing is fine where horizontal scaling actually exists.
- **Separate concerns architecturally.** Orchestration (routing decisions), load balancing (traffic distribution), and governance (policy) have different failure modes, scaling needs, and update cadences — don't force them into one box just because they sit at the same physical ingress.
- **"Core never egresses data" should be structural.** The crown-jewels invariant is safest when the core has no data-out path at all (only declassified/derived data crosses perimeter), not when it relies on a policy check that could be misconfigured.
- **OTP is likely the bottleneck, not Python.** One-time pads are information-theoretically secure but O(n) memory + O(n) bandwidth, and OTP-obfuscated data cannot be compressed or incrementally processed. For **bulk data**, OTP is the wrong tool — it shines for key material and small high-value secrets. A Go/C++ rewrite will cut interpreter overhead but will not remove the algorithmic cost. Worth isolating the source before investing in a rewrite.

## Action Items
- [ ] Pull **Ray's platform design doc** and capture what "ingress control" means to him, verbatim.
- [ ] **Benchmark smokenet** to separate algorithm cost vs. interpreter cost (e.g., time a pure-OTP round-trip in Python vs. a trivial memcpy of the same volume). Cheap, high-signal.
- [ ] Draft the **governance policy model** (what is enforced, where, and what the deny-default looks like) before choosing any ingress component.
- [ ] Decide **per-layer vs. per-system** gating once the policy model is on paper.
- [ ] Revisit the **rewrite decision** after the benchmark — only reverse-engineer if the bottleneck is confirmed to be the language/runtime.

## Strategic Insights / Pattern Recognition
- This maps directly onto **zero-trust**: verify and enforce at every layer boundary, least privilege, fail closed. The distribution→perimeter→core model is a clean expression of that.
- **"Data never leaves core" ≈ a trusted computing base / secure enclave.** Treat the core as read-mostly on sensitive data with a single, audited declassification chokepoint at the perimeter.
- **OTP-for-obfuscation vs. PQC-for-key-exchange** is a distinction worth holding: the watchlist (Open Quantum Safe, Cloudflare PQC deployment data, Stebila/Schwabe) is full of real data on the *cost* of strong crypto in production. The smokenet drag is a live, in-hand data point on that exact question — worth measuring and writing down.
- The same design tension shows up in the **agentic-sdlc** project (scope a role, decide where handoff/verification lives) — governance-at-a-boundary is a pattern you're hitting in two domains at once.

## Competitive Intel
- smokenet is an **internal tool evaluation**, not a watched competitor — not added to the watchlist. Flagging only because OTP-throughput is a live data point relevant to the quantum-safe security watch items.
