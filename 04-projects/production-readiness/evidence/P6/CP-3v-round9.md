# CP-3v round 9 — production-readiness P6, AC-3b (deciding round)

gloop HEAD `bd345bc`, verified against a fresh clone at
`/tmp/claude-1000/gloop-verify9` (binary at `.../gloop-verify9-bin` via `go build
./cmd/gloop`). `go build ./...`, `go vet ./...`, `go vet -tags integration ./...`,
and `CGO_ENABLED=1 go test ./...` all green (37 packages, 0 skips, 0 failures),
`internal/docguard`'s full 17-guard suite included (0 FAIL). `CGO_ENABLED=0 go
build ./...` and `CGO_ENABLED=0 go test ./pkg/persistence/...` also green,
directly exercising the README's pure-Go-SQLite claim rather than trusting it.

## Round 8's fixes confirmed by direct observation

- `git diff 7a5a3dd..bd345bc -- README.md docs/ROSTER.md` shows exactly the two
  claimed edits: `docs/ROSTER.md`'s opening paragraph now reads "cadre selects
  roles from a roster; gloop reads and executes what it produces... gloop's own
  commands here are `roster show` and `roster validate`"; README's Package
  Structure table carries one `pkg/govplan/` row, not two.
- `TestNoLiveDocumentClaimsGloopSelects`: reintroduced round 8's exact sentence
  ("Gloop can select roles from an external agent roster, matching routes
  locally") into `docs/ROSTER.md` — failed, naming the file, line, and text.
  Restored.
- `TestNoLiveDocumentTableRepeatsARow`: reintroduced a second `pkg/govplan/` row
  into README's table — failed, naming both line numbers. Restored.
- `TestConfigShowNeverContradictsItself`: broke its own "valid" fixture (wrong
  model string) — failed with "the valid fixture did not load," not a false
  pass. Restored.
- `TestTheLiveListInTheIndexMatchesThisGuard`: deleted the
  `ROSTER_PEER_EXCHANGE.md` entry from `docs/README.md`'s live list — failed,
  naming the mismatch. Restored.

All four mutations failed for the stated reason, not by failing to compile.
`git status` clean after each restore.

## Independent sweep of all six live documents, end to end

**`docs/README.md`** (least examined, read whole): correctly separates 4 live
docs + itself from 22 records; its own live-list claim is guard-verified above.
No claim in it is false.

**`docs/ROSTER_PEER_EXCHANGE.md`** (least examined, read whole, 179 lines):
every mechanism claim checked against `pkg/dispatch/peer_exchange.go` and
matches exactly — `DefaultPeerFindingsCap = 4000`, the `NO CHANGE` token
(case-insensitive, trimmed), the `=== peer: <name> ===` / `=== end peer ===`
delimiters, the `… [truncated]` marker, `SetPeerExchangeEnabled`/
`SetPeerFindingsCap`, `CommunicationMode` on `PlannedRole`, `executed_mode` in
`DispatchResult.Metadata`, eligibility requiring ≥2 successful round-1 members.
The Files/Test-plan tables name `cmd/gloop/cmd/select.go` and
`pkg/roster/select.go`, which no longer exist — but this section is explicitly
historical ("Files changed" / "Validation" at implementation time, dated
2026-08-22, before selection was removed), not a present-tense claim about the
current tree. Not a false claim.

**`README.md`** (full re-read): Quick Start, Installation, CLI Options
(`--config` table and positional trap — both re-run live below), Plugin
interface, Streaming interface, Web UI (endpoints, `NewWebUI`/`Token`/`Addr`,
loopback-only + per-request-token claims, session methods), Metrics
(`NewMetricsCollector`/`IncrementCounter`/`ObserveHistogram`/`SetGauge`),
Configuration (`config.toml` example, `--config` search order), End-to-end
example (dispatch-plan JSON — re-parsed, clean), External Agent Rosters,
Testing, Contributing, License, Roadmap (each checked line individually,
including the two still-unchecked items: `AuditLogger` has no persistent
backend today — confirmed, it only holds `io.Writer`s, matching "config
wiring outstanding"). Every code sample, table row, and command name checked
against source or run against the binary; none false.

**`docs/ARCHITECTURE.md`** (full re-read): package map's 21 listed packages
all exist on disk; "single routing engine" (`pkg/catalog/match.go:35`, doc
comment says exactly that) and roster file-watcher (`pkg/catalog/catalog.go`)
both confirmed. The "Route resolution (now cadre's; see `pkg/govplan`)" key-flow
entry attributes resolution to cadre explicitly and doesn't match the
selection-claim guard's pattern (subject isn't "gloop"); read closely it does
not claim gloop resolves routes.

**`docs/ROSTER.md`** (full re-read post-fix): every remaining claim checked —
`catalog.MatchRoutes` exists but is called nowhere under `pkg/roster`,
`cmd/gloop`, or `internal` (one hit is a comment in `convert.go`, the others
are the docguard test itself); `active_recipes` is the only metadata key
`cmd/gloop/cmd/dispatch.go` reads (`result.Metadata["active_recipes"]`, one
site); `dispatch blocked: %d pending gate(s)` and `dispatch blocked: gate %s
rejected` both literal in `dispatcher.go`; `~/.gloop/gates.json` +
`GLOOP_GATE_STORE` confirmed in `gloop/gates/file.go`; `roster validate`'s
unknown-route/unknown-type rejections confirmed in `pkg/roster/roster.go`;
`DefaultWaveConcurrency = 4` confirmed. `gloop roster --help` run live: matches
the doc's attribution of selection to cadre verbatim.

**`docs/MOCKERY_INTEGRATION.md`** (full re-read): `.mockery.yaml` names exactly
the 7 interfaces the doc's "Generated Mocks" list names, all 7 present in
`test/mocks/`. Copied the doc's usage-example code verbatim into
`pkg/runtime/zzdocguard_example_test.go` and ran it — compiles and passes
(`TestSessionManagerCreate` PASS), then removed the file.

## `config show`'s three states, run live (item 5)

Valid config → `configExists: true`, provider/model populated. Malformed
config (`max_iterations = "not-a-number"`) → `configExists: true`, `message`
names the load error, `provider`/`model` empty — no boolean/message
contradiction. Absent path → `configExists: false`, `message: "no gloop
config at that path..."`. No payload contradicts itself in any state.

