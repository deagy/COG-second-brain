# CP-3v round 7 — production-readiness P6, AC-3b (deciding round)

gloop HEAD `b8ba719`, verified against a fresh clone at `/tmp/claude-1000/gloop-verify7`
(deleted after this report; binary built to `/tmp/claude-1000/gloop-verify7-bin`).
`go build ./...`, `go vet ./...`, full `go test ./...` all green (37 packages, no
skips). `mockery` regenerated fresh against the checkout; `git status --short` empty
afterward. Round 6's four fixes re-confirmed holding (Testing section now says
`go test ./pkg/runtime/...`; Roadmap's Cohere line now reads shipped; both `go doc`
mentions now give `go doc ./pkg/types`; MOCKERY_INTEGRATION.md's yaml block and mocks
list match `.mockery.yaml`/`test/mocks/` exactly). The two new guards
(`TestTheMockeryDocMatchesTheMockeryConfig`, `TestEveryGoToolingCommandInTheLiveDocsRuns`)
both still pass and were spot-mutated without incident. The 22 records under
`docs/` (19 in `docs/*.md` + 3 in `docs/PLANNING/*.md`, which I had missed on first
pass — `TestEveryRecordSaysItIsOne` globs both) all carry the historical-record
banner, confirmed by direct grep, not just by re-running the guard. Workspace left
clean; every mutation made this session was reverted (`git status --short` empty
before deleting the clone) except an unexplained content diff on the accidentally
committed `gloop/gloop` binary that self-resolved back to HEAD's exact bytes on
`git checkout -- gloop/gloop` — see note at the end.

## Coverage, by category (brief's list)

- **Non-`go` shell commands**: `make build`/`make install`/`make test` (ran each,
  matches Makefile and README); `git clone` syntax (matches); `mockery`/
  `mockery --name=...` (ran fresh, zero warnings); `go install` under `GOBIN`
  (ran, binary lands as documented).
- **File/dir paths**: every `docs/*.md` link, `CHANGELOG.md`, `test/mocks/*.go`
  filenames, `pkg/roster/testdata/roster/{roster.json,catalog.yaml,
  orchestration/routing.json}` — all exist exactly as named.
- **Env vars**: `GLOOP_CONFIG`, `GLOOP_GATE_STORE`, `GLOOP_ROSTER_REPO`,
  `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` — each grepped to a real `os.Getenv` call
  in the code the doc that names it is about.
- **Config keys/types**: the full `config.toml` example loads verbatim via
  `config show`; `DispatchPattern.Timeout`/`PerRoleTimeout` json tags,
  `PlannedRole.KnowledgeRetrieval`, `[knowledge]` embedder enum (`"openai"`/
  `"mock"`, empty→openai) all match `pkg/types`/`pkg/config` exactly. One key
  does **not** exist — see Failure 3.
- **HTTP endpoints/methods**: `/api/sessions`, `/api/metrics`, `/health` all
  registered exactly as the table states; ran a live `webui.NewWebUI` — token
  omitted gives 401, token given gives 200, confirming the "every endpoint
  requires the token" and loopback claims.
- **Package names/import paths**: every `github.com/deagy/gloop/...` path named
  in the five live documents resolves via `go list`.
- **Links/anchors**: every relative link and every `#anchor` in `docs/ROSTER.md`
  resolves to a real heading.
- **Counts/quantities**: `schema_version` pinned to `1` matches
  `SupportedSchemaVersion = 1`; wave concurrency "default 4" matches
  `DefaultWaveConcurrency = 4`; peer-findings cap "default 4000 chars" matches
  `DefaultPeerFindingsCap = 4000`.
- **Behavioural prose** ("refuses", "never fails", "is refused", "requires"):
  knowledge-store dimension mismatch is refused up front (ran it against
  `verifyEmbeddingDimension`); a knowledge-store error is logged, not fatal
  (matches `dispatcher.go:944` comment near-verbatim); web UI loopback+token
  claims (ran live, above).

## New AC-3b failures — four false claims, all unguarded, none of the "guard evadable" kind

