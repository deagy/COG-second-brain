---
type: "braindump"
domain: "project-specific"
project: "agentic-sdlc"
date: "2026-09-03"
created: "2026-09-03 19:33"
themes: ["knowledge-ingest", "chat-export-parsers", "chunking", "recall"]
tags: ["#braindump", "#raw-thoughts", "#agentic-sdlc", "#recall", "#ingest"]
status: "scoped"
energy_level: "medium"
emotional_tone: "neutral"
confidence: "high"
---

# Braindump: Add Claude and custom model providers to the cadre knowledge CLI ingest

## Raw Thoughts

> I need to update the cadre knowledge cli ingest. I want to add Claude, and Custom model providers.

## What this is asking for

A terse intent capture, not a worked-through problem — recorded as stated, with the
groundwork checked so the next session starts from facts rather than from the sentence.

## Resolved: chat-export parsers, not embedders

Confirmed by Daniel, 2026-09-03. The embedder reading is dropped, and with it the
Anthropic-embeddings constraint — irrelevant to this work.

## What the ingest path actually is

Traced end to end, and it reframes the task.

**cadre delegates ingest to recall.** `internal/knowledge/README_CLI.md:159` maps cadre's
`ingest` and `batch-import` to `recall upload <path>...`. There is no chat-export handling
on the cadre side; `staged_ingest.go` is a different path entirely (the `proposed-knowledge`
staging flow for findings awaiting promotion).
[Source: `~/sdk/cadre/internal/knowledge/README_CLI.md` | 2026-09-03 | confidence: high]

**`recall upload` is a generic document uploader, not a conversation importer.** It accepts
"a file (text, markdown, CSV, JSON, HTML, PDF, DOCX) or a directory", and
`loader.ForExtension` dispatches on file extension to `TextLoader`, `MarkdownLoader`,
`CSVLoader`, `JSONLoader`, `HTMLLoader`, `PDFLoader`, `DocxLoader`.
[Source: `~/sdk/recall/cmd/recall/cmd_upload.go:38-42`, `~/sdk/recall/loader/loader.go:60-79` | 2026-09-03 | confidence: high]

**So a ChatGPT `conversations.json` today lands in `JSONLoader` and is ingested as generic
JSON** — not as conversations, turns, roles, or timestamps. The `--source
legacy-model-export` flag in cadre's CLI docs is a *label recorded on the ingest*, not a
parser selector. Nothing in recall's Go source has a conversation concept on the ingest
side; the only `conversation` references are `query/rewrite.go` and `llm/backend.go`, both
on the query/RAG side.
[Source: grep over `~/sdk/recall` | 2026-09-03 | confidence: high]

## The actual shape of the work

This is not "add two entries to a provider enum". No chat-export parser abstraction exists
yet in either repo — it has to be introduced. The good news is the seam is already there:

> `ForExtension` ... returns an error for extensions with no default loader; **callers can
> register their own via `DirectoryLoader.Loaders`.**

So a `ClaudeExportLoader`, a `ChatGPTExportLoader`, and a custom/BYO loader can register
against that hook without touching the built-in dispatch. The design questions are about
mapping, not plumbing: does one export become one document or one document per
conversation; do turns become chunks or get flattened; what conversation metadata (title,
create time, model, role) survives into document metadata so it is filterable at retrieval.

Extension-based dispatch is the one friction — both Claude and ChatGPT exports are `.json`,
so `ForExtension` alone cannot tell them apart. Selection needs to be explicit (a
`--format claude` style flag) or content-sniffed, and that choice is worth making
deliberately rather than by default.

## Resolved: one document per conversation, turns as chunks

Confirmed by Daniel, 2026-09-03. That pair of decisions is what sent me into the chunking
layer, and it turned up the most useful finding so far.

## The chunker you need already exists and is unreachable from config

`Loader.Load` returns `[]*Document`, not chunks — a loader cannot express chunk boundaries,
and chunking is a store-level config with `MaxTokens` 512 / `Overlap` 50. So "turns as
chunks" cannot be done from the loader side alone.
[Source: `~/sdk/recall/loader/loader.go:52-54`, `~/sdk/recall/config/config.go:164-174` | 2026-09-03 | confidence: high]

