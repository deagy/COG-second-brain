---
type: "spec"
project: "agentic-sdlc"
title: "Per-Task Denial Contract"
status: "draft"
created: "2026-08-28"
updated: "2026-08-28"
source_braindump: "[[04-projects/agentic-sdlc/braindumps/braindump-2026-08-28-0047-peer-review-and-authority-agents]]"
intended_home: "suite/roster/orchestration/denial-contract.md"
tags: ["#spec", "#agentic-sdlc", "#agents", "#draft"]
---

# Per-Task Denial Contract

Draft. Written to sit alongside `roster/orchestration/handoff-contracts.md` and use its vocabulary. Every rule below either ports an existing gate-level rule down to the per-task loop or closes a gap that exists at both levels; the provenance line under each says which.

## Scope

This contract governs what happens when a receiving agent, reviewer, or authority refuses a handoff inside a single task. Lifecycle gate decisions (G1–G10) are out of scope and remain governed by `roster/workflows/new-service.md` and the target project's lifecycle kernel. The one place the two meet is amend exhaustion, below.

Three rules already cover part of this ground and are not restated here:

- A rejected handoff returns to its author without being treated as approval (`handoff-contracts.md`, closing section).
- A receiving reviewer who makes a material correction becomes an author, cannot approve that revision, and another independent reviewer must decide it (same).
- Material changes are reported to the lifecycle kernel for impact analysis and any required gate invalidation (same).

What follows adds the parts those three leave open: which kind of refusal was issued, where work resumes, what the refusal voids, how many times it may repeat, and what happens when it repeats too often.

## Denial dispositions

Every refusal states exactly one disposition. The vocabulary is deliberately three values, each mapping to a mechanism that already exists in the suite rather than a new one.

**`amend`** — the artifact is defective and can be corrected within this task. Returns to the author with a re-entry step and an invalidation set. Bounded by the amend budget below. This is the ordinary case and should be the large majority of refusals.

**`escalate`** — the refusal cannot be resolved inside the task: instructions conflict, the required decision exceeds the role's authority, or the condition is one `roster/orchestration/escalation-policy.md` already reserves for a human (production diagnostics, persistent mutation, destructive action, privileged access, risk acceptance, policy exception, customer-impact commitment, unresolved critical or high finding). Leaves the task and enters the escalation path. Not bounded by the amend budget, because it is not a retry.

**`halt`** — a stop condition under `halt-authority`'s remit. Arrests work beyond this task. Only `halt-authority` may issue it, and per its own definition it may not lift it: lifting requires the causing condition resolved *and* independently confirmed.

A refusal with no disposition is itself an unauditable handoff and is returned under the existing completeness rule.

**These live in the denial record, not in the handoff enum.** `internal/orchestration/final_handoff_capture.go` defines `handoffDispositions` as `complete`, `approve`, `request-changes`, `needs-information`, `blocked`, and validates every captured envelope against it. That enum stays unchanged.

The two answer different questions. A handoff disposition states the condition of the work. A denial disposition states what happens next after a refusal. Neither derives from the other: `blocked` covers both `escalate` and `halt`, which differ in blast radius and in who may lift them, and `request-changes` says nothing about where work resumes. Housing the denial vocabulary in the denial record is the qualifier that distinction needs, without widening a shared enum for a narrower purpose.

The link between them is an obligation, not a mapping: a handoff carrying `request-changes` or `blocked` must also carry a denial record, and that record says what happens next. `request-changes` implies `amend`; `blocked` implies `escalate` or `halt`, and the denial record says which.

Per-artifact vocabularies are already how this repository works, which is why adding a fourth for denials is consistent rather than duplicative. `internal/kernel/decide.go` uses `approved | rejected | request-changes` for human gate decisions. `final_handoff_capture.go` uses the five above for an agent's returned envelope. `.agents/skills/run-agent-orchestration/references/dispatch-contract.md:96` uses `approve | request-changes | needs-information | blocked | plan-only` for the orchestrator's consolidated run record. These are three artifacts, not three spellings of one — their field lists differ, and `final_handoff` appears nowhere in the orchestration skill.

Two hazards noted while confirming this, neither blocking:

