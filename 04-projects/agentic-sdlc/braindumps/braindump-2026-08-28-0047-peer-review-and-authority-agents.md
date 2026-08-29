---
type: "braindump"
domain: "project-specific"
project: "agentic-sdlc"
date: "2026-08-28"
created: "2026-08-28 00:47"
updated: "2026-08-28 00:58"
themes: ["peer-review", "authority-hierarchy", "loop-amendment", "gate-re-entry", "agent-governance"]
tags: ["#braindump", "#raw-thoughts", "#agentic-sdlc", "#agents"]
status: "captured"
energy_level: "medium"
emotional_tone: "neutral"
confidence: "high"
---

# Braindump: Peer review between agents, and authority agents that can force the loop to amend

## Raw Thoughts

> Agents must be able to check each other / review their peers. There should be some authority level agents as well (maybe a hierarchy?) that can approve or deny decisions to force the loop to be amended.

**Clarification (00:58):** "the loop" means both — the per-task verify loop *and* the phase sequence: intent → requirements → architecture-design → governance-data → security-crypto → verification → evidence → release-readiness → deployment-auth → runtime-conformance.

## Content Analysis

### Main Themes

1. **Peer review as a structural property, not a role.** Every agent's output should be checkable by another agent. The implied rule is that no agent's output is trusted because of who produced it.
2. **Authority as a separate layer above review.** Reviewers find things; authorities decide what happens because of what was found. Approve or deny is a different power from "here is a finding."
3. **Denial must have teeth — it amends the loop.** A denial that doesn't change what the pipeline does next is decoration.
4. **Both loops are in scope.** The per-task verify cycle and the ten-phase lifecycle. These turn out to be at very different levels of maturity (see Insight 1).
5. **Hierarchy is an open question, not a decision.** Flagged with "maybe" — flat domain-scoped authorities vs. an escalating chain is undecided.

### Questions Raised

- What is the scope of an authority's approval — one artifact, one phase, or the whole run?
- If authorities are hierarchical, what escalates and on whose initiative?
- Can an authority deny on grounds no reviewer raised, or only ratify/override reviewer findings?
- Who reviews the authorities?

### Decisions Contemplated

- Whether the authority layer is a hierarchy or a flat set of domain-scoped approvers.

## Strategic Intelligence

### Key Insights

1. **The phase sequence already implements all three ideas. The per-task loop does not.** The ten phases named in the clarification map exactly onto gates G1–G10 already defined in the cadre suite (`suite/roster/RUNBOOK.md:324-334`), each with a named deciding human authority: G1 Product Owner, G2 Product Owner + Engineering Lead, G3 System Architect, G4 Governance Lead, G5 Security Lead, G6 Product Owner + Engineering Lead, G7 Release Owner, G8 Release Owner, G9 Release Authority, G10 Service Owner. The braindump is describing something largely built at that level and largely absent one level down.

2. **The phase-level amend loop is fully specified — this corrects an earlier reading.** `workflows/new-service.md:39` states it directly: failed gates return to the responsible artifact owner and name the earliest required re-entry gate; a material change invalidates that gate *and every dependent downstream gate*. `workflows/runtime-assurance.md:24` requires recording every invalidated downstream gate and preserving the previous decision as immutable history. `shared/definition-of-done.md:23` makes it a completion condition. Roles including `debugging-engineer`, `incident-commander`, and `support-triage-agent` each recommend a lifecycle re-entry gate as an output; runtime findings re-enter at G1 per `workflows/support-escalation.md:15`. This is a real amend mechanism, not a stop.

3. **The best rule in the suite is the reviewer-becomes-author rule, and it lives only at gate level.** `workflows/new-service.md:41`: "A reviewer who makes a material correction becomes an author and must transfer approval to a different independent reviewer." That is precisely the peer-review property in the braindump, stated as a transfer obligation rather than a prohibition. Nothing states it for the per-task review loop.

4. **The per-task loop's amend path is one sentence.** `orchestration/handoff-contracts.md:133` — a rejected handoff returns to its author without being treated as approval. No cascade semantics, no named re-entry point inside the task, no independence requirement on the re-review. Everything rich at phase level is missing here.

5. **Neither loop has a termination condition, and the suite already knows better.** Nothing bounds how many times a gate can be re-entered, or says what happens when a run fails the same gate repeatedly. Meanwhile `shared/library-standards.yaml:94-97` instructs implementers to `set_attempt_or_elapsed_time_limit` and `emit_retry_exhaustion_telemetry` in the code they write. The suite requires bounded retry of its outputs and does not apply it to itself.

