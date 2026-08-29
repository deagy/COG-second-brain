---
type: "braindump"
domain: "project-specific"
project: "agentic-sdlc"
date: "2026-08-28"
created: "2026-08-28 19:28"
themes: ["rewrite-vs-refactor", "separation-of-concerns", "agent-definitions", "lifecycle-kernel", "gloop", "recall"]
tags: ["#braindump", "#raw-thoughts", "#agentic-sdlc", "#strategy"]
status: "captured"
energy_level: "medium"
emotional_tone: "decisive"
confidence: "high"
---

# Braindump: Scrapping cadre in favour of gloop and recall

## Raw Thoughts

> I am considering scrapping cadre in its current form and restarting it from scratch. I like the agent definitions, so would probably like to keep that, or at least a variant of it, but the agentic-sdlc portion I feel is half-baked and brittle. I have started a couple of other side projects `gloop` and `recall` attempting to separate core functionalities with recall being the defacto knowledge store, and gloop acting as the agent orchestrator.

## Content Analysis

### Main Themes

1. **Rewrite rather than refactor.** The judgment is that cadre's current form is not worth carrying forward whole, and the successor should start clean.
2. **Separation of concerns as the organizing move.** One repository doing orchestration, knowledge, lifecycle gates, packaging, and role definitions becomes two libraries with single responsibilities: `gloop` orchestrates, `recall` stores.
3. **The role catalog is the asset.** The 159 agent definitions are named explicitly as the part worth keeping, possibly in a variant form.
4. **The lifecycle layer is the liability.** "Half-baked and brittle" is aimed specifically at the agentic-sdlc portion, not at the roles or the CLI.

### Questions Raised

- Which run-record contract survives: `agentic-lifecycle/schemas/run-record.yaml` or `cadre/kernel/contracts/run-record.schema.json`?
- Does the lifecycle stay Python? `agentic-lifecycle` is Python; `gloop` and `recall` are Go. A Go orchestrator consuming lifecycle contracts makes that boundary a choice rather than an inheritance.
- Ten phase-accountable stage agents, or 159 flat specialisms, or both at different layers?
- Does cadre get archived, maintained during the transition, or kept as the integration point that consumes the three libraries?
- Is there a migration path for whatever is already in the knowledge store, or does it start empty?

### Decisions Contemplated

- Scrap and restart versus evolve cadre in place. Leaning scrap.
- Keep the agent definitions as-is versus keep a variant. Leaning keep, form undecided.

## Strategic Intelligence

### Key Insights

1. **Today's evidence supports the diagnosis but locates the brittleness one layer away from where the braindump puts it.** Three defects shipped to cadre today — `40644827`, `1988b428`, `1a301f38` — and none of them was in the lifecycle logic. All three were in `internal/orchestration/final_handoff_capture.go`, the seam where an agent's returned work enters the store, and all three were the same failure: two authorities for one shape, with nothing holding them together. `finding.schema.json` said twelve fields while a hand-maintained Go allowlist accepted six. `dispatch-contract.md` offered `plan-only` while the validator rejected it. The artifact manifest's field set was documented nowhere at all, so an agent guessing from the kernel's contract would write `artifact_id` and be rejected. Each failure was silent: `AutomaticContextCapture` returns `not_captured` and, by explicit design, does not fail the dispatch.

2. **That failure class is a property of having two sources of truth, not of the lifecycle.** Splitting cadre into an orchestrator and a store does not remove the seam — it makes it an API boundary between two repositories, which is a *harder* place to keep two representations honest, not an easier one. The rewrite only escapes the class if each contract has exactly one authority and every other representation is generated from it.

3. **`gloop` currently gets that right, and it would be easy to lose.** It has 145 non-test Go files against 143 test files, packages separated as `roster`, `selector`, `dispatch`, `catalog`, `validate`, `plugin`, `persistence`, and — notably — no `*.schema.json` anywhere and no `jsonschema` dependency. Validation is Go-side, so the Go types *are* the contract and there is no prose copy to drift from. That immunity lasts exactly until someone writes a markdown contract describing the same shapes, which is how cadre acquired the problem.

4. **`recall` already designs out a concrete cadre wart.** cadre's knowledge store needs the cgo-backed `mattn/go-sqlite3`; `bin/cadre` carries a cgo-first-with-cgo-less-fallback build specifically because a `CGO_ENABLED=0` binary links cleanly and then fails at runtime on every `cadre knowledge` call, with nothing warning at build time. `recall` uses `modernc.org/sqlite` — pure Go, zero CGO. That removes the degradation path rather than working around it.

5. **The role definitions are the part least coupled to the machinery, which is why keeping them is the easy call.** Audited today: the eight authority aides are uniform and cover G1–G10 with no gate unassigned; `halt-authority` carries a genuinely sharp independence rule (it may not lift its own halt); `approval-router` is bound to an authority matrix it may not edit. None of that depends on how dispatch or storage is implemented.

6. **The lifecycle already has a home, and the real problem is that it has two.** `~/agentic-lifecycle` — "Portable Agentic Lifecycle", last commit 2026-08-24 — is a repository-independent set of agent definitions and workflow contracts, carrying ten stage agents (`intent-owner`, `requirements-engineer`, `solution-architect`, `implementation-designer`, `implementation-engineer`, `verification-engineer`, `security-reviewer`, `release-manager`, `lifecycle-coordinator`, `go-implementer`), plus `routing.yaml`, `workflows/`, `skills/`, and two schemas: `gate-result.yaml` and `run-record.yaml`. Meanwhile cadre's `kernel/contracts/` holds `run-record.schema.json`, `lifecycle-gates.json`, and `mutation-gates.json` — the same contracts again, in JSON, in a repository whose RUNBOOK asserts a two-repo boundary with a standalone kernel. Two authorities for one shape, which is exactly the defect class behind all three of this morning's bugs, one scale up: file-level there, repository-level here.

