# P4 evidence ledger

## T-01 — the fail-closed contract, captured (cadre `892f7507`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-08 | CP-3 | PASS | Six cases in `internal/knowledge/testdata/fail-closed-contract.json`, each driven against the live `Store.Search` and each refused: no query, no classification, no embedding provider, no source-scope decision, all-sources with filters, blank filter entry. |
| AC-08 | CP-3 | PASS | **Falsified**: dropping the classification refusal makes that case reach the embedding provider, and the stand-in reports "a refusal that should happen before any work now happens after it". |
| AC-08 | CP-3 | PASS | **Falsified**: removing a case from the fixture fails the coverage guard, naming `source scope is ambiguous` as the refusal that went missing. |
| — | CP-3 | PASS | cadre's full suite green. |

### Why now rather than during the migration

The contract exists inside one function and nowhere else. Once the engine moves to recall it cannot be re-derived — recall's `Search` takes filters a caller may omit and spans all namespaces by default, so there would be nothing to read it off. Same situation as P1's fingerprint agreement, same answer: capture it while both the behaviour and its implementation are present.

### Two things the capture surfaced

**The refusals happen before the store is touched, and that is itself part of the contract.** The test needs no database at all. A governed interface that only refuses after opening a connection has already leaked that the caller asked — worth stating, because a reimplementation over recall could easily validate after constructing a query.

**The amended AC-08 said five refusals. There are six.** The list written into the spec omitted `query is required`. Corrected in the spec, and it is the same error this ultragoal keeps producing: a list assembled by reading prose rather than counting the code. AI-10's rule generalises past `head` — the enumeration was mine and it was short.

### The fixture carries reasons, not just expectations

Each case records why it is refused. `no embedding provider`, for instance: refused rather than defaulted because the provider and model are written into the audit row, so a silent default would make retrievals unattributable. A reimplementation that satisfies the assertion without the reason will drift on the next edit.

## T-02 — delete before migrating (cadre `c95ed2ba`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-08 | CP-3 | PASS | **3,297 lines** removed across nine files: sharding, federation and rebalancing with their tests, two CLI test files, five dispatch verbs, five handlers, an orphaned `discoverShards` helper declared and never called, and the help text advertising the removed commands. Suite green. |

The plan estimated 937 lines because it counted only the four source files. Tests, CLI surface and dead helpers tripled it.

### The fourth file was not what its category said

`disaster_recovery.go` was on the deletion list because its name reads as enterprise overgrowth. Reading it first found the opposite: it is a **safety refusal**. Its own comment records that `CreateBackup` used to sleep 10ms, copy nothing and report `"completed"`, while `RestoreFromBackup` returned nil under a comment saying production "would actually restore data files" — so an operator who backed up before an incident and restored after one was told twice that it had worked. Someone replaced that with an explicit refusal naming what to do instead.

Deleting it would have removed the refusal and left the trap it was written for. It goes with the engine at T-05, and its guidance must survive into whatever replaces it.

**T-02's inventory was right about scope and wrong about kind** — the same failure shape as the rest of this ultragoal, in a new costume.

## T-03 — the governed layer over recall (recall `678aef4`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-08 | CP-3 | PASS | `recall/govern` refuses every ported contract case, **driven from cadre's captured fixture** rather than from restated assertions: five refusals exercised, each matched to a sentinel error. |
| AC-08 | CP-3 | PASS | Refusals happen before the store is touched — proven by a stand-in searcher that fails the test if reached. |
| AC-08 | CP-3 | PASS | **Falsified**: dropping the scope refusal makes a refused request reach the store and the stand-in reports it; making the recorder optional lets a store be constructed without one. |
| AC-08 | CP-3 | PASS | The vendored contract is held to cadre's copy by a guard that skips locally and fails under CI. recall's full suite green. |

### It decides no policy, and that is what makes it belong in recall

recall is a published general-purpose library. Adding one consumer's access-control policy to it would have been wrong. The six refusals turned out not to be policy: every one forces a caller to *state a decision* without prescribing what the values mean. Classification and source names are opaque required strings. The vocabulary belongs to the embedding system; what belongs in recall is that no policy can be skipped by omission.