**1. README.md's own architecture diagram omits two providers the same file says it has.**
`README.md:98-100`, the ASCII "Agent Providers" box:
```
│  │  Anthropic  │  │ Gemini/Mistr │  │  HTTP (custom)   │  │
```
Only Anthropic, Gemini/Mistral and HTTP — no OpenAI, no Cohere — three lines
below (in file position, not proximity) the Multi-Provider Features bullet
that names all six. This is a sixth location the provider list has drifted in
this phase (bullet, `config.toml` comment, `docs/ARCHITECTURE.md` twice, and
now this diagram), and it is the one no guard has ever read: mutated the line
further (`git diff` reverted) and the full `internal/docguard` suite stayed
green.

**2. The "dispatch plan" example is not valid JSON.**
`README.md:452-471`, "A dispatch plan looks like:" is fenced ` ```json ` and
contains three shell-style `#` comments inside the object
(`"knowledge_retrieval": true   # opt in...`, `"timeout": "10m",  # overall
budget...`, `"per_role_timeout": "2m"  # fresh deadline...`). Extracted the
block verbatim and ran it both through Python's `json` module and the real
binary:
```
$ gloop dispatch plan.json --config config.toml
Error: failed to parse plan: invalid character '#' after object key:value pair
```
Copying the example as shown breaks `gloop dispatch`. Unguarded — neither new
guard reads non-Go fenced blocks.

**3 & the broader defect it belongs to. `docs/ROSTER.md`'s own removal banner is
contradicted three paragraphs later, and one of the contradicting claims
names a field that does not exist anywhere in the tree.**

The file opens:
> **Removed.** `gloop roster plan` and `roster.Select` are gone... Route
> selection and dispatch-plan generation are cadre's...

The very next paragraph: "**Gloop can select roles from an external agent
roster**... The resulting dispatch plan is **self-contained**... so `gloop
dispatch` executes the plan without any roster checkout." And further down,
"Matching semantics" states "Routes are scored with the same engine as the
native catalog (`catalog.MatchRoutes`)" as gloop's own live behavior.

Checked directly: `gloop roster --help` lists only `show` and `validate` — no
selection command exists. `grep -rn "MatchRoutes(" .` shows `pkg/roster` never
calls it (only a comment references it); the only live caller is
`pkg/tenant/catalog.go`, an unrelated feature. `gloop roster show` on a real
fixture roster prints static structure only — no task, no matching, no
winning-route selection.

