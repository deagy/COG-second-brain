# CP-3v verification — capability-parity P1 (AC-1, AC-7)

Target: commits `27783e6b` (feat(knowledge): answer the verbs the roster documents but this
CLI never had) and `ffe660f4` (feat(cli): hold every documented cadre verb, not only knowledge
ones), on top of `main` at `/home/deagy/sdk/cadre`. Working tree confirmed clean before and
after this pass (`git status --short` empty both times).

## 1. Is the "never built" claim true for the six verbs?

**FALSIFIED for five of six, and materially misleading for the sixth.** `internal/cli/knowledge.go`'s
`neverShippedVerbs` comment says the six verbs "describe the Python implementation this CLI
replaced ... the honest answer is that this binary never had them, not that they moved." That
framing is a Go-only reading of "this CLI" that a reader will not supply on their own — the
roster documents describe `cadre`, not "the Go rewrite of cadre" specifically.

Git history (`b418031e "chore: Remove legacy Python CLI implementation - full Go replacement"`)
shows the **legacy Python `cadre` CLI actually shipped and tested all six**, in
`roster/knowledge-store/src/cli.py` (1048 lines) with `subparsers.add_parser("context")`,
`("retention-report")`, `("delete-ingested")`, `("list-staged")`, `("export-staged")`,
`("deletion-evidence")`, each with real handler code (`cli.py:897-991`) and dedicated test
files deleted in the same commit: `test_ingested_deletion.py` (612 lines),
`test_staged_cli.py` (1280 lines), `test_staged_records.py` (774 lines). This is exactly the
same retirement class the code already handles correctly for `ingest`, `stats`, `delete`, etc.
in `retiredVerbs` — a verb that worked in a shipped `cadre` and stopped. The message should say
"retired" (like its neighbors), not "never built."

`context` has an extra wrinkle: it was even briefly declared in the **Go** binary — commit
`f6edbedd` ("Phase 4.2 ... init and stats") added `case "context": fmt.Fprintf(os.Stderr,
"cadre knowledge context: not yet implemented (Phase 4.3+)\n")`, removed same-day by
`da635a75`. It never did anything functional, so "never built" survives on a strict
"functioning implementation" reading, but the message's framing ("the Python CLI's ... verb")
implies it is purely a Python-era concept, glossing over that Go once declared the name too.

The other five (`retention-report`, `delete-ingested`, `list-staged`, `export-staged`,
`deletion-evidence`) never appeared anywhere under Go's `internal/` at any commit
(`git log --all -S'<verb>' -- internal/` returns only the current commit for each) — so "never
built in the Go binary" is literally true, but "documented in the roster, never built in this
CLI" reads to an operator as "cadre never had this," which is false: it had it, working, tested,
in the CLI that *was* `cadre` before the language rewrite.

## 2. Are the named alternatives accurate?

Mixed. Verified each concretely:

- `context` → `cadre knowledge search` exists (`Governed retrieval over the configured recall
  store`) and `cadre context` is confirmed live and distinct (`usage: cadre context
  <init|put|get|list|search|reindex|export|promote|prune-audit|drop|expire|stats>`). **Accurate.**
- `list-staged` → "`show-staged --id <id>` reads one record; this CLI has no listing verb."
  `show-staged` confirmed as claimed. But **the underlying capability the message denies exists
  in the current, live Go code**: `internal/knowledge/staged_store.go:253`,
  `func (s *Store) ListStagedRecords(status string) ([]StagedSummary, error)`, filterable by
  status exactly like the documented `list-staged [--status <status>]` signature, actively
  called today by `ingest-accepted` (`internal/knowledge/staged_ingest.go:184`) and covered by
  tests. It is simply not wired to a CLI verb. "No listing verb" is true; "this CLI has no
  listing [capability]" is not what a reader takes away, and it is false.
- `export-staged` → `roster/knowledge-store/proposed-knowledge/` exists with real staged-record
  files; `import-staged --directory <dir>` confirmed by `--help`. **Accurate.**
- `retention-report` → "this CLI records none." Confirmed in effect: `ResolveRetentionUntil` in
  `internal/knowledge/config.go:517` still computes a per-classification window but has **zero
  callers outside its own tests** (`grep -rn ResolveRetentionUntil internal/ --include=*.go`
  shows only definition + `config_enforcement_test.go`) — dead code, nothing persists a
  retention window today. The claim holds.
