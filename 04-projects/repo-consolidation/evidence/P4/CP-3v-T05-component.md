# CP-3v independent verification — da84b963 "refactor(knowledge): delete the retrieval engine"

Verifier: read-only, no repo edits. Build artifacts and scratch stores under
`/tmp/claude-1000/cp3v/`, binaries under `/tmp/claude-1000/`.

## 1. Is the retrieval engine actually gone?

`git show da84b963 --stat` confirms deletion of `search.go`, `database.go`,
`persistence.go`, `hnsw_fts5.go`, `batch_operations.go`, `cli_persistence.go`,
`database_repair.go`, `disaster_recovery.go`, `retention.go`, `types.go`,
`config_manager.go`, and their tests (net -8,669 lines in `internal/knowledge`).
`ls internal/knowledge/*.go` post-commit shows only `config.go`,
`embeddings*.go`, `remote_embeddings*.go`, and five `staged_*.go` files — no
`search.go`/`database.go`/`hnsw_fts5.go`.

Grepped the whole repo for HNSW, FTS5, cosine similarity, and `messages`/
`chunks` table creation:
- `CosineSimilarity` remains in `internal/knowledge/embeddings.go` (dead code
  now — used nowhere for retrieval, just a leftover helper) and in
  `internal/textutil/embedding.go` / `internal/contextstore/service.go`,
  which is a **separate subsystem** (agent context store, unrelated to
  knowledge retrieval, out of scope for AC-08).
- `fts5-index`/`fts5-search` only appear as entries in `retiredVerbs` in
  `internal/cli/knowledge.go` (error messages naming the replacement).
- `CREATE TABLE messages`/`CREATE TABLE chunks` only appear in
  `internal/knowledge/staged_migration_test.go`, which deliberately
  fabricates a legacy-schema fixture to test the migration path — not live
  engine code.
- `internal/contextstore/database.go`'s `entry_chunks` table is that
  unrelated subsystem, not the retrieval engine's `chunks` table.
- No remaining call to `knowledge.Open` or a `knowledge.Store{}` engine
  literal anywhere except comments and `knowledge.OpenStaged` (the staged
  store, a different type).

**Verdict: gone.** Nothing left implements corpus storage or vector search
inside cadre.

## 2. Six refusals at `cadre knowledge search`

Built `/tmp/claude-1000/cadre-new` (`go build ./cmd/cadre`, exit 0). Drove
each contract case (`internal/knowledge/testdata/fail-closed-contract.json`)
against real configs in `/tmp/claude-1000/cp3v/contract/`.

| case | stderr observed | exit |
|---|---|---|
| no query (`""`) | `cadre knowledge search: govern: query is required` | 1 |
| no classification | `cadre knowledge search: --classification is required` | 2 |
| no embedding provider (explicit `"provider": ""`) | `cadre knowledge: embedding provider is required: set "embedding.provider" to one of: local-hashing, openai-compatible...` | 1 |
| no source scope | `cadre knowledge search: source scope is required: pass --source <project-identifier>...` | 2 |
| both all-sources and filters | `cadre knowledge search: source scope is ambiguous: pass either --source... or --all-sources, not both` | 2 |
| blank source filter entry | `invalid value "  " for flag -source: each --source must be non-empty` (flag-level, refused before store touched) | 2 |

All six refusal texts contain the fixture's `expect_refusal` substring. No
`store.db` file was created for any refused case (`md5sum store.db` before
and after each was identical for the shared-store cases; for cases that ran
against a fresh directory, `test -f store.db` reported `NO`).

Note: "no embedding provider" is caught at `knowledge.LoadConfig` time
(`internal/knowledge/config.go:391`), earlier than the engine used to catch
it, not weaker — confirmed by testing an explicit `"provider": ""` (omitting
the section entirely defaults to `local-hashing`, which is a config-default
behavior, not a defect).

**Verdict: all six hold, with no store file created on refusal.**

## 3. Staged-record workflow against a recall store

