# P4 / T-04 — escalated before starting

The plan reads "cut `cadre knowledge` over to it". Scoping it first, per the pattern that has caught something in every phase, shows it is neither one task nor unblocked.

## The hard blocker

cadre has **no dependency on recall**, and `recall/govern` is **unpushed** — one commit local to this machine. cadre cannot `go get` it. Publishing recall is a CP-6 external mutation and has not been approved.

A `replace` directive pointing at the local checkout would let the work proceed and could never ship, which is worse than waiting: it makes a green suite that depends on a directory nobody else has.

## The scope

Fifty CLI verbs remain under `cadre knowledge`, and 7,283 lines across twenty files remain in the engine after T-02's deletions. AC-08 says the retrieval engine is deleted — and deleting it takes all fifty verbs with it unless they have somewhere to go.

They do not divide evenly:

**Governed retrieval** — `search`, and arguably `ingest` and `stats`. These are what the contract governs and what `recall/govern` exists for. Small, and the actual subject of AC-08.

**Engine maintenance** — `fts5-index`, `hybrid-search`, `defragment`, `vacuum`, `optimize`, `rebuild-indexes`, `check-integrity`, `repair`, `batch-import`, `batch-delete`, `batch-update`, `replication`, `fault-tolerance`, `metrics`, `diagnostics`, `health-check`. These exist because cadre had an engine. Once it does not, most have no meaning in cadre and several already exist in recall's own CLI.

**Already covered by recall** — its `cmd/recall` offers `search`, `hybrid-search`, `backup`, `restore`, `status`, `list`, `info`, `store`, `migrate`, `upload`. Cadre's equivalents are duplicates of a CLI its own store is being retired for.

## What AC-08 actually requires

Re-reading it: recall survives, cadre's retrieval engine is deleted, and **the surviving path preserves all six refusals**. It says nothing about fifty verbs.

So the criterion is satisfied by a governed retrieval path that refuses correctly. What happens to engine maintenance is a separate question the criterion does not answer, and answering it by reflex — porting all fifty — would be the largest piece of work in this ultragoal, undertaken because a task title said "cut over" rather than because anything requires it.

## Three shapes

1. **Narrow T-04 to governed retrieval.** cadre keeps `knowledge search` (and ingest/stats) over `recall/govern`; the engine-maintenance verbs retire with the engine, with recall's CLI named as the replacement where one exists. Smallest, satisfies AC-08 as written, and requires a documented list of what retires.
2. **Port everything.** cadre's knowledge CLI keeps all fifty verbs over recall. Largest, and it rebuilds in cadre a surface recall already has.
3. **Retire cadre's knowledge CLI entirely.** Governed retrieval becomes a library call for agents; operators use `recall` directly. Smallest of all, and it removes a governed *interface* from the CLI, which may be exactly the wrong thing to remove.

## Recommendation

**Shape 1**, with the retiring verbs listed explicitly rather than deleted quietly. Shape 3 is tempting and wrong: the whole finding of this phase is that the governed interface is the part worth keeping, and shape 3 removes it from the place operators meet it.

Shape 2 is what the task title implies and nothing requires.

## Order

Publishing recall gates all three. That is a CP-6 decision, and it should be made on its own terms — `govern` is a new public package in a published library, not a private helper.

---

## Resolved 2026-08-31

Both questions answered. Shape 1 taken; recall published as `v0.3.0` and observed resolving from the module proxy. `init` repoints at recall, `config` survives narrowed to what `govern.New` requires. Full record with the executed mutations and their post-conditions: `CP-6-decisions.md`.