- The envelope validator rejects `plan-only`, verified by probe. Correct, since the run record is a different artifact — but an agent that has read the orchestration skill and is then asked for a final handoff could reach for it and have the envelope silently dropped. Plausible, not demonstrated; nothing currently routes a run record into an envelope.
- The kernel's `approved`/`rejected` against the envelope's `approve`/`blocked` is a naming trap for anyone reading both.

## Denials against a human authority's decision

A denial can only amend or halt work its issuer has authority over. When the denied artifact is a decision already made by a human gate authority, none of the three dispositions above apply: the denial is advisory, voids nothing, consumes no amend budget, and its only valid outcome is to be recorded where the deciding human will read it.

*Provenance: found by testing this contract against a real refusal, not derived.* In `roster/orchestration/runs/cadre-feature-portable-platform-2026-08-11/product-intent.md`, two independent reviewers (`security-reviewer` and `architecture-authority`) returned `request-changes` against OD-2, a Product Owner decision the record had already marked RESOLVED. The record states the correct handling directly: "A review returning `request-changes` on a decision does not unmake it, and no agent in this run held authority to." The objection was filed as an input to a decision rather than a decision, and the Product Owner reversed OD-2 himself at Revision 6 on those grounds.

Mapped naively, that refusal would have become an `amend`, since `request-changes` implies `amend` above. Every part of that is wrong here. There is no author an agent may return work to. Nothing downstream was invalidated, and the record is explicit that the G1 approval and OD-2's disposition both stand. No work was blocked; the run continued while the objection sat where the decision-maker would see it.

The reviewers used `request-changes` because the envelope enum offers nothing closer, which is a gap in that vocabulary rather than a misuse of it.

Two obligations follow, and the second is the one the run record earns:

- **State the authority boundary.** A denial names whether the artifact's author is inside the issuer's authority. When it is not, the disposition field is omitted rather than guessed, and the denial is recorded as an objection.
- **Route it where the decision-maker reads it.** An objection filed only as a task-local finding is lost. The run record puts it plainly: "a section inviting challenge is worth nothing if the challenge is then filed somewhere the decision-maker will not read it." An objection against a gate decision belongs in the record that decision lives in.

This is a scope boundary on the contract rather than a fourth disposition. The three dispositions answer what happens to the work next; an objection against a human decision answers who it is addressed to, which is a different axis and does not belong in the same enum.

## Required fields of a denial record

A denial is a first-class record, not a rejection message. It carries:

- `denial_id` — stable identifier, same pattern as `finding.schema.json` ids.
- `disposition` — `amend | escalate | halt`.
- `task_id`, `revision` — the exact revision denied. A denial is void for any other revision, matching the binding rule the `*-aide` roles already apply to decision packages.
- `denier` — role and instance. Needed to evaluate independence on re-review.
- `findings` — one or more findings conforming to `roster/shared/output-schemas/finding.schema.json`. A denial that cites no finding is an opinion; return it. Severity and status come from that schema and are not redefined here.
- `input_revisions` — the revisions this task's inputs were bound to when it was dispatched. See cross-task supersession below.
- `reentry_step` — see below. Required for `amend`, omitted for `escalate` and `halt`.
- `invalidates` — the set of completed steps or outputs voided by this denial. May be empty, but must be stated; silence is not the same as nothing.
- `amend_attempt` — which attempt of the budget this denial consumes. Required for `amend`.
- `lift_condition` — what must be true for this denial to be satisfied, in terms observable by the re-reviewer. Required for `halt`, recommended otherwise.

Denial records are append-only. A superseded denial is preserved as immutable history rather than edited or deleted, matching `roster/workflows/runtime-assurance.md:24`.

**A denial may rest on grounds no prior reviewer raised.** The reviewer is frequently the first pair of eyes on an artifact and has nothing upstream to cite; requiring a prior finding would make the first review incapable of denying. The constraint that matters is evidentiary, not procedural, and `finding.schema.json` already enforces it — `evidence` is required with `minItems: 1`. An authority may therefore deny on novel grounds but never on an unevidenced opinion. `halt-authority`'s stricter rule, that a halt must cite a condition already evidenced by another role's output, incident state, or evidence-chain integrity, is specific to halts and does not generalize: a halt stops work beyond the task that raised it, so it carries a higher bar than a denial whose blast radius is one artifact.

