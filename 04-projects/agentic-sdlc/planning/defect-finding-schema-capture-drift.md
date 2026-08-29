---
type: "defect"
project: "agentic-sdlc"
title: "Schema-conformant findings are silently dropped at final-handoff capture"
status: "fixed"
severity: "high"
created: "2026-08-28"
repo: "~/sdk/cadre"
tags: ["#defect", "#agentic-sdlc", "#schema"]
commit: "40644827"
---

# Schema-conformant findings are silently dropped at final-handoff capture

Two contracts describe an agent finding and they disagree. An agent that follows the documented one produces a final-handoff envelope that fails validation and is never captured, without the dispatch reporting a failure.

Filed out of the design work in [[04-projects/agentic-sdlc/planning/per-task-denial-contract]], but independent of it.

## The two contracts

`roster/shared/output-schemas/finding.schema.json` — the contract every role is pointed at. Twelve properties, `additionalProperties: false`, and eight required: `id`, `title`, `severity`, `status`, `summary`, `evidence`, `recommendation`, `owner`. Roles are instructed to conform to it by `roster/README.md:60`, `roster/RUNBOOK.md:283`, `roster/architecture/threat-modeler/AGENT.md:27`, `roster/review/code-reviewer/AGENT.md:44`, and `roster/orchestration/review-response-template.md:20`.

`internal/orchestration/final_handoff_capture.go` — what actually runs. `findingKeys` (line ~64) allows six: `id`, `title`, `severity`, `summary`, `evidence`, `owner`. `validateKeyedList` (line 307) rejects any entry containing a key outside the allowlist and coerces every value through `shortText`, which requires a string.

Nothing compiles `finding.schema.json`. It is not among the embedded contracts in `internal/kernel/contracts/`, and `internal/orchestration/schema_validate.go` loads only `catalog.schema.json` and `routing.schema.json`.

## Impact

`status` and `recommendation` are **required** by the documented schema and **rejected** by the validator. Any finding that satisfies the schema therefore fails capture. So do `affected_assets`, `control_mappings`, `due_date`, and `exception_reference`.

The failure is silent by construction. `AutomaticContextCapture` returns `CaptureResult{"status": "not_captured", ...}`, and the surrounding comment is explicit that a capture failure must not change whether the child completed. The dispatch succeeds, the handoff is not stored, and nothing surfaces the discrepancy.

Failure is per envelope, not per finding: `validateKeyedList` returns an error on the first offending entry, so one non-conformant finding discards the whole final handoff, including its summary, disposition, assumptions, and knowledge-steward candidates.

Severity is high rather than critical: no incorrect data is stored and no gate is bypassed. What is lost is evidence, silently, in the path built to preserve it.

## Reproduction

**Observed.** Verified against `e01dfe29` in an isolated clone by calling `validateFinalHandoff` directly with three envelopes differing only in the shape of `handoff.findings[0]`.

A finding carrying the eight fields `finding.schema.json` marks required — `id`, `title`, `severity`, `status`, `summary`, `evidence`, `recommendation`, `owner`:

```
final_handoff.handoff.findings entries must use the structured finding fields only
```

The control, identical but trimmed to the six keys the capture allowlist permits — `id`, `title`, `severity`, `summary`, `evidence`, `owner`:

```
err = <nil>
```

So the documented-conformant finding is the one rejected, and making it non-conformant is what makes it capture. The error is returned from `validateFinalHandoff` for the envelope as a whole, confirming that one offending finding discards the entire handoff rather than that entry.

A third probe replaced `owner` with null in the otherwise-accepted six-key form:

```
finding.owner must be a non-empty string
```

confirming that the coverage-finding decision needs a change in this file, not only in the schema.

Probe kept at `<scratchpad>/cadre-verify/internal/orchestration/zz_drift_verify_test.go` in a throwaway clone. It is a probe, not a commit — the regression test below is what should land.

## Fix

Reconcile upward, so the documented schema is the single contract:

1. Extend `findingKeys` to `finding.schema.json`'s full property set.
2. Compile and validate against the schema itself rather than an allowlist, using `santhosh-tekuri/jsonschema/v5` — already a dependency in `internal/orchestration/schema_validate.go` — so the two cannot drift again. The byte caps and list bounds stay: they are a capture-transport concern the schema does not express.
3. Permit `owner: null`, per the coverage-finding decision in the denial contract. `shortText` currently rejects it.