### Five of six ported, and the sixth is accounted for rather than dropped

cadre refused a search with no embedding provider. recall injects its embedder at construction, so there is no per-request equivalent — but the *reason* survives: the provider and model go into the audit row, so a silent default makes retrievals unattributable. `govern.New` now requires an embedder identity and records it on every retrieval.

A test asserts that **exactly one** case is unported and that it is that one. A refusal quietly lost in a future edit fails rather than passes, and a new refusal appearing in the contract without a port fails too.

## T-04 — the CLI over `recall/govern` (cadre `f62c657b`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-08 | CP-3 | PASS | All six contract cases refused at the **command line**, driven from `internal/knowledge/testdata/fail-closed-contract.json` rather than restated: `TestTheCLIRefusesEveryContractCase` runs each through `KnowledgeCmd`. |
| AC-08 | CP-3 | PASS | Each case refused **before the store is opened** — the configured database path does not exist and recall's SQLite store creates its file on open, so the file appearing would fail the test. `TestEveryContractCaseIsRefusedBeforeTheStoreIsOpened`. |
| AC-08 | CP-3 | PASS | No refused request writes an audit row; a completed one writes exactly one carrying scope, agent, task and the embedder identity. `TestNoContractCaseIsAudited`, `TestAScopedSearchIsServedCitedAndRecorded`. |
| AC-08 | CP-3 | PASS | **Falsified**: with the embedder-identity check removed and a width-mismatched config, the same search returns exit 0 and a full result set. Observed against the built binary, not asserted. |
| AC-08 | CP-3 | PASS | Whole path observed through the built binary: refusals, `init`, a scoped retrieval returning a cited result, scope isolation (alpha→alpha, beta→beta, all→both), classification filtering (confidential→0), no `source_uri` in any bundle, two audit rows for two completed retrievals. |
| — | CP-3 | PASS | `CGO_ENABLED=1 go test -tags sqlite_fts5 -race ./...`, `go vet`, `golangci-lint`, `gofmt`, `goimports` all clean. The CLI suite also passes with `CGO_ENABLED=0`. |

### The disposition list named three verbs recall does not have

`recall info`, `recall status` and `recall migrate` were written into the T-04 disposition as the replacements for `stats`, `health-check`/`diagnostics`/`metrics` and `export`/`import`. Reading `cmd/recall/root.go` shows recall's top-level verbs are `upload`, `search`, `hybrid-search`, `rag`, `graph`, `reason`, `store`, `cluster`, `eval` — the others are `recall store info`, `recall store backup`, `recall store restore`, `recall store migrate`, and `store migrate` applies SQL migrations rather than moving data, so `export`/`import` had no equivalent at all.

Same failure shape as every other phase: a list assembled from prose held until something read the source. The retirement messages now name verbs read from recall's command tree.

### The envelope had to move before the engine could be deleted

`RetrievalBundle`, `Citation` and the trust label live in `internal/knowledge/search.go` — inside the component T-05 deletes — and the CLI is their only other consumer. They are now defined in a new neutral package, `internal/retrieval`, and the engine holds type aliases to them rather than a second copy. Aliases rather than a duplicate specifically because two structures for one shape is the defect class this consolidation keeps finding.

The context store was checked and does **not** share them: it deliberately keeps its own trust label (`untrusted_working_context`), so nothing there had to change.

### A recall store carries no record of what embedded it — and the failure is not silence

recall's schema holds `chunks` and `embeddings` and nothing about the provider, model or width that produced them. Cadre records that identity on every audit row, so the read side asserts something the write side never stored.

The assumption in the room — carried in cadre's own roster docs — was that a mismatch "scores as non-results". **Measured, it does not.** With the guard removed and a 384-dimension config against a 128-dimension store, the search returned exit 0 and *every chunk in scope*, each at score 0, in index order, with an audit row naming `hashing-384d` for vectors produced by `hashing-128d`. A full, ordinary-looking result set with no relevance in it is worse than an empty one.

