# North-star acceptance gate — capability-parity (independent re-verification, round 2)

**Code under test:** /home/deagy/sdk/cadre @ b534fb27aad257a6c5aee8a951893798a8053248, branch main, `git status --short` empty.
**Method:** Nothing taken from the spec's traceability table, STATUS.md, report.html, or the prior northstar-gate.md on trust. Binary built fresh to /tmp/nsgate2-cadre; all AC-1 verbs run live; documented_verbs_test.go read then executed; AC-5's T-03 mutation reproduced live in a throwaway clone (/tmp/nsgate2-clone, deleted after); all four primary governance docs read in full plus a tree-wide concept grep across every tracked non-generated file for retention/deletion/TTL/audit-trail language; provider/roles and provider/codex-agents confirmed generated (byte-identical to roster/, referenced as a generation target in internal/generators/plugin_generation.go) rather than an independently-drifted hand-authored copy the AC-7 guard would miss.

## CI status (verbatim)

```
$ bash /home/deagy/cog-second-brain/.claude/lib/ci-status.sh /home/deagy/sdk/cadre
deagy/cadre                  b534fb27  success run 33572609424
```

## AC-1 — PASS

Built `/tmp/nsgate2-cadre` and ran all eight verbs directly. Each of `context`, `list-staged`, `export-staged`, `retention-report`, `delete-ingested`, `deletion-evidence` answers by name: "shipped in the Python CLI, removed in the Go rewrite (`b418031e`) and never rebuilt," each with a specific explanation (e.g. `list-staged` — "`ListStagedRecords(status)` is live... it is simply not wired to a CLI verb"). `knowledge delete` / `knowledge stats` answer "retired -- cadre no longer owns a retrieval engine," naming `recall`. All eight exit 2. `knowledge zzznotaverb` and a bare top-level unknown verb both still fall through to the generic "unknown subcommand" handler with full usage text (exit 1) — confirms the fallback path still exists and the eight verbs above are deliberate intercepts, not the only path left.

## AC-7 — PASS

Read `internal/cli/documented_verbs_test.go` (288 lines) in full. `TestEveryDocumentedKnowledgeVerbIsAnswerable` walks `roster/` and `.agents/skills/` (backtick spans and fenced-block lines only, to avoid matching English prose), plus only the `[Unreleased]` section of `CHANGELOG.md`, and fails with file:line citations for any verb not in `AnswerableKnowledgeVerbs()` ∪ `bin/subcommands.tsv`. `TestTheLiveVerbListMatchesWhatTheDispatcherAnswers` independently drives every verb in `liveKnowledgeVerbs` through the real dispatcher against a resolvable config and fails if any hits "unknown subcommand" — closing the gap where a verb is declared answerable but not actually wired.

```
$ CGO_ENABLED=1 go test -tags sqlite_fts5 -run 'TestEveryDocumentedKnowledgeVerbIsAnswerable|TestTheLiveVerbListMatchesWhatTheDispatcherAnswers' ./internal/cli/ -v
--- PASS: TestEveryDocumentedKnowledgeVerbIsAnswerable (0.08s)
--- PASS: TestTheLiveVerbListMatchesWhatTheDispatcherAnswers (0.01s)
PASS
ok  	github.com/deagy/cadre/cli/internal/cli	0.098s
```

## AC-5 — PASS

Read `evidence/P4/CP-5-acceptance-AC-5.md`. Confirmed the four cited source locations exist at current commit: `StagedRecordIsSelfApproved` (`internal/knowledge/staged_store.go:212`), its independent-inline-comparison sibling in `DispositionStagedRecord` (`staged_store.go:559`, `input.DecidedBy == StagedString(frontmatter, "staged_by")` — genuinely does not call the shared predicate), `stagedIngestRefusal` (`staged_ingest.go`), and the import self-approval check.

Reproduced T-03 independently: cloned to `/tmp/nsgate2-clone`, edited `StagedRecordIsSelfApproved` to `return false` unconditionally, ran the four named tests:

```
--- FAIL: TestAuthorizationCannotLaunderASelfApproval
--- FAIL: TestIngestRefusesASelfApprovedRecord
--- PASS: TestDispositionRefusesTheProposerAsDecider
--- FAIL: TestStagedRecordIsSelfApprovedRecognisesTheShape
```

Exact match to the evidence file's table. `TestDispositionRefusesTheProposerAsDecider` surviving is correct given the independent-comparison design confirmed above, not a gap. Clone deleted afterward; `/home/deagy/sdk/cadre` confirmed untouched (`git status --short` empty).

## AC-2, AC-3, AC-4 — PASS

Read `roster/knowledge-store/README.md` (207 lines), `SECURITY.md` (56 lines), `AGENT.md` (69 lines), and `roster/workflows/knowledge-ingestion.md` (30 lines) in full — every occurrence of retention/deletion language, not just the cited lines. No stale passage stands beside a correction in any of the four. All four state plainly: no retention window is recorded, nothing ages out, no CLI command deletes ingested content, `delete-ingested`/`retention-report`/`deletion-evidence` were removed in `b418031e` and never rebuilt, and what would restore each.