## Re-entry point

An `amend` denial names the **earliest affected step** in the task, not the step that produced the denied artifact. Work resumes there.

*Provenance: ports `roster/workflows/new-service.md:39`, "failed gates return to the responsible artifact owner and name the earliest required re-entry gate", from gate scope to task scope.*

The distinction matters because the two are frequently different. A reviewer rejecting an implementation because the acceptance criteria were ambiguous is not asking for a better implementation; the earliest affected step is the one that produced the criteria. Naming the producing step instead sends the loop back to redo work that was never the defect, which is the shape in which an amend budget gets burned without converging.

Where the earliest affected step lies outside the task boundary, the correct disposition is `escalate`, not an `amend` with an out-of-range re-entry step.

## Invalidation cascade

Work downstream of `reentry_step` that depended on the invalidated output is void and must be redone, not reviewed again as-is.

*Provenance: ports "a material change invalidates that gate and every dependent downstream gate" (`new-service.md:39`) down one level.*

Two consequences worth stating explicitly, because both are places the cascade is easy to skip:

- **Approvals on voided work are void.** An approval binds to a revision. If the revision is superseded, the approval does not carry forward, exactly as a gate signature does not carry across revisions in `approval-router`'s rule.
- **Evidence collected against voided outputs is void as evidence, not as history.** It stays in the record; it stops counting toward acceptance. Falsification evidence for regression tests (`handoff-contracts.md`) must be re-observed against the amended implementation, since a test's ability to fail is a property of the implementation it runs against.

## Cross-task supersession

When a denial voids an output that another live task already consumed, no cross-task cascade mechanism is required. Revision binding already covers it.

Each task declares `input_revisions` at dispatch. A denial supersedes a revision. Any live task holding a superseded input revision is void by the same binding rule the suite applies everywhere else — an `*-aide` decision package is void for any revision other than the one it was built against, and `approval-router` counts a signature only when recorded against the exact revision under review. The holding task's next handoff fails completeness on a stale input, which is the existing rejection path rather than a new one.

This deliberately avoids routing intra-phase dependencies through lifecycle gate invalidation, which is correct but far heavier than the situation warrants.

The residual issue is not cascade but dispatch ordering: a task that consumes another's output before that output was accepted is a scheduling defect. Fix it at dispatch, where `selection.schema.json` already models task relationships, rather than compensating for it downstream.

## Independence on re-review

Whether the same reviewer may decide the amended revision depends on what they did, not on which disposition they issued:

- Reviewer denied and did not edit → **may** re-review. Continuity is an advantage here; they know the condition.
- Reviewer denied and materially corrected the artifact → **may not** approve it. They are now an author, and an independent reviewer decides. This is the existing handoff-contracts rule; it applies unchanged.
- Disposition was `halt` → the denier may not lift it under any circumstances, and the confirmation must come from a role that is neither the author nor the halting authority.

The asymmetry is intentional. The reviewer-becomes-author rule exists to stop self-approval of one's own work, and a reviewer who only refused has not produced work to approve.

## Amend budget

Each task carries a bounded amend budget: **a maximum number of `amend` cycles, an elapsed-time limit, or both.** The budget is declared in the task brief before dispatch, not chosen while the loop is running.

*Provenance: closes a gap present at both levels. Nothing in the roster currently bounds re-entry. `roster/shared/library-standards.yaml:94-97` already requires implementers to `set_attempt_or_elapsed_time_limit` and `emit_retry_exhaustion_telemetry` in the code they write; this applies the same discipline to the loop that writes it.*

The budget varies by the risk/maturity band the task runs under. These bands — `reversible`, `committed`, `released` — are defined in the project's release process and already referenced by `approval-router`, `phase-gate`, `doctrine-conformance`, and `claim-conformance`. They are not the same thing as the capability tiers in `roster/shared/agent-autonomy.yaml`, which is a permission matrix (`allowed`, `on_request`, `human_approval`, `never`) rather than a risk model.

