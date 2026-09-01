---
type: knowledge
domain: technical
project: Verification Harness
topic: Checks That Depend On The Room
created: 2026-09-01
last_updated: 2026-09-01
source: repo-consolidation P4/P5 session
version: "1.0"
tags: ["#knowledge", "#verification", "#ci", "#testing", "#repo-consolidation"]
related:
  - WORKFLOW.md
  - .claude/skills/closed-loop/SKILL.md
  - .claude/agents/task-verifier.md
  - 04-projects/repo-consolidation/evidence/P5/north-star-evidence-audit.md
  - 04-projects/repo-consolidation/evidence/P5/ledger.md
---

# Checks That Depend On The Room

## Overview
Seven checks looked green across one repo-consolidation ultragoal (P1–P5), and none of them was evidence, for a common reason: each answered a question about the environment it happened to run in rather than the property it claimed to verify. Three were CI guards satisfied by a sibling checkout that exists on a developer machine and never on a runner; one was a config-isolation test that covered one env var while resolution order made a different one decisive; one passed for a reason unrelated to the property under test; one was a migration verifier built from a fixture that resembled the real artifact but wasn't; and comments — assertions about what the code does — rotted the same way test results do, including one claiming coverage that didn't exist.

## Current State
- **Three repositories, one bug, one caught.** `recall`'s `TestTheContractMatchesItsOrigin` fell back to a sibling `../cadre` checkout to find its comparison fixture — present on the author's machine, absent on any GitHub runner — so recall's CI was red on `v0.3.0` while the ledger recorded "full suite green." Found and fixed in `37d336e` (v0.3.1). The identical shape was live and unnoticed in the other two repositories touched by the same ultragoal: cadre's `validate` workflow had failed **10/10 consecutive pushes to `main`** since `1ed3169a` — the exact commit a ledger row cites as an AC-02 PASS — because `AGENTIC_SDLC_BIN`/`KERNEL_CONTRACTS_DIR` were never set on the runner; gloop's `ci.yml` had failed **4/4 pushes** since `pkg/govplan` landed, for the same reason. All three guards were *correctly written* to hard-fail rather than skip under CI — the defect was that nobody wired their inputs, not that the guards were weak. [Source: [[04-projects/repo-consolidation/evidence/P5/north-star-evidence-audit.md]] | 2026-09-01 | confidence: high]
- **A config-isolation test that covered the wrong variable.** `TestEveryGlobalOnlyFieldIsRefusedFromAProjectFile` passed on a clean laptop and failed on a wired CI runner for reasons unrelated to the refusal logic it tested: its isolation helper cleared `XDG_CONFIG_HOME` but not every field's own resolution variable, so the verdict depended on which environment variables happened to be set on the machine running it. Fixed by having `isolateConfigEnv` clear every field's variable and restore it after. [Source: [[04-projects/repo-consolidation/evidence/P5/ledger.md]] | 2026-09-01 | confidence: high]
- **A test that passed for the wrong reason.** Neutering the classification check in cadre's CLI left `TestKnowledgeSearchMissingClassification` green, because a *different* missing-scope error happens to return the same exit code the test asserts on. The criterion survived only because a second, broader test (`TestTheCLIRefusesEveryContractCase`) covers the real property — the narrow unit test would not have caught the deletion by itself. [Source: [[04-projects/repo-consolidation/evidence/P5/north-star-evidence-audit.md]] § Weakly verified | 2026-09-01 | confidence: high]
- **A verifier built on a plausible fixture instead of the real artifact.** A migration's own component verifier built its "legacy store" fixture from the staged schema alone and passed. Only a store written by the actual pre-migration binary carried the old engine's `chunks` table, which recall's additive schema initializer doesn't overwrite — it sees `chunks` already present, creates only what's missing, and reports ordinary success, leaving a store that is neither a valid legacy store nor a valid new one. Every later `search`/`ingest-accepted` then failed with an opaque `no such column` error nowhere near the command that caused it, and nothing distinguished the corrupted state from a healthy or empty one. The quickstart's first command was the one that silently destroyed the corpus. No amount of care *inside* the fixture would have caught this — the fixture itself was the wrong artifact to test against. [Source: [[04-projects/repo-consolidation/evidence/P4/CP-4-integration.md]] | 2026-09-01 | confidence: high]
- **A comment is a claim too, and it rots the same way.** Five stale rationales were corrected across the session, all true when written and all describing code that had since moved: four blamed cadre's cgo requirement on the knowledge store after it stopped needing cgo (`internal/contextstore` and `internal/engine/executor` still do, the store no longer does), and one told operators to install a kernel from the repository it had already been extracted out of — corrected across four operator-facing messages. Worse: one test comment claimed a sibling test covered a property "separately and without a binary," and that test did not exist — a comment asserting coverage is exactly as unverified as a green CI badge, and more dangerous, because nothing re-runs it. [Source: [[04-projects/repo-consolidation/evidence/P4/CP-2-plan.md]], [[04-projects/repo-consolidation/evidence/P4/CP-3v-T05-component.md]], [[04-projects/repo-consolidation/evidence/P5/ledger.md]] | 2026-09-01 | confidence: high — `grep -rn "func TestTheKernelVersionPinSatisfiesOurOwnProvider"` returned nothing while `provider_compatibility_test.go` named it as covering the pin; the missing test was then written]

### Key Details
- **The fix that generalizes, for one instance of the family: attach a run ID, not an exit code.** `.claude/lib/ci-status.sh` resolves each repository's HEAD sha and requires a *successful* run for that exact sha on the actual runner; "no run" and "still running" both count as not-green. It's wired into the ultragoal north-star gate and the closed-loop CP-5 post-condition already. This closes the sibling-checkout family; the other instances above need a verifier asking "what does this check actually depend on?", not a script.
- **The family test:** a check is suspect, independent of its pass/fail history, if its answer would change on a different machine, with a different fixture, or with the mechanism under test deleted. Reproduce the failure path (mutate the guard, run on a clean environment, delete the thing it claims to catch) before crediting a green result as evidence.
- **The self-observed case: reliable when deliberate, unreliable when incidental.** A record written this session claimed that raising cadre's kernel-compatibility floor makes `cadre generate-plugin` refuse a pre-port kernel. Tested afterward three ways — stale kernel wired explicitly, resolved from `PATH`, no kernel reachable at all — the generator passes every time; it never consults the kernel binary. The claim traced to one `provider validation failed` message seen mid-change, with the tree part-regenerated, and a cause inferred without isolating it. Kept in the record rather than edited out. The pattern: verification done on purpose, with an isolated test, was reliable across this session; a causal explanation produced in passing, while doing something else, was not — an incidental "that's because of X" needs the same isolation as a test result before it goes in a ledger. [Source: [[04-projects/repo-consolidation/evidence/P5/ledger.md]] § "a claim I got wrong stating it" | 2026-09-01 | confidence: high]

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-09-01 | 1.0 | Initial entry from repo-consolidation P4/P5 harvest staging and evidence audit | harvest-curator |

## Related
- [WORKFLOW.md § Evidence row contract](../../WORKFLOW.md)
- [closed-loop SKILL.md § CP-5 Acceptance](../../.claude/skills/closed-loop/SKILL.md)
- [task-verifier agent](../../.claude/agents/task-verifier.md)
