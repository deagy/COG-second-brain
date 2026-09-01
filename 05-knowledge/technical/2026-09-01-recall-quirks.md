---
type: knowledge
domain: technical
project: recall
topic: recall Chunking & Similarity Quirks
created: 2026-09-01
last_updated: 2026-09-01
source: repo-consolidation P4 session; verified against recall source
version: "1.0"
tags: ["#knowledge", "#recall", "#rag", "#embeddings"]
related:
  - 05-knowledge/technical/2026-09-01-verification-that-depends-on-the-room.md
  - 04-projects/repo-consolidation/spec.md
---

# recall Chunking & Similarity Quirks

## Overview
Two silent-failure modes in `recall` (the Go RAG library cadre's knowledge store migrated onto), found while migrating cadre off its own retrieval engine. Both fail by returning a plausible-looking result instead of an error, which is what makes them worth recording rather than something a type signature would catch on the next read.

## Current State
- **Short content is dropped silently on ingest.** `MinChunkSize` defaults to 50 (`recall/distributed/distributed.go:69`) — content shorter than that is not chunked and is not stored. A store can report a document accepted and hold nothing for it; there is no separate error path for "too short to chunk." [Source: `~/sdk/recall/distributed/distributed.go:69`, `store/health_test.go:16` | 2026-09-01 | confidence: high]
- **A dimension mismatch returns a full result, not an empty one.** `cosineSimilarity(a, b []float32)` in `recall/store/sqlite.go:799` returns `0` when `len(a) != len(b)` — the same value it returns for genuinely orthogonal vectors. An embedder-dimension mismatch (e.g. querying with a different embedding model than the store was built with) therefore does not error and does not return "no matches" — it returns *every* chunk in scope, all scored 0, in index order: an ordinary-looking, fully-populated, entirely irrelevant answer. [Source: `~/sdk/recall/store/sqlite.go:799-812`; corroborated in [[04-projects/harness/retro/2026-09-01-repo-consolidation-p4.md]] | 2026-09-01 | confidence: high]

### Key Details
- Both failure modes share a shape: the library returns a normal-shaped, non-empty result rather than an error, so a caller has to know to check for the specific condition. A caller that only checks "did I get results back" will not notice either one.
- If cadre or any other consumer wraps `recall`, worth a guard that rejects a query before searching if its embedding's width doesn't match the store's, and a warning (not silent success) on ingest when input is shorter than `MinChunkSize`.

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-09-01 | 1.0 | Initial entry from repo-consolidation P4 harvest staging, verified against recall source | harvest-curator |

## Related
- [Verification that depends on the room](./2026-09-01-verification-that-depends-on-the-room.md)