| Band | Amend cycles | Reasoning |
|---|---|---|
| `reversible` | 3 | Mistakes are cheap to undo and human attention is the scarce resource. Let the loop grind. |
| `committed` | 2 | Balanced default. |
| `released` | 1 | A wrong artifact is expensive and a human glance is comparatively cheap. Escalate early. |

The allocation is deliberately inverted from the intuition that high-stakes work deserves more attempts. More attempts means more autonomous iteration without review, which is the opposite of what a released artifact wants. The useful property of tying the budget to the band is that the band becomes a single lever controlling how much human attention the system consumes overall.

Budget accounting:

- `escalate` and `halt` do not consume budget. They are exits, not retries. Neither does a liveness timeout, below.
- An `amend` whose `reentry_step` is *earlier* than the previous denial's re-entry step resets nothing; the budget counts denials, not distance.
- Repeated denial at the same `reentry_step` for the same finding id is the signal that the loop is not converging. Two consecutive such denials should be treated as budget exhaustion regardless of remaining count, since the third attempt is unlikely to differ.

## Exhaustion

When the amend budget is exhausted, the task does not fail silently, retry once more, or return a best-effort artifact. It converts to `escalate` and surfaces to the human authority for the lifecycle gate the task sits under.

This is the property that makes the per-task loop bounded. Every unresolved per-task disagreement terminates at a named human within a known number of cycles, rather than looping between agents indefinitely or resolving by whichever agent gives up first.

The escalation record carries the full denial chain — every denial record, in order, with its findings and re-entry steps — so the deciding human sees what was tried, not only that it failed. A summary of the chain is not a substitute; the individual records are what shows whether the loop was converging slowly or oscillating.

## Liveness timeout

Separate from the amend budget, each step carries a **liveness timeout**: a maximum elapsed time with no handoff returned. Breaching it converts the step to `escalate`.

The two bounds catch different failures and are deliberately not merged. The cycle cap detects non-convergence — the loop is producing denials and not making progress. A timeout detects a hang, which produces *zero* denials and is therefore invisible to a cycle cap at any setting. A single "budget" covering both would leave hung tasks unbounded.

Three properties follow from that separation:

- **Per step, not per task.** Whole-task durations vary by orders of magnitude and no single limit fits them; time spent on one step without returning is roughly independent of overall task size.
- **Disposition is `escalate`, never `amend`.** There is no artifact to amend. A hung task reaching a human labelled as budget exhaustion misreports what failed, and the two need different responses.
- **Does not consume amend budget.** A step that never returned has not been through a review cycle.

The initial value is a deliberately generous placeholder rather than a tuned one. The purpose is catching a hang, not enforcing pace; a tight timeout would convert slow-but-progressing work into escalations and inflate the escalation-minutes metric that is supposed to detect over-triggering. Tune from observed step durations once telemetry exists.

If the motivation for a time bound is cost rather than hangs, this is the wrong lever — the banded cycle cap and the escalation-minutes metric already control cost, and a timeout only adds a second thing to tune against the same objective.

## Telemetry and calibration

Every denial emits: `task_id`, `disposition`, `denier` role, `reentry_step`, `amend_attempt`, risk band, and finding severities. Exhaustion additionally emits the full chain and the elapsed time consumed. A liveness timeout emits the step, the elapsed time, and the last completed handoff.

**Denial rate is not the metric to target.** It is an input, and a confounded one: a low rate means either clean upstream work or an incurious reviewer, and the number alone cannot distinguish them. Setting a target on it invites the layer to be tuned toward the target rather than toward correctness.

Target the two outcomes instead, which are not confounded:

- **Escape rate** — defects caught at a lifecycle gate that a per-task reviewer should have caught. Rising escapes mean the layer is under-triggering. This requires tagging gate-level findings with whether an earlier per-task review had the artifact in scope.
- **Human escalation minutes** — time spent by named gate authorities on escalations originating from per-task exhaustion. Rising minutes mean the layer is over-triggering, or the budget is too tight for the band.

Let denial rate float wherever those two put it.

One cheap in-loop proxy is worth watching in the meantime: the share of `amend` denials whose highest finding severity is `low` or `informational`. Those are style denials consuming budget that convergent work needs, and a large share is the clearest early signal that the layer is grading the wrong thing. `roster/shared/risk-severity-model.md` already defines the severity semantics this relies on.

