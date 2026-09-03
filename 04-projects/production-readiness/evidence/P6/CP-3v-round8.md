# CP-3v round 8 — production-readiness P6, AC-3b

gloop HEAD `7a5a3dd`, verified against a fresh clone at
`/tmp/claude-1000/gloop-verify8` (binary at `.../gloop-verify8-bin` via
`make build`). `go build ./...`, `go vet ./...`, `go vet -tags integration ./...`,
and `CGO_ENABLED=1 go test ./...` all green (37 packages, no skips, no
failures) — `internal/docguard`'s full 16-guard suite included. `make build`,
`make vet`, `make integration`, and `make ci` (build+vet+test+coverage, floor
87.6%, actual 87.8%) all ran clean.

## Round 7 fixes re-confirmed by direct observation, not by reading the build record

1. **Architecture diagram** — `README.md`'s "Agent Providers" box now shows all
   six (`Anthropic OpenAI Google Mistral Cohere` in one row, `HTTP (custom)`
   below). Read directly.
2. **Dispatch-plan JSON** — extracted the fenced block after "A dispatch plan
   looks like:" (`README.md:456-471`) and ran it through Python's `json`
   module: parses clean, no `#` comments present.
3. **`docs/ROSTER.md` `metadata.matched_routes`** — the sentence is gone;
   `docs/ROSTER.md:209` now reads "This sentence used to add... a key that
   appears nowhere in this repository," and `grep -rn "matched_routes"
   --include="*.go" .` still returns zero hits.
4. **Roster integration test** — `go test -tags integration ./pkg/roster/`
   ran clean (`ok  pkg/roster  1.842s`); `go vet -tags integration ./...`
   silent. `TestEveryBuildTagStillCompiles` covers this class going forward.

## New for this round — a false claim round 7 flagged but the fix left half-done

**`docs/ROSTER.md:12-16` still says gloop performs roster selection, directly
contradicting the file's own removal banner four lines above it and the CLI's
own help text.** Round 7's finding #3 quoted this exact paragraph as part of
one bundled defect ("the very next paragraph" after the banner); the fix
between round 7 and this round only touched the "Matching semantics" section
and the `matched_routes` sentence (confirmed via `git diff b8ba719..7a5a3dd --
docs/ROSTER.md`) and left this earlier paragraph untouched:

> Gloop can select roles from an external agent roster — a directory of role
> definitions (`AGENT.md`), an agent catalog (`catalog.yaml`), and a routing
> table (`orchestration/routing.json`) — instead of (or in place of) its
> bundled preset catalog... Selection against a roster is local-only: no
> provider call and no API key are required.

Four lines above it, the file's own banner: "**Removed.** `gloop roster plan`
and `roster.Select` are gone... Route selection and dispatch-plan generation
are cadre's." Ran `gloop roster --help` live: "Route selection and
dispatch-plan generation are cadre's, not gloop's: read the governed plan
cadre produces with pkg/govplan." Checked the only place `cfg.Roster` is read
at runtime (`grep -rn "cfg.Roster\|\.Roster\b" pkg/dispatch pkg/catalog
cmd/gloop`): it resolves to one line, `cmd/gloop/cmd/roster.go:180`, used only
by `roster show`/`roster validate` to locate a checkout to print or validate —
no selection code path exists anywhere gloop runs. The paragraph's own claim
("Gloop can select roles... instead of... its bundled preset catalog") is
false; the CLI's own help text says the opposite, in the same file's own
section that already got fixed for the same reason.

Unguarded: no guard reads free prose for "Gloop can select" claims —
`TestEveryProviderEnumerationNamesEveryProvider` reads provider lists,
`TestTheConfigFlagTableMatchesTheBinary` reads the generated table, neither
reads this paragraph. A reader hits this today: it is the second paragraph of
the file, immediately below the removal banner, before "## Setup".

## Other categories checked this round, all holding

- **Make targets**: `make build`, `make install` (implicit via build path
  check), `make vet`, `make test` (via `make ci`), `make integration`, `make
  ci` all ran and matched README's Testing/Installation sections.
- **Config keys not previously exercised**: `[loop_detection]` and `[roster]`
  are real top-level `Config` struct sections (`pkg/config/config.go:56,67`)
  absent from `README.md`'s `config.toml` example — checked whether this is a
  false omission: `[loop_detection]` is named and described in
  `docs/ARCHITECTURE.md:67`, `[roster]` is documented in full in
  `docs/ROSTER.md:28-58`. Not a false claim — the example just isn't
  exhaustive, and nothing says it is.
- **Config example loads**: re-extracted README's `config.toml` block fresh
  this round, ran `gloop config show --config <extracted file>` — reports the
  correct provider/model, `configExists: true`.
- **Env vars**: `GLOOP_CONFIG` (`pkg/config/config.go:679`,
  `cmd/gloop/cmd/roster.go:187`), `GLOOP_GATE_STORE`
  (`gloop/gates/file.go:21`), `GLOOP_ROSTER_REPO`
  (`pkg/roster/contract_test.go:8,27,103` — a test-only var, documented only
  for the integration-test command, matches), `ANTHROPIC_API_KEY`,
  `OPENAI_API_KEY` — all resolve to real `os.Getenv`/default-const sites.
- **Links and anchors**: every relative link across all five live documents
  resolves to a real file (scripted check); no broken in-document `#anchor`
  links found in any of them.
