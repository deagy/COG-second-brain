# CP-3v round 5 — production-readiness P6, AC-3b

gloop HEAD `7f7406f`, verified against a fresh clone at
`/tmp/claude-1000/gloop-verify5` (built binary
`/tmp/claude-1000/gloop-verify5-bin`). Workspace left clean; all mutations
made this session were reverted.

## Round 4's two fixes, by mutation — both hold

**`TestDispatchHasNoUnlistedSpecialCase`**: reproduced round 4's exact attack
(a `smuggled` branch in `execute()` before the `args[0] == "help"` check,
special-cased outside `AddCommand`). The rebuilt binary ran `gloop smuggled`
and silently accepted `--config`, same as round 4 found. This time
`TestDispatchHasNoUnlistedSpecialCase` fails, naming the exact literal:
*"execute() special-cases \"smuggled\" before consulting the command table."*
Also confirmed the guard's own stated fail-loud behavior: renaming `execute`
fails with *"execute() is gone or renamed; this guard is checking nothing"*
rather than passing silently.

**Provider-list guard**: `TestTheProviderListNamesEveryProvider` now reads
`IsKnownProviderType`'s case clause (`pkg/types/provider.go:163`, all six
constants) and checks both the Multi-Provider bullet and the `config.toml`
example's inline comment against it. README's comment now reads
`# anthropic | openai | google | mistral | cohere | http` — all six. Full
suite green on the unmutated tree (12 tests, one legitimate skip).

## New finding — a guard-evasion note, not a doc falsehood

Replacing the `if args[0] == "help"` special case with a `switch args[0] {
case "smuggled2": ...}` block reproduces the exact same undetected-dispatch
bypass (`gloop smuggled2` runs, ignores `--config`, trips no guard) — and
`TestDispatchHasNoUnlistedSpecialCase`'s own doc comment states this
precisely as its limit ("a switch, a map lookup, a helper"). Nobody has
written this branch in the tree today; `execute()` contains no such switch.
This is the fourth round's category of finding, correctly declining to
recur as a fifth: a bounded, named gap in a regex-over-source-text guard,
not a false claim any reader can currently observe.

## New finding — AC-3b failure, `docs/ARCHITECTURE.md` (live document)

`docs/ARCHITECTURE.md` line 26 (the "Core runtime" box) and line 53 (the
Package map table) both list gloop's provider runtimes as
`anthropic, openai, google, mistral, http` — five of the six
`IsKnownProviderType` accepts, omitting **cohere**. `pkg/runtime/cohere`
exists and `pkg/runtime/registry.go` imports it alongside the other five.
`docs/README.md` names `ARCHITECTURE.md` explicitly as one of the four
live documents, "kept true against the binary" — this is not a record.

This is the same provider-drift defect the phase has now fixed three times
(README bullet, README config.toml comment), recurring a fourth time in a
document neither guard reads. `TestTheProviderListNamesEveryProvider` only
touches `README.md`.

## New finding — AC-3b failure, `README.md` Metrics & Monitoring example

README.md:325-338's code sample does not compile against the tree:

```go
metrics := logging.NewMetricsCollector()          // README.md:332
metrics.RecordCounter("provider_call_count", 1)   // README.md:335
metrics.RecordHistogram("provider_call_latency_ms", latency) // :336
metrics.RecordGauge("active_sessions", 5)         // :337
```

`pkg/logging/metrics.go:53` declares
`func NewMetricsCollector(config *MetricsCollectorConfig) *MetricsCollector`
— one required argument, not zero. `*MetricsCollector` has no
`RecordCounter`/`RecordHistogram`/`RecordGauge` methods at all (`grep -rn`
across the whole tree: zero matches, including in non-test source); the
real methods are `IncrementCounter`, `SetGauge`, `ObserveHistogram`
(`pkg/logging/metrics.go:67,92,110`), each taking a `labels
map[string]string` argument the sample never supplies. Pasted this exact
snippet into a throwaway module against the checkout via `replace`:

