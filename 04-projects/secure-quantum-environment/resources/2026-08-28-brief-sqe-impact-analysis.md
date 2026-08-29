---
type: analysis
project: Secure Quantum Environment
slug: secure-quantum-environment
created: 2026-08-28
tags: [#analysis, #brief, #sqe, #pqc, #qkd, #roadmap]
sources: [daily-brief-2026-08-28, braindump 2026-08-28, safeheron-rfi-pqc-pilot-deep-dive, The Paypers, HKMA Fintech 2030]
---

# 2026-08-28 Brief → Secure Quantum Environment: Impact Analysis

> Maps every in-window story from the daily brief onto the SQE project — its
> 3-tier architecture (distribution/perimeter/core), the OTP-throughput problem,
> and the open questions in PROJECT-OVERVIEW. Each story is graded on how it
> lands on SQE and what it changes.

## Rubric
- **Direct:** changes a SQE design decision or opens a concrete action.
- **Strategic:** shapes the timeline, standards, or threat context SQE lives in.
- **Watch:** relevant but no verified action yet.
- **Context:** weakly sourced, monitor only.

## The stories, mapped

### 1. Safeheron × RFI PQC pilot — DIRECT
PQC custody pilot on ML-DSA-65 / NEAR testnet. Depth in `safeheron-rfi-pqc-pilot-deep-dive.md`.
- **How it lands:** it is the live migration-strategy + crypto-agility reference case. ML-DSA-65 is the reference algorithm pick; the **non-custodial 2-of-2 MPC** separates key *ownership* (kept by each institution) from *operational signing* — a direct parallel to the braindump's "data never leaves core" invariant: ownership/retention stays on the protected side, only transactions cross the perimeter.
- **What changes:** nothing today beyond what the deep-dive says. Anchor SQE's PQC selection to ML-DSA-65 and treat the signature-size cost (50×) as a first-class design constraint.

### 2. Anthropic Model Hardware Standard (MHS) — STRATEGIC
Protocol for AI agents to safely operate physical devices (research labs + advanced manufacturers).
- **How it lands:** if SQE ever lets agents control lab/quantum hardware (QKD/PQC equipment), MHS defines the driver-interface **and** the authorization model. This plugs straight into the braindump's "governance at the edge / fail closed" — the ingress governance must validate not just data but agent/tool-call *provenance*.
- **Action:** watch MHS's authorization model; fold agent provenance into the governance policy model.

### 3. Go 1.27 generic methods (+ `encoding/json/v2`) — WATCH
Flagship-language ergonomics.
- **How it lands:** relevant to the smokenet **rewrite** decision. The deep-dive already shows the bottleneck is the OTP algorithm (~50× PQC signature cost), not the interpreter — so a rewrite *for throughput is likely moot*. If the rewrite happens for other reasons (maintainability), 1.27 generic methods and json/v2 are favorable.
- **Action:** defer the rewrite until the benchmark confirms the bottleneck (braindump action item); Go 1.27 is a plus, not a reason to rewrite now.

### 4. Claude Code Auto Mode malware + Marimo MCP edit-mode flaw — WATCH (threat)
Prompt-injection / tool-abuse as the live attack surface for autonomous coding agents.
- **How it lands:** SQE's governance-at-boundary must extend to **agent-driven actions**. If an agent can call into the perimeter, the ingress control must authenticate the caller (agent + tool), not just the payload. Reinforces "fail closed."
- **Action:** add agent/tool-call provenance as a governance input when drafting the policy model.

### 5. Shopify / AGENTS.md dispute — CONTEXT
Standards fragmentation + vendor-lock-in risk for agent-config tooling.
- **How it lands:** indirect — only if SQE leans heavily on agent tooling. No verified action.

### 6. IonQ QKD + hybrid air-fiber QKD — CONTEXT (weak)
QKD is in SQE's scope (PQC+QKD) but these are single-tier context.
- **How it lands:** the real SQE question (PROJECT-OVERVIEW) is *where PQC and QKD overlap and where each owns key material* — not the latest QKD vendor news. No verified fresh data this window. Watch the watchlist (SandboxAQ, ID Quantique, Toshiba).

## The regulatory clock (bonus from The Paypers)
- **HKMA Fintech 2030:** quantum readiness by **2030**, with a **Quantum Preparedness Index** + whitepaper to benchmark banks' PQC progress.
- **MAS + ABS ACT taskforce** (July 2026): industry-wide cyber/tech resilience against frontier-AI risk.
- **Action:** treat 2030 as the sector quantum-readiness deadline and HKMA's Index as the benchmark to align to. This is SQE's concrete "why now."

## Synthesis — what changes for SQE
1. **PQC is a migration + governance problem, not an algorithm problem.** NEAR's partial migration (user signing PQ, validators still classical) shows the real friction is governance, partial migration, and signature-size cost. ML-DSA-65 is the reference pick.
2. **The OTP-throughput answer is coming.** The braindump's benchmark will likely confirm OTP is the bottleneck (same ~50× cost curve PQC lives in). Plan: OTP for key material and high-value secrets, not bulk data.
3. **Governance-at-boundary is validated externally.** The pilot's observer→governance phasing mirrors the braindump's "gate at layer boundaries." Cross-jurisdiction governance is the hard part — the per-layer model is the right shape.
4. **The 2030 clock is real.** HKMA + MAS give a hard regulatory deadline for quantum readiness.
5. **Agent-driven attack surface is maturing.** If SQE agents operate hardware, MHS + prompt-injection defenses become part of the governance model.

## Recommended next actions (prioritized)
1. **Run the smokenet benchmark** (braindump action item) — cheap; resolves rewrite vs. OTP-primitive.
2. **Track the Safeheron/RFI whitepaper** (watcher #1) — first real PQC custody performance data.
3. **Draft the governance policy model** (braindump action item) — incorporate agent/tool-call provenance + the observer→governance phasing from the pilot.
4. **Align crypto-agility plan to HKMA's Quantum Preparedness Index / 2030 deadline.**
5. **Watch Anthropic MHS** for the hardware-control authorization model.