- `delete-ingested` → "content lives in a recall store, which deletes by document or chunk id."
  True at the library layer: `github.com/deagy/recall@v0.3.1`'s `Store` interface has
  `DeleteChunk(ctx, id)` and `DeleteDocument(ctx, docID)` (`store/store.go:46-50`, implemented in
  `store/sqlite.go:571,605`). **But there is no `recall` CLI command that reaches it** — ran
  `recall --help`, `recall delete --help` (`unknown command "delete"`), `recall store --help`
  (`backup, info, migrate, restore` only, no delete). An operator following this pointer has no
  actual command to run; the capability is real but not operator-actionable through any shipped
  interface. Not false, but not a working replacement path either.
- `deletion-evidence` → "`delete-staged` writes staged-record deletion evidence, and
  `show-staged` shows it." **Reproduced and falsified directly.** Staged a real record
  (`cadre knowledge propose`), deleted it (`cadre knowledge delete-staged --id ... --reason ...
  --deleted-by ...` → confirms `"evidence_retained": true` in its own one-shot output), then ran
  `cadre knowledge show-staged --id <same-id>` → `error: "<id>": no staged record with that id
  in this store`. `show-staged` looks up `staged_records` by id and the row is gone after
  deletion; it cannot show deletion evidence for anything. The evidence genuinely is retained
  (`staged_record_deletions` table, `internal/knowledge/staged_store.go:74-159`), and there is
  even a bulk-read function for it — `StagedDeletionEvidenceRows()` (`staged_store.go:367`) —
  but it has no CLI caller either (only referenced from `staged_separation_test.go`). The
  message's middle clause is affirmatively wrong.

## 3. Scan completeness for AC-1 as written