But `chunker/document_aware.go` already does exactly what is needed:

> `DocumentAwareChunker` wraps an inner chunker and enforces document boundaries: content is
> first split on an explicit boundary marker (default `"---"` on its own line), and each
> segment is chunked independently. **No chunk ever contains text from two different
> documents/sections, and overlap never crosses a boundary.** Each chunk is tagged with
> `MetaSectionIndex` / `MetaSectionCount`.

That is turns-as-chunks: emit one Document per conversation with turns joined by the
boundary marker, and each turn becomes its own chunk — sub-chunked if a turn exceeds
`MaxTokens`, never bleeding into the neighbouring turn, and carrying its position in the
conversation as metadata.
[Source: `~/sdk/recall/chunker/document_aware.go:6-29` | 2026-09-03 | confidence: high]

**The gap is wiring, not capability.** `ChunkerFactory` maps only `recursive` →
`NewRecursive` with everything else falling through to `NewFixed`, and config validation
rejects any strategy that is not `fixed` or `recursive` — *"store.chunking.strategy %q
unknown (want fixed or recursive)"*. `NewDocumentAware`, `NewParentChild` and `NewSemantic`
are all built and unreachable through configuration. `DocumentAware` and `ParentChild` are
covered by `chunker/advanced_test.go` (`TestDocumentAware`), so this is exposing tested
code, not writing new chunking logic.
[Source: `~/sdk/recall/app/app.go:85-92`, `~/sdk/recall/config/config.go:415-422`, `~/sdk/recall/chunker/advanced_test.go` | 2026-09-03 | confidence: high]

`ParentChildChunker` is worth a look before committing: conversation-as-parent and
turn-as-child is a natural fit for this data, and it is sitting in the same unexposed set.

## Boundary semantics: confirmed, with two hazards the test does not cover

Read `chunker/advanced_test.go` `TestDocumentAware_NoCrossBoundaryChunks`.

**What is proven.** No chunk contains text from two sections; `MetaSectionIndex` and
`MetaSectionCount` are set on every chunk; the boundary is configurable
(`da2.Boundary = "###"`); empty segments are skipped; empty content returns `nil, nil`.
The core guarantee turns-as-chunks depends on is real and tested.
[Source: `~/sdk/recall/chunker/advanced_test.go` TestDocumentAware_NoCrossBoundaryChunks | 2026-09-03 | confidence: high]

**Hazard 1 — short turns are silently dropped.** `fixed.go:119-121`:

```go
if utf8.RuneCountInString(content) < f.config.MinChunkSize && len(parts) == 1 {
    return nil // Too small, skip
}
```

`store/memory.go:41` (and the sqlite store) invoke the factory as
`cfg.ChunkerFactory(chunker.DefaultConfig())`, where `MinChunkSize: 50` — fifty
*characters*. `DocumentAware` chunks each segment independently, so a short turn is a
single-part segment and takes that branch. "Yes, do that." is 13 characters; "one document
per conversation, turns as chunks" is 46. In chat data the short turns are
disproportionately the decisions, and they would vanish from the index with no error.
**This is the finding that changes the work**: `MinChunkSize` must be reachable per-ingest
and set at or near 0 for conversation imports.
[Source: `~/sdk/recall/chunker/fixed.go:119-121`, `~/sdk/recall/store/memory.go:41`, `~/sdk/recall/chunker/chunker.go:32` | 2026-09-03 | confidence: high]

**Hazard 1b — the field's doc comment is wrong.** `chunker.go:16` says *"Chunks smaller
than this are merged with adjacent chunks."* There is no merge logic anywhere in the
package; the only handling is that `return nil`. Merging could not work under
`DocumentAware` anyway, which forbids crossing boundaries. Documented contract and
behaviour disagree, and the behaviour is the harmful one here.
[Source: grep for merge logic over `~/sdk/recall/chunker/` | 2026-09-03 | confidence: high]

