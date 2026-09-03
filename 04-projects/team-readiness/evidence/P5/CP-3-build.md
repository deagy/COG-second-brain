# P5 — CP-3 build and CP-3v

`delete-ingested` and `deletion-evidence` exist again, released in
`cli-v0.7.9`, requiring recall `v0.3.6` for `DocumentChunkCount`.

## What was actually missing

Not the capability. recall's store has deleted by document id throughout, and
`SECURITY.md` said so: the Go API *"deletes by document or chunk id"*. What was
missing was **a way to reach it without writing Go**, which for anyone using
the shipped tools is the same as not having it. The same shape as P3's config
block — present in code, unreachable in practice.

## Three refusals, each because the alternative reads as evidence and is not

- **Deleting a document with no chunks** — recording a removal that removed
  nothing puts a false entry in the trail.
- **Recording evidence after a partial removal** — it reports how many chunks
  survived instead.
- **Presenting `deleted_by` as verified** — the record carries the same
  `actor_verification` line P3 added, rather than inventing a second answer to
  a question already settled.

The evidence table has no foreign key to the document, deliberately, and a test
asserts that rather than a comment: adding the "missing" constraint would look
like tidying up and would destroy the audit trail at the moment it matters.

## CP-3v: PASS

Run against released binaries, with the checksum verified. The cycle went
propose → disposition → ingest-accepted → search (found, score 0.578) →
`delete-ingested` (`chunks_removed: 1`) → search (`"count": 0`).

**Absence was then confirmed a third way, and that is the part worth keeping:**
`recall store info` reported `chunks: 0`, bypassing cadre entirely. Asking
cadre whether cadre's delete worked is the weak version of this check; asking
the storage engine is not.

The weak-reading hunt also held. Re-deleting an already-deleted id refused, and
the evidence afterwards showed exactly one legitimate record — the failed
attempts added nothing.

## Two findings from CP-3v, carried

**The id a colleague has is not the id the verb wants.** `propose` and
`list-staged` show `KS-…`; `delete-ingested` expects the corpus id
`proposed-knowledge:KS-…`, visible only in a prior search's citation. The
refusal is correct — "holds no chunks" — but a colleague following the CLI's
own output hits it first, which is exactly the first-hour friction P1 exists to
remove. A UX or docs fix, not a correctness one.

**`ingest`'s retirement message points somewhere that composes badly.** It
suggests `recall upload`, and content uploaded that way cannot later be deleted
through `cadre knowledge delete-ingested` unless `cadre knowledge init` ran on
the store before any content landed — `OpenForIngest` refuses a store that
"already holds content, and what embedded it is not recorded". That refusal is
a deliberate fail-closed design and right. The message suggesting the path does
not mention the ordering it requires.

Both go to the retro rather than being fixed here: AC-8 is met, and expanding a
phase to smooth an adjacent verb's message is how a criterion stops meaning
what it says.