### Attributing an escape

A gate-level finding counts against an earlier per-task review only when all three hold:

1. The affected asset was in that reviewer's declared inputs. Necessary but not sufficient — scope is assets by dimension, not assets alone.
2. The finding's dimension falls within that role's remit. `control_mappings` on the finding gives a machine-checkable hook against the role's declared domain, so a crypto reviewer does not absorb an accessibility defect in a file they read.
3. The defect was present at the revision that reviewer examined. This condition does most of the work and is the easiest to omit; without it, every later-introduced defect attributes backwards and the metric penalizes reviewers for the future.

**Attribute to the role, never to a run or an agent instance.** The metric exists to find under-specified review roles, not to score runs. As a per-run scoreboard it drives defensive denial, which inflates the low/informational share above — the two measures would then push against each other. Aggregating at role level removes the incentive.

Sort every escape into one of three buckets: **attributed**, **not-present-at-revision**, and **out-of-remit**. The third is the most valuable output here: a defect that no role's remit covered is a gap in the role catalog rather than a review failure.

All three buckets route to `agent-performance-evaluator`, which is the suite's existing feedback role and already declares "defect records and human corrections traced back to that role's prior output" as an input. It also already separates a one-off error from a recurring failure mode, which is the distinction that decides whether an escape is worth acting on. Its escalation condition covers this case almost verbatim — a recurring pattern with real consequence, "repeatedly missed a blocking condition another role should have caught," not yet corrected in the role's own definition.

From there a confirmed recurring gap becomes a roster change under `roster/workflows/agent-suite-maintenance.md`, authored per `agent-authoring` and independently reviewed, with `agent-version-control` owning provenance of the definition. The evaluator stays advisory and may not modify a role definition itself; that separation is why it is the right channel for the finding and the wrong one for the fix.

Two routes are explicitly not used. `knowledge_steward_handoffs` feeds a retrieval store curated by a steward with no authority over the roster, so a catalog gap filed there becomes retrievable and unactioned — though a lesson *drawn from* a gap may separately be store-worthy, which is a different artifact. And filing directly as suite maintenance contradicts that workflow's own scope: it is for the routine, non-defect case, and states that a defect report about the suite's behavior belongs to `debugging` even when it touches the same files.

This needs one amendment to `agent-performance-evaluator`: its scope is currently "is this role producing correct output," which presumes a role exists. Out-of-remit escapes are the case where none does, so it needs **coverage findings** as a second finding type alongside its correctness findings.

A coverage finding conforms to `finding.schema.json` with one change: `owner` becomes nullable, and a null owner means the roster itself owns the finding. The change is `"type": ["string", "null"]`, matching the form `due_date` and `exception_reference` already use in that schema, so `minLength: 1` continues to reject an empty string while permitting null.

`owner` stays in `required`. A coverage finding must state its ownerless status explicitly rather than omit the field — the same reason `invalidates` is mandatory-but-possibly-empty above: silence and "nothing" have to be distinguishable. A null owner is also the machine-readable signal that routes the finding to roster maintenance rather than to a role, so it carries meaning that an absent field would lose.

This requires a code change, not only a schema edit. `internal/orchestration/final_handoff_capture.go` runs every finding value through `shortText`, which requires a string, so a null `owner` is rejected at capture today. See Enforcement below.

One prose consumer also needs an edit: `roster/orchestration/review-response-template.md:20` lists owner among required finding content with no null case. The other canonical references — `roster/README.md:60`, `roster/RUNBOOK.md:283`, `roster/architecture/threat-modeler/AGENT.md:27`, `roster/review/code-reviewer/AGENT.md:44` — point at the schema without restating its fields and need nothing. Everything under `plugin/`, `provider/`, `cline-plugins/`, and `codex-agents/` is generated and picks the change up on regeneration.

## Open questions

- **Initial liveness timeout value.** A placeholder until step-duration telemetry exists. Whether it should also vary by risk band, as the amend budget does, is untested — the argument against is that a hang is a hang regardless of stakes.
- **Where denial records are validated.** The capture validator runs at the dispatch boundary and only on envelopes a runner returns. Denials raised inside a task, between agents that are not separate dispatches, do not pass through it. Whether those need a second validation point, or whether every denial should be forced through an envelope, is undecided.

