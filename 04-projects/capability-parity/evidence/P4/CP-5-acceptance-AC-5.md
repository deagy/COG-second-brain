# P4 — CP-5 acceptance · AC-5

**AC-5:** Every enforcement claim is exercised by a test that fails when its check is removed.

Run against a clean clone of `deagy/cadre` at `1e317729`, `CGO_ENABLED=1 go test -tags sqlite_fts5`. Each mutation was applied, the test run, and the file reverted with `git checkout --`; `git status` was empty at the end.

## Baseline

Both tests pass on the unmutated tree.

```
ok  	github.com/deagy/cadre/cli/internal/cli	0.114s
ok  	github.com/deagy/cadre/cli/internal/knowledge	0.121s
```

## T-01 — `import-staged`'s self-approval refusal

Mutation: deleted the `knowledge.StagedRecordIsSelfApproved` branch at `internal/cli/knowledge_staged.go:585`.

```
--- FAIL: TestAuthorizationCannotLaunderASelfApproval (0.03s)
    knowledge_staged_test.go:407: expected a self-approved record to be refused regardless of authorization
```

**EVIDENCE | AC-5 | CP-5 | PASS** — the test fails when the check is removed, and the failure names the guard rather than a downstream symptom.

## T-02 — `ingest-accepted`'s stager/decider match

Mutation: deleted the `StagedRecordIsSelfApproved` branch from `stagedIngestRefusal` (`internal/knowledge/staged_ingest.go:293`).

```
--- FAIL: TestIngestRefusesASelfApprovedRecord (0.05s)
    staged_ingest_test.go:226: a self-approved record was ingested:
      [{ID:KS-20260101-self-approved Reason: Classification:internal Chunks:1 DryRun:false}]
```

**EVIDENCE | AC-5 | CP-5 | PASS** — and the assertion is the strong one: it fails on the record having *reached the corpus*, not merely on a missing error. A refusal that returned an error but wrote anyway would still fail this test.

## T-03 — the shared predicate

Mutation: `StagedRecordIsSelfApproved` returns `false` unconditionally (`internal/knowledge/staged_store.go:212`).

| Test | Result |
|---|---|
| `TestAuthorizationCannotLaunderASelfApproval` | FAIL |
| `TestIngestRefusesASelfApprovedRecord` | FAIL |
| `TestStagedRecordIsSelfApprovedRecognisesTheShape` | FAIL |
| `TestDispositionRefusesTheProposerAsDecider` | **pass** |

The first three are the expected result. The fourth is the finding.

## Finding — why the predicate test was never sufficient, and what T-03 shows

The reason these two claims were recorded PARTIAL is visible in the difference between T-01/T-02 and the predicate's own test. `TestStagedRecordIsSelfApprovedRecognisesTheShape` passes whether or not anything calls the predicate; deleting either call site leaves it green. It proves the predicate computes correctly and nothing about whether the guard is wired. T-01 and T-02 are the tests that fail on an unwired guard, and they now have that demonstrated rather than assumed.

`TestDispositionRefusesTheProposerAsDecider` surviving T-03 is correct, not a gap. `DispositionStagedRecord` (`staged_store.go:559`) compares `input.DecidedBy` against `staged_by` with its own inline comparison, because it is asked a structurally different question: the decider arrives as an argument, not inside the record's frontmatter, so there is no disposition to read. The predicate's doc comment scopes itself accurately — "every path that can admit an already-decided record (import) or act on one (ingest)" — and disposition is neither.

Worth recording anyway: **"four separation checks, one predicate" is true of three of them.** Check 2 is a second independent implementation of the same rule. It cannot share the predicate, so this is not a defect to fix, but it is the drift risk the single-predicate design was adopted to remove, still present in one place — and no test would catch the two implementations diverging. Not in AC-5's scope; raised for the ultragoal's open list.

## Post-condition

`git status` clean in the mutation clone; all three source files restored. No mutation reached `deagy/cadre`.