The single most concrete falsifiable claim in this stretch, at
`docs/ROSTER.md:200`: "all matched route IDs are recorded in
`metadata.matched_routes`." `grep -rn "matched_routes" --include="*.go" .`
returns **zero hits anywhere in the tree, including test files.**
`git log -S"matched_routes" --oneline` traces it to commit `81b46e0` ("Remove
the deprecated selectors: gloop no longer routes") — the same commit that
deleted `roster.Select`. The only surviving cousin is the *singular*
`plan.Metadata["matched_route"]` (`pkg/dispatch/dispatcher.go:1139`), used
only for gate quality-check lookups and holding one route, not "all matched
route IDs." This is a document telling readers about a plan-metadata contract
that was deleted alongside the code it depended on, and the deletion commit
predates every round of this phase.

**4. The documented integration-test command for the roster contract fails to
compile, and the "skips when offline" claim is unreachable.**
`docs/ROSTER.md`'s "Upstream format contract" section gives:
```sh
GLOOP_ROSTER_REPO=/path/to/cadre-roster go test -tags integration ./pkg/roster/
# or clone from GitHub (skips when offline)
go test -tags integration ./pkg/roster/
```
Ran both. Both fail identically, before any network or filesystem check runs:
```
pkg/roster/contract_test.go:70:18: r.Select undefined (type *Roster has no field or method Select)
pkg/roster/peer_exchange_e2e_test.go:101:17: r.Select undefined (type *Roster has no field or method Select)
FAIL	github.com/deagy/gloop/pkg/roster [build failed]
```
Same commit (`81b46e0`) removed `Roster.Select` and left these two
`integration`-tagged test files calling it. `go build ./...` never compiles
test files, and `go test ./...` (no tags) never compiles this file either
— so this has been broken since before round 1 of this phase and is invisible
to CI and to every guard. `TestEveryGoToolingCommandInTheLiveDocsRuns`
explicitly does not run `go test` — its own comment states packages are
"resolved with `go list` instead" because running the suite takes minutes —
and `go list ./pkg/roster/` succeeds fine (the package exists; only the
`integration`-tagged test files fail to build), so the guard cannot see this
class of defect by design, stated in its own source.
`docs/ROSTER_PEER_EXCHANGE.md:128` repeats the same false premise in prose
("integration roster contract test... must stay green").

All four are the "false claim a reader hits today" kind, not the "guard
evadable by a change nobody made" kind — no guard reads any of these four
spots at all, so there is nothing to falsify by mutation; the defects are
already live. None are ambiguous, security-sensitive, or judgment calls; each
is a bounded, mechanical correction.

## Everything else re-checked and holding (not counted as failures)

- `--config` three-bucket table: ran all three buckets fresh (`config show`
  honoured, `status`/`handoff list` silently ignored, `gate list`/`handoff get`
  rejected) — matches exactly, including the exact JSON shape for the
  silent-ignore case.
- Positional trap: `gloop dispatch --config x plan.json` still fails with
  `failed to read plan file: open --config: no such file or directory`,
  verbatim as quoted.
- `config show`'s three states (valid/absent/malformed) — no payload
  contradicts itself; malformed correctly reports `configExists: true` with an
  explanatory message, distinct from absent's `configExists: false`.
- Gate lifecycle (`create`→`approve`→`list`) round-trips live exactly as
  `docs/ROSTER.md` shows.
- `roster validate`/`roster show` against the real testdata fixture: exit 0,
  output matches the documented shape.
- Plugin interface, `Streamer` interface, metrics sample, web UI Go samples —
  covered by `TestEveryGoSampleInTheLiveDocsIsAccountedFor`; independently
  re-confirmed the `Plugin`/`Streamer` declarations still match source.
- Web UI: `/health` without a token → 401; with the per-start token → 200;
  `Addr()` binds `127.0.0.1`. Ran live, not read.
- `go test -race ./pkg/dispatch/` (named in `docs/ROSTER_PEER_EXCHANGE.md`'s
  "Validation" note): fails under default `CGO_ENABLED=0`, **passes** under
  `CGO_ENABLED=1` — exactly the environment `make test` sets. Not counted as a
  failure: the doc doesn't instruct running it standalone with a bare shell,
  and the section is a historical "what was validated" record inside a
  document whose own header says `Status: IMPLEMENTED`, not a copy-paste
  instruction.
- `docs/PLANNING/*.md` (3 files, found via `docs/*/*.md` — I missed this
  subdirectory on first pass and only caught it by reconciling the guard's
  logged count of 22 against my own manual count of 19): all three correctly
  carry the historical-record banner. Note, not a failure: `docs/README.md`'s
  index prose never names or links this subdirectory, so a reader browsing the
  index alone would not discover it exists — the banner is still true on
  arrival, so this is an index-completeness gap, not a false claim.
- Anomaly, not a doc claim: `gloop/gloop`, a compiled ARM64 binary, is
  committed in the working tree at `gloop/gloop` (introduced in this phase's
  own commit `b8ba719`, alongside `context/`, `gates/`, `handoff/`, etc. — real
  source packages under the same `gloop/` directory). It does not break
  `go build ./...` and no live document references it. During this session my
  own build tooling left it modified in the scratch clone at one point;
  `git checkout -- gloop/gloop` restored it to HEAD's exact bytes
  (`git show HEAD:gloop/gloop | md5sum` matched). Flagged for the record, not
  scored against AC-3b — nothing in the live docs claims the tree is free of
  build artifacts.

## Verdict

Four more concrete, unguarded false claims in live documents, none of the
"guard could be evaded by a change nobody made" shape — a reader hits all four
today by following the document as written (a redrawn diagram, a copy-pasted
plan file, a citation to a deleted metadata field, a compile-failing test
command). This is the fourth consecutive round finding new, previously-unseen
false claims in categories the prior round's guards did not reach (round 4:
dispatch bypass + 3rd provider list; round 5: architecture provider list +
uncompiled sample; round 6: streaming test path + Roadmap contradiction + `go
doc` syntax + mockery doc; round 7: architecture diagram + invalid-JSON
example + stale roster-selection narrative + broken integration test) —
worth surfacing to the orchestrator as a pattern independent of this round's
fixability call, since `AI-18`'s three-failure rule is about the same
criterion repeating, and AC-3b has now failed four rounds running since the
escalation was last put to the user. Each of this round's four findings is
individually bounded and mechanical, not ambiguous or judgment-requiring, so
this round's call is FAIL:fixable on its own terms; whether to spend another
fix attempt or re-escalate given the cumulative pattern is the orchestrator's
call, not this verifier's.

