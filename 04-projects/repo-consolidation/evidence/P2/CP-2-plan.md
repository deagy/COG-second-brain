# P2 — CP-2 plan: retire `agentic-lifecycle`

Covers AC-05: repository archived; anything salvaged exists in exactly one other repository; no `run-record` definition exists outside the kernel.

## What is actually there

`~/agentic-lifecycle`, `deagy/agentic-lifecycle` on GitHub, last commit 2026-08-24. Python package `portable-agentic-lifecycle`. Ten agents, `routing.yaml`, `workflows/`, `skills/`, `examples/`, `src/agentic_lifecycle/`, and two schemas: `gate-result.yaml`, `run-record.yaml`.

## The overlap, measured

Its ten agents are one per lifecycle **phase**:

| Agent | Phase | Capability |
|---|---|---|
| intent-owner | intake | product_intent |
| requirements-engineer | requirements | requirements_analysis |
| solution-architect | design | architecture_design |
| implementation-designer | design | implementation_planning |
| implementation-engineer | build | bounded_implementation |
| go-implementer | build | go_implementation |
| verification-engineer | verification | test_and_evidence |
| security-reviewer | assurance | security_review |
| release-manager | release | release_readiness |
| lifecycle-coordinator | orchestration | workflow_coordination |

cadre's 159 are grouped by **discipline**: engineering 71, testing 18, review 14, security 12, operations 9, authority 8, documentation 7, architecture 6, planning 6, orchestration 3, support 3, data 2, governance 2.

Only one id collides outright (`security-reviewer`). The README's claim that these are two layers — "stage agents own decisions and evidence for a phase; optional technology specialists supply implementation" — is structurally true on that evidence: different axes, phase against discipline.

**But cadre already has the phase layer, and it is the more developed one.** `roster/authority/` holds eight aides, one per lifecycle gate, covering G1–G10 with no gate unassigned. Every stage agent maps onto one: `intent-owner` onto G1's `product-owner-aide`, `solution-architect` onto G3's `system-architect-aide`, `security-reviewer` onto G5's `security-lead-aide`, `verification-engineer` onto G6, `release-manager` onto G7–G9's release aides.

The real difference is authority, not coverage. A stage agent "owns decisions and evidence for a phase". An aide is explicitly forbidden from making, implying, or recording the decision it prepares a package for, and names a human authority instead. Those are two answers to one question, and cadre's is the one with the constraints, the gate mapping, and the boundary rules already written.

## Recommendation: retire wholesale, salvage nothing as code

The schemas are superseded — `run-record.yaml` is a placeholder template with no types or required set, against the kernel's 24-required-field closed schema. The agents are a thinner, earlier expression of a layer cadre implements more rigorously. `routing.yaml` and `workflows/` describe a lifecycle the kernel now owns.

What is worth keeping is the idea its README states plainly, and that is worth one paragraph in the ownership decision rather than a repository.

## Tasks

| ID | Task | Covers | Gate |
|---|---|---|---|
| T-01 | Record the salvage decision: what survives, what does not, and why, in the ownership decision doc | AC-05 | internal |
| T-02 | Confirm no `run-record` or gate contract definition exists outside `cadre-kernel` — grep both remaining repos and cadre's vendored copies | AC-05 | internal |
| T-03 | Archive `deagy/agentic-lifecycle` with a final README note naming where the lifecycle now lives | AC-05 | **external — CP-6 review gate** |

## Open question for the user

Do the ten stage agents die, or does one of them survive as something cadre lacks? The candidate is `lifecycle-coordinator` (phase `orchestration`, capability `workflow_coordination`) — cadre's `orchestration/` holds three roles and gloop is taking dispatch, so whether a phase-level coordinator has a home after P3 is genuinely unclear. Everything else has a cadre counterpart with stronger authority rules.

That is a judgment call about your own design, not something the evidence settles.