## `--config` table and positional trap, run live (items 2–3)

`config show --config <path>` reports the path + provider/model (honoured).
`status --config <path>` reports `configPath: null` (silently ignored).
`gate list --config <path>` prints the subcommand's usage line (rejected).
`gloop dispatch --config x.toml plan.json` fails with `failed to read plan
file: open --config: no such file or directory`, verbatim as the README
quotes it; `gloop dispatch plan.json --config x.toml` (config after plan)
works.

## Help-text fixes (item 4)

No `gloop gloop` anywhere in source or `--help` output. Every `#` comment in
README's bash blocks is immediately followed by a real command. `gloop select`
and `gloop roster plan` appear in the tree only once, as a code comment
(`roster.go:156`) recounting removal history — not in any error or help
string. `gloop roster --help` run live: says selection is cadre's, not
gloop's.

## Scoping decision (item 1)

23 files under `docs/` + README.md; 4 live + the index (`docs/README.md`)
+ 22 records = matches. `grep -L` for the historical-record banner across all
22 records: zero misses. Spot-checked three — `docs/HYGIENE-FIX-PLAN.md`,
`docs/PLANNING/02-implementation-plan.md`, `docs/PHASE6_IMPLEMENTATION_SUMMARY.md`
— each carries the banner as the second line of the file, before any
substantive content, explicitly redirecting to README/ARCHITECTURE for current
truth. The division holds: a record makes no present-tense claim a reader
would act on without first passing a banner that says otherwise.

## Residue — noted, not scored against AC-3b

