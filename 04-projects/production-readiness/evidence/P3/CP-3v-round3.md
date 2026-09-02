# AC-4 Verification Report — round 3 (production-readiness P3)

Artifacts: `/home/deagy/sdk/cadre` at `a4c4d984` (claimed CI run 33641313290 green).

## Verdict

**FAIL:fixable**

Everything rounds 1 and 2 found is now genuinely fixed: all four named flags (`--staged-by` via
`propose`, `--decided-by`, `--deleted-by`, `--authorized-by` on both `delete-staged` and
`import-staged`) derive/record `observed_actor`; env spoofing does not move it; the additive
`ALTER TABLE` migration lets a pre-`bd8423aa` **split-file** store (`staged-records.db` already
separate from `cfg.Database`) open and run every verb; `SECURITY.md` and its mirror are accurate
and do not overclaim.

But item 3's instruction to "construct a store with the pre-change schema by hand" and exercise
it end to end surfaced a **second, different, still-broken migration path** that neither round
tested: `MigrateStagedRecords` — the one-time copy of a *pre-file-split legacy combined store*
(one whose staged tables still live inside `cfg.Database` itself, never having been split into
`staged-records.db` at all) — breaks on first open, and the second open silently strands the
data with no error at all.

## New finding: `MigrateStagedRecords` breaks on a genuinely legacy combined store

`internal/knowledge/staged_db.go:186-206` (`MigrateStagedRecords`) copies four tables out of a
legacy combined store with a raw, unqualified copy:

```go
result, err := store.db.Exec(fmt.Sprintf(
    `INSERT OR IGNORE INTO main.%s SELECT * FROM legacy.%s`, table, table))
```