```
./main.go:6:13: not enough arguments in call to logging.NewMetricsCollector
	have ()
	want (*logging.MetricsCollectorConfig)
./main.go:7:10: metrics.RecordCounter undefined (type *logging.MetricsCollector has no field or method RecordCounter)
./main.go:8:10: metrics.RecordHistogram undefined (type *logging.MetricsCollector has no field or method RecordHistogram)
./main.go:9:10: metrics.RecordGauge undefined (type *logging.MetricsCollector has no field or method RecordGauge)
```

The adjacent "Predefined Metrics" table (the eight metric name/type/
description rows) is separately correct — every name matches a
`Metric*` constant in `pkg/logging/metrics.go:212-219` — so CP-3-build.md's
claim that "all eight documented metrics" held is right about the table
and silent about the code sample sitting directly above it, which does
not.

## Everything else checked and holding

- **`--config` table, every row run directly** (not read from source): all
  three Honoured rows (`config setup`, `config show`, `config update`)
  confirmed by writing/rewriting a real file and reading it back; both
  Ignored rows (`handoff list`, `status`) confirmed silent (no error,
  `configPath: null`); all thirteen Rejected subcommands run with a valid
  positional argument *and* `--config`, each producing the usage/rejection
  error instead of proceeding — ruling out the round-2 shape where a
  rejection was really unrelated argument validation.
- **Positional trap**: `gloop dispatch --config x plan.json` and
  `gloop run --config x plan.json` both emit
  `Error: failed to read plan file: open --config: no such file or directory`,
  verbatim as quoted; `plan.json --config x` order reaches a different,
  later error in both, confirming the flag is read that time.