- **`cmd/gloop/cmd/root.go`'s help `Long` text** ("...It provides capabilities
  for selecting agents...") contradicts the now-established fact that
  selection is cadre's — the same class of claim round 8 fixed in
  `docs/ROSTER.md`. But no live document quotes or reproduces this string
  (checked: `grep -n "selecting agents\|comprehensive CLI tool" README.md
  docs/*.md` → no hits), so no *documentation* claim is false here — the
  binary's own help text is wrong about itself, which is adjacent to but
  outside AC-3b's scope (docs held against the binary, not the binary's
  self-description). `TestNoLiveDocumentClaimsGloopSelects` does not scan
  `--help` output, only markdown files — a guard-coverage gap, not a doc
  falsehood, since nothing in the audited document set says this.
- **The selection-claim guard's escape clause is broad**: any line containing
  the substring "not gloop" anywhere is exempted, not just lines where that
  phrase disclaims the specific selection claim on that line. No live
  document currently exploits this — mutation testing above used a sentence
  without "not gloop" and the guard caught it correctly — but a future
  sentence like "X, not gloop's concern" sitting next to an unrelated false
  "gloop selects" clause on the same line would slip through undetected. A
  guard that could be evaded by a change nobody has made, not a present
  falsehood.

## Verdict

Zero new false claims found this round, after reading all six live documents
end to end (two of them — `docs/README.md`, `docs/ROSTER_PEER_EXCHANGE.md` —
for the first time this thoroughly) and re-running every command, sample, and
table the brief called out. Both round-8 guards mutation-verified to fail for
the stated reason. Full suite, both `go vet` configurations, and a
`CGO_ENABLED=0` build+test all green. The trend across nine rounds — 19, then
several, several, several, several, 4, 4, 1, 0 — bottomed out. The two
residue items are guard-coverage gaps and a self-description bug in the
binary, not falsehoods in the six documents this criterion scopes.

AC-3b: every other claim in gloop's documentation holds against the binary.

