# P2 — the documents describe what exists

Covers AC-2 (no absent capability described as current; recall named for what moved) and AC-6 (a convention is not written as a control). cadre `36ba82d6`.

## The edit that would have been wrong

Deleting every sentence naming an absent verb. P1 established why: these were **real commands** in `roster/knowledge-store/src/cli.py`, with handler code and dedicated test modules, removed in `b418031e`. Every sentence was accurate when written.

And the prose is not filler. `SECURITY.md` carried, in detail, why retention defaults shipped indefinite — *"shipping working day-counts ahead of that decision would let them become policy by default inertia"* — why deletion evidence commits in two phases so `completed` cannot lie, and three limits stated plainly rather than hidden: a deletion cannot redact what a past retrieval already returned; exported bundles are outside its reach; residue reclaim covers the live database only, never backups.

**That is the specification for a capability P3 had to decide about.** Satisfying AC-2 by deleting it would have closed one criterion by making the next one's decision worse-informed.

## What was done instead

The reasoning moved to `DESIGN-NOTES-deletion-and-retention.md`, **verbatim**, relabelled as design intent. The words are unchanged; only the claim they make about the world is corrected. Three of its limits are properties of the problem rather than of the Python implementation, so a replacement inherits them — and one that quietly did not say so would be the weaker artifact.

| File | Was | Is |
|---|---|---|
| `knowledge-store/README.md` | `## Commands` listed the full Python-era surface as current | What the CLI answers, plus a removed-verbs table naming where each went |
| `knowledge-store/SECURITY.md` | Four paragraphs of present-tense description | The absence stated plainly; the design preserved by reference |
| `knowledge-store/AGENT.md` | Steward deliverables that cannot be produced | Corrected, including that the committed snapshot is now frozen — `import-staged` reads such a directory but nothing writes one, so the round trip is half present |
| `workflows/knowledge-ingestion.md` | Step 9 described both deletion paths as live | One exists; the other is named as removed with a pointer |
| `.agents/skills/{knowledge-ingestion,agent-stores}/SKILL.md` | Instructed agents to run `cadre knowledge context` | `search`, with its scope requirement stated |
| `CHANGELOG.md` `[Unreleased]` | `--source` newly repeatable on a removed verb | The `search` half stands; the other is noted as removed in the same window |

## AC-6 — one sentence, in the wrong place

`SECURITY.md` told a reader to route ingestion, correction, retention and deletion "through the knowledge-store steward". That reads as a control. It is a convention: **the CLI has no caller identity at all**, and `--decided-by`, `--deleted-by` and `--authorized-by` are free-text strings authenticated by nobody — which the same document admitted sixteen lines further down.

The admission now sits next to the claim, with the four separation-of-duties rules that *are* enforced named explicitly, so a reader can tell which is which. Those four are real: P4 proved each fails when its check is removed.

## Three things the repository's own machinery taught, none of them planned

- Editing a role's `AGENT.md` cascades: role metadata, then the plugin, then the Cline mirror, in that order.
- `port-cline-agents` takes `--source plugin`; defaulting it to `--root` fails with a missing-directory error that does not explain why.
- **The plugin generator packages only tracked files.** A new design note was invisible to it until staged — and `knowledgeStoreExtras` then had to name it, for the reason that allowlist's own comment already gives: shipping documents that cite a file the reader cannot open is the defect this phase exists to remove.

## A note on the CI control, since it was questioned

A verifier described `ci-status.sh` as showing a "stale PENDING snapshot" while GitHub reported green. Checked: it was neither stale nor wrong. The run genuinely had not finished when the script was asked, and it reported `PENDING ... not finished, so not green`. Once the run landed, the same command returned `success run 33570800837`, exit 0.

Recorded because the obvious response to that report would be to make the script accept an in-flight run — which would turn the control back into the thing it replaced. Its header already says why: *"a run still in progress is NOT green. It has not finished disagreeing."*

Also confirmed while checking: cadre runs one workflow per commit, so there is no risk of an unrelated queued job masking a green `validate`.

## Verification: four rounds

AC-2 and AC-6 were built at `36ba82d6` and did not close until `b534fb27`. Three verification rounds failed first, each on a different cause, and the phase's own record is worth more than its outcome.

| Round | Verdict | Cause |
|---|---|---|
| 1 | FAIL | Fixed the named locations; never enumerated the set |
| 2 | FAIL | Same, and introduced a verbatim duplicate paragraph — the stale copy 19 lines above its own correction |
| 3 | FAIL | Enumerated, but by removed-verb **name**. Four documents assert the capabilities without naming any command, so no name-based search could reach them |
| 4 | PASS | Enumerated by capability **concept**, plus a mechanical near-duplicate detector |

Round 3's fix commit made the name-vs-concept mistake in the same message that diagnosed it as the root cause of round 2. That is the durable lesson: naming a failure mode does not protect against it, and the fix has to be mechanical.

**EVIDENCE AC-2 | CP-3v | PASS** — cadre `b534fb27`, CI run 33572609424. See `CP-5-acceptance-AC-2.md`.
**EVIDENCE AC-6 | CP-3v | PASS** — round 2, `SECURITY.md`: the convention now sits beside the limitation that makes it one, with the four enforced separation rules named so a reader can tell them apart. P4 later proved three of the four fail when their check is removed.
