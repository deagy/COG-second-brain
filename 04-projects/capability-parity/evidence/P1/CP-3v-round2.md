# CP-3v re-verification — capability-parity P1, fixes in `20119003`

Target: `20119003` "fix(knowledge): these verbs were retired, not never built", on top of
`ffe660f4`/`27783e6b`, pushed to `origin/main` (confirmed `git branch -a --contains 20119003`
implicit via CI run against it). Working tree confirmed clean before and after
(`git status --short` empty both times; all mutations made in `/tmp` or reverted in-repo and
diffed back to empty).

## 1. Six-verb classification ("shipped in the Python CLI, removed in the Go rewrite (b418031e)
and never rebuilt")

**True for all six, confirmed independently.**

- `b418031e` ("chore: Remove legacy Python CLI implementation") deletes `roster/knowledge-store/src/`;
  `git show b418031e~1:roster/knowledge-store/src/cli.py` shows all six as real
  `subparsers.add_parser(...)` entries: `context`, `retention-report`, `delete-ingested`,
  `list-staged`, `export-staged`, `deletion-evidence`.
- For the five non-`context` verbs: `git log --all --oneline -S'"<verb>"' -- internal/` returns
  **only** the fix commit `27783e6b` itself — never present in the Go tree at any commit before
  or after. "Never rebuilt" holds.
- `context` is the one with the extra wrinkle the message claims, and it checks out exactly:
  `f6edbedd` (2026-08-13 19:01:42) added `case "context": ... "not yet implemented (Phase 4.3+)"`;
  `da635a75` (2026-08-13 19:25:21, same day, 24 minutes later) removed it. `git log --oneline
  -S'case "context":' -- internal/` shows exactly these two commits and no others before
  `27783e6b`. All other `"context"` hits across history in `internal/` are the Go standard-library
  `"context"` import (confirmed by inspecting each diff), not the subcommand literal.

## 2. Three corrected pointers, re-tested against the built binary

Built `/tmp/claude-1000/cadre-reverify` at `20119003` (CGO/sqlite_fts5).

**`deletion-evidence`.** Staged a real record via `propose --from-finding`, deleted it with
`delete-staged --reason ... --deleted-by ...` (`evidence_retained: true` in the response), then:
- `show-staged --id <id>` → `error: "<id>": no staged record with that id in this store`
  (exit 1) — matches the new message's claim that `show-staged` cannot show it.
- Queried `staged-records.db` directly with Python's sqlite3: the `staged_record_deletions` table
  has one row for the deleted record (`record_id`, `title`, `content_digest`,
  `status_at_deletion`, `reason`, `deleted_by`, `deleted_at` all populated) — evidence genuinely
  outlives the record, as claimed.
- `grep -rn StagedDeletionEvidenceRows` (the function that reads that table back) shows callers
  only in `internal/knowledge/staged_separation_test.go`; no CLI verb calls it — "nothing reads it
  back" holds for every shipped verb.
Both claims verified true.

**`list-staged`.** All four sub-claims verified in the code:
- `func (s *Store) ListStagedRecords(status string) ([]StagedSummary, error)` exists,
  `internal/knowledge/staged_store.go:253`.
- Filterable by status: `if status != "" { query += " WHERE status = ?" ...}` at the same location.
- Tested directly: `internal/cli/knowledge_staged_test.go:91` and
  `internal/knowledge/staged_migration_test.go:62` both call `store.ListStagedRecords("")`.
- Called by `ingest-accepted`: `internal/knowledge/staged_ingest.go:184`,
  `accepted, err := s.ListStagedRecords("accepted")`.

**`delete-ingested`.** Built `recall`'s CLI at `/home/deagy/sdk/recall` (`cmd/recall`) and ran
`--help` on the root and every subcommand (`store`, `cluster`, `graph`, `eval`, plus a repo-wide
`grep` for `"delete"|"remove"|"purge"` under `cmd/recall/`): zero hits, no delete/remove command
anywhere in the CLI surface. `store/store.go:46-50` confirms `DeleteChunk(ctx, id)` and
`DeleteDocument(ctx, docID)` exist as library methods on the `Store` interface. "Recall's CLI has
no delete command; this is a library call" is accurate.

## 3. Widened scan (`roster/` + `.agents/skills/`)

