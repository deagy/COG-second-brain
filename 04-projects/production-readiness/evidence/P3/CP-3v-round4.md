# AC-4 Verification Report — round 4 (production-readiness P3)

Artifacts: `/home/deagy/sdk/cadre` at `4da28060` (claimed CI run 33643385856 green).

## Verdict

**PASS**

Three prior rounds each found a distinct blast-radius gap from the `observed_actor` column addition
(deletion-only coverage, missing `ALTER TABLE` migration on the split-file store, and `SELECT *` breaking
`MigrateStagedRecords` on a genuinely pre-file-split legacy combined store). Round 4 worked outward from the
change itself — every consumer of the four actor-bearing tables, and every other place a schema is assumed —
instead of re-checking what round 3 named. No new defect found. Report below states what was enumerated so
the verdict is auditable rather than trusted.

## Step 1 — every consumer of the four tables, enumerated independently

Grepped `staged_records`, `staged_record_dispositions`, `staged_record_imports`, `staged_record_deletions`
across `*.go`, `*.py`, `*.sql`, `*.sh` in the tracked tree (excluding stale registered worktrees on other
branches — see Housekeeping). Every hit classified:

- **Four `INSERT`s**, one per table, all populate `observed_actor` via `platform.ObserveActor().String()`:
  `PutStagedRecord` (`internal/knowledge/staged_store.go:547`), `DispositionStagedRecord` (`:706`),
  `RecordStagedImportAuthorization` (`:738`), `DeleteStagedRecord` (`:844`).
- **One more `INSERT INTO staged_record_dispositions`**, in `PutStagedHistory` (`staged_history.go:247`,
  the sidecar-restore path inside `import-staged`) — deliberately leaves `observed_actor` empty. Confirmed
  live in this round (legacy-migration test below): restoring a decision made elsewhere is not something the
  current process observed, and the column stays honest rather than fabricated. Correct by design, not a gap.
- **All `SELECT`s against the four tables are column-explicit**, no `SELECT *` remaining anywhere in the
  non-test tree (`staged_store.go:307,334,388,401,433,471,538`). The only `SELECT *` hits left in the whole
  repo are inside the new falsification target's own comment text and one unrelated `contextstore` test
  (`access_runs` table, a different subsystem, not one of the four tables).
- **One raw table-copy**, `MigrateStagedRecords` (`staged_db.go:186-233`) — this round's fix target. Now uses
  an explicit per-table column list on both sides of `INSERT OR IGNORE INTO main.<t> (<cols>) SELECT <cols>
  FROM legacy.<t>`, omitting `observed_actor` from the legacy side so the destination's `DEFAULT ''` fills it.
- **Two schema-creation paths**: `stagedSchema` (`CREATE TABLE IF NOT EXISTS`, additive/idempotent, a no-op
  against an existing table) and `migrateAdditiveStagedColumns` (four `ALTER TABLE ... ADD COLUMN
  observed_actor ... DEFAULT ''`, guarded by a duplicate-column check), both run unconditionally on every
  `OpenStaged` (`staged_db.go:98-105`) — this is round 2's fix, re-verified live below, not re-broken.
- No other `INSERT`, `UPDATE`, `SELECT *`, `PRAGMA table_info`, or schema-comparison touching any of the four
  tables exists anywhere in `internal/` or `cmd/`.

## Step 2 — other places a schema is assumed

- `internal/retrieval/legacy.go:47` (`RefuseLegacyStore`) queries `sqlite_master` for a *different* set of
  tables (`messages, ingestion_runs, retrieval_runs, deletion_runs` — the old retrieval engine's, not the
  staged tables) to refuse opening a pre-migration combined store with recall's schema initializer. Its own
  comment states staged records "are migrated separately and are not at risk" — consistent with what this
  round found; not a second migration path for the four tables.
- No backup/restore/export/snapshot code touches the four tables. `cadre knowledge backup/export/import` are
  retired verbs that redirect to `recall store backup/restore` (`internal/cli/knowledge.go:35,51-52`), which
  operates on `cfg.Database` — a file the staged tables were deliberately split out of
  (`staged_db.go:24-34`), so recall's backup tooling never sees them.