In `/tmp/claude-1000/cp3v/workflow/` (config naming `./store.db`, no store
pre-created): ran `propose --from-finding`, `disposition-staged`,
`ingest-accepted`, `show-staged` in sequence.

- `propose` created `staged-records.db` (49,152 bytes) as its own file,
  separate from `store.db` — no `embedding_provider` column error, the T-04
  defect the commit describes.
- `show-staged` before disposition showed `status: proposed`, empty
  `disposition_history`.
- `disposition-staged --action accepted ...` returned
  `{"status":"accepted","sequence":1}`.
- `ingest-accepted` (no id filter) returned
  `{"ingested":[{"id":"KS-...","classification":"internal","chunks":1}],...}`
  and created `store.db` (36,864 bytes) — the recall store, claimed on
  first write.
- `show-staged` after showed the full `disposition_history` entry and
  `disposition` block in frontmatter.

**Verdict: works end to end, exactly as claimed.**

## 4. Does ingest-accepted make a record retrievable?

`cadre knowledge search --classification internal --all-sources "recall
migration works end to end round trip" --json` (well, non-JSON output shown)
returned 1 result: `[proposed-knowledge] score 0.5822`, title "Recall
migration works end to end", with a full citation line: `conversation=...
message=... chunk=...::chunk-0 hash=12456c0a92f9 class=internal`.

Re-running `ingest-accepted` with no `--id` filter a second time returned:
`{"ingested":[],"skipped":[{"id":"KS-...","reason":"already in the
corpus"}],...}` — no duplicate write, `Skipped` not `Ingested`.

**Verdict: retrievable with citation; second run skips, does not duplicate.**

## 5. Migration from a legacy combined store

Used `/tmp/claude-1000/cadre-cgo` (pre-T-05, still has `knowledge.Open`) to
`propose --from-finding` into `/tmp/claude-1000/cp3v/legacy/store.db`.
Confirmed via direct sqlite introspection that this file holds BOTH engine
tables (`messages`, `chunks`, `ingestion_runs`, `retrieval_runs`,
`deletion_runs`) and staged tables (`staged_records`,
`staged_record_dispositions`, etc.) — the "one database, two concerns" state
the commit describes.

Ran `/tmp/claude-1000/cadre-new knowledge show-staged` against the same
config. Stderr printed: `cadre knowledge: moved 1 staged row(s) from
.../store.db into .../staged-records.db. The originals are left in place.`
Then:
- `staged-records.db` (new, separate file) contains the migrated row
  (`id`, `status='proposed'` present).
- `store.db` (legacy) MD5 was **identical** before and after the migration
  run (`be28c03a77ab2f64b1d830fcc8e5579f`) — untouched.
- `store.db`'s `staged_records` table still has the original row.
- Running the new binary a second and third time produced **no** "moved"
  message and the row count in `staged-records.db` stayed at 1 (no
  duplication).

**Verdict: real, non-destructive, idempotent migration.**

## 6. Adversarial pass

- **Embedder identity mismatch (search):** claimed a store at 128
  dimensions via `ingest-accepted`, then queried it with a 64-dimension
  config. Refused: `retrieval: configured embedder does not match the
  store: ... was embedded with local-hashing / hashing-128d ..., and this
  configuration would query it with local-hashing / hashing-64d ...`
  (exit 1).
- **Embedder identity mismatch (ingest-accepted):** staged+accepted a
  second record under the 64-dim config, then ran `ingest-accepted` against
  the same 128-dim-claimed store. Refused with the identical mismatch
  message before any write (exit 1).
- **Claim a store with unattributed pre-existing content:** created a store
  via `recall upload` directly (no cadre identity file), then staged +
  accepted a record and ran `ingest-accepted` against it. Refused:
  `retrieval: the store's embedder identity has not been recorded: .../store.db
  already holds content, and what embedded it is not recorded. Run \`cadre
  knowledge init\` to state it; ingesting would claim vectors cadre may not
  have written` (exit 1).
- **Self-approved record (staged_by == decided_by), path 1 — direct
  disposition-staged:** refused before acceptance:
  `"same-agent" staged this record and cannot also disposition it...`
  (exit 1) — never reaches `ingest-accepted`.
- **Self-approved record, path 2 — hand-crafted already-`accepted` .md file
  via `import-staged --authorized-by <human>`:** refused:
  `"same-agent-import" both staged and dispositioned this record. Importing
  cannot launder a self-approval, and no --authorized-by permits it...`
  (exit 1) — the import-time check (SEPARATION CHECK 2) catches it before
  the ingest-time check (SEPARATION CHECK 4) is even needed. Both front
  doors refuse it; only direct DB manipulation could get a self-approved
  row into `staged_records` with `status='accepted'`, which is outside any
  CLI code path.
- **Remaining code path opening the recall store with cadre's own schema:**
  grepped for `CREATE TABLE`/`sql.Open` across `internal/`. Every
  `sql.Open` inside `internal/knowledge` targets `staged-records.db` (or
  `:memory:` for the driver probe) — none targets `cfg.Database`. The
  recall store is opened exclusively through `internal/retrieval.Open` →
  `store.NewSQLiteStore` (recall's own package). `internal/contextstore`
  and `internal/engine/executor` have their own, unrelated schemas
  (`entries`, `entry_chunks`, `run_checkpoints`) in their own files —
  legitimately out of scope, not cadre's knowledge schema.

**Verdict: adversarial pass found no exploitable gap.**

## 7. cgo claim

`CGO_ENABLED=0 go build ./internal/knowledge/... ./internal/cli/...
./internal/retrieval/...` — exit 0.
`CGO_ENABLED=0 go test` on the same three packages — all `ok` (knowledge
21.98s, cli 10.47s, retrieval 0.05s).

Also built a full `CGO_ENABLED=0` `cmd/cadre` binary
(`/tmp/claude-1000/cadre-nocgo`) and ran the staged-record `propose` verb
against it live — succeeded, proving the pure-Go path works in the actual
binary, not just under `go test`.

Grepped for actual `import _ "github.com/mattn/go-sqlite3"` (not just
mentions in comments/strings) repo-wide:
- `internal/contextstore/database.go` — real import.
- `internal/contextstore/sqlite_guard_test.go` — real import (test).
- `internal/engine/executor/sqlite.go` — real import.
- `internal/knowledge/staged_db.go` mentions "mattn/go-sqlite3" only in a
  comment, not an import (it imports `modernc.org/sqlite`).
- `internal/cli/sbom_check.go`, `internal/release/platforms_test.go` mention
  it only in doc text / SBOM check strings.

This matches the commit's claim exactly: only `internal/contextstore` and
`internal/engine/executor` still need cgo.

Minor, pre-existing staleness (not introduced by this commit, not touched
by its diff): `internal/release/platforms_test.go`'s
`TestEveryCliCrossBuildLegForcesCgo` still says "The knowledge store
(github.com/mattn/go-sqlite3) needs cgo" as its rationale for forcing
`CGO_ENABLED=1` on CLI cross-build legs. The knowledge store no longer needs
cgo; the CLI as a whole still does, because it links `internal/contextstore`.
The test's *behavior* is still correct (CLI legs still need cgo), but its
comment now names the wrong reason. Cosmetic; does not affect AC-08 or CI.

**Verdict: cgo claim true.**

## 8. CI gate

- `gofmt -l .` — no output, exit 0.
- `go vet ./...` — no output, exit 0.
- `CGO_ENABLED=1 go test -tags sqlite_fts5 -race ./...` — every package
  `ok`, exit 0 (internal/cli 88.6s, internal/knowledge cached-ok,
  internal/retrieval cached-ok, internal/contextstore cached-ok, etc.).
- `go tool golangci-lint run ./...` — `0 issues.`

**Verdict: CI gate green.**

---

## EVIDENCE

EVIDENCE AC-08 | CP-3v | PASS | Engine files (search.go, database.go, hnsw_fts5.go, persistence.go, retention.go, etc., -8,669 lines) deleted; grep for HNSW/FTS5/cosine-similarity/messages/chunks table creation inside cadre finds no live retrieval engine code, only an unrelated subsystem (contextstore) and a test fixture simulating the legacy schema | `git show da84b963 --stat`; `grep -rniE "hnsw|fts5|cosine" --include=*.go .`
EVIDENCE AC-08 | CP-3v | PASS | All six fail-closed-contract.json refusals reproduced verbatim (query/classification/provider/scope-required/scope-ambiguous/blank-filter), each with correct exit code and no store.db file created on refusal | `/tmp/claude-1000/cadre-new knowledge -config .../config.json search ...` in `/tmp/claude-1000/cp3v/contract/`
EVIDENCE AC-08 | CP-3v | PASS | propose -> disposition-staged -> ingest-accepted -> show-staged round trip works against a fresh recall store with no config-column error (the T-04 defect the commit fixes) | `/tmp/claude-1000/cp3v/workflow/` session transcript
EVIDENCE AC-08 | CP-3v | PASS | ingest-accepted makes the record retrievable via `cadre knowledge search` with a full citation (conversation/message/chunk/hash/classification); a second ingest-accepted run skips rather than duplicates | `/tmp/claude-1000/cp3v/workflow/` search output; second ingest-accepted JSON showing `"skipped"` not `"ingested"`
EVIDENCE AC-08 | CP-3v | PASS | Migration from a legacy combined store (staged via pre-T-05 /tmp/claude-1000/cadre-cgo) is real: staged-records.db gets the row, legacy store.db MD5 is byte-identical before/after, and a second/third run neither re-migrates nor duplicates | `/tmp/claude-1000/cp3v/legacy/` md5sum + sqlite queries before/after
EVIDENCE AC-08 | CP-3v | PASS | Adversarial pass: embedder-identity mismatch refused on both search and ingest-accepted; claiming a store with unattributed pre-existing content refused; self-approved record (staged_by==decided_by) refused at both disposition-staged and import-staged, never reaching ingest; no remaining code path opens the recall store file with cadre's own schema | `/tmp/claude-1000/cp3v/adversarial/{mismatch,claim,selfapprove}/` transcripts; `grep -rn "sql.Open" internal/`
EVIDENCE AC-08 | CP-3v | PASS | cgo claim true: CGO_ENABLED=0 build+test green for knowledge/cli/retrieval, a CGO_ENABLED=0 cmd/cadre binary runs the staged workflow live; only internal/contextstore and internal/engine/executor still `import _ "github.com/mattn/go-sqlite3"` | `CGO_ENABLED=0 go test ./internal/knowledge/... ./internal/cli/... ./internal/retrieval/...`; `/tmp/claude-1000/cadre-nocgo`
EVIDENCE AC-08 | CP-3v | PASS | CI gate green: gofmt clean, go vet clean, CGO_ENABLED=1 go test -tags sqlite_fts5 -race ./... all ok, golangci-lint 0 issues | terminal output of each command, this session

## VERDICT: PASS

All eight independent checks confirm the commit's claims: the retrieval
engine is fully deleted with no residue, all six fail-closed refusals hold
exactly as specified in the contract fixture, the staged-record workflow
(the T-04 defect this commit's scoping found) works end to end against a
real recall store, ingest-accepted makes records retrievable with citations
and is idempotent, the legacy-store migration is real/non-destructive/
idempotent, the adversarial pass found no way to defeat the embedder-identity
guard, the store-claiming guard, or the self-approval separation across two
independent entry points (disposition-staged and import-staged), the cgo
claim is accurate down to the exact importer list, and the full CI gate
(fmt/vet/race-tested-suite/lint) is green.

One cosmetic, pre-existing note (not introduced by this commit, no action
needed for AC-08): `internal/release/platforms_test.go`'s
`TestEveryCliCrossBuildLegForcesCgo` comment still attributes cadre's cgo
requirement to "the knowledge store," which is no longer accurate post-T-05
— the requirement is now driven by `internal/contextstore`. The test's
enforced behavior (forcing `CGO_ENABLED=1` on CLI legs) remains correct.