- **`config show`'s three states**: valid/malformed/absent all produce
  distinct, self-consistent JSON; no boolean/message contradiction.
  `TestConfigShowNeverContradictsItself`'s own fixture-validity check
  mutated (broke the "valid" fixture's model value) — fails loudly with
  *"the valid fixture did not load... this test would then be asserting
  nothing about the honoured path"* rather than passing over a fixture that
  quietly stopped proving anything.
- **`TestTheLiveListInTheIndexMatchesThisGuard`**: deleted `docs/README.md`'s
  MOCKERY_INTEGRATION.md entry from the live list — fails with
  *"liveDocs names MOCKERY_INTEGRATION.md but docs/README.md's live list
  does not."*
- **Records**: `TestEveryRecordSaysItIsOne` logs 22; spot-checked
  `PHASE1-REVIEW.md`, `ENHANCEMENT_PLAN.md`, `SPEC-...md` directly — each
  opens with the "Historical record, not a description of the shipped
  system" banner.
- **Help-text fixes**: `gloop --help` opens `Usage: gloop` (no doubling);
  `--help` and `roster validate` output grepped for `gloop gloop`,
  `select agent`, `roster plan`, `select` — none found.
- **Plugin interface, `types.Streamer`**: both README code blocks match
  `pkg/plugin/plugin.go` and `pkg/types/provider.go:63-72` verbatim.
- **Web UI**: `NewWebUI`/`Start`/`Token`/`Addr`/`AddSession`/`UpdateSession`/
  `RemoveSession`/`GetSessions` all present with matching signatures;
  `/api/sessions`, `/api/metrics`, `/health` all registered in
  `pkg/webui/webui.go:129-131`; loopback-only claim matches
  `ErrNonLoopbackListen` and `isLoopbackHost`.
- **`gloop/{orchestrate,loops,gates,handoff,context,logging,metrics}`**
  (ARCHITECTURE.md's Layers/Package-map, not to be confused with the
  root-level `pkg/`): all seven directories exist under `gloop/`.
- **`pkg/govplan`**: exists, `BlockedByHumanGate`/`ErrHumanGate` match the
  "refuses to execute past a human gate" claim in both README and
  ARCHITECTURE.md.
- **`docs/ROSTER.md`**: `gloop roster --help` lists exactly `show` and
  `validate`; the doc's `gloop roster plan` mention sits inside its own
  "> **Removed.**" note, correctly scoped.
- **`docs/MOCKERY_INTEGRATION.md`**: `.mockery.yaml` on disk matches the
  quoted config verbatim (dir, outpkg, with-expecter, interface list);
  `mockery` binary present at `~/go/bin/mockery`.
- **`docs/ROSTER_PEER_EXCHANGE.md`**: spot-checked `SessionManager.Send`
  signature, `communication_mode`/`fallback` field names, commit `51cb6ff`
  — all present in source/history as described.
- go.mod / go version / Makefile `build`/`install` targets / absence of a
  `LICENSE*` file — all match README's installation section.

## Scope note

Per the round's instruction, the switch-statement variant of the dispatch
bypass is recorded above as a robustness note (guard limit, not a doc
falsehood) and does not count toward the verdict.

VERDICT: FAIL:fixable
LANE: full
CLAIMS_CHECKED: 24
EVIDENCE:
EVIDENCE AC-3b-round4-dispatch-bypass-remutated | CP-3v | PASS | Reproduced round 4's smuggled-subcommand attack verbatim; TestDispatchHasNoUnlistedSpecialCase now fails naming the literal, and fails loudly (not silently) when execute() is renamed. | mutated/reverted /tmp/claude-1000/gloop-verify5/cmd/gloop/cmd/root.go, test output this session
EVIDENCE AC-3b-round4-provider-list-third-occurrence | CP-3v | PASS | TestTheProviderListNamesEveryProvider now reads IsKnownProviderType's case clause and checks both the Multi-Provider bullet and the config.toml comment against it; README's comment names all six providers. | pkg/types/provider.go:157-168, README.md:365, internal/docguard/help_text_test.go:692-752
EVIDENCE AC-3b-switch-based-dispatch-bypass | CP-3v | PASS(note) | Reproduced the same undetected-dispatch shape using a `switch` instead of `if`; the guard's own doc comment names this exact limit ("a switch, a map lookup, a helper") and no such branch exists in the tree today. Robustness observation, not a doc falsehood. | mutated/reverted root.go this session
EVIDENCE AC-3b-architecture-provider-list-omits-cohere | CP-3v | FAIL | docs/ARCHITECTURE.md:26 and :53 (both live-doc, "kept true against the binary" per docs/README.md) list provider runtimes as anthropic,openai,google,mistral,http — omitting cohere, which pkg/runtime/cohere and registry.go's imports confirm is real and built. Neither docguard test reads ARCHITECTURE.md. | docs/ARCHITECTURE.md:24-27,53; pkg/runtime/registry.go:7-12
EVIDENCE AC-3b-metrics-code-sample-does-not-compile | CP-3v | FAIL | README.md:325-338's Metrics & Monitoring Go sample calls logging.NewMetricsCollector() with no args (real signature takes one *MetricsCollectorConfig) and metrics.RecordCounter/RecordHistogram/RecordGauge, none of which exist on *MetricsCollector anywhere in the tree (grep: zero hits). Compiled the exact snippet against the checkout via a replace directive; four compile errors. Real methods are IncrementCounter/SetGauge/ObserveHistogram, each requiring a labels map. | pkg/logging/metrics.go:53,67,92,110; compile output this session, /tmp/claude-1000/gloop-snippet-test
EVIDENCE AC-3b-config-table-every-row-run | CP-3v | PASS | Ran all 18 classified subcommands directly against a real config file: 3 Honoured (config setup/show/update — file written/rewritten and read back), 2 Ignored (handoff list/status — silent, configPath null), 13 Rejected (each given a valid positional arg plus --config, still errors with usage/unexpected-argument rather than proceeding, ruling out the round-2 "unrelated validation" shape). | binary runs this session, /tmp/claude-1000/gloop-verify5-bin
EVIDENCE AC-3b-positional-trap-message | CP-3v | PASS | `gloop dispatch --config x plan.json` and `gloop run --config x plan.json` both emit `Error: failed to read plan file: open --config: no such file or directory` verbatim; reordered form reaches a distinct later error in both. | binary runs this session
EVIDENCE AC-3b-config-show-three-states | CP-3v | PASS | valid/malformed/absent produce distinct, non-contradictory JSON; TestConfigShowNeverContradictsItself's own fixture mutated (bad model value) and fails with the stated self-check message rather than passing. | binary runs + test mutation this session
EVIDENCE AC-3b-live-list-guard-mutation | CP-3v | PASS | Deleted MOCKERY_INTEGRATION.md's entry from docs/README.md's live list; TestTheLiveListInTheIndexMatchesThisGuard fails naming exactly that document. | mutated/reverted docs/README.md this session
EVIDENCE AC-3b-record-banners-and-help-text | CP-3v | PASS | 22 records logged by TestEveryRecordSaysItIsOne; 3 sampled directly all carry the historical-record banner; gloop --help/roster validate output grepped clean for gloop gloop / select agent / roster plan / select. | docs/PHASE1-REVIEW.md, docs/ENHANCEMENT_PLAN.md, docs/SPEC-go-agent-orchestration-library.md, binary runs this session
EVIDENCE AC-3b-plugin-streamer-webui-govplan | CP-3v | PASS | Plugin interface, types.Streamer, WebUI methods/endpoints/loopback guard, and pkg/govplan's human-gate refusal all match README/ARCHITECTURE.md text verbatim in source. | pkg/plugin/plugin.go, pkg/types/provider.go:63-72, pkg/webui/webui.go, pkg/govplan/execute.go,govplan.go
EVIDENCE AC-3b-roster-mockery-peer-exchange-docs | CP-3v | PASS | ROSTER.md's roster plan mention is scoped inside its own Removed note (help output confirms only show/validate exist); MOCKERY_INTEGRATION.md's .mockery.yaml quote matches the file on disk; ROSTER_PEER_EXCHANGE.md's SessionManager.Send signature and communication_mode/fallback fields match source. | docs/ROSTER.md, docs/MOCKERY_INTEGRATION.md, docs/ROSTER_PEER_EXCHANGE.md, .mockery.yaml, pkg/runtime/session.go:413
FAILURES:
- AC-3b | docs/ARCHITECTURE.md provider-runtime list | Lines 26 and 53 list five provider runtimes (anthropic, openai, google, mistral, http), omitting cohere, which is real and built by registry.go. A live document, unguarded by any docguard test.
- AC-3b | README.md Metrics & Monitoring code sample | Lines 325-338 call a zero-arg NewMetricsCollector() and RecordCounter/RecordHistogram/RecordGauge methods that do not exist anywhere in the tree; confirmed by compiling the exact snippet against the checkout (4 errors). A reader following this example cannot make it compile.
FIX_HINTS:
- AC-3b | Fix docs/ARCHITECTURE.md's two provider lists to name all six (anthropic, openai, google, mistral, cohere, http), and consider whether TestTheProviderListNamesEveryProvider's registry-derived check should also cover ARCHITECTURE.md rather than only README.md, given this is the second live document to drift on the exact same fact.
- AC-3b | Rewrite README.md's Metrics & Monitoring example to match pkg/logging/metrics.go's real API: `logging.NewMetricsCollector(nil)` (or a populated config), and `IncrementCounter(name, labels, value)` / `SetGauge(name, labels, value)` / `ObserveHistogram(name, labels, value)` in place of the RecordX methods. Since this is the second time an unguarded code sample in a live document has drifted from source (the plugin/Streamer samples are correct only because nothing has changed them since being written), consider a guard that compiles README's fenced Go blocks, not just greps them.
