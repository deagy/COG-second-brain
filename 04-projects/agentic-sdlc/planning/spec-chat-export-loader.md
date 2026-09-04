# SPEC-002: Chat-export loaders for the recall ingest

> Lane: `normal` · Repo: `~/sdk/recall` · Date: 2026-09-03
> Source: [[braindump-2026-09-03-1933-cadre-ingest-claude-and-custom-providers]]
> Depends on: recall `v0.4.0` (document_aware chunking, `min_chunk_size`, `boundary`)

## Goal

`recall upload <claude-export.json>` produces one document per conversation, with each
turn its own chunk and the speaker recoverable at retrieval. Today that file is handled by
`JSONLoader` and ingested as generic JSON — no conversations, no turns, no roles. A custom
format lets the same path absorb an export shape nobody has written a parser for.

The chunking half is already released; this is the ingest half.

## Non-goals

- Embedder providers. Settled: this is export parsing, not embeddings.
- ChatGPT/OpenAI export parsing. The design must not preclude it — the sniffing seam in
  T-02 exists for it — but no ChatGPT parser ships here.
- Any change to `cadre`. It imports `recall/core`, `index` and `govern`, none of which
  this touches.
- Re-ingest or migration tooling for stores already holding conversation JSON.
- The `chunker/chunker.go:16` doc comment that promises a merge which does not exist.
  Separate, real, and unrelated to this.

## What is already true

Verified in `~/sdk/recall` at `v0.4.0`, not recalled:

- `loader.Loader` is `Load(ctx, ref string) ([]*Document, error)`. A loader returns
  documents; it cannot express chunk boundaries.
- `loader.Document` carries `ID`, `Title`, `Source`, `Content`, `Metadata`, and
  `toCoreDocument` (`cmd/recall/local.go`) copies all of them into the store's document.
  **Document-level metadata survives; per-turn metadata has nowhere to live** on a
  one-document-per-conversation model — chunk metadata comes from the chunker.
- `document_aware` chunking splits on `store.chunking.boundary` and guarantees no chunk
  spans two sections, tagging `MetaSectionIndex` / `MetaSectionCount`.
- `min_chunk_size` defaults to 0 for `document_aware`, so short turns survive.

## The constraint that shapes the work

**The `DirectoryLoader.Loaders` hook is not reachable from the CLI.** `loaderForPath` in
`cmd/recall/local.go` passes `nil` for `Loaders` on the directory path, and sends single
files to `loader.ForExtension(ext)`, bypassing `DirectoryLoader` entirely. Registering a
loader against that hook — which the braindump proposed — changes nothing for
`recall upload`. The work is in `loaderForPath` and `ForExtension`, not in a registration.

**`Loaders` is keyed by extension**, so there can be exactly one `.json` loader. Claude and
ChatGPT exports are both `.json`. Format selection therefore happens either inside a single
registered `.json` loader (sniffing) or by a flag that changes which loader is built.

## Acceptance criteria

| ID | Criterion | Verify method |
|---|---|---|
| AC-01 | A real Claude export parses into one document per conversation | `recall upload <export>` then `recall store stats`; document count equals conversation count in the export |
| AC-02 | Each turn is its own chunk under `document_aware` | ingest a 5-turn conversation; chunk count for that document is >= 5 and no chunk contains text from two turns |
| AC-03 | A turn shorter than 50 characters is present in the index | ingest a conversation containing a <50-char turn; `recall search` for its text returns it |
| AC-04 | The speaker is recoverable for a retrieved chunk | a chunk retrieved from an assistant turn is distinguishable from a user turn without re-reading the export |
| AC-05 | Conversation identity survives on the document | title and conversation id are set on the document and visible in retrieval output |
| AC-06 | A `.json` file that is not a chat export still ingests as before | ingest a plain JSON document; behaviour matches `v0.4.0` `JSONLoader` |
| AC-07 | A malformed or truncated export fails with a named error, not a panic or a silent empty ingest | feed a truncated export; command exits non-zero naming the file |
| AC-08 | The custom format ingests an export shape with no built-in parser | supply a mapping (T-05) for a hand-made export; AC-01..AC-04 hold for it |

## Tasks

| ID | Task | Covers |
|---|---|---|
| T-01 | Obtain a real Claude export and record its actual schema in this spec. **Nothing below is designed until this exists.** | AC-01 |
| T-02 | `ConversationLoader` for `.json`: sniff the shape, dispatch to a Claude parser, else fall through to `JSONLoader` | AC-01, AC-06 |
| T-03 | Wire it into `loaderForPath` for both the single-file and directory paths | AC-01, AC-06 |
| T-04 | Emit one Document per conversation: turns joined by the configured boundary, each turn prefixed with its role; conversation id/title/timestamps as document metadata | AC-02, AC-04, AC-05 |
| T-05 | Custom format: a mapping (field paths for conversations, turns, role, text) supplied by config or flag | AC-08 |
| T-06 | Error paths: truncated file, empty export, unknown shape | AC-07 |
| T-07 | Tests, each mutation-checked before being trusted | all |

## Traceability matrix

| AC | Task | Evidence | Status |
|---|---|---|---|
| AC-01 | T-01, T-02, T-03 | | pending |
| AC-02 | T-04 | | pending |
| AC-03 | T-04 | | pending |
| AC-04 | T-04 | | pending |
| AC-05 | T-04 | | pending |
| AC-06 | T-02, T-03 | | pending |
| AC-07 | T-06 | | pending |
| AC-08 | T-05 | | pending |

## Decisions taken

- **One document per conversation, turns as chunks.** Settled 2026-09-03.
- **Sniffing, not a `--format` flag.** `Loaders` is keyed by extension and directory ingest
  passes no per-file format, so a flag cannot express "this directory holds both kinds".
  Sniffing handles the mixed directory and keeps `upload` signature-compatible. A flag can
  be added later as an override; the reverse is harder.
- **Role goes in the chunk text, not in metadata.** The loader emits one Document, so it
  cannot attach per-turn metadata — chunk metadata comes from the chunker. Prefixing each
  turn with its speaker (`user:` / `assistant:`) is the only way the role reaches the
  chunk, and it survives retrieval because it is part of the text that gets embedded.

## Risks and open questions

- **The Claude export schema is unverified.** I have not read a real export. Everything
  about field names and nesting is unknown until T-01. Designing before that is the exact
  mistake this project has already made twice — do not skip it.
- **`MetaSectionIndex` is not a turn number.** It is a raw split index with empty segments
  skipped, and `MetaSectionCount` is computed before dropping them, so indices can be
  non-contiguous and the count can exceed the turns indexed. Either fix that in
  `document_aware` upstream or do not present it as "turn N of M".
- **Boundary collision.** The default is `"\n---\n"` and chat transcripts routinely contain
  `---` — every markdown rule and pasted frontmatter fence. The loader must pick a marker
  the content cannot contain, or escape occurrences in turn text.
- **A conversation is not obviously one document.** Long conversations may exceed useful
  document size, and retrieval returns chunks anyway. Revisit if AC-01 produces documents
  that are unwieldy in practice.
- **Ingesting an export twice.** Dedup behaviour for a re-exported conversation with new
  turns is undefined here. `ingest/dedup.go` exists; whether it does the right thing for
  this shape is unverified.