Added a phantom verb to each root simultaneously — `roster/phantom-verb-reverify.md` with
`` `cadre knowledge frobnicate-reverify-xyz` `` plus adjacent bare-prose ("the cadre framework
and cadre binary are widely used... a cadre role can pick either"), and
`.agents/skills/phantom-verb-reverify.md` with `` `cadre knowledge zorptastic-reverify-verb` ``
plus its own bare-prose sentence. `go test ./internal/cli/... -run
TestEveryDocumentedKnowledgeVerbIsAnswerable -v` → **FAIL**, reporting exactly the two phantom
verbs at their correct file:line, and correctly not flagging either bare-prose sentence in the
same run. Removed both files, `git status --short` confirmed clean before continuing.

**A further unscanned hand-authored, git-tracked surface exists: `CHANGELOG.md`.** Its own header
states its purpose as tracking "consumer-visible changes to what this suite ships: new or changed
`cadre` CLI subcommands and flags" — squarely a governance/documentation surface, not generated
(unlike `provider/codex-agents/*.toml`, confirmed generated via
`# GENERATED FILE: canonical source is roster/...` headers). Line 166, still under the
`## [Unreleased]` heading (`git blame` dates it 2026-08-12, before `b418031e` on 2026-08-13),
reads: `` and `cadre knowledge context` (order-preserving, de-duplicated...) `` — describing the
dead verb's flag behavior with no correction anywhere in the file (`grep -n "b418031e\|Python
CLI" CHANGELOG.md` → no hits). Unlike `roster/orchestration/runs/`, which the guard explicitly and
correctly exempts as a *dated archive of past runs*, `CHANGELOG.md`'s `[Unreleased]` section is
presented as pending/current, not historical — this reads as a live claim. In this specific case
the substantive AC-1 property still holds (`context` is answered via `pythonEraVerbs`, not
`unknown subcommand`, regardless of which document a reader followed), so there is no live
fall-through today — but the regression guard would not catch a **new** phantom verb introduced
only in `CHANGELOG.md`, the same class of gap the fix commit found and closed for
`.agents/skills/`. A second, lower-confidence hit: `docs/proposals/staged-records-in-the-store-2026-08.md:194`
names `` `cadre knowledge export-staged` ``, but that document is explicitly `Status: PROPOSED —
decisions taken, not yet scheduled`, i.e. aspirational rather than a claim about current behavior,
closer in kind to the exempted `runs/` archive.

**Also found: a stale identifier in the guard's own failure message.** `20119003` renamed
`neverShippedVerbs` → `pythonEraVerbs` throughout `internal/cli/knowledge.go`, but
`internal/cli/documented_verbs_test.go:206` still tells a future maintainer to "add it to
retiredVerbs / neverShippedVerbs in internal/cli/knowledge.go" — `neverShippedVerbs` no longer
exists under that name. Cosmetic only (the test still passes/fails on the right condition), but
it is new drift this exact commit introduced.

## 4. CI and local gate

- `bash .claude/lib/ci-status.sh /home/deagy/sdk/cadre` — initially `PENDING` (one job,
  `cmd/, internal/` Go suite, still running); polled `gh run view 33556372778` until it finished,
  then re-ran: `deagy/cadre 20119003 success run 33556372778`. All 12 jobs green, including
  `plugin/ generated content matches its source`.
- `CGO_ENABLED=1 go test -tags sqlite_fts5 -race ./...` → all packages `ok` (internal/cli 87.7s,
  internal/generators 79.9s, internal/orchestration 27.4s, rest cached/fast). No failures.
- `go vet ./...` → clean.
- `go tool golangci-lint run ./...` → `0 issues.`
- `gofmt -l .` → no output.
- `./bin/cadre generate-plugin --check --output plugin` → `Generated plugin is current under
  .../plugin`. (Note: `bin/cadre` is a tracked shell wrapper, not a raw Go binary — a direct
  `go build -o bin/cadre` correctly refused to clobber it; the wrapper's own build-and-run path
  is what the CI job and this check exercise.)
- `git status --short` → empty throughout and at the end.

## Verdict

EVIDENCE AC-1 | CP-3v | PASS | All six verbs' "shipped in Python CLI, removed in Go rewrite (b418031e), never rebuilt" claim holds: 5 verbs never appear in Go `internal/` history outside the fix commit itself; `context` was briefly stubbed in Go (`f6edbedd`) and removed the same day (`da635a75`), consistent with the message's parenthetical | `git log --all -S'"<verb>"' -- internal/` per verb; `git show b418031e~1:roster/knowledge-store/src/cli.py`
EVIDENCE AC-1 | CP-3v | PASS | `deletion-evidence` pointer reproduced true: staged+deleted a record, `show-staged` errors (no record), `staged_record_deletions` row confirmed present via direct sqlite read, `StagedDeletionEvidenceRows()` has no CLI caller | staged/deleted `KS-20260901-reverify-test-finding-5f4add500642`; `python3 -c "sqlite3...staged_record_deletions"`; `grep -rn StagedDeletionEvidenceRows`
EVIDENCE AC-1 | CP-3v | PASS | `list-staged` pointer's four claims (live, tested, filterable by status, called by `ingest-accepted`) all confirmed in code | `internal/knowledge/staged_store.go:253`, `internal/cli/knowledge_staged_test.go:91`, `internal/knowledge/staged_ingest.go:184`
EVIDENCE AC-1 | CP-3v | PASS | `delete-ingested` pointer confirmed: `recall` CLI (built fresh) has no delete/remove/purge command anywhere in its command tree; `DeleteChunk`/`DeleteDocument` exist as library-only methods | `recall store --help`, `recall --help`, grep of `cmd/recall/`; `store/store.go:46-50`
EVIDENCE AC-1 | CP-3v | FAIL | `CHANGELOG.md:166`, a hand-authored, non-generated, git-tracked governance surface (self-described purpose: document consumer-visible CLI subcommands/flags), still under `[Unreleased]` and dated before `b418031e`, names the dead verb `cadre knowledge context` with no correction anywhere in the file — a location outside the two scanned roots that the guard's regression protection does not cover, the same class of gap the fix commit closed for `.agents/skills/` | `CHANGELOG.md:166`, `git blame -L160,170 CHANGELOG.md`
EVIDENCE AC-7 | CP-3v | PASS | Widened scan verified live: a phantom verb planted in `roster/` and, simultaneously, a different phantom verb planted in `.agents/skills/` both caused `TestEveryDocumentedKnowledgeVerbIsAnswerable` to FAIL, reporting both at correct file:line; adjacent bare-prose "cadre" sentences in both files correctly not flagged in the same run; tree restored to clean | `go test ./internal/cli/... -run TestEveryDocumentedKnowledgeVerbIsAnswerable -v`; `git status --short` clean after
EVIDENCE AC-7 | CP-3v | PASS (minor defect noted) | CI gate green at HEAD `20119003` after the in-flight job finished; full local gate (test -race, vet, lint, golangci-lint, gofmt, generate-plugin --check) all clean. Separately: the guard's own failure-message text at `documented_verbs_test.go:206` still says `neverShippedVerbs`, a name `20119003` renamed to `pythonEraVerbs` everywhere else — stale guidance to a future maintainer, cosmetic only, introduced by this exact commit | `bash .claude/lib/ci-status.sh` → `success run 33556372778`; `internal/cli/documented_verbs_test.go:206`

**FAIL:fixable.** Two of the four original findings' fixes hold cleanly and are not being
reopened (classification, and the `list-staged`/`delete-ingested`/`deletion-evidence` pointers).
The widened-scan fix is real and correctly closes the specific `.agents/skills/` gap it targeted,
but the underlying pattern was not exhausted — a second hand-authored, non-generated, git-tracked
location (`CHANGELOG.md`) still names a dead verb outside the scan, unprotected by the regression
guard, discovered the same way the prior pass found `.agents/skills/` (by looking, not assuming
the set was complete). Fix direction, both bounded:
1. Extend `TestEveryDocumentedKnowledgeVerbIsAnswerable`'s `roots` to include `CHANGELOG.md` (or
   any top-level hand-authored `.md`/`README.md` naming CLI verbs), or explicitly correct/annotate
   the stale `CHANGELOG.md:166` entry and document in the test's comment why changelog entries are
   exempt (parallel to the `runs/` archive reasoning) if that is the intended stance.
2. Update `documented_verbs_test.go:206`'s failure-message text from `neverShippedVerbs` to
   `pythonEraVerbs` to match the rename this same commit made.