`store` (the destination) is opened fresh via `OpenStaged(stagedPath)` just above this loop, which
always builds the **current** schema — `staged_records` etc. with `observed_actor` already
present via `stagedSchema`'s inline column definitions (`staged_store.go:44-107`) plus
`migrateAdditiveStagedColumns` (a no-op on a table that was just created with the column already
in it). If `legacy` (the caller's existing `cfg.Database`) predates *any* of the `observed_actor`
additions — the exact "pre-change schema" state item 3 asks for — column counts between `main.*`
and `legacy.*` disagree, and bare `SELECT *` fails outright.

**Reproduced live**, built binary `/tmp/v4c-cadre` from the real `a4c4d984` HEAD:

```
$ mkdir -p /tmp/v4c-scratch/store
$ python3 - <<'PY'   # writes staged tables with the pre-observed_actor schema (0f4bd58c)
...                  # straight into /tmp/v4c-scratch/store/knowledge.db (= cfg.Database)
PY
$ /tmp/v4c-cadre knowledge --config config.json list-staged
error: cannot copy staged_records: SQL logic error: table main.staged_records has 8 columns but 7 values were supplied (1)
```

**Second call is worse — silent data loss, no error at all.** The failed first call already
created `staged-records.db` (with the full current schema, 0 rows) before the copy loop errored.
`openStagedStore` (`internal/cli/knowledge_staged.go:172-197`) only attempts migration
`if os.IsNotExist(statErr)` on the *destination* path — which is no longer true after the failed
first attempt. Every subsequent invocation silently opens the now-permanent empty
`staged-records.db` and reports normally:

```
$ /tmp/v4c-cadre knowledge --config config.json list-staged
{"count": 0, "records": [], "status_filter": ""}
```

The legacy store's staged records are now unreachable through any documented path, with zero
error signal on the second and all later runs. Confirmed via `python3`/`sqlite3` inspection:
`store/knowledge.db` still has the 7-column pre-change `staged_records` (untouched, per
`MigrateStagedRecords`'s "never deletes the source" contract — that part held), but
`store/staged-records.db` has the 8-column current schema and holds nothing.

**Why no test caught this.** `internal/knowledge/staged_migration_test.go`'s `legacyStore` helper
(the only place `MigrateStagedRecords` is tested) builds its "legacy" fixture with
`db.Exec(stagedSchema)` — the live, current schema constant, which already carries
`observed_actor` on every table since `bd8423aa`/`a4c4d984`. Its "legacy" store is therefore
never actually legacy in the one dimension that matters here. This is the same test-fixture
class of gap the round-2 finding described (`TestAStoreFromBeforeTheObservedColumnStillOpens`
writes the old schema by hand for exactly this reason) — but it was applied to
`migrateAdditiveStagedColumns`'s own test, not `MigrateStagedRecords`'s.

**This regression predates `a4c4d984`.** `staged_record_deletions` got `observed_actor` first, in
round 1's `b174bfea`; `MigrateStagedRecords`'s blind `SELECT *` over that table would already have
broken then, for anyone still on a genuinely pre-`b174bfea` combined store. It was never exercised
by any of the three commits or two verification rounds because `OpenStaged`/`list-staged` is the
only way to trigger it, and no test or manual run before this one pointed a fresh binary at a
truly old, never-split combined store.

## Call-site and table enumeration (independent of prior rounds)

Grepped `--staged-by|--decided-by|--deleted-by|--authorized-by` and struct/flag names across
`internal/` and `cmd/`. No `--staged-by` CLI flag exists anywhere (`staged_by` is a frontmatter
field the caller authors into the record given to `propose`, per AC-4's own gloss). Confirmed
flags: `disposition-staged --decided-by` (`internal/cli/knowledge_staged.go:795`),
`delete-staged --deleted-by`/`--authorized-by` (`:891-892`), `import-staged --authorized-by`
(`:565`). Four `INSERT`s into the four actor-bearing tables, all populate `observed_actor` via
`platform.ObserveActor().String()`:
- `staged_records` ← `PutStagedRecord`, `staged_store.go:546-556` (propose, both `--input` and
  `--from-finding`; `PutGeneratedStagedRecord` funnels through the same function).
- `staged_record_dispositions` ← `DispositionStagedRecord`, `staged_store.go:706-712`
  (disposition-staged).
- `staged_record_imports` ← `RecordStagedImportAuthorization`, `staged_store.go:736-742`
  (import-staged).
- `staged_record_deletions` ← `DeleteStagedRecord`, `staged_store.go:844-849` (delete-staged).

A fifth `INSERT INTO staged_record_dispositions` exists (`staged_history.go:247`, inside
`PutStagedHistory`, the sidecar-restore path) and deliberately leaves `observed_actor` empty by
design — restoring a decision made elsewhere is not an observation this process can honestly
make. Confirmed the reasoning is sound and matches SECURITY.md; not a gap.

Schema (`staged_store.go:44-122`) has exactly four actor-bearing tables:
`staged_records`, `staged_record_dispositions`, `staged_record_imports`,
`staged_record_deletions` — all four carry `observed_actor` and all four are in
`migrateAdditiveStagedColumns`'s statement list (`staged_store.go:243-249`).
`staged_record_ingestions` has no actor column and `ingest-accepted` takes neither
`--decided-by` nor `--authorized-by` by design (`internal/cli/knowledge_staged.go:838-844`) —
correctly out of scope. No other `INSERT INTO staged_record_*` exists anywhere in the tree
(`internal/generators/plugin_generation.go` only mentions the table name in a comment).
`internal/contextstore/service.go`'s `Finding.StagedBy` (`promote_entry`, a different subsystem)
derives from `row.Agent` — set by a separate `--agent` flag at context-write time, not a
`--staged-by` flag, and it round-trips into `propose --from-finding`'s frontmatter, which then
goes through the same, already-covered `PutStagedRecord` call site. Not a missed AC-4 site.

## Verified end to end against a genuinely pre-change store (split-file layout)

Built `/tmp/v4c-cadre`. Hand-wrote the exact `0f4bd58c` (pre-any-`observed_actor`) schema directly
into `staged-records.db` (the file `OpenStaged` actually reads), at `/tmp/v4c-scratch2`, then ran:

- `propose --input record1.md` (`staged_by: OBVIOUSLY-FALSE-STAGER`) → succeeded;
  `show-staged` returned `observed_actor: "os:deagy git:daniel.eagy@sqs.world"` beside the
  preserved false `staged_by`.
- `disposition-staged --decided-by OBVIOUSLY-FALSE-DECIDER --action accepted` → succeeded;
  `disposition_history[0].observed_actor` recorded, distinct from `decided_by`.
- `delete-staged --deleted-by OBVIOUSLY-FALSE-DELETER --authorized-by OBVIOUSLY-FALSE-AUTHORIZER`
  → succeeded, command output and `deletion-evidence-staged` both carried `observed_actor`.
- `import-staged --directory import-batch --authorized-by OBVIOUSLY-FALSE-IMPORT-AUTHORIZER`
  (batch record pre-dispositioned; refused without `--authorized-by`, as required) → succeeded;
  `show-staged`'s `import_authorizations[0].observed_actor` recorded.

All five verbs worked, every evidence row carried the derived value distinct from the
caller-supplied assertion, on a store whose on-disk schema at the correct file never had
`observed_actor` at all.

**Environment cannot move it, repeated against the same old-schema store**: rebuilt a fresh
old-schema `staged-records.db` at `/tmp/v4c-scratch3`, ran `propose` under
`env -i USER=someone-else LOGNAME=someone-else` → `observed_actor` still
`"os:deagy git:daniel.eagy@sqs.world"`, unchanged.

## Falsification

`git worktree add /tmp/v4c-clone a4c4d984 --detach`. Removed the `migrateAdditiveStagedColumns`
call from `initStagedSchema` (`internal/knowledge/staged_db.go:98-105`, replaced with a
discard-var no-op so the function stays referenced and the package still compiles).
`go build ./...` succeeded (mutation compiles). `CGO_ENABLED=1 go test -tags sqlite_fts5
./internal/knowledge/... -run TestAStoreFromBeforeTheObservedColumnStillOpens` failed:
```
staged_separation_test.go:472: cannot stage KS-20260101-legacy-store: cannot store staged record
"KS-20260101-legacy-store": SQL logic error: table staged_records has no column named
observed_actor (1)
```
Confirms the test actually detects the regression it claims to catch, on the split-file path.

## SECURITY.md

`roster/knowledge-store/SECURITY.md` and `plugin/suite/roster/knowledge-store/SECURITY.md` are
identical apart from the generated-file banner (`diff` confirmed). Content accurately lists all
four covered call sites, the sidecar's deliberate omission, and repeats the "not authentication"
caveat without softening it. It says nothing about `MigrateStagedRecords`/the legacy
pre-file-split path either way — not an overclaim (it never asserts that path is covered), but
also not a disclosure of the newly-found gap. No accuracy defect found in the document itself.

## Build and tests (real repo, untouched)

`go build ./...` clean. `go vet ./...` clean. `CGO_ENABLED=1 go test -tags sqlite_fts5 ./...` —
every package `ok`, including `internal/knowledge` (21.9s) and `internal/cli` (12.9s). Consistent
with the new finding: no test exercises `MigrateStagedRecords` against a hand-written pre-change
schema, so CI has no way to see this break.

## EVIDENCE

EVIDENCE AC-4 | CP-3v | PASS | All four named flags' call sites enumerated independently (grep for flag names + every `INSERT INTO staged_record_*`); all four write `observed_actor` via `platform.ObserveActor()`. | `internal/knowledge/staged_store.go:546-556,706-712,736-742,844-849`
EVIDENCE AC-4 | CP-3v | PASS | Sidecar-restore path (`PutStagedHistory`) deliberately leaves `observed_actor` empty; reasoning sound, matches SECURITY.md. | `internal/knowledge/staged_history.go:243-251`
EVIDENCE AC-4 | CP-3v | PASS | Genuinely pre-change store (hand-written `0f4bd58c` schema at the real `staged-records.db` path) runs `propose`, `disposition-staged`, `show-staged`, `delete-staged`, `deletion-evidence-staged`, `import-staged --authorized-by` end to end, each recording a distinct `observed_actor`. | `/tmp/v4c-scratch2` transcript above
EVIDENCE AC-4 | CP-3v | PASS | Environment cannot move `observed_actor`, repeated against the old-schema store. | `/tmp/v4c-scratch3`, `env -i USER=someone-else LOGNAME=someone-else`
EVIDENCE AC-4 | CP-3v | PASS | Falsification: migration call removed from `initStagedSchema`, mutation compiles, `TestAStoreFromBeforeTheObservedColumnStillOpens` fails with the expected "no such column" error. | `/tmp/v4c-clone` (worktree at `a4c4d984`, left in place — see Housekeeping), `go test` output above
EVIDENCE AC-4 | CP-3v | PASS | `SECURITY.md` and its plugin mirror accurate, no overclaim. | `roster/knowledge-store/SECURITY.md:54-62`, `diff` against mirror
EVIDENCE AC-4 | CP-3v | PASS | `go build ./...`, `go vet ./...`, `CGO_ENABLED=1 go test -tags sqlite_fts5 ./...` all clean/green. | `/home/deagy/sdk/cadre` at `a4c4d984`
EVIDENCE AC-4 | CP-3v | FAIL | `MigrateStagedRecords` (the legacy pre-file-split combined-store migration, a distinct "store created before the change" path from the one `migrateAdditiveStagedColumns` fixes) fails outright on first open against a genuinely pre-`observed_actor` legacy store, then silently strands the legacy data on every subsequent open with no error at all. | `internal/knowledge/staged_db.go:186-206`; reproduced live at `/tmp/v4c-scratch` (transcripts above); no test exercises this (`internal/knowledge/staged_migration_test.go`'s `legacyStore` helper builds its fixture from the live `stagedSchema` constant, not a hand-written old one)

## FAILURES

- AC-4 (post-condition, "a store created before the change gets it added") | Every table with an actor column must be reachable, migrated, and non-lossy for a store that predates `observed_actor` | `MigrateStagedRecords` copies all four actor-bearing tables with an unqualified `SELECT *` against a destination schema that already has `observed_actor`; against a genuinely old *legacy combined* store (staged tables still inside `cfg.Database`, never split into `staged-records.db`) this fails with a column-count SQL error on first open, and — because the failed attempt already creates an empty `staged-records.db` — silently opens that same empty store with **no error** on every later invocation, permanently stranding the legacy staged records with no user-visible signal.

## FIX_HINTS

- AC-4 (`MigrateStagedRecords`) | Two independent problems to close together: (1) make the copy schema-tolerant — name the columns explicitly per table (`INSERT OR IGNORE INTO main.staged_records (id, status, ..., created_at, updated_at) SELECT id, status, ..., created_at, updated_at FROM legacy.staged_records`, omitting `observed_actor` from the legacy side so it defaults to `''` on the destination) instead of `SELECT *`; (2) close the silent-strand hole — either don't create/keep `staged-records.db` when the copy loop fails partway (roll back or delete it so `os.IsNotExist` is true again next run), or track "migration attempted" independently of "destination file exists" so a failed first attempt doesn't get silently treated as "nothing to migrate" thereafter. Add a regression test mirroring `TestAStoreFromBeforeTheObservedColumnStillOpens`'s discipline but for `MigrateStagedRecords`: write the pre-`observed_actor` schema by hand as the *legacy* store (not via the `stagedSchema` constant, which `legacyStore` currently uses and which is why this was never caught), migrate, and assert every verb succeeds afterward with no data loss.

## Housekeeping

- `/home/deagy/cog-second-brain` and `/home/deagy/sdk/cadre` both clean (`git status --short` empty) throughout.
- Scratch dirs, safe to delete: `/tmp/v4c-scratch`, `/tmp/v4c-scratch2`, `/tmp/v4c-scratch3`, `/tmp/v4c-cadre` (binary).
- One git worktree left registered per this environment's destructive-action policy (worktree removal requires human approval): `/tmp/v4c-clone` (detached at `a4c4d984`, `internal/knowledge/staged_db.go` mutated for falsification only — disposable). Operator can remove with `git -C /home/deagy/sdk/cadre worktree remove /tmp/v4c-clone --force`.
