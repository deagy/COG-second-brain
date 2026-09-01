# CP-4 integration verification — P4 (repo-consolidation), AC-08

Read-only cross-task verification. Ledger/CP-6-decisions treated as claims, re-observed at
the binary, the CI runners, and both repositories rather than trusted.

AC-08 in full: recall survives as the knowledge store, cadre's own retrieval engine is
deleted, and the surviving retrieval path preserves all six refusals the deleted engine
enforced. Six cases are in `internal/knowledge/testdata/fail-closed-contract.json`.

## 1. The contract across both repositories

The two fixture copies are currently byte-identical: `recall/govern/testdata/fail-closed-contract.json`
matches `cadre/internal/knowledge/testdata/fail-closed-contract.json` exactly (JSON-normalized
compare via `govern.TestTheContractMatchesItsOrigin`, run directly).

The guard mechanism (`recall/govern/contract_test.go:151-189`, `TestTheContractMatchesItsOrigin`)
works correctly when it runs:
- Agreement: passes when pointed (`CADRE_FAIL_CLOSED_CONTRACT=<cadre's file>`) at the real cadre fixture.
- Divergence: fails with a named diff when pointed at a one-case-shorter mutated copy (built in `/tmp`, never touching either repo).
- No-source-under-CI: with `CI=1` set and no discoverable origin, it hard-`Fatal`s rather than skipping (`contract_test.go:165-168`).

**But it never actually runs as designed in recall's real CI.** `recall/.github/workflows/go.yml`'s
`test` job runs `go test ./... -count=1 -race` with only `actions/checkout@v4` on the recall repo
itself — no cadre checkout, no `CADRE_FAIL_CLOSED_CONTRACT` env var anywhere in the workflow. GitHub
Actions sets `CI=true` for every job. Reproduced in an isolated copy of the recall repo (no cadre
sibling present): `TestTheContractMatchesItsOrigin` hard-fails with exactly the message above, not
because the fixtures differ, but because CI can never supply the origin file at all.