7. **The clean shape is already built; what is missing is the decision to commit to it.** `recall` owns storage, `gloop` owns orchestration, `agentic-lifecycle` owns gates, authorities, run records, and stage agents. The role catalog is markdown and YAML — a data package the other three consume, not a fourth code project. cadre then becomes the thin integration point that wires them together, or it retires, because every responsibility it currently holds is owned somewhere else.

8. **The "variant" of the agent definitions may already be written.** `agentic-lifecycle`'s README states its organizing principle directly: it "separates lifecycle accountability from implementation expertise: stage agents own decisions and evidence for a phase; optional technology" specialists supply the rest. Ten phase-accountable agents plus optional specialists is a different model from cadre's 159 flat specialisms, and it is a plausible answer to "a variant of the agent definitions" without designing one.

### Pattern Recognition

- **Connection to earlier today:** [[04-projects/agentic-sdlc/braindumps/braindump-2026-08-28-0047-peer-review-and-authority-agents]] and the [[04-projects/agentic-sdlc/planning/per-task-denial-contract|per-task denial contract]] built on it. That contract is written against cadre's structures — `handoff-contracts.md`, `final_handoff_capture.go`, `finding.schema.json`. Its *rules* are portable; its wiring is not.
- **Recurring pattern across the day:** every design conclusion reached by reasoning was wrong, and every one reached by reading the code held. The step-1 wiring plan, the "no machine consumers" audit, and the `blocked`-splits question were each corrected by looking. Worth carrying into the rewrite as a working rule rather than a lesson.
- **Evolution:** this morning's thinking was about adding rigor to cadre's loop. Twelve hours later the question is whether that loop should exist in cadre at all. The denial-contract work is not wasted by that — it is the specification a successor would implement — but its target moved.

### Strategic Implications

- The decision that matters is not scrap-versus-evolve, and it is not where the lifecycle goes either — it already lives in `agentic-lifecycle`. It is whether that repository is treated as the authority and cadre's `kernel/contracts/` deleted, or the reverse. Everything else follows from picking one.
- Whatever is decided, the single-authority rule is the one property worth protecting from day one in both new repositories, because it is the only defect class that reproduced three times in one day.
- cadre still has value as the integration point even under a full split: it is where roles, orchestration, storage, and lifecycle currently meet, and something has to play that part.

## Action Items

### Immediate (24-48 hours)
- [ ] Pick the surviving run-record contract — `agentic-lifecycle/schemas/run-record.yaml` or `cadre/kernel/contracts/run-record.schema.json` — and delete or generate the other 📅 2026-08-29

### Short-term (1-2 weeks)
- [ ] Write down what cadre becomes: archived, maintained during transition, or the integration point consuming gloop and recall 📅 2026-09-04
- [ ] Compare `agentic-lifecycle`'s ten stage agents against cadre's 159 roles and decide whether they are two layers of one model or two competing ones 📅 2026-09-04
- [ ] Decide whether the lifecycle stays Python, given `gloop` and `recall` are Go 📅 2026-09-04
- [ ] Record the single-authority rule in both new repositories before either grows a markdown contract 📅 2026-09-04

### Strategic Considerations
- A rewrite that keeps the roles inherits their assumptions. The roles assume gates, human authorities, evidence chains, and an approval matrix. Keeping them is a decision to keep that model, whether or not the lifecycle code comes along.
- cadre is at `180a00ca` with five commits shipped today and a clean suite. Scrapping it is cheaper now than it will be after further investment, and more expensive than it was yesterday. Neither observation argues for a direction; both argue for deciding soon rather than drifting.

## Connections
- **Related Braindumps:** [[04-projects/agentic-sdlc/braindumps/braindump-2026-08-28-0047-peer-review-and-authority-agents]]
- **Relevant Projects:** [[04-projects/agentic-sdlc/PROJECT-OVERVIEW]]
- **Planning:** [[04-projects/agentic-sdlc/planning/per-task-denial-contract]], [[04-projects/agentic-sdlc/planning/defect-finding-schema-capture-drift]]
- **Repositories read while processing:** `~/sdk/cadre` @ `180a00ca`, `~/sdk/gloop` @ `83409d6`, `~/sdk/recall` @ `65dd3d0`, `~/agentic-lifecycle` @ `7866fb8`

## Domain Classification
- **Primary Domain:** project-specific — agentic-sdlc (90%)
- **Reasoning:** The subject is the future of the agentic-sdlc work. Filed here because gloop and recall are its successors rather than separate efforts, though that may not hold for long.
- **Cross-Domain Elements:** None. This is a build decision, not a career or personal one.
- **Privacy Level:** private

## Processing Notes

### Emotional Context
- **Energy Level:** medium
- **Emotional Tone:** decisive rather than frustrated. "Half-baked and brittle" is a diagnosis, and the successors already exist and have commits — this reads as a decision being confirmed, not one being agonized over.

### Confidence Assessment
- **Overall Analysis:** 90%
- **Domain Classification:** 90% — gloop and recall may warrant their own project folders soon, which would move future notes
- **Strategic Insights:** 92% — claims about all three repositories were read from the working trees and git logs today, not recalled
- **Areas Requiring Clarification:** whether "scrapping cadre" means the repository is retired or only the agentic-sdlc portion is. The insights above hold either way, but the action items differ sharply.
- **Corrected after first pass:** the initial reading concluded the split left the lifecycle homeless. It does not — `~/agentic-lifecycle` has owned it since before this, and is four days from its last commit. The gap is duplication, not absence. Found by looking rather than reasoning, which is the third time today.

---

*Processed by COG Brain Dump Analyst*