`cadre knowledge init` now records the identity beside the store and every search checks it. Only `init` writes it: a search that recorded it on first use would be asserting, on the operator's behalf, a fact it cannot check, at the moment they are least likely to notice. That gives it the same standing as classification and source scope — stated by the caller, authenticated by nobody, and impossible to skip by omission.

### Consequences of taking the dependency

- recall requires `go 1.26.5`, so cadre's go directive rose from 1.25.0. CI reads the version from `go.mod`, so nothing there had to change — but the newer toolchain enables staticcheck findings that were previously not reported: six pre-existing SA5011 sites in test files, all nil-check-then-`t.Fatal`, now need an explicit `return`. Fixed, or CI would have been red on unrelated code.
- `internal/cli` now passes with `CGO_ENABLED=0`. The governed path is pure Go (recall uses `modernc.org/sqlite`); only the engine still needs cgo. That is the first half of what T-06 was to measure, and it does not make cadre cgo-free — `internal/contextstore` and `internal/engine/executor` still import `mattn/go-sqlite3`, exactly as the CP-2 plan predicted.

### Two things T-04 could not close, both blocking T-05

**`delete` has nowhere to go.** recall's `Store` deletes by chunk id or document id and offers no way to enumerate what matches a metadata scope. Cadre's four modes — `--expired`, `--classification`, `--source`, `--age` — have no equivalent to route to, and building one over capped `TopK` searches would delete whatever a query happened to return, which is not what any of those modes mean. `delete` therefore still runs on the retiring engine. It is the one verb that does, and it blocks deleting the engine.

The disposition that kept `delete` governed was written from the verb list rather than from recall's interface. Reading the interface is what found this.

**The documented ingest path cannot feed cadre's default configuration.** `recall upload` embeds with recall's configured embedder — `mock`, `openai`, `cohere`, `ollama`, `onnx` — and cadre's default is `local-hashing`, which recall does not have. A store uploaded by recall under cadre's default config is one cadre will now refuse rather than mis-search, which is the right failure, but it means the quickstart flow works only when both sides are configured to the same real embedder.

Three ways out, none of them T-04's to choose: configure both sides to a shared real embedder and retire `local-hashing` as a default; contribute a deterministic hashing embedder to recall; or have recall record the embedder identity in the store so the check becomes a verification rather than an assertion. The third is the one that removes the class rather than the instance.

## T-04 — CP-3v, independent component verify

A read-only verifier built its own binaries (default and CI-matching cgo), built recall from source, created a **real recall store with `recall upload`**, and drove both CLIs by hand rather than reading any test. Full report: `CP-3v-T04-component.md`.

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-08 | CP-3v | PASS | All six contract cases refused, text matched against `fail-closed-contract.json`, reproduced independently of cadre's own contract test. |
| AC-08 | CP-3v | PASS | Refusal precedes store creation: after all six runs, `find` shows only the config files — no `store.db`, no `embedder-identity.json`. |
| AC-08 | CP-3v | PASS | One completed retrieval wrote one audit row; two subsequent refused searches left the line count unchanged. |
| AC-08 | CP-3v | PASS | All 22 retired verbs answer by name at exit 2, and every replacement named exists in recall's command tree — checked against `cmd/recall/root.go` and `cmd_store.go`, not against the disposition. |
| AC-08 | CP-3v | PASS | `init` refuses to create a store and creates no file; `config get/set/list` refuse citing D-3's reasoning. |
| AC-08 | CP-3v | PASS | **Adversarial**: only two call sites reach `retrieval.Open` in the whole repository, both CLI-gated. `Citation` has no `source_uri` field and `ResultsFrom` never reads one — the omission is structural, not a filter that could regress. |
| — | CP-3v | PASS | CI gate reproduced clean: race suite with `sqlite_fts5` across 33 packages, `go vet`, `golangci-lint`, `gofmt`. |
| AC-08 | CP-3v | **FAIL** | `cadre knowledge delete` against a real recall store fails with `cannot open store: cannot initialize schema: no such column: embedding_provider`. Not a refusal — a schema error, against the only kind of store this commit leaves cadre pointed at. |