## Enforcement

Findings are validated in code, but not against `finding.schema.json`. Two contracts describe the same object and they disagree.

`finding.schema.json` defines twelve fields and requires `id`, `title`, `severity`, `status`, `summary`, `evidence`, `recommendation`, and `owner`. Nothing compiles it: it is not among the kernel's embedded contracts in `internal/kernel/contracts/`, and `internal/orchestration/schema_validate.go` loads only `catalog.schema.json` and `routing.schema.json`.

What actually validates a finding is `validateKeyedList` in `internal/orchestration/final_handoff_capture.go:307`, checking each entry against a `findingKeys` allowlist of six — `id`, `title`, `severity`, `summary`, `evidence`, `owner` — rejecting any key outside it and coercing every value through `shortText`, which requires a string.

Three consequences bear directly on this contract:

- **A schema-conformant finding fails capture.** `status` and `recommendation` are required by the documented schema and absent from the allowlist, so a finding that follows the documentation is rejected. The rejection is silent by design: `AutomaticContextCapture` returns `not_captured` and must not change whether the child completed. The handoff is simply never stored.
- **Null `owner` is rejected today.** `shortText` requires a string, so the coverage-finding decision above needs a change in this file, not only in the schema.
- **`affected_assets` cannot survive capture.** The escape-attribution rule depends on it, and it is outside the allowlist.

The dispatch side is unaffected. `selection.schema.json` is an embedded kernel contract and is validated, so `input_revisions`, the banded amend budget, and the liveness timeout land on enforced ground.

**Reconcile upward before building on either.** Align the capture validator to `finding.schema.json`: extend `findingKeys` to the full field set, permit null `owner`, and compile the schema with `santhosh-tekuri/jsonschema/v5`, already a dependency in `schema_validate.go`. Reconciling downward — cutting the documented schema to the validator's six fields — would drop `status` and `recommendation`, which the review roles rely on, and `affected_assets`, which the escape-attribution rule requires.

This drift is a defect in its own right and does not wait on the denial contract; it silently drops conforming handoffs today. Written up separately in [[04-projects/agentic-sdlc/planning/defect-finding-schema-capture-drift]].

## Adoption sequence

0. ~~Reconcile `finding.schema.json` with the capture validator~~ — done, commit `40644827`. The disposition half resolved without a code change: `handoffDispositions` stays as it is and denials carry their own vocabulary, so `blocked` neither splits nor gains a qualifier.
1. ~~Define `denial.schema.json`~~ — done, commit `51be12bc`. One correction to this step as written: `schema_validate.go` validates static repository config (`catalog.yaml`, `routing.json`, `roster.json`), so a runtime denial record has no file there to validate. It is validated on the capture path in `final_handoff_capture.go`, beside findings, and carried as `handoff.denials`. `TestTheSchemaAndTheValidatorAgree` runs the same denials through the schema and the capture path and fails when they disagree, since the Go side reimplements the schema's `if`/`then` rather than compiling it.
2. Add `reentry_step`, `invalidates`, and `input_revisions` to that schema, with the cascade and supersession rules stated in the contract prose.
3. Add the banded amend budget and the liveness timeout to the task brief template (`roster/orchestration/task-brief-template.md`, which already has a slot for re-entry behavior) and wire both terminal paths into the existing escalation path.
4. Add telemetry, then the escape-attribution rule, the `agent-performance-evaluator` coverage-finding type, and the nullable `owner` with its one template edit. Observe before setting targets on escape rate or escalation minutes.

Steps 1 and 2 are inert on their own — they make denials describable and checkable without changing control flow. Step 3 is the one that changes what the system does.

Validation against real refusals is done, and it changed the contract: the portable-platform run's OD-2 objection did not classify into the three dispositions at all, which produced the authority-boundary section above. Doing it before step 1 was the point — the schema would otherwise have encoded `request-changes` as `amend` unconditionally. Further cases are still worth sampling, particularly any real `needs-information` refusal, which none of the run records appear to carry.
