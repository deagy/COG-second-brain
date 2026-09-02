# AC-4 Verification Report — round 2 (production-readiness P3)

Artifacts: `/home/deagy/sdk/cadre` at `bd8423aa` (claimed CI run 33639527855 green).

## Verdict

**FAIL:fixable**

Two independent, bounded gaps found by direct execution, neither of which is a documentation or scoping
question this time — one is a coverage gap the build's own commit message implicitly narrowed away, the
other is a live regression that breaks every pre-existing staged-records store.

## Summary of findings

1. **A fourth call site of `--authorized-by` was never covered.** AC-4 names the flag `--authorized-by`
   by name, generically. `import-staged` accepts `--authorized-by` (a *different* call site from
   `delete-staged`'s `--authorized-by`, which round 1 fixed). It gets no `observed_actor` companion, no
   schema column, and no runtime disclosure beyond an honest `SECURITY.md` caveat — the exact defect
   pattern round 1 flagged for `propose`/`disposition-staged`, reappearing on the path the round-2 commit
   didn't touch. `SECURITY.md` itself concedes this plainly (not an overclaim — see item 5), but per the
   same AC-5 argument that sank round 1, disclosure-only-in-`SECURITY.md` does not satisfy AC-4's "the
   command says plainly" branch, and no such runtime disclosure exists here either.

2. **Schema regression: pre-existing staged stores are broken by this binary.** The commit added
   `observed_actor` columns to `staged_records` and `staged_record_dispositions` via
   `CREATE TABLE IF NOT EXISTS` (`stagedSchema` in `internal/knowledge/staged_store.go:44-46`), which is a
   no-op against a table that already exists under the old schema. No `ALTER TABLE ADD COLUMN` migration
   exists. Reproduced directly: a store created with the pre-`bd8423aa` binary (`b174bfea`), opened with
   the current binary, fails on **every** staged-records operation — not just reads of old rows:
   ```
   $ /tmp/v4b-cadre knowledge --config config.json show-staged --id KS-20260101-oldschema
   error: cannot read disposition history for "KS-20260101-oldschema": SQL logic error: no such column: observed_actor (1)

   $ /tmp/v4b-cadre knowledge --config config.json propose --input record2.md
   error: cannot store staged record "KS-20260101-newrecord": SQL logic error: table staged_records has no column named observed_actor (1)
   ```
   This falsifies the item-6 premise ("the columns carry `DEFAULT ''`, so a store created before this
   change still opens and reads") — `DEFAULT ''` only takes effect for a table created fresh under the
   new schema; it does nothing for a table that already existed. No test in the suite constructs an
   old-schema store and opens it with the new code, which is why CI stayed green through this.

## Verified as claimed (items 1–5, apart from the gaps above)

**Item 1 — all four named flags, end to end (three of four call sites).** Built `/tmp/v4b-cadre`, scratch
store at `/tmp/v4b-scratch`.
- `propose --input record.md` with `staged_by: OBVIOUSLY-FALSE-STAGER` → `show-staged` returns
  `frontmatter.staged_by = "OBVIOUSLY-FALSE-STAGER"` (preserved) and top-level
  `observed_actor = "os:deagy git:daniel.eagy@sqs.world"` (recorded, differs).
- `disposition-staged --decided-by OBVIOUSLY-FALSE-DECIDER` → `show-staged`'s
  `disposition_history[0].decided_by = "OBVIOUSLY-FALSE-DECIDER"` (preserved),
  `disposition_history[0].observed_actor = "os:deagy git:daniel.eagy@sqs.world"` (recorded, differs).
- `delete-staged --deleted-by OBVIOUSLY-FALSE-DELETER --authorized-by OBVIOUSLY-FALSE-AUTHORIZER` →
  command output and `deletion-evidence-staged` both carry `deleted_by`/`authorized_by` verbatim plus a
  distinct `observed_actor = "os:deagy git:daniel.eagy@sqs.world"`.
- The fourth flag instance, `import-staged --authorized-by`, is the item-1 gap above: it is recorded
  verbatim in `staged_record_imports.authorized_by` (via `RecordStagedImportAuthorization`,
  `internal/knowledge/staged_store.go:685-703`) with **no** paired observation field at all — confirmed by
  reading the table DDL (`staged_store.go:79-87`, no `observed_actor` column) and the
  `StagedImportAuthorization` struct (`staged_store.go:171-178`, no `ObservedActor` field).

**Item 2 — environment cannot move it.** Repeated the full propose/disposition/show/delete flow at
`/tmp/v4b-scratch2` with `env USER=someone-else LOGNAME=someone-else`. Every `observed_actor` value was
identical to the unspoofed run: `"os:deagy git:daniel.eagy@sqs.world"`. Confirms `platform.ObserveActor()`
reads process credentials via `os/user.Current()`, not `$USER`.

**Item 3 — sidecar omission is real, and correctly judged honest.** Built an import batch at
`/tmp/v4b-scratch3` with `KS-20260101-with-history.md` (status `accepted`, `staged_by: proposing-agent`,
`decided_by: knowledge-store-steward`) plus a `.history.json` sidecar. After
`import-staged --authorized-by "an authorized human"`, `show-staged` returned
`disposition_history[0].observed_actor = ""` — confirmed empty as claimed
(`internal/knowledge/staged_history.go:243-246`, `PutStagedHistory`). **Judgment: empty is the honest
record, not a gap AC-4 requires filled.** AC-4's bar is "derives the value from a verifiable local source,
or refuses to run" for a command *asserting* an actor at the moment of its own call. `import-staged` is not
asserting who made a decision it is restoring — it is asserting who authorized the *admission* of a
decision made elsewhere, which is exactly what its own `--authorized-by` flag (and evidence table) is for.
Writing a fabricated `observed_actor` on a restored history row would misrepresent the current process as
having witnessed a past decision it did not witness — worse than silence, not better. A marker distinguishing
"live decision, no observation" from "restored decision, not applicable" would be a legitimate improvement,
but AC-4 as written does not require it, and the current empty string plus the `SECURITY.md` explanation
is not misleading. This part of the build's judgment holds.

**Item 4 — falsification.** In `/tmp/v4b-clone` (fresh clone of the real repo, real repo left untouched —
`git status --short` clean throughout), mutated `PutStagedRecord`'s insert
(`internal/knowledge/staged_store.go:507`) to write `StagedString(frontmatter, "staged_by")` instead of
`platform.ObserveActor().String()`. `go build ./...` succeeded (mutation compiles, proving the call site
exists and is live, not just present). `CGO_ENABLED=1 go test -tags sqlite_fts5 ./internal/knowledge/...
-run TestStagingAndDispositionRecordWhatWasObserved` failed:
```
staged_separation_test.go:383: the observation equals the asserted stager ("proposing-agent"); a flag must not set it
```
The test detects substitution, not merely presence.

**Item 5 — `SECURITY.md` does not overclaim.** `roster/knowledge-store/SECURITY.md` line 54 lists exactly
three covered call sites (`propose`↔`staged_by`, `disposition-staged`↔`decided_by`,
`delete-staged`↔`deleted_by`/`authorized_by`) — it does **not** claim `import-staged`'s `--authorized-by`
is covered; line 60 explicitly says that flag's name "is asserted, not verified," consistent with what I
found in code. Line 56 states the sidecar omission accurately (matches item 3's finding). Line 58/62 still
say caller identity is absent and `observed_actor` doesn't change enforcement, matching code. The
`plugin/suite/roster/knowledge-store/SECURITY.md` mirror is identical apart from a 2-line generated-file
banner (`diff` confirmed).

**Item 6 — regressions.** `go build ./...` clean, `go vet ./...` clean,
`CGO_ENABLED=1 go test -tags sqlite_fts5 ./...` all packages `ok` (`internal/knowledge` 22.1s,
`internal/cli` 13.0s, no failures). The old-store compatibility check is the item-2 gap above — it fails.

## EVIDENCE

EVIDENCE AC-4 | CP-3v | PASS | `propose`/`disposition-staged`/`delete-staged`: assertion preserved, distinct observation recorded, both survive env spoofing. | `/tmp/v4b-scratch`, `/tmp/v4b-scratch2` transcripts above.
EVIDENCE AC-4 | CP-3v | PASS | Sidecar-restored disposition carries no `observed_actor`; judged an honest, correctly-scoped omission, not a gap. | `/tmp/v4b-scratch3` transcript above; `internal/knowledge/staged_history.go:243-246`.
EVIDENCE AC-4 | CP-3v | PASS | Mutation (`staged_by` echoed into `observed_actor`) compiles and is caught by `TestStagingAndDispositionRecordWhatWasObserved`. | `/tmp/v4b-clone`, `go test ... -run TestStagingAndDispositionRecordWhatWasObserved` output above; real repo untouched.
EVIDENCE AC-4 | CP-3v | PASS | `SECURITY.md` (both copies) accurately describes exactly what is and isn't covered, including the `import-staged --authorized-by` gap and the sidecar omission — no overclaim found. | `roster/knowledge-store/SECURITY.md:54-62`, `plugin/suite/...` diff.
EVIDENCE AC-4 | CP-3v | FAIL | `import-staged --authorized-by` (a fourth, AC-4-named flag instance) has no `observed_actor` companion, no schema column, no runtime disclosure — same defect pattern as round 1's finding, on an uncovered call site. | `internal/knowledge/staged_store.go:79-87` (DDL, no column), `:171-178` (struct, no field), `:685-703` (`RecordStagedImportAuthorization`, no observation written).
EVIDENCE AC-4 | CP-3v | FAIL | A store created before `bd8423aa` cannot be opened or written to by the current binary: every staged-records verb fails with a SQL error, contradicting the `DEFAULT ''`-implies-compatible premise. | Reproduced live: pre-change binary built from worktree `/tmp/v4b-oldcommit` (commit `b174bfea`) created `/tmp/v4b-oldstore/store/staged-records.db`; current binary's `show-staged` and `propose` against that same file both errored (`SQL logic error: no such column: observed_actor` / `table staged_records has no column named observed_actor`).
EVIDENCE AC-4 | CP-3v | PASS | No other regressions. | `go build ./...`, `go vet ./...`, `CGO_ENABLED=1 go test -tags sqlite_fts5 ./...` all clean/green in `/home/deagy/sdk/cadre`.

## FAILURES

- AC-4 | "every command accepting `--staged-by`, `--decided-by`, `--deleted-by` or `--authorized-by` derives the value from a verifiable local source, or refuses to run" | `import-staged`'s `--authorized-by` (a distinct call site from `delete-staged`'s) gets no derivation, no refusal, and no runtime disclosure — only the same `SECURITY.md`-only pattern round 1 already ruled insufficient via AC-5's precedent.
- AC-4 (post-condition, "nothing regressed") | A store created before this commit must still open and read | It does not. Every staged-records verb against a pre-`bd8423aa` store fails with a SQL `no such column`/`has no column named observed_actor` error on the current binary; `CREATE TABLE IF NOT EXISTS` does not retrofit columns onto an existing table, and no `ALTER TABLE` migration exists.

## FIX_HINTS

- AC-4 (import-staged) | Add an `observed_actor` column to `staged_record_imports` (same pattern as the other three tables), record `platform.ObserveActor().String()` in `RecordStagedImportAuthorization`, surface it on `StagedImportAuthorization` and in `show-staged`'s `import_authorizations` list, and update both `SECURITY.md` copies' line-54/60 language to match once it's covered.
- AC-4 (schema regression) | Add an explicit migration step in `openStagedStore` (or `OpenStaged`) that runs `ALTER TABLE staged_records ADD COLUMN observed_actor TEXT NOT NULL DEFAULT ''` etc. guarded by a column-existence check (SQLite has no `ADD COLUMN IF NOT EXISTS`), for each of the three tables that predate this change. Add a regression test that builds a store under the old schema (or asserts the migration runs against a hand-crafted old-schema DB) and confirms `show-staged`/`propose`/`disposition-staged` succeed afterward — this is exactly the gap that let CI stay green through a breaking change.

## Housekeeping

- `/home/deagy/cog-second-brain` and `/home/deagy/sdk/cadre` are both clean (`git status --short` empty).
- Scratch dirs used: `/tmp/v4b-scratch`, `/tmp/v4b-scratch2`, `/tmp/v4b-scratch3`, `/tmp/v4b-oldstore`, `/tmp/v4b-clone` (mutated clone, disposable), `/tmp/v4b-cadre*` binaries — all outside any repo, safe to delete.
- One git worktree remains registered and was **not** removed per this environment's destructive-action policy (`workspace-isolation.md`): `/tmp/v4b-oldcommit` (detached at `b174bfea`, used to build the pre-change binary for the compatibility repro). Operator can remove with `git -C /home/deagy/sdk/cadre worktree remove /tmp/v4b-oldcommit` when convenient.
