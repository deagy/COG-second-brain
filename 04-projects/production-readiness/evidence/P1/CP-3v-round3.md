# CP-3v Round 3 — gloop docs re-verification

Commit verified: `39c2fc2aab2b0d8ba744d62d4212bd6250ca93eb` (HEAD, matches claim). Repo left clean (`git status --short` empty after all checks).

## AC-3: VERDICT = FAIL:fixable

Round 2's three cited fixes (ARCHITECTURE.md CLI diagram, ROSTER.md tier-pinning section, `warnUnpinnedTiers` removal) are genuinely done. But the same failure mode recurred: fixes touched the cited lines and missed sibling content in the same or sibling files. Three new/surviving defects found by reading whole documents and running the binary, none of which are the two lines already fixed.

### 1. README.md:80 — stale "Selector Engine" in the Architecture diagram (FAIL)

README.md's own `🏗️ Architecture` diagram (separate from `docs/ARCHITECTURE.md`'s, which round 2 did fix) still shows:

```
│  │  Catalog    │  │   Selector   │  │    Dispatch      │  │
│  │  Manager    │  │   Engine     │  │    Controller    │  │
```

as a current "Core Runtime" component, unqualified. This directly contradicts `docs/ROSTER.md:3-4` ("`gloop select` and `pkg/selector`" are "**Removed**") and the source: `pkg/selector` does not exist (`ls pkg/selector` → no such file or directory), and `cmd/gloop/cmd/` has no `select` subcommand. Round 2 fixed ARCHITECTURE.md's diagram but never re-read README.md's separate, near-identical diagram carrying the same stale box.

### 2. docs/ARCHITECTURE.md:45 — package map claims the CLI uses cobra (FAIL)

```
| `cmd/gloop/` | CLI entry point (cobra); the only main package. |
```

False. `cmd/gloop/cmd/root.go` defines a hand-rolled `Command`/`Flag` struct and its own `execute`/`findCommand`/`findAndHelp` dispatch — no `github.com/spf13/cobra` import anywhere (`grep -rln spf13/cobra --include=*.go .` → empty) and no `cobra` entry in `go.mod`/`go.sum`. This is in the *same file* whose diagram (lines 10-15) was fixed and does correctly match `--help` output — the fix corrected the diagram a few lines above and never touched the package-map row a few lines below describing the same package.

### 3. README.md:164-167 — "All commands support ... --config <path>" is false for whole command groups (FAIL)

```
All commands support:
- --help or -h - Show help
- --config <path> - Config file to use ...
- --verbose or -v - Enable verbose logging
```

Verified against the built binary (`/tmp/r3-gloop`, built from HEAD):

| Command | `--config` | `--verbose` |
|---|---|---|
| `gloop run` / `gloop dispatch` / `gloop status` / `gloop config show` | accepted (shown in `--help`) | accepted |
| `gloop gate list` | **rejected**: `Error: usage: gloop gate list [--task <task-id>]` | **rejected**, same error |
| `gloop roster show` / `gloop roster validate` | **rejected**: `Error: usage: gloop roster show [<roster>]` | not shown in `--help`, untested further once rejection confirmed on `--config` |
| `gloop session list` | **rejected**: `Error: usage: gloop session list [--dir <dir> --db <db> --format <table|json>]` | **rejected**, same error |
| `gloop handoff list` | silently ignored (exits 0, no error, flag has no visible effect) | — |

`--help` output for `gate list`, `session show`, `roster validate` (captured this round) lists no `--config`/`--verbose` flags at all — only group-specific flags (`--task`, `--dir`/`--db`, none). The blanket "All commands support" claim is wrong for every leaf command under `gate`, `roster`, `session`, and inconsistent (silent-ignore vs. hard error) for `handoff`. Not one of the two previously-cited defects; this is a documentation claim nobody re-checked against the actual flag parser per subcommand group.

### Checks that passed (no new defect)