**Hazard 2 — section numbering is not turn numbering.** The split is a plain
`strings.Split(content, boundary)`, not line-anchored — the default `"\n---\n"` is only
line-ish because the marker contains newlines, and a custom boundary matches mid-line (the
test's `###` case splits `"one two ### ### three four"` inline). Separately,
`MetaSectionIndex` uses the raw split index while empty segments are `continue`d, and
`MetaSectionCount` is `len(segments)` *before* empties are dropped. So indices can be
non-contiguous and the count can exceed the turns actually indexed. Fine as an opaque
section id; wrong if it is meant to read as "turn 3 of 12".
[Source: `~/sdk/recall/chunker/document_aware.go` Chunk | 2026-09-03 | confidence: high]

## Correction: ParentChild is size-based, not structure-based

An earlier note in this braindump suggested `ParentChildChunker` might map
conversation-to-parent and turn-to-child "more literally". That was wrong. `Chunk` runs
*both* the parent and child chunkers over the **same content** and differentiates by
granularity, not by structure — children are embedded and searched, parents carry context,
linked by `MetaParentID`, and only children are returned for indexing (parents are stashed
and retrieved via `ParentFor` / `ExpandChunks`).

It could still be *composed* to get the shape you want — a `DocumentAware` child over turns
inside a `ParentChild` whose parent spans the conversation — but it does not do it natively,
and its child chunker inherits the same `MinChunkSize` drop. Fixing hazard 1 is a
prerequisite either way.
[Source: `~/sdk/recall/chunker/parent_child.go:51-80` | 2026-09-03 | confidence: high]

## Open questions

- Expose `document_aware` as a config strategy, or select it implicitly for conversation loaders?
- How does `MinChunkSize` become reachable per-ingest — config field, loader hint, or a
  conversation-specific chunker that does not drop?
- Boundary marker that cannot collide with chat content (which routinely contains `---`)?
- Should `MetaSectionIndex` be replaced by an explicit turn index the loader sets, given the
  raw-split-index behaviour?
- Fix or re-document the `MinChunkSize` "merged with adjacent" comment upstream?
- Format selection: explicit `--format claude` vs content sniffing, given both exports are `.json`?

## Action Items

### Immediate (24-48 hours)
- [ ] Decide how `MinChunkSize` becomes per-ingest controllable — without this, short turns drop silently 📅 2026-09-04
- [ ] Pick a boundary marker that cannot collide with `---` in chat content 📅 2026-09-04

### Short-term (1-2 weeks)
- [ ] Expose `document_aware` in `config.go` validation and `app.ChunkerFactory` 📅 2026-09-10
- [ ] Prototype `ClaudeExportLoader` via `DirectoryLoader.Loaders`: one Document per conversation, turns boundary-separated 📅 2026-09-10
- [ ] Add a regression test for a sub-50-character turn surviving ingest 📅 2026-09-10
- [ ] Decide whether the loader sets an explicit turn index rather than relying on `MetaSectionIndex` 📅 2026-09-10
- [ ] Report or fix the `MinChunkSize` doc/behaviour mismatch in `chunker/chunker.go:16` 📅 2026-09-10

## Connections
- **Related Braindumps:** [[braindump-2026-08-28-1928-scrapping-cadre-for-gloop-and-recall]]
- **Relevant Projects:** [[agentic-sdlc]], [[repo-consolidation]]

## Domain Classification
- **Primary Domain:** project-specific — agentic-sdlc (95%)
- **Reasoning:** names the cadre knowledge CLI directly; `recall` is the knowledge store in
  the four-repo split recorded in the 2026-08-28 braindump.
- **Privacy Level:** private

## Processing Notes

- **Input length:** two sentences. The analysis above is deliberately not padded to a
  standard shape — there are no five themes to extract from a stated intent, and inventing
  them would bury the one thing that actually matters (the A/B ambiguity).
- **Confidence:** high on the code facts, all of which were read rather than recalled.
  Medium overall, because the intent itself is ambiguous and the analysis is groundwork
  for a decision rather than the decision.

---

*Processed by COG Brain Dump Analyst*