The scanner (`internal/cli/documented_verbs_test.go`) walks `roster/**/*.md`, extracts only
backtick code-spans and fenced-block lines (verified: a bare-prose "the cadre framework and
cadre binary" sentence placed next to a real phantom verb was correctly *not* flagged — see §5),
and skips `roster/orchestration/runs/` entirely (`filepath.SkipDir` on `runs`).

- `runs/` exclusion: legitimate. Only 3 of ~200+ files under `runs/` mention any of the six dead
  verbs, all in dated, named proposal/plan records (e.g.
  `cadre-feature-agent-context-store-2026-08-11/implementation-plan.md`) — the same archival
  class the P4 migration precedent (cited in the test's own comment) already exempted.
- **`plugin/` and `cline-plugins/` (955 + 679 tracked `.md` files, 320 of them containing one of
  the six dead verbs verbatim)**: these are legitimately out of scope for the *scan*, because
  they are mechanically generated from `roster/` and verified byte-identical by
  `cadre generate-plugin --check` (confirmed: ran it, `Generated plugin is current`). As long as
  that check stays in CI, drift here is caught without a second scan, and the CLI-level fix
  (`knowledgeNeverShipped`) answers the verb regardless of which generated copy a reader followed
  it from. Legitimate exclusion.
- **`.agents/skills/` is a real gap.** It is *also* copied into the packaged plugin
  (`internal/generators/plugin_generation.go:1228`, `generateSkillCopies`), but unlike
  `plugin/agents/*.md`, its `SKILL.md` files are **hand-authored source**, not derived from
  `roster/`. Two of its 15 tracked files name a dead verb as a live, actionable instruction, not
  historical prose:
  - `.agents/skills/knowledge-ingestion/SKILL.md:37`: "Retrieve context with `cadre knowledge
    context` using a specific agent, task ID, query, classification..."
  - `.agents/skills/agent-stores/SKILL.md:53`: "Ordinary agents may retrieve curated knowledge
    with `cadre knowledge context`"

  These are outside `roster/**` and outside the `plugin/`/`generate-plugin --check` safety net
  (the check verifies `plugin/` matches `.agents/skills/`, not that `.agents/skills/` itself is
  accurate — `.agents/skills/` is the *source*, with no upstream check on its own content). AC-1
  as literally scoped ("every verb named in `roster/**`") does not cover them, and nothing else
  does either. Since the actual fix is CLI-level (any of the six verbs is answered by name no
  matter which document sent an operator to type it), the substantive AC-1 property still holds
  in practice for these two files — but the *regression guard* (the test) would not catch a
  **new** phantom verb introduced only in `.agents/skills/`, which is a real, currently-shipped,
  hand-maintained governance surface. This should be in AC-1's scan scope; it is not.
- `.claude/worktrees/cline-dispatch-investigation/...` also turned up in a grep, but is an
  untracked stray worktree directory, not part of the repository's governance tree — correctly
  irrelevant, noted only to rule it out.

## 4. Does `AnswerableKnowledgeVerbs()` match dispatcher reality?

**Confirmed.** Ran every verb in the union of `liveKnowledgeVerbs`, `retiredVerbs` (all 23
entries), `neverShippedVerbs` (6), `knowledgeStagedSubcommands` (6), plus `help`: none produced
`unknown subcommand`. Cross-checked with the package's own
`TestTheLiveVerbListMatchesWhatTheDispatcherAnswers` (`go test ./internal/cli/... -run
TestTheLiveVerbListMatchesWhatTheDispatcherAnswers -v` → PASS) and confirmed a genuinely unknown
verb (`totally-bogus-verb-xyz`) still correctly falls through to the generic handler.

## 5. Falsifying the guard

All mutations made directly in the checkout, each reverted and confirmed clean
(`diff` against a pre-mutation copy, then `git status --short`):

1. **Phantom verb in a live roster doc.** Added `roster/phantom-verb-test.md` with `` `cadre
   knowledge frobnicate-nonexistent-verb-xyz` `` in a backtick span, plus an adjacent bare-prose
   sentence using "cadre" as a noun with no backticks/fence ("the cadre framework and cadre
   binary are widely used..."). `TestEveryDocumentedKnowledgeVerbIsAnswerable` → **FAIL**,
   reporting only `knowledge frobnicate-nonexistent-verb-xyz` at line 3 — the bare-prose mentions
   were correctly not flagged in the same run, confirming the prose-immunity property in one shot.
2. **Verb removed from the answerable set while docs still name it.** Deleted the `"context"`
   entry from `neverShippedVerbs` in `internal/cli/knowledge.go` (roster docs still reference
   `cadre knowledge context`, e.g. `roster/knowledge-store/SECURITY.md:28`). Build succeeded
   (Go map lookup, no compile error). `TestEveryDocumentedKnowledgeVerbIsAnswerable` → **FAIL**,
   correctly reporting `knowledge context` at `roster/knowledge-store/SECURITY.md:28`. Restored
   from backup, diff empty.
3. **Top-level verb removed from `bin/subcommands.tsv`.** Deleted the `select` line (documented
   live and heavily used, e.g. `roster/README.md`, `roster/RUNBOOK.md` ×13). `TestEvery...` →
   **FAIL**, reporting `select` at 26 distinct roster locations. Restored, diff empty.
4. Confirmed post-mutation-3 that both guard tests pass again on the truly clean tree.

The guard is real: it fails in both directions cleanly, exactly as AC-7 requires structurally.

## 6. CI gate

- `CGO_ENABLED=1 go test -tags sqlite_fts5 -race ./...` → **all packages pass** (internal/cli
  89.6s, internal/generators 76.0s, internal/orchestration 27.7s, rest cached/fast).
- `go vet ./...` → clean, no output.
- `go tool golangci-lint run ./...` → `0 issues.`
- `gofmt -l .` → no output (nothing unformatted).
- `./bin/cadre generate-plugin --check --output plugin` → `Generated plugin is current under
  .../plugin`.
- `bash .claude/lib/ci-status.sh /home/deagy/sdk/cadre` → **FAIL**:
  `deagy/cadre ffe660f4 NO RUN — a commit with no CI is not green`. Confirmed why: `origin/main`
  is at `23fe930a`, far behind local `main` at `ffe660f4`; `git branch -a --contains ffe660f4`
  shows only the local `main` — these two commits have never been pushed, so GitHub Actions
  never ran on them. Every local check is green, but the pushed/CI-verified post-condition this
  task asked me to check is unmet.

## Verdict

EVIDENCE AC-1 | CP-3v | FAIL | `deletion-evidence`'s replacement message ("`show-staged` shows it") is reproducibly false: staged a record, deleted it via `delete-staged`, then `show-staged --id <id>` returns `error: "<id>": no staged record with that id in this store` — deletion evidence is never shown by any verb | `bin/cadre knowledge show-staged --id KS-20260901-verify-test-record` (exit 1) after `delete-staged`
EVIDENCE AC-1 | CP-3v | FAIL | Five of six "never built in this CLI" verbs were real, tested, shipped commands in the pre-rewrite Python `cadre` CLI (`roster/knowledge-store/src/cli.py`, deleted in `b418031e`), the same retirement class already correctly labeled `retiredVerbs` for `ingest`/`stats`/`delete`; framing them as "never built" instead of "retired" misstates cadre's own history | `git show b418031e --stat -- roster/knowledge-store/src`, `git show b418031e~1:roster/knowledge-store/src/cli.py` lines 87-234, 897-991
EVIDENCE AC-1 | CP-3v | FAIL | `.agents/skills/knowledge-ingestion/SKILL.md:37` and `.agents/skills/agent-stores/SKILL.md:53` are hand-authored, git-tracked governance docs outside `roster/**` that actively instruct running the dead verb `cadre knowledge context`; not covered by the AC-1 scan or by the `generate-plugin --check` safety net that legitimately excuses `plugin/`/`cline-plugins/` | `.agents/skills/knowledge-ingestion/SKILL.md:37`, `.agents/skills/agent-stores/SKILL.md:53`
EVIDENCE AC-1 | CP-3v | PARTIAL | `list-staged`'s "this CLI has no listing verb" is true narrowly but conceals that the exact capability (`ListStagedRecords(status)`, filterable, matching the documented `--status` flag) is live, tested Go code already called by `ingest-accepted` — just not CLI-wired; `delete-ingested`'s recall pointer names a real library method (`DeleteChunk`/`DeleteDocument`) with no reachable `recall` CLI command | `internal/knowledge/staged_store.go:253`, `internal/knowledge/staged_ingest.go:184`; `recall store --help` (no delete subcommand)
EVIDENCE AC-1 | CP-3v | PASS | `AnswerableKnowledgeVerbs()` matches dispatcher reality: every verb in the union of live/retired/never-shipped/staged sets was run against the built binary, none fell through to `unknown subcommand`; a genuinely unknown verb still does | `bin/cadre knowledge <verb>` for all 34 verbs; `go test ./internal/cli/... -run TestTheLiveVerbListMatchesWhatTheDispatcherAnswers -v`
EVIDENCE AC-7 | CP-3v | PASS | Guard falsified in both directions: passes on the repaired tree, fails on a phantom verb added to a live roster doc, fails when a verb is dropped from the answerable set while docs still name it, fails when a top-level verb is dropped from `bin/subcommands.tsv`; bare-prose "cadre" mentions correctly ignored throughout | `go test ./internal/cli/... -run TestEveryDocumentedKnowledgeVerbIsAnswerable -v` (3 mutation runs + restore, tree confirmed clean via `git status --short`)
EVIDENCE AC-7 | CP-3v | FAIL | CI gate unmet for the pushed state: `ffe660f4`/`27783e6b` exist only on local `main`; `origin/main` is at `23fe930a`; `ci-status.sh` reports `NO RUN — a commit with no CI is not green`. All local checks (test -race, vet, lint, gofmt, generate-plugin --check) are green, but nothing has verified this on the actual CI post-condition | `bash .claude/lib/ci-status.sh /home/deagy/sdk/cadre`; `git branch -a --contains ffe660f4`

**FAIL:fixable.** Fixes, all bounded and mechanical:
1. Reclassify `retention-report`, `delete-ingested`, `list-staged`, `export-staged`,
   `deletion-evidence` (and arguably `context`) from `neverShippedVerbs` to `retiredVerbs`-style
   framing that names the Python-to-Go rewrite as what retired them, since they were real,
   tested, shipped commands before it.
2. Correct the `deletion-evidence` message: `show-staged` does not show deletion evidence for a
   deleted record (it cannot — the record is gone). Either wire `StagedDeletionEvidenceRows()`
   to a real verb and point to that, or state plainly that nothing currently surfaces it after
   the fact.
3. Soften or correct `list-staged`'s "no listing verb" (the capability exists, unwired) and
   `delete-ingested`'s recall pointer (real at the library layer, unreachable via any shipped
   `recall` command) so neither implies an operator has a path they do not.
4. Extend the AC-1 scan (or explicitly document why not) to `.agents/skills/**`, which is
   hand-authored and currently carries at least two actionable dead-verb instructions.
5. Push `27783e6b`/`ffe660f4` to `origin/main` (or the review branch CI actually runs against)
   so the CI gate has a real result instead of `NO RUN`.