- **CLI diagram**: `docs/ARCHITECTURE.md:13`'s subcommand list (`run, dispatch, status, config, gate, handoff, init, roster, session`) matches `/tmp/r3-gloop --help` exactly — 9 commands, both directions, no extra/missing.
- **`warnUnpinnedTiers`**: confirmed gone (`grep -rn "warnUnpinnedTiers|runRosterPlan"` → no hits anywhere).
- **Other dead code (unexported, zero non-test callers)**: swept every unexported func in `cmd/gloop/cmd/*.go` and `pkg/roster/*.go` (101 candidates). All `run*`/`parse*`/`build*` functions turned out to be wired via `RunE: fnName` (no-parens reference my first grep pass missed) or called directly. One genuine new finding: **`loadCatalogForCLI` (`cmd/gloop/cmd/setup.go:217`) has zero callers anywhere in the repo — not even a test.** Same defect class as `warnUnpinnedTiers`, arguably worse (no test hides it at all). Not requested to be fixed by this task's scope statement (task only asked to *report* additional instances), so flagged here rather than fixed.
- **Licence/badge claims**: no MIT/licence badge or Go-Report-Card/pkg.go.dev-index badge reappeared in any `.md` under the repo. README.md's own paragraph explaining their removal (line 7) is the only remaining mention, correctly phrased in the past tense.
- **Build/vet/test**: `go build ./...` clean, `go vet ./...` clean, `go test ./...` — all packages `ok` (`cmd/gloop/cmd`, `pkg/roster`, `pkg/dispatch`, `internal/docguard`, etc.), no failures, no skips beyond normal `[no test files]`.
- `docs/ROSTER_PEER_EXCHANGE.md` — read fully; no mention of `gloop select`, `roster.Select`, `pkg/selector`, or a `--provider`/`--model` flag on any gloop command; internally consistent with ROSTER.md's tier-pinning and gate sections.
- `docs/ROSTER.md`'s tier-pinning section (lines 127-134) — reads correctly now: states plainly there is no request-level `--provider`/`--model` override and that it "lived on `gloop select`, which is gone."

## FIX_HINTS (fixable, bounded)

- README.md:80 — replace the `Selector Engine` box with `Roster Loader` (or drop the third box down to two: `Catalog Manager` / `Dispatch Controller`), matching what ARCHITECTURE.md's fixed diagram now shows for the equivalent layer, or delete this second diagram entirely in favor of linking to ARCHITECTURE.md (there is no reason for README.md to carry a second, drifting architecture diagram).
- docs/ARCHITECTURE.md:45 — drop "(cobra)" from the package-map row, or replace with the actual mechanism ("hand-rolled `Command`/`Flag` dispatch in `root.go`").
- README.md:164-167 — either scope the flag list per command group (top-level commands only) or note explicitly which subcommands don't take `--config`/`--verbose`. Whoever fixes this should re-run `--help` against every leaf subcommand, not just the top-level ones, given the pattern above.
- (optional, not required by this AC) `cmd/gloop/cmd/setup.go:217` `loadCatalogForCLI` — delete, or wire it in if it was meant to replace inline `cfg.LoadCatalog()` calls.

## Evidence commands run

```
cd /home/deagy/sdk/gloop && git log -1 --format="%H %s"   # 39c2fc2a ...
go build -o /tmp/r3-gloop ./cmd/gloop                      # OK
/tmp/r3-gloop --help ; /tmp/r3-gloop <cmd> --help  (all 9 top-level + leaf subcommands)
grep -rn "Selector\|selector" README.md docs/ARCHITECTURE.md docs/ROSTER.md docs/ROSTER_PEER_EXCHANGE.md
grep -rln "spf13/cobra" --include="*.go" .                 # empty
grep -n cobra go.mod go.sum                                 # empty
/tmp/r3-gloop gate list --config /tmp/x.toml                # Error: usage: ...
/tmp/r3-gloop roster show --config /tmp/x.toml              # Error: usage: ...
/tmp/r3-gloop session list --config /tmp/x.toml             # Error: usage: ...
go build ./... && go vet ./... && go test ./...             # all clean/ok
grep -rniE "mit licen[sc]e|go report card|pkg.go.dev/github.com/deagy/gloop" --include="*.md" .
```
