# CP-3v round 6 — production-readiness P6, AC-3b (deciding round)

gloop HEAD `8a7f67e`, verified against a fresh clone at
`/tmp/claude-1000/gloop-verify6` (built binary
`/tmp/claude-1000/gloop-verify6-bin`). Full suite green (37 packages, no
skips reported this run). Workspace left clean; every mutation made this
session (README.md, docs/ARCHITECTURE.md, pkg/types/provider.go) was
reverted and `git status --short` confirmed clean before writing this
report.

## Round 5's two fixes — both hold

**ARCHITECTURE.md provider lists**: line 28 (Core-runtime box) and line 53
(package table) both now read `anthropic, openai, google, mistral, cohere,
http` — all six. Re-omitting cohere from line 28 leaves the suite green
(no guard reads this file — a residual gap, not a regression, matching
round 5's fix-hint that was left as "consider," not required).

**Metrics sample**: README.md:325-338 now reads `NewMetricsCollector(nil)`
and `IncrementCounter`/`ObserveHistogram`/`SetGauge`, each with a `nil`
labels map. Compiled the exact snippet against the checkout via a
`replace` directive in a throwaway module — clean build, exit 0.

**New guard, `TestEveryGoSampleInTheLiveDocsIsAccountedFor`**, mutation-tested
twice: reintroducing `RecordCounter` in the README sample fails naming the
compiler's own error; renaming `type Streamer interface` in
`pkg/types/provider.go` (breaking the quoted-declaration set) fails the
guard with the changed line and file — and separately breaks the real
build in three provider packages, confirming the interface is load-bearing,
not just quoted.

**Mockery**: `docs/MOCKERY_INTEGRATION.md`'s Go usage sample now calls
`mocks.NewMockProvider` and `Complete(ctx, messages, tools)`, matching
`test/mocks/mock_Provider.go:26` (3 args) and `types.Provider.Complete`
(`pkg/types/provider.go:20`, 3 args). `.mockery.yaml` no longer names
`AgentProvider` or a `pkg/runtime`-scoped `TokenCounter`. Ran `mockery`
fresh against the checkout: zero "no such interface" warnings (round 4's
symptom), and `git status --short` after regeneration is empty — the
checked-in mocks are exactly what mockery produces today.

## New AC-3b failures — four false claims, all in live documents, none guarded

**1. README.md Testing section names a package that was deleted.**
Line ~516: `go test ./pkg/streaming/...`. Ran it verbatim:
```
# ./pkg/streaming/...
pattern ./pkg/streaming/...: lstat ./pkg/streaming/: no such file or directory
FAIL	./pkg/streaming/... [setup failed]
```
`git blame` traces this line to the original README commit (`b9cdf3da`,
2026-08-14) and `pkg/streaming` was removed by `cb8176d` ("Close-out:
remove legacy pkg/streaming, fix README streaming docs, ratchet CI floor")
— a commit whose own message claims to have fixed the README's streaming
docs and left this one command unfixed. No guard reads the Testing
section.

**2. README.md's Roadmap directly contradicts its own Features section.**
Line ~578: `- [ ] Support for additional providers (Cohere, etc.)`, still
unchecked. But the Features section three lines from the top of the same
file says `Support for Anthropic, OpenAI, Google Gemini, Mistral, Cohere,
and generic HTTP endpoints`, the `config.toml` example's inline comment
lists `cohere` as accepted, and `pkg/runtime/cohere` + `IsKnownProviderType`
confirm it ships. `git blame` traces the roadmap line to `47eea8e6`
(2026-08-16) — predates every round of this phase. A reader who reads only
the Roadmap is told to wait for something already shipped; a reader who
reads both sections is told two contradictory things by the same document.

**3. `go doc ./...` is not valid `go doc` syntax, and the doc gives it as a
command twice.** README.md line 75 ("API reference — `go doc ./...` in a
checkout") and line 566 ("Documentation: `go doc ./...`..."). Ran it:
```
$ go doc ./...
doc: cannot find package "." in:
	/tmp/claude-1000/gloop-verify6/...
```
`go help doc` confirms `go doc` takes zero, one, or two arguments — a
package or symbol, not a `...` wildcard pattern (that syntax belongs to
`go build`/`go test`/`go vet`). A reader following either instruction
verbatim gets an error, not documentation.

**4. `docs/MOCKERY_INTEGRATION.md`'s Configuration section and Generated
Mocks list are stale in exactly the way the Usage Example was before round
5's fix — just outside the new guard's reach.** The new guard
(`TestEveryGoSampleInTheLiveDocsIsAccountedFor`) only scans ` ```go ` fences
in this file; this document's drift is in a ` ```yaml ` fence and a plain
bullet list, neither of which it touches. Diffed round 5→6: only the Go
usage-example block changed; the yaml block and the list are untouched.
Concretely, both are still wrong against the real `.mockery.yaml` and
`test/mocks/`:
- The yaml block shows `packages: github.com/deagy/gloop/pkg/runtime:
  interfaces: AgentProvider: ... TokenCounter: ...` — the real
  `.mockery.yaml` has no `pkg/runtime` package block at all; `AgentProvider`
  does not exist anywhere in the tree (`grep -rn AgentProvider` — zero
  hits); `TokenCounter` is under `pkg/types` (`pkg/types/session.go:93`,
  confirmed by the real `.mockery.yaml`'s own comment explaining exactly
  this history).
- The "Generated Mocks" bullet list names `mock_AgentProvider.go`,
  `mock_StreamProvider.go` and `mock_StreamCallback.go` — none exist
  (`ls test/mocks/` — 7 files, none of those three; no `streaming` package
  anywhere in the tree) — and attributes `mock_TokenCounter.go` to
  `runtime.TokenCounter`, which is the same wrong package as the yaml block.

This is the same shape named in the build record itself ("Two lists of one
fact drift; three drift faster"): the fix touched the one instance a
verifier had flagged and left two sibling instances of the identical false
claim, in the same file, unfixed.

## Everything else re-checked and holding

- `gate approve`/`gate list`/`gate create` syntax in `docs/ROSTER.md`
  (`gloop gate approve G1 reviewer alice@example.com
  https://example.com/pr/1 --task <id>`) run against a live gate store —
  create, approve, and list round-trip exactly as shown.
- `gloop roster --help` matches `docs/ROSTER.md`'s "Removed" framing;
  `show`/`validate` are the only subcommands.
- Provider-list guard re-mutated (dropped Cohere from the README
  Multi-Provider bullet): `TestTheProviderListNamesEveryProvider` still
  fails, naming the omission.
- go.mod (`go 1.26.5`) matches the installed toolchain and README's stated
  requirement; `make build`/`make install` targets present; no `LICENSE*`
  file, matching the License section's claim.
- Package-structure table has a duplicate `pkg/govplan/` row (two
  differently-worded but not contradictory descriptions, both true per
  round 5's `BlockedByHumanGate`/`ErrHumanGate` check) — a redundancy, not
  a falsehood; not counted as an AC-3b failure.

## Verdict

Four new, concrete, unguarded false claims in live documents this round —
none are the "guard could be evaded by a change nobody made" shape; all
four are commands or claims a reader hits today, right now, by following
the document as written. All four are bounded, mechanical corrections
(delete/replace one line each; sync one yaml block and one list to the
real `.mockery.yaml`/`test/mocks/`), not judgment calls or scope creep —
fixable, not escalation-worthy.

VERDICT: FAIL:fixable
LANE: full
CLAIMS_CHECKED: 13
EVIDENCE:
EVIDENCE AC-3b-architecture-cohere-fix-holds | CP-3v | PASS | docs/ARCHITECTURE.md:28,53 both now name all six provider runtimes including cohere; re-omitting cohere leaves the suite green (unguarded gap, not a regression — noted, not counted). | docs/ARCHITECTURE.md:24-28,53
EVIDENCE AC-3b-metrics-sample-compiles | CP-3v | PASS | README.md:325-338's sample (NewMetricsCollector(nil), IncrementCounter/ObserveHistogram/SetGauge with nil labels) compiled clean via replace directive against the checkout; matches pkg/logging/metrics.go:53,67,92,110 exactly. | pkg/logging/metrics.go, /tmp/claude-1000/gloop-snippet-test6
EVIDENCE AC-3b-go-sample-guard-mutation-tested | CP-3v | PASS | Reintroducing RecordCounter fails naming the compiler error; renaming Streamer in pkg/types/provider.go fails the guard (and breaks the real build in 3 packages), confirming the quoted set is load-bearing. | internal/docguard/help_text_test.go:827-907, mutated/reverted this session
EVIDENCE AC-3b-mockery-regenerated-clean | CP-3v | PASS | mockery run fresh against the checkout: zero "no such interface" warnings; git status empty after regeneration; mock_Provider.go's Complete takes 3 args matching types.Provider.Complete. | .mockery.yaml, test/mocks/mock_Provider.go:26, pkg/types/provider.go:20
EVIDENCE AC-3b-full-suite-green | CP-3v | PASS | go build ./... and go test ./... both clean, 37 packages, no failures. | build/test output this session
EVIDENCE AC-3b-streaming-test-command-fails | CP-3v | FAIL | README.md Testing section's `go test ./pkg/streaming/...` fails with "no such file or directory" — pkg/streaming was removed by commit cb8176d; the line predates every round of this phase and is unguarded. | README.md:~516, command output this session
EVIDENCE AC-3b-roadmap-cohere-contradiction | CP-3v | FAIL | README.md Roadmap still lists "Support for additional providers (Cohere, etc.)" unchecked, while the Features section, config.toml comment, and pkg/runtime/cohere all confirm Cohere already ships — same document, two contradictory claims. Predates this phase (commit 47eea8e6). | README.md:~578 vs README.md:17,365
EVIDENCE AC-3b-go-doc-wildcard-invalid | CP-3v | FAIL | `go doc ./...`, given twice (README.md:75,566) as a command to run, fails with "cannot find package \".\" in: .../..." — go doc takes a package or symbol, not a `...` pattern, per `go help doc`. | README.md:75,566, command output this session
EVIDENCE AC-3b-mockery-doc-yaml-and-list-stale | CP-3v | FAIL | docs/MOCKERY_INTEGRATION.md's yaml config block and "Generated Mocks" list still name AgentProvider (nonexistent), StreamProvider/StreamCallback (nonexistent, no streaming package anywhere), and misattribute TokenCounter to pkg/runtime instead of pkg/types — unfixed by round 5/6's Go-sample guard, which only scans \`\`\`go fences in this file, not the \`\`\`yaml fence or the prose list. | docs/MOCKERY_INTEGRATION.md:19-33,60-70; .mockery.yaml; test/mocks/ (ls); pkg/types/session.go:93
EVIDENCE AC-3b-provider-list-guard-holds-round6 | CP-3v | PASS | Re-mutated (dropped Cohere from README's Multi-Provider bullet); TestTheProviderListNamesEveryProvider still fails naming the omission. | mutated/reverted README.md this session
EVIDENCE AC-3b-roster-gate-cli-verified | CP-3v | PASS | docs/ROSTER.md's gate create/approve/list syntax run against a live gate store, round-trips exactly as documented. | docs/ROSTER.md:78-79, command output this session
EVIDENCE AC-3b-install-requirements-hold | CP-3v | PASS | go.mod's `go 1.26.5` matches installed toolchain and README's requirement; make build/install targets present; no LICENSE* file matching the License section's claim. | go.mod, Makefile:27,31
EVIDENCE AC-3b-govplan-duplicate-row-note | CP-3v | PASS(note) | Package-structure table has two pkg/govplan/ rows with different wording but no contradiction (both confirmed true by round 5's BlockedByHumanGate/ErrHumanGate check) — redundancy, not a falsehood, not counted against the verdict. | README.md:128-129
FAILURES:
- AC-3b | README.md Testing section | `go test ./pkg/streaming/...` fails outright ("no such file or directory"); pkg/streaming was removed. Unguarded, predates this phase.
- AC-3b | README.md Roadmap vs Features | Roadmap lists Cohere support as an unchecked TODO while Features/config.toml/registry all confirm it ships — a direct in-document contradiction. Unguarded, predates this phase.
- AC-3b | README.md Documentation/Support sections | `go doc ./...` (given twice) is not valid go doc syntax and fails when run verbatim; go doc takes a package/symbol argument, not a `...` pattern.
- AC-3b | docs/MOCKERY_INTEGRATION.md Configuration + Generated Mocks | The yaml config block and the mocks list still name AgentProvider/StreamProvider/StreamCallback (none exist) and misattribute TokenCounter to pkg/runtime instead of pkg/types — the same staleness round 5/6 fixed in this file's Go usage example, left uncorrected in the two sibling instances because the new guard only scans ```go fences.
FIX_HINTS:
- AC-3b | Testing section | Delete or replace `go test ./pkg/streaming/...` with a package that exists (e.g. `go test ./pkg/plugin/...` is already listed next to it and works).
- AC-3b | Roadmap | Remove the Cohere line from Roadmap (or reword to a provider genuinely not yet supported), since it directly contradicts the Features section three lines above it in the same file.
- AC-3b | Documentation/Support sections | Replace `go doc ./...` with a real invocation — `go doc ./pkg/types` (or similar single-package form), or `go doc -all ./pkg/...` is also invalid; the only supported forms take one package or symbol at a time.
- AC-3b | MOCKERY_INTEGRATION.md | Sync the Configuration yaml block and the Generated Mocks list to the real `.mockery.yaml` and `test/mocks/` contents (drop AgentProvider/StreamProvider/StreamCallback, move TokenCounter to pkg/types). Given this is the second time this exact file has been fixed in one place and left wrong in a sibling, consider widening the guard (or adding a sibling guard) to cover non-Go fenced blocks and plain-prose file/symbol lists in live documents, not just ```go samples.
