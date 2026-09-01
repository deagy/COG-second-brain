# P4 / T-05 — scoping the engine deletion before deleting it

The phase plan says "delete `internal/knowledge`'s retrieval engine". Scoping it first, per the pattern that has caught something in every phase, finds a defect already shipped and two decisions the task cannot make for itself.

## The defect T-04 left behind

`cadre knowledge propose`, `show-staged`, `disposition-staged`, `ingest-accepted`, `import-staged` and `delete-staged` resolve their store through `knowledge.LoadConfig` and open it with `knowledge.Open` — the retrieval engine's constructor. `cfg.Database` now names a **recall** store. Observed, cgo build, against the store T-04's own acceptance evidence used:

```
$ cadre knowledge --config <cfg> show-staged some-id
error: cannot initialize schema: no such column: embedding_provider
```

The same failure `delete` had, in a second place, found by asking where the staged records live rather than by running the suite — cadre's tests seed their own stores, so nothing fails.

**The whole knowledge-governance workflow is unreachable against the only kind of store this migration creates.** That is not a consequence of deleting the engine; it is already true. T-05 has to fix it before it can delete anything.

## What the staged side actually needs from the engine

Read rather than assumed. Across the five staged files, exactly one function reaches the retrieval engine:

- `staged_ingest.go`'s `ingestOneStagedRecord` calls `s.SaveMessage` and `s.SaveChunk`, and embeds with `NewLocalHashingEmbedder(128)`.

Everything else uses `s.db` and the four staged tables (`staged_records`, `staged_record_dispositions`, `staged_record_imports`, `staged_record_deletions`), which `staged_store.go` creates additively over whatever schema `Open` built. The coupling is one write path plus a shared `Store` struct and a shared database file — not a shared concern. P2 already recorded that these are different concerns and should not be merged; this is what merging them cost.

## Inventory

**Goes** (retrieval engine + its CLI-era support): `search.go`, `database.go`, `persistence.go`, `hnsw_fts5.go`, `batch_operations.go`, `cli_persistence.go`, `database_repair.go`, `disaster_recovery.go`, `retention.go`, `types.go`, `config_manager.go`, and their tests — including `fail_closed_contract_test.go`, whose fixture survives as the contract's authority and is already driven from `internal/cli`.

**Stays**: the five `staged_*.go` files, `config.go` (`LoadConfig`, `ValidateClassification`), `embeddings.go` and `remote_embeddings.go` (embedding providers, which are not the engine — `internal/retrieval` takes any provider).

**Moves**: the staged store needs its own `Store` type, its own `Open`, and its own schema, since `database.go` currently supplies all three.

## Two decisions this task cannot make

**D-5. Where staged records live.** They are in `cfg.Database` today, which is now a recall store file.

**D-6. What `ingest-accepted` writes to.** It exists to make an accepted record retrievable. Retrieval is recall's now.

Both are put to the user rather than guessed, because both move or drop operator data.

## Also on the table

The staged store uses `mattn/go-sqlite3` (cgo). recall uses `modernc.org/sqlite` (pure Go) and the file format is identical. Swapping the driver would remove cadre's last cgo dependency on the knowledge side, delete `driver_probe.go` and the `doctor` check that reports it, and let the staged tests run in the default build — where today they fail with `Binary was compiled with 'CGO_ENABLED=0'`. Folded into D-5 rather than decided separately, since it is the same file.
