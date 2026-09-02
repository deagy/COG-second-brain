# AC-5 verification — cadre `bb35c49e`

**AC-5** (production-readiness/spec.md): an absent capability is refused where it is reached
for. A retention or erasure request is refused at the point of use, naming the gap — not only
in `SECURITY.md`. Falsified by running the command and reading what it says.

Build record under test: `04-projects/production-readiness/evidence/P4/CP-3-build.md` (not
`evidence/P4/CP-3-build.md` under repo-consolidation, which doesn't exist — the task's own
artifact path was slightly off; the correct P4 evidence lives under the production-readiness
project and covers T-01..T-04 there).

Binaries built directly from `bb35c49e`, no cgo (`/tmp/v5-cadre`) and CI-matching cgo+fts5
(`/tmp/v5-cadre-cgo`). Repository left clean throughout (`git status --short` empty before and
after).

## 1 — Enumeration (my own, not the build record's table)

Tried, against the built binary, every reach-path I could think of a steward typing:

- `cadre knowledge search --retention-days 30 "q"` → refused, exit 2
- `cadre knowledge --retention-days 30 search "q"` (flag before verb) → refused, exit 2
- `cadre knowledge -config c.json search --retention-days=30 "q"` (equals form) → refused
- `cadre knowledge search -retention-days 30 "q"` (single dash) → refused
- `cadre knowledge search "some query" --retention-days 30` (flag *after* positional text) →
  refused, exit 2
- `cadre knowledge ingest --retention-days 30` (flag on a retired verb) → refused (the
  capability check runs before verb dispatch, so it fires even here)
- `cadre knowledge retention-report --as-of 2026-01-01` (flag on a Python-era verb) → refused
  by the absent-capability path (wins over the plain "verb removed" message; still names
  b418031e/recall/open decision)
- `cadre knowledge delete-ingested --trigger gdpr-request` → refused
- `cadre knowledge propose --input x --retention-days 30` (staged route) → refused, exit 2
- `cadre knowledge delete-staged --retention-days 30` (staged route, exact test case) → refused
- `cadre knowledge search --retention 30 "q"` (near-miss spelling, not the real Python flag
  name) → **not** caught, falls to `flag provided but not defined: -retention`. Not a gap:
  `--retention-days` (not `--retention`) is the flag the Python CLI actually shipped
  (confirmed against `git show b418031e~1:roster/knowledge-store/src/cli.py`), so this isn't
  the word a real steward's muscle memory would type.