**Confirmed live, not just simulated.** `gh run view 33466261336 --repo deagy/recall` — the "Go" CI
run for commit `675ad07` (`chore: release v0.3.0`, the exact version cadre's `go.mod` pins) —
is `completed / failure`. Its log: `contract_test.go:166: no origin contract reachable and this is
CI, where this guard must not be skipped. Set CADRE_FAIL_CLOSED_CONTRACT.` The release tag run
succeeded separately (it doesn't run this test job), so v0.3.0 was tagged and published while
recall's own Go CI was red on this exact test.

This contradicts the ledger's T-03 claim ("recall's full suite green") for the state that actually
shipped. Locally, on this machine, the test passes silently because `/home/deagy/sdk/recall` and
`/home/deagy/sdk/cadre` happen to be sibling checkouts, which the test's fallback heuristic finds —
that is what made local verification (and the ledger's claim) look true. On GitHub's runner there is
no such sibling, so the guard that is supposed to keep the two copies honest going forward currently
cannot run at all, and would stay red even if never touched again.

**EVIDENCE AC-08 | CP-4 | FAIL | recall's own CI ("Go" workflow, commit 675ad07 = v0.3.0) is red on `TestTheContractMatchesItsOrigin` because the workflow never supplies the origin fixture (no cadre checkout, no CADRE_FAIL_CLOSED_CONTRACT); the guard only "passes" locally because of an incidental sibling-directory checkout | `gh run view 33466261336 --repo deagy/recall`; `recall/.github/workflows/go.yml`; `recall/govern/contract_test.go:151-189`**

## 2. One path, not two

Only `internal/retrieval/store.go` imports `github.com/deagy/recall/{core,embedder,govern,store}` in
non-test cadre code. All governed access funnels through `retrieval.Open` (2 call sites) and
`retrieval.OpenForIngest` (1 call site, which itself calls `Open` at `store.go:300`), all three inside
`internal/cli` (`knowledge.go:189,462`, `knowledge_staged.go:773`). No other file in the repository
references the recall module outside tests. `retrieval.NewProviderAdapter` (exported for seeding a
matching store) has exactly one caller, and it is a `_test.go` file — no production entry point uses
it, so it is not a live second path, just dead-for-production exported surface.

**EVIDENCE AC-08 | CP-4 | PASS | Exactly one funnel (`retrieval.Open`/`OpenForIngest`, both routing through `govern.New`), three call sites, all CLI-gated, no bypass found repo-wide | `grep -rn "deagy/recall" --include='*.go' .` (non-test hits confined to internal/retrieval/*.go)**

## 3. Whole operator story (fresh machine, built binary)

Built `cadre-new` (`CGO_ENABLED=1 -tags sqlite_fts5`, matching CI) and walked the documented path
against a fresh config in `/tmp`: `init` on a nonexistent store correctly refuses and creates nothing
("cadre does not create stores... run recall upload"); `propose --from-finding` (after fixing my
first attempt's shape — see below) stages a record; `disposition-staged` (different `-decided-by`
than `-staged-by`) accepts it; `ingest-accepted` creates the store, records the embedder identity
automatically, and reports one ingested chunk; a correctly-scoped `search` retrieves it with a full
citation and trust envelope. All six refusal cases reproduced directly at the binary with the correct
refusal text and exit codes (missing classification, missing scope, ambiguous scope, blank source
entry, missing query when omitted, embedder-identity mismatch).

**Two real points of friction, neither in `cadre knowledge help` or README_CLI.md:**

- **`--from-finding` JSON shape is stricter than the docs show.** `evidence` must be a JSON array of
  strings (a plain string is rejected with a message explaining the YAML-list requirement);
  `untrusted_instruction_risk` must be JSON `true`/`false`/`"unknown"`, not any other string. Neither
  `cadre knowledge help` nor README_CLI.md shows the `--from-finding` JSON shape; only
  `roster/knowledge-store/proposed-knowledge.schema.json` documents it precisely, and README_CLI.md
  never points there.

- **`--source` for staged/ingested records ignores the operator's declared `source_scope` entirely.**
  `internal/knowledge/staged_ingest.go:59,349`: every record made retrievable via `ingest-accepted` is
  written with the fixed recall `Source` = `StagedIngestSource` = `"proposed-knowledge"`, regardless
  of the `source_scope` field the operator set when proposing the finding (`source_scope` is only
  carried in metadata, never used as the retrieval-governed source). Concretely reproduced: staged a
  finding with `source_scope: "opstory-test"`, ingested it, then `search --source opstory-test`
  returned **zero results with no error** (a normal-looking empty retrieval, not a refusal) while
  `search --source proposed-knowledge` returned the record. An operator who follows the documented
  story literally — declare a source scope, then search that scope — silently gets nothing and no
  hint why. README_CLI.md's `--source` description ("Source scope; repeatable") and its Quick Start
  example (`--source legacy-model-export`, a `recall upload`-created source) never disclose that
  staged-ingested content always lands under one fixed source name unrelated to what the operator
  declared.

**Adversarial note, not a regression:** a query argument that is present but empty (`""`) slips past
the CLI's own pre-store-open fast check (`internal/cli/knowledge.go:429`, which only checks
`fs.NArg() < 1`, i.e. the argument being wholly omitted) and reaches `govern`'s internal
`ErrNoQuery` check only after `retrieval.Open` runs; a *whitespace-only* query (`"   "`) passes
`govern.ErrNoQuery` too (it checks `Query == ""` exactly, no trim) and executes a real search,
returning a spurious score-0.0000 "result" with a full citation and a written audit row — reproduced
directly. This looks like fail-closed erosion but is not: `git show c95ed2ba:internal/knowledge/search.go`
shows the deleted engine used the identical `opts.Query == ""` check with no trimming, so this is
faithfully-preserved original behaviour, not something this phase introduced. The JSON-fixture-driven
contract tests (both cadre's and recall's) cannot see this because their test harness omits the
argument entirely for the empty case (`internal/cli/knowledge_contract_test.go:73-74`) rather than
passing an empty string, so coverage of the *literal* six cases is real but does not generalize to
this adjacent, pre-existing edge.

**EVIDENCE AC-08 | CP-4 | PASS | All six refusals reproduced at the binary with correct text; happy path (propose→disposition→ingest→search) completes end to end | `/tmp/claude-1000/bin/cadre-new knowledge -config .../config.json {propose,disposition-staged,ingest-accepted,search}`**

## 4. The upgrade story (both binaries)

`/tmp/claude-1000/cadre-cgo` confirmed to be the intended pre-migration artifact: `strings` shows it
still links `internal/knowledge/{search.go,database.go,persistence.go,driver_probe.go,hnsw_fts5.go}`
(all deleted at T-05) while its `knowledge help` text already matches the post-T-04 narrowed CLI and
it links `recall@v0.3.0`/`recall/govern` — i.e. built at the T-04-corrected commit (`df2f3211`),
before T-05's engine deletion (`da84b963`).

Built a genuine combined store using **only** this old binary's own `propose` → `disposition-staged`
→ `ingest-accepted` (no `init`, no `search` yet touched it) — this reproduces exactly "a combined
store with staged records and a corpus in one file," since at this pre-T-05 commit both live in the
same SQLite file written by the old engine.

Then, as the first and only touch, ran `cadre knowledge init` with the **new** post-T-05 binary
against that file — exactly the first command README_CLI.md's Quick Start tells an operator to run.
It reported clean, ordinary success:
```
Store:       .../combined.db
Embedded by: local-hashing / hashing-128d at 128 dimensions (recorded in .../embedder-identity.json)
Retrieval is governed: a search states its classification and source scope or is refused.
```
No warning of any kind. Every subsequent `search` and `ingest-accepted` against that same file then
fails with an opaque, low-level error: `SQL logic error: no such column: c.document_ref`. Root cause:
`init` (and `search`) open the file through `store.NewSQLiteStore` (recall's own schema
initializer), which — finding a `chunks` table already present with the *old engine's* column
layout — does not create recall's expected columns, leaving a file that is neither a valid legacy
store nor a valid recall store. Reproduced twice independently (once via the old binary's own `init`
first, once skipping straight to the new binary) with identical results.

**What survives the upgrade, and what does not:**
- **Kept, correctly, with a clear signal:** staged records and their full disposition history.
  `show-staged` on the new binary triggers an automatic one-time migration
  (`cadre knowledge: moved 2 staged row(s) from .../combined.db into .../staged-records.db. The
  originals are left in place.`) and the migrated record's frontmatter, body, and disposition history
  (steward, reason, timestamp) come back byte-for-byte correct via `show-staged`.
- **Lost, silently:** the corpus. The content the old binary reported as successfully ingested
  becomes permanently unreachable, and nothing distinguishes this broken state from an empty or
  healthy store — `init`'s success message is identical in shape to a genuinely healthy store's.

**EVIDENCE AC-08 | CP-4 | FAIL | `cadre knowledge init` (new binary) against a real combined pre-T-05 store reports ordinary success and silently corrupts the corpus (recall's schema init collides with the old engine's `chunks` table); every later `search`/`ingest-accepted` then fails with an opaque SQL error with no diagnostic pointing at the cause, while staged records migrate correctly with an explicit message | reproduced twice at `/tmp/claude-1000/upgrade/` and `/tmp/claude-1000/upgrade2/` with `cadre-cgo` (pre-T-05) + `cadre-new` (post-T-05)**

(This bears on the phase's upgrade story, not on AC-08's literal three clauses — recall still
survives as the store, the engine is still deleted, and the six refusals are unaffected by this. It
is reported because CP-4 explicitly asked for the upgrade path to be walked and because none of
T-04/T-05's evidence or the README_CLI Quick Start discloses this failure mode.)

## 5. What the docs now promise

- `internal/knowledge/README_CLI.md`, `roster/RUNBOOK.md`'s knowledge-store section, and the retired-verb
  table were all checked against the live binary and are accurate, including the explicitly
  pre-existing gaps the task named (`delete-ingested`, `retention-report`, `export-staged`,
  `list-staged`, `cadre knowledge context` — confirmed these are not in `cadre knowledge help` and are
  correctly not claimed as regressions).
- `roster/knowledge-store/config.example.json` still uses the old Python-era shape
  (`"provider": "hashing"`, plus unused `chunking`/`ingestion`/`base_url` keys). This is handled
  gracefully, not broken: `internal/knowledge/config.go:69-96` explicitly normalizes the legacy
  `"hashing"` provider name to `"local-hashing"` for exactly this reason (`LegacyLocalEmbeddingProvider`,
  with its own comment explaining the Python→Go rename). Confirmed via `cadre knowledge config` on the
  unmodified example file: resolves correctly to `local-hashing`. Not a defect.
- **New drift this phase exposed but did not fix:** `roster/workflows/knowledge-ingestion.md:15` still
  describes `cadre knowledge ingest --retention-days` as the live mechanism for recording a per-message
  retention window. `ingest` is one of the 22 verbs T-04 retired; running it now exits 2 with
  `cadre knowledge ingest: retired -- cadre no longer owns a retrieval engine. run 'recall upload
  <path>...'`. Unlike this file, `roster/RUNBOOK.md` and `README_CLI.md` were correctly updated to
  describe the new `recall upload` path. This one was not, and it is not one of the five gaps the task
  pre-identified as pre-existing drift — it appears to be this phase's own retirement landing
  incompletely across the doc set.
- `README.md:333`'s claim that `--source` is what keeps different projects' content distinguishable is
  accurate for ordinary `recall upload`-populated content; it does not mention (nor need to, at that
  level) the staged-ingestion `--source` gap in §3 above.
- Exit-code note: README_CLI.md's own table states governance refusals exit 2. An explicit-but-empty
  query argument (`search ... ""`) refuses via `govern.ErrNoQuery` at exit 1, not 2, because it skips
  the CLI's own pre-flight `NArg()==0` check (which does correctly exit 2) and is only caught inside
  `govern` afterward. Minor, and see the "not a regression" note in §3.

**EVIDENCE AC-08 | CP-4 | FAIL | `roster/workflows/knowledge-ingestion.md:15` documents `cadre knowledge ingest --retention-days` as the live retention mechanism; the verb is retired and exits 2 naming `recall upload` instead — a claim a reader would act on that fails literally, not on the task's pre-declared pre-existing-drift list | `cadre-new knowledge ingest --retention-days 30` -> exit 2; `roster/workflows/knowledge-ingestion.md:15`**

## 6. CI gate, as CI runs it

All reproduced clean, from a clean `git status` (only the pre-existing, gitignored, untracked
`.agents/knowledge-store/` scratch directory — not a tracked repo file — was touched, and only by
side effect of an earlier verification run before this session; nothing under version control was
modified):

- `CGO_ENABLED=1 go test -tags sqlite_fts5 -race ./...` — 33 tested packages, all `ok`, no failures, no
  data races, no panics. Includes `internal/knowledge`, `internal/retrieval`, `internal/cli`,
  `internal/contextstore`, `internal/engine/executor` (the two cgo holdouts T-06 documents).
- `go vet ./...` — clean.
- `go tool golangci-lint run ./...` — `0 issues`.
- `gofmt -l .` — no output.
- `./bin/cadre generate-plugin --check --output plugin` — "Generated plugin is current."
- `./bin/cadre generate-role-metadata --check` — "321 role metadata files are current."
- `./bin/cadre schema-validate` — "schema validation passed" for `catalog.yaml`, `routing.json`,
  `roster.json`.

**EVIDENCE AC-08 | CP-4 | PASS | Full CI gate reproduced clean on cadre's side: race suite (33 pkgs), vet, lint (0 issues), gofmt (clean), plugin/role-metadata/schema checks all current | `CGO_ENABLED=1 go test -tags sqlite_fts5 -race ./...`; `go tool golangci-lint run ./...`; `./bin/cadre schema-validate`**

## Summary against AC-08 as written

The three literal clauses hold: recall is the surviving store (confirmed via `recall store info`
against real ingested content), cadre's own retrieval engine is fully gone (`internal/knowledge/*.go`
now holds only staged-record governance, config, and embedding-provider code; repo-wide grep for
HNSW/cosine/corpus-engine remnants outside `internal/retrieval` and tests is empty), and all six
fixture refusals reproduce correctly and identically at the binary.

What CP-4 additionally found, at the seams CP-3v could not reach: the cross-repo guard that is
supposed to keep the two fixture copies honest going forward is not actually enforced by recall's own
CI — it is currently red on the exact commit/tag (v0.3.0) cadre depends on, for a reason unrelated to
divergence (the workflow never supplies the origin file), contradicting the ledger's "recall's full
suite green" claim for that state. Separately, the upgrade path from a genuine pre-migration combined
store silently destroys the corpus while reporting ordinary success, and the staged-ingestion
`--source` value is an undocumented fixed constant unrelated to what an operator declares.

## VERDICT

**FAIL:fixable** — fix: wire `recall/.github/workflows/go.yml`'s `test` job to actually supply the
origin contract to `TestTheContractMatchesItsOrigin` (checkout cadre's `internal/knowledge/testdata/`
alongside, or set `CADRE_FAIL_CLOSED_CONTRACT` from a pinned source), then re-tag so the published
module version has a real green CI run behind it. This is the one finding that bears directly on
CP-4's explicit charge ("does the guard that holds them together actually fail when they diverge? ...
rather than trusting that it exists") and on the ledger's own accuracy, rather than on scope beyond
AC-08's wording. AC-08's three literal clauses (recall as store, engine deleted, six refusals
preserved) are independently verified PASS and do not need to be re-litigated once the guard is fixed.

The upgrade-story corruption (§4) and the staged-ingestion `--source` gap (§3) are reported because
CP-4 was asked to walk those stories, but neither falls inside AC-08's literal wording (both are about
retrievability/UX, not about the six named refusals), so they are not counted against the verdict —
flagged for a follow-up phase or an explicit, recorded decision the way D-2's `delete` gap was
recorded, not for AC-08 itself.
