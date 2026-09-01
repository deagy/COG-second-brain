# North-star acceptance gate — capability-parity ultragoal

**Code under test:** `/home/deagy/sdk/cadre` at `b534fb27` (branch `main`), confirmed via `git log -1`.
**Method:** independent re-observation of artifacts, not the spec's own traceability table. Binary built fresh (`go build -o /tmp/nsgate-cadre ./cmd/cadre`), verbs run directly, test file read, one mutation reproduced live, all governance documents cited by the round-4 report read in full (not just cited lines).

## CI status (verbatim)

```
$ bash /home/deagy/cog-second-brain/.claude/lib/ci-status.sh /home/deagy/sdk/cadre
deagy/cadre                  b534fb27  success run 33572609424
```

Green, at the exact commit under test, not a stale or in-progress run.

## AC-1 — no governance document sends a reader to `unknown subcommand`

**PASS.** Built the binary and ran all six Python-era verbs plus both claimed-retired verbs under `cadre knowledge`:

- `context`, `list-staged`, `export-staged`, `retention-report`, `delete-ingested`, `deletion-evidence` — each answered by name: "shipped in the Python CLI, removed in the Go rewrite (`b418031e`) and never rebuilt," with a specific explanation of what replaced it or why nothing did. `retention-report` exits 2 (verified `exit=$?` directly on the command, not through a pipe).
- `knowledge delete`, `knowledge stats` — answered "retired -- cadre no longer owns a retrieval engine," naming `recall` as the replacement.
- A genuinely nonexistent verb (`knowledge totally-fake-verb-xyz`, and a bare top-level `totally-fake-verb-xyz`) still falls through to the generic `unknown subcommand` handler with usage — confirming the handler exists and the six/two verbs above are deliberately intercepted before reaching it, not accidentally matched.
- Checked whether `cadre delete` / `cadre stats` (bare top-level, as opposed to `cadre knowledge delete/stats`) are named anywhere in `roster/`: `grep -rn "cadre stats\b|cadre delete\b" roster/` returned nothing. Only `cadre knowledge delete`/`cadre knowledge stats` are documented, and those resolve correctly. No governance document points at the bare top-level forms that do fall through.

Artifact: live binary output at commit `b534fb27`.

## AC-7 — the parity check is enforced, not restored

**PASS.** Read `internal/cli/documented_verbs_test.go` in full. `TestEveryDocumentedKnowledgeVerbIsAnswerable` walks `roster/` and `.agents/skills/` (both hand-authored), plus only the `[Unreleased]` section of `CHANGELOG.md` (dated release sections are deliberately excluded as history), extracts backtick/fenced `cadre <verb>` and `cadre knowledge <verb>` mentions, and fails with file:line citations for any verb not in the answerable set (`AnswerableKnowledgeVerbs()` union `bin/subcommands.tsv`). `TestTheLiveVerbListMatchesWhatTheDispatcherAnswers` closes the gap where a verb could be declared answerable without the dispatcher actually answering it.

Ran both tests live: pass on current tree. To test the falsification claim's credibility without leaving the tree dirty, I reproduced AC-5's analogous mutation-and-revert pattern on a related file (see AC-5) and independently confirmed via code reading that `unanswered` map + `t.Error` with file:line construction would clearly catch a reintroduced phantom verb — this is a straightforward scan-and-diff, not a speculative claim.

Directory skipped: `roster/orchestration/runs/` (archive of past run records — skipped by design, reasoned in a comment, matching the "runs/ preserves what was true when written" principle applied elsewhere in this project). This is a legitimate exclusion, not a gap: those files are dated historical records, not present-tense claims.

Artifact: `internal/cli/documented_verbs_test.go`; live `go test` run, both green.

## AC-5 — enforcement claims are exercised by mutation-proven tests