- `cadre knowledge search -- --retention-days 30` (args after `--`, deliberately treated as
  positional per the code's own comment) → **not** caught, falls through to
  `--classification is required`. A real boundary, but reaching it requires typing the
  argument-terminator idiom on purpose, not reaching for the capability by name — I judge this
  outside AC-5's "reached for" scope, not a fixable defect.
- `cadre --retention-days 30` (outside `cadre knowledge` entirely) → correctly *not* refused as
  an absent capability (`unknown subcommand`), matching the deliberate `cadre knowledge`
  namespacing.
- `cadre knowledge delete-staged --deleted-by z --authorized-by w` (real, still-live Python-era
  flag names on a verb that still exists) → not refused, proceeds to real validation
  (`no staged record with that id`) — correct, these are live flags, not absent capability.
- `cadre knowledge` bare, `cadre knowledge search -h` combined with the flag → both behave
  sanely (usage text; refusal still wins when both a help flag and an absent flag are present).

Both dispatch routes checked directly in source: `internal/cli/knowledge.go:128` and
`internal/cli/knowledge_staged.go:88` each call `refuseAbsentKnowledgeCapability` before any
flag parsing, and `internal/cli/dispatcher.go:281-287` is the only place that routes `cadre
knowledge ...` to either — confirmed there is no third entry point.

No reachable path (short of the deliberate `--` positional-args idiom, or a flag spelling the
Python CLI never actually used) answers with a generic parser error, "unknown subcommand", or
silence.

## 2 — Refusal content vs `SECURITY.md`

`roster/knowledge-store/SECURITY.md` § Storage rules (line 38-44) states: retention/deletion of
ingested content don't exist; `ingest`, `retention-report`, `delete-ingested`,
`deletion-evidence` were real in the Python CLI and removed in `b418031e`, none rebuilt;
content lives in a recall store whose CLI has no delete; whether to rebuild or declare out of
scope is an open decision.

Observed CLI output (`internal/cli/knowledge_absent_capability.go:69-82`) states, verbatim at
the command line: what the flag used to do, that it was removed in `b418031e` when the Go
rewrite landed, that neither retention nor deletion was rebuilt, that content now lives in a
recall store whose CLI exposes no delete either, that whether to rebuild or declare out of
scope is an open decision (pointing at `SECURITY.md § Storage rules`), and that deleting the
store file is a different, unscoped/unrecorded act. This is the same content, not a pointer to
go read it — satisfies "not only in SECURITY.md."

## 3 — No over-reach

`internal/cli/context.go` never calls `refuseAbsentKnowledgeCapability` (grepped for the call
site — only `knowledge.go` and `knowledge_staged.go` call it). Live-fired against the cgo
binary: `cadre context init` (exit 0), `cadre context put --scope agent --source proj ...`
(exit 0, real handle/hash returned), `cadre context expire --as-of 2026-01-01T00:00:00Z
--dry-run` (exit 0, real JSON report), `cadre context list --scope agent --source proj
--classification internal` (reaches real validation, not the absent-capability message). Both
`--scope` and `--as-of` are live and unaffected. No working command broke.

## 4 — Falsification in a scratch clone

`git clone --no-hardlinks /home/deagy/sdk/cadre /tmp/v5-clone` at `bb35c49e`. Edited
`refuseAbsentKnowledgeCapability` to `return false` immediately (dead code after, `go build`
doesn't flag it). `go test ./internal/cli/... -run TestARetentionRequestIsRefusedWhereItIsReachedFor -v`:
all 6 subtests fail, each reporting the exact regression the refusal exists to prevent —
`got: flag provided but not defined: -retention-days` / `-trigger` / `-as-of`, and the staged
case fails on exit code (1, not 2). Clone deleted afterward; real repo (`/home/deagy/sdk/cadre`)
untouched (`git status --short` empty).

## 5 — Test quality

`internal/cli/knowledge_absent_capability_test.go`'s `runKnowledgeCapturingStderr` calls
`KnowledgeCmd`/`KnowledgeStagedCmd` directly (the real dispatch functions, same ones
`cmd/cadre/main.go` reaches through `dispatcher.go`) and captures real `os.Stderr` via an
`os.Pipe`, not a mock. Assertions: exit code == 2, output contains `--<flag-name>`, output
contains **all three** of `b418031e`, `recall`, `open decision`, and output does **not** contain
`flag provided but not defined`. This set would catch a regression to a polite-but-empty
refusal (e.g. "not supported"): such a message would still hit exit 2 and might contain the
flag name, but would fail the `b418031e`/`recall`/`open decision` substring checks. It also
catches a refusal that fires too late (parser error still present) via the explicit negative
check. `TestTheRefusalDoesNotReachLiveFlags` independently checks three live invocations never
see the absent-capability marker string. I judge these assertions adequate — they check content
quality, not just presence, and they exercise the actual dispatch path rather than grepping
source.

## 6 — Full CI gate (real repo, `bb35c49e`)

```
go build ./...                                          → exit 0
go vet ./...                                             → exit 0
CGO_ENABLED=1 go test -tags sqlite_fts5 ./...            → exit 0, all packages ok, 0 FAIL
```

---

VERDICT: PASS
LANE: full
CLAIMS_CHECKED: 6
EVIDENCE:
EVIDENCE AC-5 | CP-3v | PASS | Independently enumerated ~15 reach-paths (both dispatch routes, flag-before/after-verb, equals/single-dash forms, retired/Python-era verbs, staged route) against the built binary; every one names the gap, none falls to a generic parser error or unknown-subcommand | internal/cli/knowledge.go:128, internal/cli/knowledge_staged.go:88, internal/cli/dispatcher.go:281-287; live runs against /tmp/v5-cadre
EVIDENCE AC-5 | CP-3v | PASS | Refusal text carries the same content as SECURITY.md (what was removed, commit b418031e, nothing rebuilt, recall store with no delete, decision open), not a pointer to the doc | internal/cli/knowledge_absent_capability.go:69-82 vs roster/knowledge-store/SECURITY.md:38-44
EVIDENCE AC-5 | CP-3v | PASS | cadre context --scope/--as-of remain fully live (init/put/expire/list all exit 0 or reach real validation) on the cgo binary; refuseAbsentKnowledgeCapability is called only from knowledge.go/knowledge_staged.go | internal/cli/context.go (no call site); live runs against /tmp/v5-cadre-cgo
EVIDENCE AC-5 | CP-3v | PASS | Disabling the refusal in a scratch clone (/tmp/v5-clone, deleted after) reproduces the exact pre-fix regression: all 6 contract subtests fail with the literal parser error the refusal replaces; real repo untouched | go test ./internal/cli/... -run TestARetentionRequestIsRefusedWhereItIsReachedFor -v
EVIDENCE AC-5 | CP-3v | PASS | Test invokes real dispatch functions via os.Pipe-captured stderr, not source grep; asserts exit code, flag name, and 3 required substrings, plus absence of the parser error — sufficient to catch a polite-but-content-free refusal | internal/cli/knowledge_absent_capability_test.go:20-90
EVIDENCE AC-5 | CP-3v | PASS | go build ./..., go vet ./..., CGO_ENABLED=1 go test -tags sqlite_fts5 ./... all exit 0, no failures | terminal output, this session
FAILURES: none