### What the verifier found that the build had not

T-04 recorded that `delete` stays on the retiring engine and why. What it did not establish is that `delete` is **broken**, not merely unmigrated: `cfg.Database` is one path for the whole subcommand group, so `delete` inherits the recall store that `search`, `init` and `config` now use, and cadre's engine cannot open it. The top-level usage lists `delete` beside them with no caveat.

Two consequences. `CP-6-decisions.md` D-2 and `T-04-verb-disposition.md` both record `delete` as kept and governed over `recall/govern`; the shipped code contradicts both, and says so in its own comment. And a verb advertised as working fails with a SQL error where the other 22 fail with an explanation.

The decision record is corrected below. What `delete` becomes is a decision, not a fix.

## T-04 — escalation resolved, `delete` retired (cadre `df2f3211`)

Decided 2026-08-31: retire it by name, like the other twenty-two.

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-08 | CP-3 | PASS | `cadre knowledge delete --expired` against the recall store now answers `retired -- ... remove content with recall, by document or chunk id. Deletion by retention window, classification, source or age has no equivalent ...` at exit 2. Previously `cannot initialize schema: no such column: embedding_provider`. Observed at the binary. |
| AC-08 | CP-3 | PASS | The verb no longer appears in `cadre knowledge help`; `search` unaffected (same query still returns `project-alpha` at 0.2887). |
| — | CP-3 | PASS | Race suite with `sqlite_fts5`, `go vet`, `golangci-lint`, `gofmt` all clean after the change. |
| — | CP-6 | PASS | Pushed: `c95ed2ba..df2f3211`. `git ls-remote origin main` → `df2f3211`. |

**The capability that went with it.** Deletion by retention window, classification, source or age is now unavailable in cadre and cannot be rebuilt over recall's interface. It is stated in the verb's own refusal and in `README_CLI.md` rather than approximated over capped queries, which would delete whatever a query happened to return.

`roster/knowledge-store/SECURITY.md` already described a `delete-ingested` verb with deletion evidence that the Go CLI never shipped. The policy was ahead of the implementation before this; T-04 widened the distance rather than creating it, and closing it is a P5 question — either recall grows metadata-scoped deletion, or the policy is rewritten to describe what exists.

**T-05 is unblocked.** Nothing in the CLI now reaches the retrieval engine.

## T-05 — the retrieval engine deleted (cadre `da84b963`)

**8,600 lines gone**: `search.go`, `database.go`, `persistence.go`, `hnsw_fts5.go`, `batch_operations.go`, `cli_persistence.go`, `database_repair.go`, `disaster_recovery.go`, `retention.go`, `types.go`, `config_manager.go`, `driver_probe.go` and every test over them. Net for the commit: 1,049 insertions, 9,718 deletions across 46 files.

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-08 | CP-3 | PASS | The engine is gone: no corpus table, no vector search, no index, no retention sweep in cadre. What remains in `internal/knowledge` is staged-record governance, config resolution and embedding providers. |
| AC-08 | CP-3 | PASS | Observed at the binary: `propose` → `disposition-staged` → `ingest-accepted` → `search` returns the accepted record at score 0.5375, cited to `proposed-knowledge` with document id `proposed-knowledge:KS-20260901-t05`. The governance chain survives the engine. |
| AC-08 | CP-3 | PASS | A second `ingest-accepted` reports `ingested 0, skipped 1` and the corpus stays at one result — idempotent through cadre's own evidence rather than through a corpus query. |
| AC-08 | CP-3 | PASS | **Migration observed with two binaries.** A record staged by the pre-T-05 binary into a combined store, then read by the post-T-05 binary: `moved 1 staged row(s) ... The originals are left in place`, record readable from `staged-records.db`, legacy file still holding its row, new database carrying only the five staged tables. |
| — | CP-3 | PASS | `internal/knowledge`, `internal/cli` and `internal/retrieval` all pass with `CGO_ENABLED=0`. Race suite with `sqlite_fts5`, `go vet`, `golangci-lint`, `gofmt`, `goimports` clean. |

