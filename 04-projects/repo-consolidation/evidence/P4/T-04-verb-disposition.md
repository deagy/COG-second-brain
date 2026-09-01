# T-04 — what happens to each `cadre knowledge` verb

Shape 1 requires the retiring verbs to be listed explicitly rather than deleted quietly. This is that list: 26 advertised top-level verbs, each with a disposition and a reason.

Marked **[proposal]** where the call is a product judgement rather than a consequence of the migration.

## Keep, governed over `recall/govern`

| Verb | Why it stays |
|---|---|
| `search` | The contract's subject. Every one of the six captured refusals exists to govern this verb. |
| `delete` | Removal is an authority act — the knowledge-use policy requires a steward, and deletion of accepted content requires an authorized human. Governing it is the same reason `search` is governed. **[proposal]** |

## Replaced by recall's own CLI

recall already ships these. Cadre's versions duplicate a CLI whose store is replacing cadre's.

| Verb | recall equivalent |
|---|---|
| `stats` | `recall info` / `recall status` |
| `ingest` | `recall upload` |
| `hybrid-search` | `recall hybrid-search` |
| `backup` | `recall backup` |
| `export`, `import` | `recall migrate` |
| `health-check`, `diagnostics`, `metrics` | `recall status` / `recall info` |

**`backup` is worth calling out.** Cadre's is the `ErrNotImplemented` refusal from T-02 — it copies nothing and says so, telling the operator to copy the database file directly. recall's is real. Retiring cadre's replaces a refusal with a working capability, which resolves the T-02 concern cleanly: the guidance survives by becoming unnecessary.

## Retire with the engine

These exist because cadre had a SQLite engine. Once it does not, they describe nothing.

`fts5-index`, `fts5-search`, `hybrid-stats`, `fault-tolerance`, `replication`, `maintenance`, `batch-import`, `batch-delete`, `batch-update`, `check-integrity`, `repair`, `rebuild-indexes`, `defragment`

Two notes. `fault-tolerance` and `replication` are backed by `cli_persistence.go`, not by the files T-02 deleted, so they are engine surface that survived that pass. And `check-integrity`, `repair` and `rebuild-indexes` are index-maintenance verbs for an index recall owns — recall's HNSW index has its own lifecycle.

## Needs a decision

| Verb | Question |
|---|---|
| `init` | Does cadre still create a store, or does an operator run `recall store` and point cadre at it? The second is cleaner and changes cadre's setup instructions. **[proposal: point at recall]** |
| `config` | Cadre's store config includes the embedder choice, which `govern.New` now requires as an identity. Where that is configured decides whether this verb survives. **[proposal: keep, narrowed to what govern needs]** |

## What this does not touch

The staged-record verbs — `propose`, `list-staged`, `show-staged`, `disposition-staged`, `ingest-accepted`, `import-staged`, `delete-staged` — are **out of scope**. P2 recorded that knowledge governance (separation of duties over proposals) and knowledge retrieval are different concerns and should not be merged. They live in `staged_*.go`, are file-based, and do not depend on the retrieval engine.

## Count

26 advertised verbs: **2 kept and governed, 9 replaced by recall, 13 retired with the engine, 2 needing a decision.**

The two kept are the two the contract exists for. That is the shape AC-08 asks for, and it is a much smaller cadre than the one that had an engine.
