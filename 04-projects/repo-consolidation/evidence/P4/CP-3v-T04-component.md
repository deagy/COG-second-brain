# CP-3v verification — commit f62c657b, AC-08

Independent read-only verification. Built `/tmp/verify-cadre` (no cgo, no tags — matches default
build) and `/tmp/verify-cadre-cgo` (`CGO_ENABLED=1 -tags sqlite_fts5` — matches CI). Built
`/tmp/verify-recall` from `/home/deagy/sdk/recall` at the checked-out commit to construct a real
recall store (`recall upload` with `store.embedder.type: mock`, dimension 128) and drove both
binaries directly, never trusting the worker's own test file.

## 1 — Six contract cases actually refused by `cadre knowledge search`

Ran each case by hand against `/tmp/verify-cadre` with a config pointing at a database path that
does not exist (`/tmp/cp3v-t04-test/nonexistent/store.db` and `.../nonexistent2/store.db` for the
no-provider case, since it needs `embedding.provider: ""` in the config file).

```
$ cadre knowledge -config good.json search --classification internal --all-sources
cadre knowledge search: query is required                                   (exit 2)

$ cadre knowledge -config good.json search --all-sources "anything"
cadre knowledge search: --classification is required                       (exit 2)

$ cadre knowledge -config noprovider.json search --classification internal --all-sources "anything"
cadre knowledge: embedding provider is required: set "embedding.provider" to
one of: local-hashing, openai-compatible. ...                               (exit 1)

$ cadre knowledge -config good.json search --classification internal "anything"
cadre knowledge search: source scope is required: pass --source ...         (exit 2)

$ cadre knowledge -config good.json search --classification internal --all-sources --source a "anything"
cadre knowledge search: source scope is ambiguous: pass either --source ... (exit 2)

$ cadre knowledge -config good.json search --classification internal --source a --source "  " "anything"
invalid value "  " for flag -source: each --source must be non-empty        (exit 2)
```

All six substrings match `fail-closed-contract.json`'s `expect_refusal` exactly. Also confirmed
this is the only reachable call site: `grep -rn "retrieval.Open\|govern.Request{"` across the repo
shows exactly two callers, both in `internal/cli/knowledge.go` (`knowledgeInit`, `knowledgeSearch`)
— no bypass exists.

## 2 — Refusal happens before the store is opened

`find /tmp/cp3v-t04-test -type f` after all six runs above: only the two config files exist. No
`nonexistent/`, no `nonexistent2/`, no `store.db`, no `embedder-identity.json`. recall's SQLite
store (`modernc.org/sqlite`, confirmed pure-Go, no cgo) creates its file on open, so the absence is
proof the refusal came first. Traced why: `knowledgeSearch` runs its own query/classification/mode/
scope checks (`internal/cli/knowledge.go:430-456`) before calling `resolveEmbedder` or
`retrieval.Open`; the "no provider" case is caught even earlier, in `knowledge.LoadConfig` before
`KnowledgeCmd` dispatches to any subcommand. Inside `retrieval.Open` itself, `EmbedderIdentity` and
`CheckIdentity` are also both evaluated before `store.NewSQLiteStore` is called (`store.go:85-116`).

## 3 — Audit log excludes refusals, includes completions

Built a real store (`recall upload` a test doc, mock embedder, dim 128), ran `cadre knowledge init`
(wrote `embedder-identity.json`, no audit file yet), then one successful search:

```
$ cadre knowledge -config real.json search --classification internal --all-sources \
    --agent verifier --task-id cp3v-t04 "test document"
Retrieval results (vector search, 0)
...
$ cat retrievals.jsonl
{"recorded_at":"...","query_id":"4837479125758add","classification":"internal",
 "source_filters":null,"all_sources":true,"agent":"verifier","task_id":"cp3v-t04",
 "result_count":0,"embedder":"local-hashing","model":"hashing-128d"}
```

(0 results because generic `recall upload` doesn't stamp `classification` chunk metadata — a test
artifact, not a bug in the governed path; the row itself is correct and complete.) Then ran two
refused searches (no query; no source scope) against the same store — `wc -l retrievals.jsonl`
stayed at 1 both times. Traced why: `govern.Store.Search` (`recall/govern/govern.go`) calls
`Validate` first and returns on any refusal before touching `s.search.Search` or `s.recorder`;
`RecordRetrieval` is only reached after a successful store search, right before results are
returned.

