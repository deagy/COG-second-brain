# P3 — retention and deletion: declared, not built

Covers AC-3 and AC-4. cadre `7d0b2ea0`.

## The decision, and why it went this way

Both criteria offer a fork: build the capability, or state plainly that it does not exist. **Declared**, for reasons the evidence supports rather than convenience:

- Rebuilding retention enforcement and steward-facing deletion is a capability decision with an owner problem, not an implementation task. The Python version existed and was removed deliberately when the store moved to recall; nothing since has established that cadre should own it again.
- Recall, which now holds the content, deletes by document or chunk id through its Go API and exposes **no delete command at all**. A cadre-side deletion verb would need a capability its own store does not offer.
- The criteria permit declaring — but require the declaration to carry what would change it, and what its absence costs. A gap stated without those is technically accurate and practically useless.

## What each document now says

`roster/shared/knowledge-use-policy.md` carried the strongest version of the false claim: it told a reader the store *implements* retention and deletion of ingested content. It now states the opposite concretely — no retention window is recorded for any content, nothing ages out, nothing reports what has expired, no steward-facing command removes ingested content — followed by both required elements.

**What would change it:** a command recording a per-message window at ingest and one reporting expiry restores the retention half; a deletion command writing the evidence `DESIGN-NOTES-deletion-and-retention.md` specifies restores the other.

**What the absence costs**, written down rather than left to inference, because this is a governance document someone may be relying on:

> a steward asked to honour a deletion request, a retention window, or an erasure obligation has no tool here to do it with, and no evidence trail if they act by other means. Deleting the store file is still possible and is not the same act — it is unscoped, unrecorded, and takes everything else with it. Every commitment these documents make about retention or erasure is currently a commitment about process, not about software.

That last sentence is the one that matters. The documents were making software commitments; they are making process commitments now, and saying so.

## The shape of this criterion, noted honestly

AC-3 and AC-4 are satisfiable by writing a paragraph, and I wrote the paragraph. That was flagged when the spec was drafted — a criterion whose cheap branch is available is a criterion that can be closed cheaply, and the north star is *parity between documents and code*, not completeness of the code.

What makes the cheap branch legitimate here is that the expensive branch was never decided against on its merits — it was never decided at all, and the documents pretended otherwise. Parity is restored by telling the truth. Whether cadre *should* enforce retention is a product question this goal deliberately does not answer, and `DESIGN-NOTES-deletion-and-retention.md` is what a future decision will need.