### The defect T-04 shipped, found by scoping rather than by testing

Every staged verb resolved its store through `knowledge.LoadConfig` and opened it with `knowledge.Open`. `cfg.Database` names a recall store after T-04, so:

```
$ cadre knowledge --config <cfg> show-staged some-id
error: cannot initialize schema: no such column: embedding_provider
```

The same failure `delete` had, in a second place, and the suite never saw it because cadre's tests seed their own stores. **The entire knowledge-governance workflow was unreachable against the only kind of store the migration creates.** Not a consequence of deleting the engine — already true, and fixed here.

Worth naming the pattern: T-04's verifier found the first instance by running a verb the tests never ran against a real recall store. The second instance was found the same way one task later, by asking where the staged records live. Both were invisible to a green suite for the same reason.

### One call site, not a shared concern

Read rather than assumed: across the five staged files, exactly one function reached the engine — `ingestOneStagedRecord`, calling `SaveMessage` and `SaveChunk`. Everything else used `s.db` and the staged tables. The coupling was a shared struct and a shared file, not a shared purpose, which is what P2 recorded and what merging them cost.

### What the separation bought

**Its own database.** `staged-records.db` beside whatever the config names. cadre's governance tables have no business inside a database recall's backup, restore and migration tooling operates on without knowing they are there.

**Pure Go.** The staged store now uses `modernc.org/sqlite`, the driver recall already uses. `internal/cli`'s cgo test guard went with it. cadre is **not** cgo-free — `internal/contextstore` and `internal/engine/executor` still import `mattn/go-sqlite3`, exactly as the CP-2 plan predicted a phase ago — but the knowledge path is, and a `CGO_ENABLED=0` build no longer fails at the first knowledge query.

**A write path with the same guarantee as the read path.** `ingest-accepted` goes through the governed view, so a record cannot be written with vectors the store's other content will never be comparable against. It may claim a store it is creating — the vectors are its own — and is refused against a store that already holds content with no recorded identity, because claiming that would assert the one thing nobody can check.

### Two shapes kept to one authority

`CorpusRecord` is a type alias to `retrieval.Record` rather than a second struct with the same fields, for the same reason the retrieval envelope was aliased in T-04. Two declarations of one shape is the defect class this consolidation keeps finding; an alias cannot drift.

## T-05 — CP-3v, independent component verify

A read-only verifier built its own binaries, built a real recall store, and drove the whole workflow by hand. Full report: `CP-3v-T05-component.md`.

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-08 | CP-3v | PASS | Engine fully deleted with no residue: −8,669 lines, and a repo-wide grep for corpus tables, cosine similarity, HNSW and FTS5 finds only the unrelated context store and a migration-test fixture. |
| AC-08 | CP-3v | PASS | All six refusals reproduced verbatim with correct exit codes, and no store file created on any refusal. |
| AC-08 | CP-3v | PASS | `propose` → `disposition-staged` → `ingest-accepted` → `show-staged` round-trips against a fresh recall store. T-04's defect is fixed. |
| AC-08 | CP-3v | PASS | The ingested record is retrievable with a full citation; a second `ingest-accepted` skips rather than duplicating. |
| AC-08 | CP-3v | PASS | Migration real, non-destructive and idempotent — legacy file MD5 unchanged, no re-migration or duplication on repeated runs. |
| AC-08 | CP-3v | PASS | **Adversarial**: embedder mismatch refused on both read and write; claiming a store with existing content refused; self-approval refused at both `disposition-staged` and `import-staged`; no code path opens a recall store with cadre's schema. |
| — | CP-3v | PASS | cgo claim verified: `CGO_ENABLED=0` build and tests green, and a genuinely cgo-free binary runs the whole workflow. Only `internal/contextstore` and `internal/engine/executor` still import `mattn/go-sqlite3`. |
| — | CP-3v | PASS | CI gate green: race suite, `go vet`, `golangci-lint`, `gofmt`. |

### The one note, and why it was worth acting on

