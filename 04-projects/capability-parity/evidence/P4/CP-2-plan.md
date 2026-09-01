# P4 — CP-2 plan · AC-5

**AC-5:** Every enforcement claim is exercised by a test that fails when its check is removed. The two PARTIAL claims — `import-staged`'s self-approval refusal and `ingest-accepted`'s stager/decider match — each gain a mutation-proven test.

## What the scoping read found

Both tests already exist. The gap is not coverage, it is proof.

| Claim | Check | Test | Status |
|---|---|---|---|
| `import-staged` refuses a self-approval | `internal/cli/knowledge_staged.go:585` | `TestAuthorizationCannotLaunderASelfApproval` (`internal/cli/knowledge_staged_test.go:396`) | exists, unproven |
| `ingest-accepted` refuses a self-approval | `internal/knowledge/staged_ingest.go:293` | `TestIngestRefusesASelfApprovedRecord` (`internal/knowledge/staged_ingest_test.go:207`) | exists, unproven |

Both call the single shared predicate `knowledge.StagedRecordIsSelfApproved` (`internal/knowledge/staged_store.go:212`). One predicate, four separation checks, deliberately — so the checks cannot drift into disagreeing about what a self-approval is.

That shared predicate is itself directly tested by `TestStagedRecordIsSelfApprovedRecognisesTheShape` (`internal/knowledge/staged_separation_test.go:274`), and **that is the reason these two claims are recorded PARTIAL.** A test of the predicate passes whether or not anything calls it. Deleting the call site at `knowledge_staged.go:585` or the branch at `staged_ingest.go:293` leaves the predicate test green, so on its own it proves the predicate works and nothing about whether the guard is wired.

## Tasks

- **T-01 — mutate the import call site.** Delete the `StagedRecordIsSelfApproved` branch at `internal/cli/knowledge_staged.go:585`. Run `TestAuthorizationCannotLaunderASelfApproval`. It must FAIL. Record the failure output. Revert with `git checkout --`.
- **T-02 — mutate the ingest branch.** Delete the `StagedRecordIsSelfApproved` branch in `stagedIngestRefusal` (`internal/knowledge/staged_ingest.go:293`). Run `TestIngestRefusesASelfApprovedRecord`. It must FAIL. Record the output. Revert.
- **T-03 — mutate the shared predicate.** Make `StagedRecordIsSelfApproved` return `false` unconditionally. Both tests above **and** the disposition test (`TestDispositionRefusesTheProposerAsDecider`) must fail. This proves the single-predicate design has no unguarded path, which the two call-site mutations alone do not show.
- **T-04 — record.** Write each mutation, the exact test output, and the restore into `evidence/P4/CP-5-acceptance-AC-5.md`. A mutation that does *not* fail its test is an AC-5 finding, not a step to retry.

## What would falsify this phase

A mutation that leaves its test passing. That would mean the test asserts something other than the guard — the exact condition AC-5 exists to detect — and the fix is a better test, not a re-run.

## Not in scope

Adding new tests. Both exist and both are well-shaped; if a mutation shows one is not, that becomes a task then, on evidence.