Went beyond the four mandated documents: grepped the entire tracked tree (excluding `plugin/`, `cline-plugins/`, `roster/orchestration/runs/`) for "retention window / ages out / TTL / expires / audit trail / retention policy / deletion evidence / delete-ingested / retention-report" and read every non-generated hit that could plausibly claim an ingested-content retention/deletion capability:
- `.agents/skills/run-agent-orchestration/references/dispatch-contract.md:25` — states the corrected version live (staged-record deletion exists, ingested-content deletion does not); this is the exact passage the b534fb27 commit message says it fixed, confirmed fixed.
- `roster/shared/knowledge-use-policy.md:24-30` — states the absence plainly with cost and restoration conditions.
- `roster/operations/retention-and-deletion-executor/AGENT.md:15` — explicitly carves out that the knowledge store "has no capability at all over *ingested* content."
- `roster/RUNBOOK.md`, `roster/orchestration/SECURITY-CONTROLS.md`, `docs/proposals/*`, `PHASE4_ROADMAP.md`, `RELEASE_NOTES_PHASE4.md`, `DISPATCH_CORE_ROADMAP.md`, `DISTRIBUTION.md` — remaining hits are either unrelated subsystems (context-store TTL, which is a real separate implemented feature; dispatch-core job TTL; a data-governance role's abstract retention duty) or, for the two Phase-4 documents, carry SUPERSEDED banners at the top naming every withdrawn capability (TTL-based expiry, age-based retention, source-based deletion, deletion audit trail) before any reader reaches the stale "COMPLETE"/"Production Ready" body text below.
- `provider/roles/knowledge-store/AGENT.md` confirmed byte-identical to `roster/knowledge-store/AGENT.md` (`diff` empty) and confirmed generated by `internal/generators/plugin_generation.go` — not an independent copy that could have drifted outside the AC-7 guard's scan roots.

No document found asserting a retention or ingested-content-deletion capability that does not exist.

## AC-6 — PASS

Read `roster/knowledge-store/SECURITY.md` § Retrieval rules in full. The steward-only-routing sentence is immediately followed, in the same paragraph, by: "That last sentence is a convention, not a control, and nothing in this CLI enforces it. There is no caller identity: `--decided-by`, `--deleted-by` and `--authorized-by` are free-text strings authenticated by nobody..." The limitation (no caller identity) sits directly beside the label. § Known limitations further grades each of the four self-approval guards individually rather than treating them as uniform.

## Closure-artifact audit

**STATUS.md** — commit `b534fb27` and CI run `33572609424` match the live `git log` and `ci-status.sh` output. Phase states (P0–P4 all done) match spec.md and the evidence directories that exist on disk. "Open AC-n: None" matches — all seven criteria independently confirmed above.

Checked the three "carried forward" items against code, since these are falsifiable claims:
- **`list-staged` is "one CLI wire away"**: confirmed. `ListStagedRecords(status)` (`internal/knowledge/staged_store.go:253`) is live, called internally by `staged_ingest.go:184`, and covered by `staged_migration_test.go`. No CLI dispatch wires it to a verb.
- **"Four separation checks, one predicate" true of three**: confirmed by reading `staged_store.go:559` — `DispositionStagedRecord` compares `input.DecidedBy == StagedString(frontmatter, "staged_by")` inline, does not call `StagedRecordIsSelfApproved`.
- **Staged-deletion-evidence "missing reader, not missing capability"**: verified precisely. A library function `StagedDeletionEvidenceRows()` (`staged_store.go:367`) does read `staged_record_deletions` back, but its only callers are `staged_separation_test.go` — no CLI verb calls it, and the governance documents' claim ("`show-staged` resolves a record by id, and after a deletion there is no record to find") is scoped to the CLI-level claim, which holds. Not an overstatement.

**report.html** — Phase table, AC table, and evidence table verdicts all match what was independently reproduced above. Evidence-table artifact citations spot-checked: `README_CLI.md:172-186` (cited for AC-4) exists at `internal/knowledge/README_CLI.md` and its "## Deletion" section states exactly what the row claims (no retention/classification/source/age deletion equivalent, explicit note that `SECURITY.md`'s `delete-ingested` claim was already ahead of the Go implementation). CI row (`deagy/cadre b534fb27 — success run 33572609424`) matches live `ci-status.sh` output.

**`04-projects/harness/ultragoals.md`** registry row: "P4 · done — north-star gate COMPLETE, all 7 AC verified at cadre `b534fb27` / run 33572609424" — matches commit, run id, and phase state confirmed above.

**Traceability-matrix evidence files** (spec.md) — confirmed each cited file exists on disk: `evidence/P1/CP-5-acceptance.md`, `evidence/P2/CP-5-acceptance-AC-2.md`, `evidence/P2/ledger.md`, `evidence/P2/CP-3v-round4-AC-2-3-4.md`, `evidence/P3/CP-5-acceptance-AC-3-AC-4.md`, `evidence/P4/CP-5-acceptance-AC-5.md`.

No discrepancy found in any closure artifact. No overstatement identified.

## Overall verdict: COMPLETE

All seven acceptance criteria (AC-1 through AC-7) carry at least one PASS row traced to an artifact independently built, run, or read in this session — not taken from the work session's own account. CI is green at the exact commit under test. The closure artifacts (STATUS.md, report.html, ultragoals.md registry row) were independently audited and found accurate, including the three "carried forward, not blocking" claims, which were checked against source rather than accepted as prose.