## 4 — Retired verbs name real recall replacements

Read `recall`'s actual command tree from source (`/home/deagy/sdk/recall/cmd/recall/root.go` +
`cmd_store.go`, `cmd_cluster.go`): top-level `upload, search, hybrid-search, rag, graph, reason,
store, cluster, eval`, with `store` nesting `info, migrate, backup, restore` and `cluster` nesting
`status`. There is no top-level `recall info`, `recall status`, `recall migrate`, or `recall
backup` — those spellings from the original T-04 disposition draft do not exist, exactly as the
commit message claims. Ran all 22 retired verbs against the built binary; each answers by name,
exit 2, e.g.:

```
cadre knowledge stats: retired -- cadre no longer owns a retrieval engine.
  run `recall store info` against the same store
cadre knowledge backup: retired -- ...
  run `recall store backup <destination>` -- cadre's backup copied nothing and said so; recall's is real
cadre knowledge export: retired -- ...
  run `recall store backup <destination>` copies a whole store
cadre knowledge import: retired -- ...
  run `recall store restore <backup>` restores one
```

Every named replacement (`recall store info`, `recall upload`, `recall hybrid-search`, `recall
store backup`, `recall store restore`) matches a real command in recall's tree — none of the
messages name a phantom verb.

## 5 — `init` and `config`