- **Counts**: all 8 rows of README's Predefined Metrics table
  (`provider_call_latency_ms` etc.) each grepped to exactly one (or two, for
  `retry_count`) real string-literal site in non-test Go source.
- **Defaults/claims re-checked**: Roadmap's persistence line
  (`pkg/persistence/sqlite.go` — `PRAGMA journal_mode=WAL` confirmed,
  `pkg/persistence/doc.go` describes FileStore/SQLiteStore as claimed),
  `pkg/observability/{tracer,metrics,interceptor}.go` all exist as the
  Roadmap's tracing line claims, `session list|show|delete` wired in
  `cmd/gloop/cmd/session.go` as claimed.

## Residue — noted, not scored against AC-3b

- **`README.md`'s Package Structure table lists `pkg/govplan/` twice**
  (lines 131-132), with two different but individually-true descriptions.
  `git blame` traces the second row to `81b46e0` (2026-09-02), the same
  commit that produced round 7's other findings — so it predates this round
  but was never caught, because no guard reads markdown-table rows for
  duplication and neither sentence is individually false. This is a
  duplicate-row hygiene defect, not a false claim — flagging for the fix
  pass since it sits one paragraph from a finding that is being fixed
  anyway, but not counted as an AC-3b failure since nothing a reader is told
  is wrong.
- **"Test Results: 100% pass rate"** (`README.md`, Test Coverage bullet) —
  true right now (confirmed: full suite green), not a guard-evadable claim
  in the round 7 sense, but also not a claim any guard pins to the binary;
  noted as the kind of claim that goes stale silently rather than loudly.

## Verdict

One false claim found, in a category (contradictory prose left over from a
partially-applied fix) that no prior round's guard reads and that this
round's brief specifically asked to check for residue. It is the same
underlying defect round 7 already named — the fix that landed addressed only
part of what round 7 quoted — so this is not a new kind of claim, but it is a
false statement a reader hits today, sitting in a live document, four lines
below a banner and a working `--help` output that both say the opposite. That
makes it AC-3b-failing rather than a guard-evadable note: nothing needs to
change in the codebase for this to be wrong — it already is.