The verifier flagged a stale comment rather than a defect: `internal/release/platforms_test.go` still blamed "the knowledge store" for cadre's cgo requirement. Behaviour correct, reason obsolete — the knowledge store is exactly the thing that stopped needing cgo.

Fixed in `b3773400`, because a comment that names the wrong cause is what a later change reasons from. This ultragoal has now corrected three claims of that kind — the disposition's phantom recall verbs, the "scores as non-results" assumption, and this — and all three were prose that had drifted from code nobody re-read.

## T-06 — verify: what the migration actually did (cadre `bde3a9c9`, `9135d02a`, `b3773400`)

The task the phase plan wrote as "suites, generator checks, and what cgo status actually became". It found two things the suites could not.

### The generated plugin was stale, and had already been pushed

`./bin/cadre generate-plugin --check --output plugin`:

```
Generated plugin is stale or non-deterministic; run cadre generate-plugin
  content differs: suite/roster/RUNBOOK.md
  content differs: suite/roster/knowledge-store/README.md
```

T-04 edited two roster documents whose quickstarts named retired verbs. The committed plugin tree carries copies of both, and nothing in `go test` looks at it — CI's own check would have caught it on the next run, after two commits had already gone up. Regenerated in `bde3a9c9`.

Worth stating plainly: a green suite and an independent CP-3v pass both missed this, because neither runs the repository's own generators. That is what a separate verify task is for.

### The cgo requirement moved; it did not go away

Measured against a genuinely `CGO_ENABLED=0` binary rather than inferred:

| Command | Result |
|---|---|
| `cadre knowledge propose` → `disposition-staged` → `ingest-accepted` → `search` | the whole chain runs; search returns the ingested record |
| `cadre context list --source t06` | `Binary was compiled with 'CGO_ENABLED=0', go-sqlite3 requires cgo to work. This is a stub`, exit 1 |
| `cadre doctor` | `knowledge store: available (pure-Go sqlite driver, no cgo required)` |

The CP-2 plan predicted exactly this a phase ago, when it checked the tempting inference and rejected it: removing `internal/knowledge`'s `mattn/go-sqlite3` leaves two other importers. Both are still there — `internal/contextstore/database.go` and `internal/engine/executor/sqlite.go` — so `bin/cadre`'s cgo-first-with-fallback build still earns its place.

**What changed is which command an operator hits it on.** Three places still said a cgo-less build breaks `cadre knowledge` and sent the reader after a C toolchain: `bin/cadre`'s fallback comment, `DISTRIBUTION.md`, and `cadre doctor`'s warning — the one an operator actually reads. A warning that names the wrong subsystem is worse than none, because it is actionable and wrong. Corrected in `9135d02a`, with the doctor test now asserting the warning does **not** blame cgo, so it cannot regress to the old text. A fourth, in `internal/release/platforms_test.go`, was corrected in `b3773400` after the T-05 verifier flagged it.

That is four stale rationales in one phase, all of the same kind: prose that was true when written, describing code that moved. None of them broke anything; all four would have been reasoned from.

### Everything else the phase's CI runs

`generate-role-metadata --check` (321 files current), `schema-validate`, `generate-authority-aides --check` (8 files current), `cadre help`, `cadre select`, and the race suite with `sqlite_fts5` — all clean.

## CP-4 — integration verify across the phase

A read-only integration verifier walked the seams the per-task passes could not reach: both repositories, both binaries, the operator story from nothing, and the upgrade path. Full report: `CP-4-integration.md`.

**AC-08's three literal clauses hold** — recall survives as the store, the engine is gone, all six refusals reproduce at the binary. **Three defects were found around them**, two of which no per-task verification could have seen.

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-08 | CP-4 | PASS | Exactly one funnel to recall — `retrieval.Open` / `OpenForIngest`, three call sites, all CLI-gated. No bypass repo-wide. |
| AC-08 | CP-4 | PASS | All six refusals reproduced at the binary; propose → disposition → ingest → search completes end to end. |
| AC-08 | CP-4 | **FAIL** → fixed | recall's CI was **red on v0.3.0**, the exact tag cadre pinned. |
| AC-08 | CP-4 | **FAIL** → fixed | `cadre knowledge init` against a genuine pre-migration store reported success and silently corrupted the corpus. |
| AC-08 | CP-4 | **FAIL** → fixed | `roster/workflows/knowledge-ingestion.md` documented a retired verb as the live retention mechanism. |
| — | CP-4 | PASS | Full CI gate reproduced clean on cadre's side, including the generator checks. |