VERDICT: FAIL:fixable
LANE: full
CLAIMS_CHECKED: 19
EVIDENCE:
EVIDENCE AC-3b-round6-fixes-hold | CP-3v | PASS | Testing section now reads `go test ./pkg/runtime/...`; Roadmap's Cohere line reads shipped; both `go doc` mentions now give `go doc ./pkg/types`; MOCKERY_INTEGRATION.md's yaml block and mocks list match `.mockery.yaml`/`test/mocks/` exactly (mockery regenerated fresh, git status empty after). | README.md:75,566,578,~516; docs/MOCKERY_INTEGRATION.md:19-33,60-70; command output this session
EVIDENCE AC-3b-full-suite-and-guards-green | CP-3v | PASS | go build ./..., go vet ./..., go test ./... all clean (37 packages); TestTheMockeryDocMatchesTheMockeryConfig and TestEveryGoToolingCommandInTheLiveDocsRuns both pass and were spot-mutated without incident. | build/test/vet output this session
EVIDENCE AC-3b-config-table-and-positional-trap-hold | CP-3v | PASS | All three --config buckets (honoured/ignored/rejected) and the dispatch/run positional-trap error message reproduced live, verbatim. | command output this session
EVIDENCE AC-3b-webui-endpoints-and-auth | CP-3v | PASS | Ran a live webui.NewWebUI: /health with no token -> 401; with the per-start token -> 200; Addr() binds 127.0.0.1. Matches README.md's endpoint table and loopback/token claims. | pkg/webui/webui.go:129-131,311-330; command output this session
EVIDENCE AC-3b-config-toml-example-loads | CP-3v | PASS | README.md's full config.toml example extracted verbatim and loaded via `gloop config show --config` — reports the correct provider/model. | README.md:361-408; command output this session
EVIDENCE AC-3b-quantities-and-envvars-hold | CP-3v | PASS | schema_version=1 matches SupportedSchemaVersion; wave concurrency "default 4" matches DefaultWaveConcurrency=4; findings cap "default 4000" matches DefaultPeerFindingsCap=4000; GLOOP_CONFIG/GLOOP_GATE_STORE/GLOOP_ROSTER_REPO all resolve to real os.Getenv calls. | pkg/roster/roster.go:18, pkg/dispatch/dispatcher.go:30, pkg/dispatch/peer_exchange.go:19,27,34; grep output this session
EVIDENCE AC-3b-architecture-diagram-omits-providers | CP-3v | FAIL | README.md:98-100's ASCII "Agent Providers" box lists only Anthropic, Gemini/Mistral, HTTP — omitting OpenAI and Cohere, which the Multi-Provider bullet in the same file names. Sixth drifted location of this fact; unguarded (mutation-tested: docguard suite stays green when the line is further garbled). | README.md:15,98-100
EVIDENCE AC-3b-dispatch-plan-example-invalid-json | CP-3v | FAIL | README.md:452-471's "A dispatch plan looks like:" example carries inline # comments inside a ```json block; copied verbatim and run through `gloop dispatch` fails with `Error: failed to parse plan: invalid character '#' after object key:value pair`. Unguarded. | README.md:452-471; command output this session
EVIDENCE AC-3b-matched-routes-field-does-not-exist | CP-3v | FAIL | docs/ROSTER.md:200 claims all matched route IDs are recorded in `metadata.matched_routes`; grep -rn "matched_routes" --include="*.go" . returns zero hits anywhere including tests. git log -S traces it to commit 81b46e0, which deleted roster.Select. Only a singular, unrelated `metadata.matched_route` (one route, gate lookups) survives. | docs/ROSTER.md:200; pkg/dispatch/dispatcher.go:1139; git log -S"matched_routes" this session
EVIDENCE AC-3b-roster-selection-narrative-contradicts-its-own-banner | CP-3v | FAIL | docs/ROSTER.md's opening banner says roster.Select/selection are gone and are cadre's now; the next paragraph says "Gloop can select roles from an external agent roster" and "Matching semantics" describes catalog.MatchRoutes as gloop's live engine. `gloop roster --help` lists only show/validate; `grep -rn "MatchRoutes(" .` shows pkg/roster never calls it; `roster show` on a real fixture prints static structure only, no matching. | docs/ROSTER.md:1-20,183-199; command output this session
EVIDENCE AC-3b-integration-test-command-fails-to-compile | CP-3v | FAIL | docs/ROSTER.md's and docs/ROSTER_PEER_EXCHANGE.md:128's documented `go test -tags integration ./pkg/roster/` (with or without GLOOP_ROSTER_REPO) fails to compile: contract_test.go:70 and peer_exchange_e2e_test.go:101 call r.Select, removed in 81b46e0. "Skips when offline" is unreachable — it fails before any network step. Predates this phase; invisible to the new guard by the guard's own stated design (go test args are resolved via go list, not compiled). | docs/ROSTER.md:254-258; docs/ROSTER_PEER_EXCHANGE.md:128; command output this session
EVIDENCE AC-3b-planning-docs-carry-banners-note | CP-3v | PASS(note) | docs/PLANNING/{00-intent,01-requirements,02-implementation-plan}.md (missed on first sweep, found by reconciling the guard's logged count of 22 against a manual count of 19) all carry the historical-record banner correctly; docs/README.md's index never names or links this subdirectory — an index-completeness gap, not a false claim, since the banner is true on arrival. | docs/PLANNING/*.md; docs/README.md
EVIDENCE AC-3b-stray-binary-note | CP-3v | PASS(note) | gloop/gloop, a committed ARM64 binary introduced in this phase's own commit b8ba719, does not break go build ./... and is referenced by no live document; not scored against AC-3b. | gloop/gloop; git show b8ba719 --stat
FAILURES:
- AC-3b | README.md architecture diagram | The "Agent Providers" ASCII box (line ~100) lists Anthropic, Gemini/Mistral, HTTP only — omitting OpenAI and Cohere, which the Multi-Provider Features bullet three lines above names. Unguarded.
- AC-3b | README.md dispatch-plan example | The ```json "A dispatch plan looks like:" block (line ~452) contains shell-style `#` comments, making it invalid JSON; copied verbatim it fails `gloop dispatch` with a parse error. Unguarded.
- AC-3b | docs/ROSTER.md Matching semantics / metadata.matched_routes | Describes gloop performing live route matching/selection and recording `metadata.matched_routes`, both removed in commit 81b46e0 alongside `roster.Select`; the field does not exist anywhere in the tree, and gloop's roster package never calls `catalog.MatchRoutes`. Directly contradicts the document's own opening banner three paragraphs above. Unguarded.
- AC-3b | docs/ROSTER.md + docs/ROSTER_PEER_EXCHANGE.md integration test command | `go test -tags integration ./pkg/roster/` (both forms given) fails to compile because `contract_test.go` and `peer_exchange_e2e_test.go` still call the removed `Roster.Select`; the documented "skips when offline" behavior is unreachable. Predates this phase; the new go-tooling guard resolves `go test` package args via `go list` rather than compiling, by its own stated design, so this class is invisible to it.
FIX_HINTS:
- AC-3b | README.md architecture diagram | Redraw the "Agent Providers" box to name all six (or say "six providers" generically) and add a guard reading this block, or fold it into TestTheProviderListNamesEveryProvider's scope, so a seventh drift is caught rather than found by hand again.
- AC-3b | README.md dispatch-plan example | Strip the inline `#` comments from the JSON block (move each note to prose above/below the fence, or use JSON5/jsonc styling only if the doc says the file supports it — it does not) so the block is valid JSON if copied verbatim.
- AC-3b | docs/ROSTER.md Matching semantics section | Either delete/rewrite "Gloop can select roles..." and "Matching semantics" to describe what `roster show`/`roster validate` actually do (load and display, not match), or reframe explicitly as "this is the engine cadre uses" if that's the intent — and drop the `metadata.matched_routes` sentence entirely, since no code writes that key.
- AC-3b | Upstream format contract section | Either fix `contract_test.go`/`peer_exchange_e2e_test.go` to use the roster's current API instead of the removed `Select`, or remove/rewrite the documented command until they're fixed — a broken example is worse than no example.