6. **`halt-authority` already encodes the anti-capture rule worth generalizing.** It may not lift its own halt — lifting requires the causing condition resolved *and independently confirmed*. Any new authority role should inherit that.

### Pattern Recognition

- **Connection to previous thinking:** Answers the constraint in [[04-projects/agentic-sdlc/PROJECT-OVERVIEW]] — "who checks an agent's output, and how is 'a worker never grades its own homework' enforced?" The suite's answer at gate level is the reviewer-becomes-author transfer rule.
- **Cross-project echo:** COG's own harness caps the fix loop at two attempts per cycle with a read-only verifier and a separate `fix-agent`. That is a concrete answer to Insight 5 that the cadre roster currently lacks.
- **Structural asymmetry worth naming:** the mature loop is the one with human authorities attached to it. The per-task loop, which runs far more often and entirely without humans, has the weaker rules. Frequency and autonomy both argue it should have the stronger ones.

### Strategic Implications

- The design work is not adding roles or inventing a hierarchy. It is porting three phase-level rules down to the per-task loop: earliest-affected re-entry point, invalidation cascade, and reviewer-becomes-author transfer.
- Both loops then need the one rule neither has: a bound on amend cycles and a defined terminal state when the bound is hit.
- Hierarchy remains a downstream question. G1–G10 already establishes an ordering of authorities by phase; whether they escalate *to each other* only matters once denial semantics are uniform across both loops.

## Action Items

### Immediate (24-48 hours)
- [ ] Write the per-task denial contract, porting from `workflows/new-service.md:39-41`: earliest affected step to re-enter, what downstream work is invalidated, and the independence requirement on re-review 📅 2026-08-29

### Short-term (1-2 weeks)
- [ ] Define the amend bound for both loops — max cycles or elapsed limit, terminal state on exhaustion, and what telemetry is emitted; mirror `shared/library-standards.yaml:94-97` 📅 2026-09-04
- [ ] Decide flat-vs-hierarchical for the authority layer, after both denial contracts exist 📅 2026-09-04
- [ ] Audit the seven authority-phase `*-aide` roles against the "cannot lift its own block" rule from `halt-authority` 📅 2026-09-04

### Strategic Considerations
- An authority layer only earns its cost if denials are rare and consequential. Worth defining upfront what fraction of runs should hit one, so the layer can be judged as over- or under-triggering rather than assumed correct.
- G1–G10 assigns a *human* to every gate. As per-task autonomy grows, the question becomes which per-task denials must surface to one of those humans and which resolve inside the loop.

## Connections
- **Relevant Projects:** [[04-projects/agentic-sdlc/PROJECT-OVERVIEW]]
- **External sources read while processing:** `~/.claude/plugins/marketplaces/cadre-team/plugin/suite/roster/` — `RUNBOOK.md:318-334`, `workflows/new-service.md:39-41`, `workflows/runtime-assurance.md:24`, `workflows/support-escalation.md:15`, `shared/definition-of-done.md:23`, `shared/library-standards.yaml:85-97`, `orchestration/handoff-contracts.md:133`, `orchestration/escalation-policy.md:16`, `agents/{halt-authority,approval-router,system-architect-aide}.md`

## Domain Classification
- **Primary Domain:** project-specific — agentic-sdlc (98%)
- **Reasoning:** Explicitly about agent-to-agent review and lifecycle authority structure, the project's core subject.
- **Cross-Domain Elements:** The verifier/fixer separation and attempt cap apply to COG's own harness design.
- **Privacy Level:** private

## Processing Notes

### Emotional Context
- **Energy Level:** medium — terse, design-mode phrasing
- **Emotional Tone:** neutral. Late-night design thinking; not inferring more from three sentences.

### Confidence Assessment
- **Overall Analysis:** 92%
- **Domain Classification:** 98%
- **Strategic Insights:** 92% — claims about gate mechanics were read directly from the cadre source files cited above, with line numbers, rather than recalled
- **Correction logged:** an earlier pass concluded re-entry was unspecified in both loops. That came from grepping only `orchestration/*.md`. A roster-wide search found the phase-level mechanism documented across `workflows/`, `shared/definition-of-done.md`, and several role definitions. The gap is narrower and better located than first stated: per-task amend semantics and the amend bound, not re-entry as such.

---

*Processed by COG Brain Dump Analyst*