### The guard that was never running

`TestTheContractMatchesItsOrigin` is what keeps cadre's fixture and recall's vendored copy honest. It hard-fails under CI rather than skipping, deliberately. But recall's workflow never supplied the origin file, so **it failed for want of the file rather than for divergence — and had since it was written.** `gh run view 33466261336` shows the Go run for `675ad07` (v0.3.0) red on exactly that.

It passed locally only by accident: the test falls back to a sibling `../cadre` checkout, which exists on this machine and never on a runner. **That accident is what made T-03's ledger claim "recall's full suite green" look true.** The claim was honestly made and locally verified; the environment was doing work nobody had accounted for.

Fixed in recall `37d336e` — the workflow now checks cadre out and points the guard at its contract, failing loudly if the file is not where it expects. Verified both directions: green with the origin, hard-failing in an isolated copy under `CI=1` without it. Released as `v0.3.1` (library code identical to v0.3.0; the difference is a tagged commit whose guard actually ran) and cadre pinned to it in `f578a0b4`.

**Post-condition, observed rather than assumed.** `gh run view 33516565481` → `success | chore: release v0.3.1 | 2c00c05`, and `v0.3.1^{}` resolves to that same commit. The run's log carries the `Point the contract guard at its origin` step. The same workflow on `675ad07` is still recorded as `failure`, on this exact test — the before and after are both on the record.

### Silent corpus corruption on the first documented command

The worst finding of the phase, and it needed both binaries to see.

An operator upgrading has a combined store — staged records and a corpus in one file. `cadre knowledge init`, the first command the quickstart tells them to run, reported ordinary success against it:

```
Store:       .../combined.db
Embedded by: local-hashing / hashing-128d at 128 dimensions
Retrieval is governed: a search states its classification and source scope or is refused.
```

recall's store initializer is additive. Finding a `chunks` table already present with the old engine's columns, it creates what is missing, sees `chunks` there, and returns cleanly — leaving a file that is neither a valid legacy store nor a valid recall one. Every later search then failed with `no such column: c.document_ref`, an opaque error arbitrarily far from the command that caused it, with the corpus permanently unreachable and nothing distinguishing that state from a healthy store.

Reproduced twice by the verifier, then reproduced again here against the shipped binary before fixing.

Fixed in `4ad7fa57`: refused before recall's initializer is allowed near the file, keyed on the four tables only the engine ever had, with a message naming what the file is, what would have happened, and that staged records in it are migrated automatically and are not at risk. Checked ahead of the embedder-identity question in the ingest path too, so an operator is not sent to `init` for a store `init` also refuses. Four regression tests, including that a refused open does not change the file's size.

**Why nothing caught this earlier.** T-05's CP-3v exercised the migration and passed — because it built its legacy store the way the *tests* do, from the staged schema alone. Only a store built by the actual pre-migration binary carries the corpus tables that collide. The difference between a plausible fixture and the real artifact is the entire finding.

### Two notes recorded rather than fixed

**`ingest-accepted` writes every record under the fixed source `proposed-knowledge`,** not the `source_scope` the operator declared — searching the declared scope returns nothing, with no error. Documented in `README_CLI.md` rather than changed: making `source_scope` the retrieval source is a design decision, not a bug fix, and it belongs to whoever owns the staging contract.

**An empty or whitespace-only query** slips past the CLI's `NArg()` check and, for whitespace, past `govern`'s exact `Query == ""` test, producing a score-0 result and an audit row. The verifier checked `git show c95ed2ba:internal/knowledge/search.go` and found the deleted engine did exactly the same — faithfully preserved behaviour, not erosion introduced here. Worth fixing in recall's `govern`; not this phase's to change.
