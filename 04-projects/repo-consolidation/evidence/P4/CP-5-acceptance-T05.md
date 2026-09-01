# P4 / T-05 — acceptance, observed at the binary

Built from `da84b963`. Two binaries were used deliberately: the current one, and the pre-T-05 build that still has the engine, so the migration could be exercised against a store an older cadre actually wrote.

## The governance chain survives the engine

```
$ cadre knowledge --config <cfg> propose --input finding.md
{ "id": "KS-20260901-t05", "record_status": "proposed", "status": "staged",
  "note": "Staging is not ingestion: nothing is retrievable until a steward accepts this record and it is ingested." }

$ cadre knowledge --config <cfg> disposition-staged --id KS-20260901-t05 \
    --action accepted --reason "verified against the commits" \
    --classification-used internal --decided-by knowledge-store-steward
{ "id": "KS-20260901-t05", "status": "accepted", "sequence": 1 }

$ cadre knowledge --config <cfg> ingest-accepted
{ "ingested": [ { "id": "KS-20260901-t05", "classification": "internal", "chunks": 1 } ],
  "skipped": [], "refused": [], "not_accepted": [], "dry_run": false }

$ cadre knowledge --config <cfg> search --classification internal --all-sources "retrieval engine moved to recall"
count 1
  0.5375 | proposed-knowledge | proposed-knowledge:KS-20260901-t05 | The retrieval engine moved to recall...
```

The store and its `embedder-identity.json` did not exist before `ingest-accepted`; it created and claimed both, which it may do because the vectors it wrote are its own.

## Idempotent through cadre's own evidence

```
$ cadre knowledge --config <cfg> ingest-accepted     # second run
ingested 0  skipped 1
$ cadre knowledge --config <cfg> search --all-sources ...
count 1
```

## The staged store is its own file

```
$ ls .agents/knowledge-store/
config.json  embedder-identity.json  staged-records.db  store.db
```

`staged-records.db` holds exactly five tables — `staged_records`, `staged_record_dispositions`, `staged_record_imports`, `staged_record_deletions`, `staged_record_ingestions` — and nothing of recall's.

## Migration, exercised with two binaries

A record staged by the **pre-T-05** binary into a combined store, then read by the current one:

```
$ cadre knowledge --config <legacy cfg> show-staged --id KS-20260901-t05
cadre knowledge: moved 1 staged row(s) from .../store.db into .../staged-records.db.
The originals are left in place.
{ "frontmatter": { "id": "KS-20260901-t05", ... }, "body": "...", "disposition_history": [] }
```

Legacy store after: `staged_records` still holds its row. New store: 1 row, staged tables only.

## The defect this task fixed

Before `da84b963`, the same command against the same store:

```
error: cannot initialize schema: no such column: embedding_provider
```

Every staged verb resolved `cfg.Database` — a recall store — and opened it with cadre's engine schema.

## cgo

```
$ CGO_ENABLED=0 go test -count=1 ./internal/knowledge/ ./internal/cli/ ./internal/retrieval/
ok  github.com/deagy/cadre/cli/internal/knowledge   21.7s
ok  github.com/deagy/cadre/cli/internal/cli         10.8s
ok  github.com/deagy/cadre/cli/internal/retrieval    0.0s
```

Remaining `mattn/go-sqlite3` importers: `internal/contextstore/database.go`, `internal/engine/executor/sqlite.go`. cadre still needs cgo; the knowledge store no longer does — the outcome T-06 was to measure, arrived at rather than assumed.

## Traceability

AC-08 asks that recall survives, cadre's retrieval engine is deleted, and the surviving path preserves all six refusals. The engine is deleted (−8,669 lines, verified by an independent grep for any residue), and the six refusals were reproduced verbatim at the command line by a verifier that built its own binaries and its own store: `CP-3v-T05-component.md`.