- `proposed-knowledge/` and `proposed-knowledge.schema.json` are frontmatter-contract references in
  `internal/generators/cline_tables.go` (doc-generation lookup tables) and a comment in
  `plugin_generation.go:1714` — no code there serializes a staged-record table, and `observed_actor` is
  explicitly a column, never a frontmatter key (`staged_store.go:52-56` comment), so it cannot leak into or
  break that export path.
- The only stale Python `staged_store.py`/`staged_records.py` copies found anywhere in the working tree live
  inside five *other branches'* registered worktrees (`.worktrees/`, `.claude/worktrees/`), all pre-dating
  the Go port's deletion of the Python subsystem (`b418031e`) — not reachable from `main`, out of this
  change's blast radius, not evidence of a missed call site on the branch under test.

## Step 3 — all four flags, end to end, fresh and pre-change stores, env spoofed

All runs used `env USER=someone-else LOGNAME=someone-else` against binary `/tmp/v4d-bin/cadre` built from
`4da28060`.

- **Fresh store** (`/tmp/v4d-scratch`): `propose --from-finding` (`staged_by`), `disposition-staged`
  (`decided_by`), `delete-staged` (`deleted_by`/`authorized_by`), `import-staged --authorized-by` on a
  pre-dispositioned batch record — all five commands succeeded; every evidence row carried the caller-asserted
  string verbatim *and* a distinct `observed_actor = "os:deagy git:daniel.eagy@sqs.world"`, unmoved by the
  env spoof.
- **Hand-built pre-change split-file store** (`/tmp/v4d-oldschema/store/staged-records.db`, old 7-column
  schema written directly via `sqlite3`/Python, no `observed_actor`): same five commands, same result —
  `propose` on the old-schema file succeeded (retrofitted by `migrateAdditiveStagedColumns`), and every
  subsequent verb recorded a distinct `observed_actor`, env spoof included.
- **Hand-built pre-file-split legacy combined store** (`/tmp/v4d-legacycombined/store/knowledge.db`, old
  4-table schema plus an unrelated `messages` table, staged tables never split out): `list-staged` triggered
  `MigrateStagedRecords`, reported `"moved 2 staged row(s)"` to stderr, and returned the migrated record.
  `show-staged` confirmed `observed_actor = ""` on both the record and its restored disposition — honest, not
  fabricated, matching round 3's judged-correct design. **Second `list-staged` call still returns the record**
  (no silent stranding — this is exactly the failure mode round 3 found and this commit fixes). Legacy source
  file re-queried directly: still holds its 1 original row, untouched.

## Step 4 — falsification

`git worktree add /tmp/v4d-falsify 4da28060 --detach`. Reverted `MigrateStagedRecords`'s explicit column list
back to the pre-fix `INSERT OR IGNORE INTO main.%s SELECT * FROM legacy.%s`. `go build ./...` succeeded
(mutation compiles). `CGO_ENABLED=1 go test -tags sqlite_fts5 ./internal/knowledge/... -run
'TestALegacyStoreWithAnOlderSchemaStillMigrates|TestAStoreFromBeforeTheObservedColumnStillOpens'`:
`TestAStoreFromBeforeTheObservedColumnStillOpens` still passed (a different code path — the `ALTER TABLE`
migration, untouched by this mutation); `TestALegacyStoreWithAnOlderSchemaStillMigrates` failed with `SQL
logic error: table main.staged_records has 8 columns but 7 values were supplied` — the exact defect round 3
reported. Confirms the new test detects the regression it claims to catch, on a fixture written out in full
(not derived from the live `stagedSchema` constant — checked directly at
`internal/knowledge/staged_separation_test.go:507-580`, distinct from the older, still-current-schema-derived
`legacyStore` helper in `staged_migration_test.go` that let this defect through three times).

## Step 5 — build and tests

`go build ./...` clean. `go vet ./...` clean. `CGO_ENABLED=1 go test -tags sqlite_fts5 ./...` — every package
`ok`, including `internal/knowledge` and `internal/cli`. `bash .claude/lib/ci-status.sh /home/deagy/sdk/cadre`
reports `deagy/cadre 4da28060 success run 33643385856` — matches the claimed run.

`roster/knowledge-store/SECURITY.md` and its `plugin/suite/` mirror are identical apart from the generated-file
banner (`diff` confirmed). Content accurately describes all four flags' `observed_actor` treatment
(lines 54-62); says nothing about `MigrateStagedRecords`/the legacy-combined path either way, which is not an
overclaim since it never asserts that path is covered by the flag-level guarantees it does describe.