VERDICT: PASS
LANE: full
CLAIMS_CHECKED: 24
EVIDENCE:
EVIDENCE AC-3b-round8-fixes-confirmed | CP-3v | PASS | git diff 7a5a3dd..bd345bc shows exactly the claimed ROSTER.md rewrite and README table dedup; both landed as described. | docs/ROSTER.md; README.md:128-133; git diff output this session
EVIDENCE AC-3b-guard-selects-mutation | CP-3v | PASS | TestNoLiveDocumentClaimsGloopSelects reintroduces round 8's exact false sentence into docs/ROSTER.md and fails, naming file/line/text; restored clean. | internal/docguard/help_text_test.go:1254; command output this session
EVIDENCE AC-3b-guard-duprow-mutation | CP-3v | PASS | TestNoLiveDocumentTableRepeatsARow reintroduces a second pkg/govplan/ row into README.md and fails, naming both line numbers; restored clean. | internal/docguard/help_text_test.go:1283; command output this session
EVIDENCE AC-3b-guard-configshow-mutation | CP-3v | PASS | TestConfigShowNeverContradictsItself's own valid fixture broken (wrong model string) and the test fails "the valid fixture did not load," not a silent pass; restored clean. | internal/docguard/help_text_test.go:617-657; command output this session
EVIDENCE AC-3b-guard-livelist-mutation | CP-3v | PASS | TestTheLiveListInTheIndexMatchesThisGuard fails when ROSTER_PEER_EXCHANGE.md's entry is stripped from docs/README.md's live list, naming the mismatch; restored clean. | internal/docguard/help_text_test.go:591-606; command output this session
EVIDENCE AC-3b-full-suite-both-vets-green | CP-3v | PASS | go build, go vet, go vet -tags integration, CGO_ENABLED=1 go test ./... all clean (37 packages, 0 fail); internal/docguard's 17 top-level guards all pass. | command output this session
EVIDENCE AC-3b-cgo-disabled-claim-run | CP-3v | PASS | README's "builds and tests with CGO_ENABLED=0" claim actually run: CGO_ENABLED=0 go build ./... and go test ./pkg/persistence/... both green. | README.md:131; command output this session
EVIDENCE AC-3b-roster-peer-exchange-mechanism | CP-3v | PASS | Every mechanism claim in docs/ROSTER_PEER_EXCHANGE.md (cap 4000, NO CHANGE token, peer delimiters, truncation marker, setters, CommunicationMode, executed_mode, ≥2-member eligibility) matches pkg/dispatch/peer_exchange.go read directly; stale select.go/select-command mentions are in the doc's historical Files/Test-plan sections, dated before selection was removed. | docs/ROSTER_PEER_EXCHANGE.md; pkg/dispatch/peer_exchange.go
EVIDENCE AC-3b-config-flag-table-live | CP-3v | PASS | config show honours --config, status silently ignores it (configPath: null), gate list rejects it with usage text — all three buckets run live and match the README table. | README.md:180-205; command output this session
EVIDENCE AC-3b-positional-trap-live | CP-3v | PASS | gloop dispatch --config x.toml plan.json fails with the README's verbatim quoted error; plan.json --config x.toml (config after plan) works. | README.md:212-215; command output this session
EVIDENCE AC-3b-config-show-three-states | CP-3v | PASS | Valid/malformed/absent config each produce a self-consistent payload (configExists matches message) via direct binary runs. | command output this session
EVIDENCE AC-3b-help-text-fixes-hold | CP-3v | PASS | No "gloop gloop" in source or --help; every README bash comment precedes a real command; "gloop select"/"gloop roster plan" appear only as a code comment recounting removal history, never in help/error text; gloop roster --help attributes selection to cadre live. | cmd/gloop/cmd/roster.go:156; command output this session
EVIDENCE AC-3b-scoping-defensible | CP-3v | PASS | 23 docs/*.md + README = 4 live + index + 22 records; all 22 carry the historical-record banner (grep, zero misses); 3 spot-checked (HYGIENE-FIX-PLAN, PLANNING/02-implementation-plan, PHASE6_IMPLEMENTATION_SUMMARY) each disclaim current-tense truth in their second line. | docs/*.md; command output this session
EVIDENCE AC-3b-mockery-doc-compiles | CP-3v | PASS | .mockery.yaml's 7 interfaces match test/mocks/ exactly and the doc's Generated Mocks list; the doc's usage example compiled and run verbatim (TestSessionManagerCreate PASS). | docs/MOCKERY_INTEGRATION.md; pkg/runtime (temp test file, removed)
EVIDENCE AC-3b-architecture-package-map | CP-3v | PASS | All 21 packages in docs/ARCHITECTURE.md's package map exist on disk; "single routing engine" and file-watcher claims confirmed in pkg/catalog source. | docs/ARCHITECTURE.md; pkg/catalog/match.go:35; pkg/catalog/catalog.go
EVIDENCE AC-3b-roster-md-remaining-claims | CP-3v | PASS | catalog.MatchRoutes uncalled outside a comment and the docguard test itself; active_recipes is dispatch.go's only Metadata read; gate error strings, gates.json path/env, roster validate's rejection rules, and DefaultWaveConcurrency=4 all confirmed against source. | docs/ROSTER.md; cmd/gloop/cmd/dispatch.go:212; pkg/dispatch/dispatcher.go
EVIDENCE AC-3b-root-help-text-not-a-doc-claim | CP-3v | PASS(note) | cmd/gloop/cmd/root.go's help text says gloop provides "capabilities for selecting agents," contradicting the established fact — but no live document quotes this string (grepped, zero hits), so no documentation claim is false; flagged as residue, not an AC-3b failure. | cmd/gloop/cmd/root.go:34
FAILURES:
(none)
FIX_HINTS:
(none — see Residue for two optional follow-ups: extend TestNoLiveDocumentClaimsGloopSelects to also scan --help Long strings in cmd/gloop/cmd/*.go, or fix root.go's help text directly; and narrow the guard's "not gloop" escape clause to require the disclaiming phrase adjacent to the matched claim rather than anywhere on the line)