`init` against a config pointing at a non-existent database: refuses ("no store at ...; cadre does
not create stores. Create one with `recall upload <path>...`"), exit 1, no file created —
`find /tmp/cp3v-t04-test/nostore -type f` empty. Matches CP-6 D-3. Against a real store, `init`
records `embedder-identity.json` and does not otherwise mutate the store.

`config show` prints database, audit log path, embedding provider/model/dims, recorded identity.
`config get`, `config set`, `config list` all refuse with exit 2 and the exact CP-6 D-3 rationale
("Its keys configured the SQLite engine cadre no longer owns, and `set` wrote to memory that was
discarded at exit"). Matches CP-6 D-3.

## 6 — Adversarial pass

- Could not reach `governed.Search` without both classification and a source-scope decision from
  any code path — only two call sites exist in the whole repo (see §1), both CLI-gated before
  `retrieval.Open`.
- Could not produce a completed retrieval with no audit row: `govern.Store.Search` records before
  returning, and a recording failure fails the whole call (`return nil, fmt.Errorf("govern:
  retrieval could not be recorded: %w", err)`).
- `source_uri`: `internal/retrieval/bundle.go`'s `Citation` struct has no `source_uri` field at
  all, and `internal/retrieval/results.go`'s `ResultsFrom` never reads a `source_uri` key out of
  chunk metadata. It cannot appear in an emitted bundle by construction, not by omission-that-could-
  regress. Matches SECURITY.md: "The Python CLI omits stored `source_uri` values because they may
  expose local paths."

## 7 — Full CI suite

```
CGO_ENABLED=1 go test -tags sqlite_fts5 -race ./...   → EXIT:0, 33 packages ok, 0 FAIL, 0 races
go vet ./...                                            → EXIT:0, no output
go tool golangci-lint run ./...                         → 0 issues. EXIT:0
gofmt -l .                                               → no output (nothing unformatted)
```

Full logs: `/tmp/cp3v-t04-gotest.log`, `/tmp/cp3v-t04-lint.log`.

## Finding outside the seven checks: `delete` does not do what CP-6-decisions.md D-2 says

`CP-6-decisions.md` D-2 states as decided and executed: "cadre keeps `knowledge search` and
`knowledge delete` over `recall/govern`." `T-04-verb-disposition.md`'s table lists `delete` under
"Keep, governed over `recall/govern`." The actual code does not do this.
`internal/cli/knowledge.go:502-514` (`knowledgeDelete`) carries a comment stating outright: "The
one verb still on cadre's own engine, and deliberately not migrated here... Recorded rather than
papered over: this blocks deleting the engine, and the disposition that kept `delete` was written
from the verb list rather than from recall's interface." The function calls `knowledge.Open(dbPath)`
— cadre's legacy engine — not `retrieval.Open`/`govern`.

Verified this is not just stale prose but an actual functional break: ran `cadre knowledge -config
real.json delete --expired` against the same recall-format store `search`/`init`/`config` operate
on, with the CI-matching cgo build:

```
cadre knowledge delete: cannot open store: cannot initialize schema: no such column: embedding_provider
```

`cfg.Database` is the one path config resolves for the whole subcommand group; `delete` shares it
with `search`/`init`/`config` in `KnowledgeCmd`'s dispatch, and the top-level usage text lists
`delete` alongside them with no caveat. Every store this migration targets (recall-created, via
`recall upload`) is one `cadre knowledge delete` cannot open. This is unrelated to AC-08's specific
ask (the six refusals on the surviving *retrieval* path, which is `search` and which fully holds),
but it means a decision record the task's own scope document names as authoritative asserts
something the shipped code contradicts, and a currently-advertised verb is broken against the only
kind of store this commit leaves cadre pointed at.

---

EVIDENCE AC-08 | CP-3v | PASS | All six fail-closed-contract.json cases refused via cadre knowledge search with matching text (query/classification/no-provider/no-scope/ambiguous-scope/blank-source), verified independently of the worker's own contract test | internal/cli/knowledge.go:430-456, internal/knowledge/testdata/fail-closed-contract.json
EVIDENCE AC-08 | CP-3v | PASS | Refusal precedes store creation: no file appears under a nonexistent db path for any of the six cases; EmbedderIdentity/CheckIdentity run before store.NewSQLiteStore in retrieval.Open | internal/retrieval/store.go:85-118, manual find after 6 runs
EVIDENCE AC-08 | CP-3v | PASS | Completed retrieval recorded (agent/task-id/embedder/model/result_count in retrievals.jsonl); two subsequent refused searches left the line count unchanged at 1 | internal/retrieval/audit.go, recall/govern/govern.go Search()
EVIDENCE AC-08 | CP-3v | PASS | All 22 retired verbs answer by name, exit 2; every named replacement (recall store info/backup/restore, recall upload, recall hybrid-search) is a real command in recall's cmd tree, none phantom | /home/deagy/sdk/recall/cmd/recall/root.go, cmd_store.go, cmd_cluster.go; internal/cli/knowledge.go:28-51
EVIDENCE AC-08 | CP-3v | PASS | init refuses to create a missing store (exit 1, no file created); config show prints resolved store/embedder state; config get/set/list refuse citing the CP-6 D-3 rationale verbatim | internal/cli/knowledge.go:153-183, 626-659
EVIDENCE AC-08 | CP-3v | PASS | No bypass of classification+scope exists (2 call sites total, both CLI-gated); recording is on-path with search (failure fails the call); Citation struct has no source_uri field, ResultsFrom never reads one | internal/retrieval/bundle.go, results.go, recall/govern/govern.go
EVIDENCE AC-08 | CP-3v | PASS | CGO_ENABLED=1 go test -tags sqlite_fts5 -race ./... exit 0, 33 packages, 0 failures, 0 races; go vet clean; golangci-lint 0 issues; gofmt -l . empty | /tmp/cp3v-t04-gotest.log, /tmp/cp3v-t04-lint.log
EVIDENCE AC-08 | CP-3v | FAIL | CP-6-decisions.md D-2 says delete is kept "over recall/govern"; code instead keeps it on cadre's legacy engine (knowledge.Open) with an explicit in-code admission of the divergence, and running it against a real recall store fails with a schema error, not a refusal | internal/cli/knowledge.go:502-514; live run: "cannot initialize schema: no such column: embedding_provider"

VERDICT: FAIL:escalate — the six-refusal contract itself (the literal text of AC-08) is fully satisfied and independently reproduced end-to-end, including the full CI gate (race tests, vet, lint, gofmt all clean). The escalation is scoped to one item outside the six checks the task named explicitly but inside the scope documents it told me to treat as authoritative: CP-6-decisions.md D-2 records a decision ("delete stays governed over recall/govern") that the shipped code does not implement and says so in its own comments, and the as-shipped `delete` verb is not a refusal but a hard failure against every store this migration leaves cadre pointed at (recall-created stores). Decision needed from a human: either (a) correct CP-6-decisions.md/T-04-verb-disposition.md to record that delete stays on the legacy engine (and decide what that means for T-05's plan to delete that engine, since delete would break entirely once it's gone), or (b) treat this as an open gap in T-04 and route delete through govern or retire it explicitly, the way the other 22 verbs were retired by name rather than left silently broken.
