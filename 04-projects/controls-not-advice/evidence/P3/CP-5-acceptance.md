# P3 — CP-5 acceptance · AC-3, AC-6

**EVIDENCE AC-3 | CP-5 | PASS** — all five advice items landed where they load, each with a reason specific to it. `CLAUDE.md:171-173` (AI-2, AI-9, AI-14), `CLAUDE.md:156` (AI-7), `WORKFLOW.md:78-84` (AI-6b). Verification tested the bar most at risk of passing on prose quality — whether a reason would fit two or three other items equally well — and found none interchangeable. AI-7 confirmed honest as a cost argument rather than dressed as impossibility. Artifact: `CP-3v-round1.md`.

**EVIDENCE AC-6 | CP-5 | PASS** — the backlog header defines `control`, `advice` and `landed` and says what closes each; all twenty rows carry exactly one, with no fourth label. Verification confirmed against git history that the six previously-`done` rows were relabelled with substance preserved. Artifact: `CP-3v-round1.md`.

**EVIDENCE — | CP-4 | PASS** — 5 claims, round 2. Artifact: `CP-4-integration.md`.

## What the gates caught

| Gate | Verdict | What it found |
|---|---|---|
| CP-3v | PASS, one note | Every `control` row happened to cite a commit, which acted as the built/unbuilt signal — but the convention was inferred from the rows, not stated. A future control landing without a citation would have been indistinguishable from a built one, which is the exact distinction AC-6 exists to preserve |
| CP-4 round 1 | **FAIL** | Two rows contradicted the record they summarise |
| CP-4 round 2 | PASS | Both fixed, mutually consistent, no new inconsistency |

### The two contradictions, because they are the session's recurring shape

**AI-14's row claimed AI-13's control covers its originating instance.** P2's verification had established the opposite — AI-13 guards a discarded *path*, AI-14 originated in an unlogged *version*. That correction reached P2's build record and the `CLAUDE.md` landing. It did not reach the backlog row, which is where a reader checking coverage would look.

**AI-1's row labelled a built control as `advice`**, citing a landing never made, while AI-11 — the other half of the same merged item — read `control`. Two rows for one item disagreeing about whether it was built, in the same commit that introduced the vocabulary to prevent that.

Both are stale text standing beside its own correction. That shape has now appeared in this session in `README.md`, `SECURITY.md`, `AGENT.md` twice, a triage cross-reference, and these two rows. **Every occurrence was found by a mechanical cross-check; none by re-reading.** The near-duplicate detector shipped this morning covers one form of it in cadre's governance documents, and would not have caught any of the last three.

## Carried into P4

- **A row-versus-reality cross-check is the missing control.** Six of the eight defects in P2 and P3 were a claim in one document contradicting another document or the code. `duplicate_paragraphs_test.go` catches near-duplicate prose within a file; nothing checks a claim against the artifact it names. That is a bigger thing than P4's scope, and it is the honest next goal rather than something to bolt on here.
- AI-10's row cited a file with no commit, failing the `control — unbuilt` convention added hours earlier. Fixed; noted because a convention fails first on the table that introduced it.