Bounded and mechanical: delete or rewrite the "Gloop can select roles..." /
"Selection against a roster is local-only..." paragraph (`docs/ROSTER.md:12-16`)
to attribute selection to cadre, matching the fixed "Matching semantics"
section three screens down and the CLI's own help text. No guard exists for
this class (prose contradicting a file's own banner); adding one is a
reasonable fix-hint but not required to close this specific finding.

The `pkg/govplan/` duplicate-row item is real but not a false claim — reported
as a note per the brief's instruction to separate the two kinds.

VERDICT: FAIL:fixable
LANE: full
CLAIMS_CHECKED: 17
EVIDENCE:
EVIDENCE AC-3b-round7-fixes-hold | CP-3v | PASS | Architecture diagram now names all six providers; dispatch-plan JSON block parses clean (verified via Python json module); metadata.matched_routes sentence removed and grep confirms zero hits in tree; go test -tags integration ./pkg/roster/ and go vet -tags integration ./... both clean. | README.md:98-106,456-471; docs/ROSTER.md:209; command output this session
EVIDENCE AC-3b-full-suite-and-guards-green | CP-3v | PASS | go build, go vet, go vet -tags integration, CGO_ENABLED=1 go test ./... all clean (37 packages); make build/vet/integration/ci all clean, coverage 87.8% vs floor 87.6%. | build/test/make output this session
EVIDENCE AC-3b-roster-selection-paragraph-still-false | CP-3v | FAIL | docs/ROSTER.md:12-16 ("Gloop can select roles from an external agent roster... instead of... its bundled preset catalog. Selection against a roster is local-only...") directly contradicts the file's own removal banner 4 lines above and gloop roster --help's live output ("Route selection and dispatch-plan generation are cadre's, not gloop's"). grep of cfg.Roster usage across pkg/dispatch, pkg/catalog, cmd/gloop shows only roster.go:180 (show/validate path-resolution), no selection code anywhere. Round 7 quoted this same paragraph as part of its finding #3; the fix between b8ba719 and 7a5a3dd (git diff) only touched the Matching-semantics section and the matched_routes sentence, leaving this paragraph unchanged. | docs/ROSTER.md:1-21; cmd/gloop/cmd/roster.go:172-187; command output this session
EVIDENCE AC-3b-make-targets-run | CP-3v | PASS | make build, make vet, make integration, make ci all ran clean; make ci reports coverage total 87.8% against floor 87.6%. | Makefile; command output this session
EVIDENCE AC-3b-envvars-hold | CP-3v | PASS | GLOOP_CONFIG, GLOOP_GATE_STORE, GLOOP_ROSTER_REPO, ANTHROPIC_API_KEY, OPENAI_API_KEY each grepped to a real os.Getenv/const site matching the doc that names it. | pkg/config/config.go:679; gloop/gates/file.go:21; pkg/roster/contract_test.go:8,27,103; command output this session
EVIDENCE AC-3b-links-and-anchors-clean | CP-3v | PASS | Scripted check of every relative link and #anchor across README.md + 4 live docs/*.md — all resolve to real files/headings, none broken. | README.md, docs/{ARCHITECTURE,ROSTER,ROSTER_PEER_EXCHANGE,MOCKERY_INTEGRATION}.md; script output this session
EVIDENCE AC-3b-config-toml-example-still-loads | CP-3v | PASS | README's config.toml block re-extracted fresh and loaded via gloop config show --config <file> — reports correct provider/model, configExists true. | README.md:361-408; command output this session
EVIDENCE AC-3b-metrics-and-defaults-hold | CP-3v | PASS | All 8 Predefined Metrics table entries grepped to a real string-literal site; pkg/persistence (WAL pragma), pkg/observability (tracer/metrics/interceptor files), cmd/gloop/cmd/session.go (list/show/delete) all match Roadmap claims. | README.md:345-354,586-592; pkg/persistence/sqlite.go:64; command output this session
EVIDENCE AC-3b-govplan-duplicate-row-note | CP-3v | PASS(note) | README.md's Package Structure table lists pkg/govplan/ twice (lines 131-132) with two individually-true but differently-worded descriptions; git blame traces the second to commit 81b46e0. Not a false claim — a duplication hygiene defect, no guard reads table-row uniqueness. | README.md:131-132; git blame output this session
FAILURES:
- AC-3b | docs/ROSTER.md:12-16 | The paragraph opening "Gloop can select roles from an external agent roster... instead of (or in place of) its bundled preset catalog" and "Selection against a roster is local-only" both claim gloop performs roster-based selection. The file's own removal banner 4 lines above and `gloop roster --help`'s live output both say selection is cadre's, not gloop's; no selection code path exists in gloop (only `roster show`/`roster validate` read `cfg.Roster`). This is the same paragraph round 7 quoted as part of its finding #3; the intervening fix addressed only the Matching-semantics section and the matched_routes sentence, not this paragraph.
FIX_HINTS:
- AC-3b | docs/ROSTER.md:12-16 | Rewrite to attribute selection to cadre, matching the fixed "Matching semantics — cadre's, not gloop's" section further down and the CLI's own help text — e.g. "cadre can select roles from an external agent roster... and hand gloop a self-contained plan" rather than "Gloop can select roles." Consider a guard that flags any live-doc sentence starting "Gloop can select/match/route" outside a historical-record banner, since this is the second time this exact claim has needed correcting in the same file.
