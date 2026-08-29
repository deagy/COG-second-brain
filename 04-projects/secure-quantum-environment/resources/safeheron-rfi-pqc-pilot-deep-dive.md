---
type: research-note
project: Secure Quantum Environment
slug: secure-quantum-environment
created: 2026-08-28
tags: [#research, #pqc, #safeheron, #rfi, #digital-assets, #custody]
sources: [Safeheron press release, The Quantum Insider, Quantum Computing Report, Open Source For You, NEAR nearcore docs]
---

# Safeheron × RFI Post-Quantum Digital Asset Pilot — Deep Dive

> Reference note supporting the Secure Quantum Environment project. The
> braindump (2026-08-28) flagged OTP/signature throughput as its central
> engineering worry; this note is the closest real-world data point on what PQC
> actually costs in signature size, gas, and signing latency. Read the
> "Throughput connection" section first if that's your angle.

## At a Glance

On **24 August 2026** (Singapore dateline), the **Responsible Fintech Institute
(RFI)** and digital-asset custody vendor **Safeheron** launched a cross-regional
pilot to evaluate **post-quantum cryptography for digital-asset transactions** in a
regulated, multi-jurisdiction setting. RFI convenes and owns governance; Safeheron
supplies the protocol and engineering. The near-term thesis: prove that an
institutional-grade PQC signing workflow can run *across banks and regulators in
different legal jurisdictions*, then publish it as a shared reference.

This is the first story in the daily brief flagged as a **direct hit on the SQS
stack** — not because Safeheron is a competitor, but because it is the most
concrete public look at exactly which PQC algorithm, which key model, and which
operational friction real financial institutions are choosing today.

## The Facts (as announced)

**Protocol / crypto**
- PQC research program built around a **multi-party computation (MPC)** protocol.
- Signature standard: **ML-DSA-65**, i.e. **NIST FIPS 204** at NIST security
  Level 3.
- **Testing surface:** wallet generation + on-chain transfer activity on the
  **NEAR testnet**.
- **Key model:** a *tentative non-custodial 2-of-2 MPC* design — intended to
  minimize operational burden while keeping key ownership with each institution.

**Participants (multiple jurisdictions)**
- Regulators (Phase 1 = observers; Phase 2 = governance workstream):
  - **ADGM** — Abu Dhabi Global Market
  - **GFSO** — Gelephu Financial Services Office (Bhutan)
  - **MFSA** — Malta Financial Services Authority
- Banks: **Bison Bank**, **DK Bank** (more institutions "in discussion").

**Deliverables**
- A **research whitepaper** covering protocol design + testing findings.
- **Open-sourcing** of Safeheron's PQC protocol code (framed as "stand up to
  independent scrutiny, not ask for trust").

**Phasing**
- **Phase 1:** participants test a shared signing environment; regulators observe.
- **Phase 2:** regulators join a governance workstream; whitepaper published.

**Attributed voices**
- Chia Hock Lai — Chairman, RFI ("a standard we all helped write").
- Jag Foo — Chief Security & Policy Officer, Safeheron.
- António Henriques — CEO, Bison Bank.
- David Peters — Managing Director, GFSO.
- Alan Decelis — Head of Supervisory ICT Risk & Cybersecurity, MFSA.

## Technical Deep Dive

### ML-DSA-65 is the load-bearing choice — and it is big

Verified against FIPS 204 / the `ml-dsa-65` crate constants (`constants.rs`) and
the Connolly parameter table:

| Item | ML-DSA-65 | Ed25519 (current norm) |
|---|---|---|
| Public key | 1,952 B | 32 B |
| Signature | ~3,308–3,309 B | 64 B |
| Private key (seed / expanded) | 32 B / ~4,032 B | 32 B |
| NIST strength | Level 3 (~AES-192) | ~Level 2 |

A signature goes from **64 B to ~3,308 B — roughly 52× larger**. The private key
stays a compact 32-byte seed (expanded form is cached for signing), so key *storage*
isn't the problem — *signature and public-key bandwidth* are. Every signed
transaction, access key, and on-chain verification now carries ~50× more bytes.

### The NEAR testnet is genuinely PQC-capable (not just marketing)

NEAR shipped ML-DSA-65 to **testnet, stabilized at protocol v85** under the
`PostQuantumSignatures` feature, backed by `aws-lc-rs::unstable::ML_DSA_65`
(AWS-LC). This is real, but **narrowly scoped** — which matters for reading the
pilot honestly:
- **In scope:** transaction signing, ML-DSA-65 access keys, and an `ml_dsa_verify`
  on-chain host function.
- **Out of scope (still classical):** validator / staking keys remain ed25519-only;
  block/chunk signatures and implicit-account derivation unchanged.
- **Pricing:** an extra `ml_dsa_65_verification_cost` = **100 Ggas** per signature
  (~2× the measured ~50 µs verification-time delta over classical).
- **A real bug they flagged:** the VM pre-charge passes raw `public_key_len` to the
  gas-fee helper while runtime exec uses `trie_id_len()` — a **~40× difference for
  MLDSA65**. NEAR itself marked this as needing an end-to-end test.

Net: NEAR is "quantum-resistant" for the *user-facing signing path only*. Callers
and validators still run classical crypto. That partial migration is the honest
## Throughput Connection (your braindump's core worry)

The braindump's key hypothesis — *"the OTP throughput drag is likely the algorithm,
not Python; OTP is O(n) memory/bandwidth that can't be compressed or incrementally
processed"* — is **validated by exactly this class of problem**, and the Safeheron
pilot is the cleanest public evidence:

- PQC signatures are **inherently ~50× larger** than classical ones by construction.
  This is not an implementation bug and not a language choice — it is the size of the
  lattice math. No amount of compression or incremental processing recovers it; the
  signature is what it is.
- NEAR measures the *compute* side too: **~50 µs mean verification-time delta**, priced
  as **100 Ggas** extra per signature. So you pay twice — bigger bytes on the wire AND
  more CPU to verify.
- The ~40× `public_key_len` vs `trie_id_len()` gas mismatch NEAR had to fix shows the
  cost leaks into **gas/pricing, serialization, and storage** — not just signing.

**Implication for the benchmark the braindump recommended:** don't benchmark "OTP vs.
memcpy" in isolation. Benchmark the *real* cost curve you're worried about —
signature bytes transacted + verify CPU + storage — under PQC, because that is where
the drag actually lives. If your OTP path is dominated by bytes-in-flight, PQC makes
that term ~50× bigger and there is no algorithmic shortcut around it. That finding
itself is decision-relevant: it tells you PQC is the wrong tool for high-volume bulk
data paths and the right tool for low-volume key material / signing events — which is
precisely the braindump's own conclusion.

## Why This Matters for Secure Quantum Environment

- **Algorithm choice is now visible:** the industry's financial-grade pick is
  ML-DSA-65 (FIPS 204, Level 3). If SQE is selecting PQC, this is the reference point
  to reason against, not a surprise.
- **Key model, not just algorithm:** the **non-custodial 2-of-2 MPC** design is the
  operational answer to "who holds the key." It separates *key ownership* (kept by each
  institution) from *operational burden* (shared signing). That separation maps directly
  onto the braindump's "gate at layer boundaries, not per-system" guidance — ownership,
  routing, and policy enforcement are different concerns with different failure modes.
- **The evidence story:** SQE's open question *"how is quantum-safety demonstrated to
  an auditor?"* has a template here — a whitepaper + open-sourced, independently
  audited protocol. The pilot is explicitly building that reference; watch for the
  whitepaper.
- **Partial migration is the norm:** NEAR left validators on classical crypto. SQE's
  own open question ("what cannot be made crypto-agile?") has a real-world answer: the
  parts with the highest cadence / trust requirements migrate last, if at all.

## Critical Reading (what's real vs. what's PR)

- **Real:** ML-DSA-65 on NEAR testnet is shipped and verifiable in nearcore; the
  signature-size and gas costs are quantified, not hand-waved.
- **PR / to watch:**
  - "Quantum-resistant NEAR testnet" overstates scope — only the user signing path.
  - "2-of-2 MPC" is labeled *tentative* — the key model is not locked.
  - Only **two** banks named; "additional institutions in discussion." This is a
    proof-of-concept, not a production rollout.
  - No performance numbers published yet (latency, throughput, signature counts). The
    whitepaper is the first real data — that's the artifact to wait for.
  - Safeheron is both the vendor and the open-sourcer — "independent scrutiny" is a
    promise, not yet an outcome.
- **Structural read:** the phased regulator involvement (observe → govern) is the
  mechanism that turns a technical pilot into regulatory precedent. The crypto is the
  easy part; cross-jurisdiction governance is the hard part they're sequencing around.

## Sources

- Safeheron (primary): "Consortium launches cross-regional pilot on post-quantum
  security" — 2026-08-24, https://safeheron.com/blog/cross-regional-post-quantum-security-pilot/
- The Quantum Insider — https://thequantuminsider.com/2026/08/24/rfi-safeheron-post-quantum-security-digital-assets/
- Quantum Computing Report — https://www.quantumcomputingreport.com (2026-08-24)
- Open Source For You — https://www.opensourceforu.com/2026/08/safeheron-plans-to-open-source-pqc-code-for-financial-security/
- NEAR nearcore (verified implementation): `docs/architecture/how/post_quantum_signatures.md`;
  NEAR blog "Preparing NEAR for the Quantum Computing Era"; finway.com.ua (2026-06-03).

state of the art in August 2026.