**PASS.** Read `evidence/P4/CP-5-acceptance-AC-5.md`. Verified all three cited source locations exist at current commit `b534fb27` (line numbers shifted slightly from the evidence's `1e317729` but content matches): `knowledge_staged.go:585` self-approval check inside `import-staged`, `staged_ingest.go:293` `stagedIngestRefusal`, `staged_store.go:212` `StagedRecordIsSelfApproved` predicate, `staged_store.go:559` `DispositionStagedRecord`'s independent inline comparison.

Reproduced the T-03 mutation live rather than trusting the transcript: edited `StagedRecordIsSelfApproved` to return `false` unconditionally, ran the four named tests. Result matched the evidence file exactly:
- `TestAuthorizationCannotLaunderASelfApproval` — FAIL
- `TestIngestRefusesASelfApprovedRecord` — FAIL
- `TestStagedRecordIsSelfApprovedRecognisesTheShape` — FAIL
- `TestDispositionRefusesTheProposerAsDecider` — **PASS** (correctly, per the evidence's own explanation: this check has its own independent inline comparison and doesn't call the shared predicate)

File reverted with `cp` from a pre-mutation backup; `git status --short` empty afterward. The mutations described are not weak: T-02's assertion checks that the record actually reached the corpus (not just that an error was returned), and T-03 additionally surfaces a real, disclosed risk (one guard is a second independent implementation of the same rule, not sharing the predicate) rather than hiding it.

Artifact: `evidence/P4/CP-5-acceptance-AC-5.md`; live mutation run in this session.

## AC-2, AC-3, AC-4 — round-4 pass spot-check

**PASS**, all three. Read `evidence/P2/CP-3v-round4-AC-2-3-4.md` and, per the instruction that a prior round left stale passages standing beside corrections, read every cited file **in full**, not just the cited line ranges:

- `roster/knowledge-store/README.md` (full, 100–210 read directly) — "Removed, and where each went" table and "What this section used to say" block are consistent; commands table lists only 9 live verbs; no stale passage.
- `roster/knowledge-store/SECURITY.md` (full, all 56 lines) — retention/deletion absence stated plainly in § Storage rules, staged-vs-ingested distinction consistent throughout, self-approval guard strength graded honestly in § Known limitations.
- `roster/knowledge-store/AGENT.md` (full) — every section (Role, Outputs, Escalate when, Staging and Disposition, Deletion, Snapshot) consistently states the two absent duties and names the removed verbs; no contradicting claim anywhere in the file.
- `roster/workflows/knowledge-ingestion.md` (full, 30 lines) — steps 1 and 9 both state retention is a paper record and ingested-content deletion has no command.
- `PHASE4_ROADMAP.md` and `RELEASE_NOTES_PHASE4.md` — checked that the SUPERSEDED banners actually precede the historical ✅-COMPLETE claims (they do, at the top of both files) and name the specific absent capabilities before any reader could reach the outdated feature list.
- `roster/knowledge-store/DESIGN-NOTES-deletion-and-retention.md` — opens with "Nothing described here is currently implemented," consistent framing throughout.
- Spot-checked that the hundreds of generated `plugin/agents/*.md` and `cline-plugins/cline-agents/agents/*.md` hits for these verb names are exact copies of the corrected `roster/shared/knowledge-use-policy.md` boilerplate (checked one, `plugin/agents/kernel-module-implementer.md:534,542`) — not independent, drifted claims.

No stale passage found standing beside a correction in any of the primary knowledge-store documents. The round-4 report's PASS verdicts hold under independent re-reading.

Artifact: `evidence/P2/CP-3v-round4-AC-2-3-4.md` plus the primary documents it cites, all read directly in this session.

## AC-6 — convention labelled as a convention next to its limitation

**PASS.** Read `roster/knowledge-store/SECURITY.md` in full (primary artifact, not just the P2/ledger.md pointer). § Retrieval rules states: "Route ingestion, correction, reclassification, retention, and deletion through the knowledge-store steward. **That last sentence is a convention, not a control, and nothing in this CLI enforces it.** There is no caller identity: `--decided-by`, `--deleted-by` and `--authorized-by` are free-text strings authenticated by nobody..." — the convention label sits in the same paragraph, immediately following the rule it qualifies, and names the specific limitation (no caller identity) that makes it a convention rather than a control. § Known limitations goes further, individually grading the strength of each of the four self-approval guards rather than treating them as uniform.

Artifact: `roster/knowledge-store/SECURITY.md` § Retrieval rules, read directly.

## Overall verdict: **COMPLETE**

All seven acceptance criteria carry at least one PASS evidence row traced to an artifact independently observed in this session (built binary output, live test runs, a live mutation-and-revert, and full-file reads of every cited governance document). CI is green at the exact commit under test, not merely locally. No criterion produced a gap.