## EVIDENCE

EVIDENCE AC-4 | CP-3v | PASS | Enumerated every consumer of the four actor-bearing tables (4 INSERTs writing `observed_actor`, 1 deliberate-empty sidecar INSERT, all SELECTs column-explicit, 1 raw-copy path now column-explicit, 2 schema-creation paths). No uncovered call site found. | `internal/knowledge/staged_store.go:547,706,738,844`; `staged_history.go:247`; `staged_db.go:98-105,186-233`
EVIDENCE AC-4 | CP-3v | PASS | No other schema-assumption code (backup/export/snapshot/PRAGMA table_info) touches the four tables; `internal/retrieval/legacy.go`'s `sqlite_master` check targets a disjoint table set for a different refusal. | `internal/retrieval/legacy.go:19,47`; `internal/cli/knowledge.go:35,51-52`
EVIDENCE AC-4 | CP-3v | PASS | All four flags end to end on a fresh store, with env spoofing (`USER=someone-else`); every evidence row carries a distinct, unmoved `observed_actor`. | `/tmp/v4d-scratch` transcript above
EVIDENCE AC-4 | CP-3v | PASS | All four flags end to end on a hand-built pre-change split-file store (old 7-column schema, no `observed_actor`), env spoofed. | `/tmp/v4d-oldschema` transcript above
EVIDENCE AC-4 | CP-3v | PASS | Legacy pre-file-split combined store migrates on first `list-staged`, migrated record/disposition carry empty (honest) `observed_actor`, second call does not strand the data, legacy source untouched. | `/tmp/v4d-legacycombined` transcript above
EVIDENCE AC-4 | CP-3v | PASS | Falsification: `SELECT *` reverted, mutation compiles, `TestALegacyStoreWithAnOlderSchemaStillMigrates` fails with the exact "8 columns but 7 values" defect; sibling test on the unrelated `ALTER TABLE` path still passes, showing the test isolates the right mechanism. | `/tmp/v4d-falsify` (worktree, not removed per policy — see Housekeeping)
EVIDENCE AC-4 | CP-3v | PASS | `go build ./...`, `go vet ./...`, `CGO_ENABLED=1 go test -tags sqlite_fts5 ./...` all clean; CI status independently re-fetched and matches the claimed run. | `/home/deagy/sdk/cadre` at `4da28060`; `ci-status.sh` output: `success run 33643385856`
EVIDENCE AC-4 | CP-3v | PASS | `SECURITY.md` and its plugin mirror identical (banner only), accurate on all four flags' treatment, silent (not false) on the legacy-migration path. | `roster/knowledge-store/SECURITY.md:54-62`; `diff` against mirror

## FAILURES

None.

## Housekeeping

- `/home/deagy/cog-second-brain` and `/home/deagy/sdk/cadre` both clean (`git status --short` empty)
  throughout this round.
- Scratch dirs, safe to delete: `/tmp/v4d-scratch`, `/tmp/v4d-oldschema`, `/tmp/v4d-legacycombined`,
  `/tmp/v4d-bin` (binary).
- One new git worktree left registered per this environment's destructive-action policy (worktree removal
  requires human approval): `/tmp/v4d-falsify` (detached at `4da28060`, `staged_db.go` reverted to `SELECT *`
  for falsification only — disposable). Also still present from prior rounds and not removed by this round:
  `/tmp/v4b-oldcommit` (detached `b174bfea`), `/tmp/v4c-clone` (detached `a4c4d984`, mutated). Operator can
  remove all three with `git -C /home/deagy/sdk/cadre worktree remove <path> --force`.
- Five *other-branch* worktrees (`.claude/worktrees/cline-agents-parent-model`,
  `.claude/worktrees/cline-dispatch-investigation`, `.worktrees/pr-256-safe-repair-2026-08-13/root`,
  `.worktrees/release-plugin-v0.23.0-pr254`, `.worktrees/release-v0-22-0/...`) still carry the pre-Go-port
  Python `staged_store.py` — noted in Step 2 as out of this change's blast radius, not touched or flagged as
  a defect of `4da28060`.