Reconciling downward — trimming the documented schema to the validator's six fields — is the cheaper edit and the wrong one. `status` and `recommendation` are load-bearing for the review roles, and `affected_assets` is required by the escape-attribution rule in the denial contract.

## Regression coverage

A test that asserts a minimal `finding.schema.json`-conformant finding captures successfully. Per `handoff-contracts.md`'s falsification requirement, the test must be shown to fail against the current `findingKeys` allowlist before the fix, with the observed failing output recorded, not merely asserted.

Worth adding alongside it: a test that the two contracts agree — that every required property of `finding.schema.json` is accepted by the capture path. That is the test whose absence let this drift open.

## Fix as applied

Commit `40644827`, off `e01dfe29`. Merged fast-forward to `main` and pushed to `origin`; remote `refs/heads/main` verified at `40644827`.

`internal/orchestration/final_handoff_capture.go` — `findingKeys` now mirrors all twelve properties of `finding.schema.json`. The allowlist gained a type, `fieldKind`, because the schema is not uniformly string-typed: `evidence`, `affected_assets`, and `control_mappings` are lists, and `owner`, `due_date`, and `exception_reference` are nullable. `validateKeyedList` switches on that kind instead of special-casing `evidence` by name, and `knowledgeHandoffKeys` was converted to the same form with its behavior unchanged.

`roster/shared/output-schemas/finding.schema.json` — `owner` becomes `"type": ["string", "null"]`, matching the form `due_date` and `exception_reference` already used. It stays in `required`.

`roster/orchestration/review-response-template.md` — states that `owner` is null only for a coverage finding.

`plugin/` regenerated; `generate-plugin --check` and `generate-role-metadata --check` both report current.

Required-field enforcement was deliberately **not** added. The validator allowlists but does not require, and making the schema's eight required fields mandatory here would reject producers currently emitting the six-key shape. That is a separate, breaking decision.

## Regression coverage as applied

`internal/orchestration/final_handoff_finding_schema_test.go`, four tests:

- `TestFindingKeysCoverTheFindingSchema` reads the schema off disk and asserts the two contracts agree in both directions. This is the check whose absence let the drift open.
- `TestSchemaConformantFindingIsCaptured` captures a finding carrying the schema's eight required fields and asserts `status` and `recommendation` survive.
- `TestCoverageFindingCarriesNullOwner` asserts a null owner survives capture as null.
- `TestUnknownFindingFieldIsStillRejected` keeps the widening honest: the allowlist grew to the schema, not to anything a child invents.

**Falsification observed.** With the source fix reverted (`git stash` on the `.go` file alone) and the tests left in place, three of the four fail:

```
--- FAIL: TestFindingKeysCoverTheFindingSchema
    finding.schema.json declares "recommendation" but findingKeys rejects it
    finding.schema.json declares "status" but findingKeys rejects it
    finding.schema.json declares "affected_assets" but findingKeys rejects it
    finding.schema.json declares "control_mappings" but findingKeys rejects it
    finding.schema.json declares "due_date" but findingKeys rejects it
    finding.schema.json declares "exception_reference" but findingKeys rejects it
--- FAIL: TestSchemaConformantFindingIsCaptured
    a schema-conformant finding must capture, got: final_handoff.handoff.findings entries must use the structured finding fields only
--- FAIL: TestCoverageFindingCarriesNullOwner
    a coverage finding must capture, got: finding.owner must be a non-empty string
```

`TestUnknownFindingFieldIsStillRejected` passes either way, correctly: it guards against over-widening rather than describing the defect.

## Test run

`go test ./internal/orchestration/ ./internal/generators/ ./internal/kernel/` all pass. Three packages fail repo-wide — `contextstore`, `engine/executor`, `knowledge` — every failure reading `Binary was compiled with 'CGO_ENABLED=0', go-sqlite3 requires cgo to work`. Verified pre-existing by stashing all changes and re-running: identical failures on the clean tree.

## Open

- Whether other `*Keys` allowlists in the same file have drifted from their documented counterparts. `artifactKeys` and `knowledgeHandoffKeys` were not checked, and `knowledgeHandoffKeys` has a documented counterpart in `roster/shared/knowledge-use-policy.md`.
- Whether `not_captured` should be visible in the dispatch result rather than only recorded. The current design is deliberate and defensible, but a silently discarded handoff is indistinguishable from a runner that returned none.
