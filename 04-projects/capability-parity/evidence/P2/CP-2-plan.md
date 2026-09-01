# P2 — the documents describe what exists

Covers AC-2 (the knowledge-store documents describe no capability the inventory found absent, and name recall for what moved there) and AC-6 (a convention is not written as a control).

## What reading the documents changed about the plan

The obvious approach — find every sentence describing an absent verb and delete it — is wrong, and P1 is why.

These capabilities were **real**. `roster/knowledge-store/src/cli.py` implemented `retention-report`, `delete-ingested`, `deletion-evidence`, `list-staged` and `export-staged` with handler code and dedicated test modules, removed wholesale in `b418031e` when Go replaced Python. Every sentence describing them was accurate when written.

And the prose is not filler. `SECURITY.md` lines 36–44 carry, in detail:

- why retention defaults ship as indefinite — *"a deliberate placeholder, not a judgement that content should be kept forever… shipping working day-counts ahead of that decision would let them become policy by default inertia"*
- the two-phase deletion-evidence commit, and why `delete_status='completed'` is the only value that means removed
- three honest limits: a deletion cannot redact what a past retrieval already returned; exported bundles are outside its reach; residue reclaim covers the live database only, never backups
- that `--deleted-by` and `--authorized-by` are caller-asserted, *including* that one actor asserting both roles is accepted and recorded as written

**That is the design specification for a capability P3 has to decide whether to build.** Deleting it to satisfy AC-2 would destroy the input to the next phase's decision — closing one criterion by making another harder to answer well.

So P2's edit is *say what happened*, and the reasoning is preserved rather than removed.

## Approach

**Split description from design intent.** Each affected document keeps a section describing what the CLI does today, and the Python-era reasoning moves to a clearly-labelled design note that says it specifies something not currently built. A reader of the live document is never misled; a reader of P3's decision still has the thinking.

## Files

| File | What is wrong | Edit |
|---|---|---|
| `roster/knowledge-store/README.md` | The `## Commands` block lists the full Python-era surface as current | Replace with what the CLI answers, marking removed verbs and what replaced each |
| `roster/knowledge-store/SECURITY.md` | Lines 36–44 describe retention, `delete-ingested` and `deletion-evidence` as shipped behaviour | Move the reasoning to the design note; leave a short, true statement of what exists and what does not |
| `roster/knowledge-store/AGENT.md` | Instructs the steward to use absent verbs | Correct the instructions; keep the separation-of-duties rules, which do hold |
| `roster/workflows/knowledge-ingestion.md` | Step 8 and step 9 describe `delete-ingested` and `retention-report` as live | Correct; the workflow's *sequence* is still right |
| `.agents/skills/knowledge-ingestion/SKILL.md:37` | Instructs running `cadre knowledge context` | Point at `cadre knowledge search` |
| `.agents/skills/agent-stores/SKILL.md:53` | Same | Same |
| `CHANGELOG.md` `[Unreleased]` | Describes `--source` becoming repeatable on `cadre knowledge context` | Note that the verb went with the rewrite; the `search` half stands |

## AC-6 — the convention that is written as a control

`SECURITY.md:27` says to *"route ingestion, correction, reclassification, retention, and deletion through the knowledge-store steward"*, and the inventory recorded this UNTESTABLE: **the CLI has no caller identity at all.** `--decided-by`, `--deleted-by` and `--authorized-by` are unauthenticated strings, which that same document admits further down.

So the sentence describes a convention people follow, not a gate anything enforces. AC-6 asks only that it be labelled as one — next to the limitation that makes it so, rather than sixteen lines away.

Worth stating precisely because the surrounding document is unusually honest about its own limits; this is the one place where a process rule reads like a technical control.

## What P2 must not do

- **Do not delete the retention and deletion reasoning.** P3 decides whether to build those, and this is its specification.
- **Do not rewrite the dated CHANGELOG sections.** Those record what was true when they shipped; the `[Unreleased]` entry is the only live claim.
- **Do not touch `roster/orchestration/runs/`.** Archived records of what was believed on a date.
- **Do not soften the separation-of-duties rules.** Four of them — `propose`, `disposition-staged`, `import-staged`, `ingest-accepted` — are real, enforced and verified. Only the steward-routing sentence is a convention.
