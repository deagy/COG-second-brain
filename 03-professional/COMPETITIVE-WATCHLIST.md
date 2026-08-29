---
type: competitive-intelligence
created: 2026-08-28
tags: ["#competitive", "#intelligence", "#tracking"]
---

# Competitive Watchlist

*Companies, people, and organizations worth an eye on. Started as recommendations during onboarding — prune anything that doesn't earn its slot.*

## Watching — quantum-safe security

**Standards and mandates** *(these set the deadlines everything else reacts to)*
- NIST PQC program — the algorithm standards themselves and any additions or parameter changes
- NSA CNSA 2.0 — migration timelines that drive procurement requirements
- ETSI ISG-QKD — QKD interface and protocol standardization
- IETF (TLS, LAMPS, IPSECME working groups) — how PQC actually lands in protocols you deploy

**Implementations**
- Open Quantum Safe / Post-Quantum Cryptography Alliance — liboqs and the reference integrations most stacks build on
- Cloudflare Research — the largest public dataset on real-world PQC handshake deployment and its performance cost
- PQShield, SandboxAQ — PQC vendor tooling and hardware IP

**QKD hardware and networks**
- ID Quantique — QKD systems and QRNG
- Toshiba Quantum Technology — QKD systems and metro network trials
- National QKD testbeds (EuroQCI, and equivalents) — what integration problems surface at scale

**People**
- Bas Westerbaan (Cloudflare) — deployment-side PQC writing, the practical migration view
- Peter Schwabe — co-author on Kyber/Dilithium, ongoing implementation and side-channel work
- Douglas Stebila — Open Quantum Safe, hybrid key exchange design
- Daniel J. Bernstein — the adversarial read on PQC standards and security claims; useful precisely because he disagrees

## Watching — agentic SDLC

- Anthropic — Claude Code, the Agent SDK, and MCP; closest prior art to your dispatch model
- OpenAI — Agents SDK and tool/handoff patterns
- Cognition (Devin), Cursor, All Hands (OpenHands), Aider — the range of autonomy models, from full-auto to pair-style
- LangChain / LangGraph — graph-based orchestration; useful as a contrast to role-based dispatch
- SWE-bench and METR evaluations — the benchmarks anyone will cite at you when judging an agentic pipeline
- Simon Willison — consistently practical, skeptical coverage of what agents actually do

## Why I'm Tracking Them

The quantum-safe list splits into three jobs: standards bodies tell you what you will be required to support and by when, implementations tell you what the migration actually costs, and hardware vendors tell you what integrates with the network stack you have.

The agentic list is prior art. The design questions your `agentic-sdlc` project keeps hitting — how to scope a specialist role, when to hand off, how to verify an agent's output — are the same questions each of these has answered differently. Watch the divergence, not the announcements.

---

*When you mention these in braindumps, COG will automatically extract the intel to your project competitive folders.*
