# P4 — recall's parity, read before planning

Required by the spec's own open question, which has said "recall parity is unverified" since charter, and by AI-11: read the destination before planning a move into it.

## The four features to check

cadre's store does exact-match classification filtering, source scoping by repository slug with a canonical-path-hash fallback, audit metadata on retrieval, and a shared-global-store fallback for projects with no partition.

## What recall has

`recall` is a Go RAG library plus an optional service layer, under two hard constraints it states up front: **zero CGO** and **dependency injection** for embedders and LLMs. Its primitives:

- `core.Document` carries `ID`, `Title`, `Author`, **`Source`**, and **`Namespace`**
- `core.Chunk` carries content, a document reference and metadata
- `query` provides `Filter` and `TermFilter` for metadata matching
- `api/auth.go` provides authentication — **at the REST layer, not in the store**

So classification, source scoping and partitioning are all *expressible*: `Source` is first-class, `Namespace` exists, and metadata filters can carry a classification term.

## What it does not have, and the difference is posture rather than features

`store.Search(ctx, query, opts index.SearchOptions)` — the filters live in `opts`, and a caller may pass none. `Document.Namespace`'s own doc says search **"spans all namespaces present in a store"**. Recall searches everything by default and filters when asked.

cadre's `Store.Search(opts SearchOptions)` opens by refusing:

```go
if opts.Classification == "" {
    return nil, fmt.Errorf("classification is required")
}
...
if err := requireExplicitSourceScope(opts.AllSources, opts.SourceFilters); err != nil {
    return nil, err
}
```

And `requireExplicitSourceScope` refuses an empty scope, refuses both-at-once as ambiguous, and refuses blank entries:

> source scope is required: pass at least one source filter, or set AllSources to deliberately span every source in the store

Every search also calls `recordRetrievalRun`, recording the provider, model and result count.

**cadre's store fails closed.** You cannot search it without naming a classification and deciding your scope, and spanning every source is something you must ask for by name. Recall's library will happily search everything if you say nothing.

## What this means for AC-08

AC-08 says exactly one of the two survives. The reading changes what each option costs.

**If recall survives**, its primitives can express all four features, but the refusal has to be rebuilt on top — a wrapper that requires classification, requires an explicit scope decision, records retrieval, and does not let a caller omit any of it. That is not a large amount of code. It is, however, the entire security posture, and it currently exists only in the thing being retired.

**If cadre's store survives**, it keeps the posture and loses recall's substance: pure-Go SQLite, HNSW indexing, BM25 hybrid search with weighted fusion and RRF, rerankers, an eval harness, a distributed layer, and 162 test files. cadre's store also carries `sharding.go`, `federation.go`, `rebalancing.go` and `disaster_recovery.go` — capabilities a single-operator store does not need and which are evidence it grew past its purpose.

## The question this actually surfaces

The two are not competing implementations of one thing, any more than gloop's selector was competing with cadre's. **recall is a retrieval engine; cadre's store is a governed retrieval interface with an engine inside it.** The same shape as P3, found the same way, by reading the destination.

That suggests a third option AC-08 does not currently allow: recall becomes the engine, cadre's governance becomes a thin layer over it, and neither is deleted whole. Whether that counts as "one owner" depends on whether the concern is *storage* or *governed storage* — which is the same distinction that split P3's concern in two.

## Recommendation

Do not plan P4 until AC-08 is settled against this. As written it forces a choice between a posture and an engine, and the evidence says the honest answer may be to keep one of each — exactly as P3 concluded for selection and execution.
