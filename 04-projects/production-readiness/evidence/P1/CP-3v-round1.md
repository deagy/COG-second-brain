# P1 verification — AC-1, AC-2, AC-3

Repositories inspected in place, read-only. All four remain `git status --porcelain` clean after this run (confirmed).

## AC-1 — no repository claims a licence it does not carry — PASS

| Repo | `gh repo view` licenseInfo | Self-claim in own docs | Verdict |
|---|---|---|---|
| cadre | apache-2.0 | `packaging/plugin-README.md:80`, `plugin/README.md:152`, `plugin/suite/README.md:82` — all say "Apache-2.0" | match |
| cadre-kernel | apache-2.0 | none found (repo has no README.md; only `SECURITY.md`, which makes no licence claim) | no claim = no mismatch |
| recall | MIT | `GOVERNANCE.md:53` — "Recall is licensed under the [MIT License]" | match |
| gloop | null (private, no licence) | `README.md:5` — "carries no licence"; `README.md:509` — "This repository carries no licence" | match |

recall's other hit, `CHANGELOG.md:229-232`, reads: *"CI license check: `go-licenses` misclassifies the BSD-3-Clause LICENSE of `modernc.org/mathutil` (transitive dependency of `modernc.org/sqlite`)..."* — independently confirmed this is a statement about a transitive dependency's licence, not a claim about recall itself. Build record's characterization of this line is accurate.

gloop's README (`:7`) also confirms the badges were removed, not left dangling — checked directly below (AC-3).

Broader sweep: grepped all four repos' `*.md` for `MIT|Apache|BSD|GPL|MPL|ISC|Unlicense` license-name patterns and manually reviewed every hit. No conflicting self-claims found in cadre (the ~2000 raw "licen[sc]e" hits in cadre are agent-role-definition prose about handling license *review* as a policy topic — e.g. `provider/roles/engineering/dependency-remediation-implementer/AGENT.md:11` — not assertions about cadre's own licence).

## AC-2 — nothing installable resolves an unlicensed dependency — PASS

Read `internal/generators/plugin_generation.go` (2407 lines), `install.sh` (345 lines), `install.ps1` (308 lines) directly rather than trusting the build record. Extracted every URL/domain (`grep -noE 'https?://...'` and a broader domain-suffix sweep for `.com|.org|.io|.dev|.net`):

- `install.sh:4`, `install.sh:24`, `install.sh:121` → `github.com/deagy/cadre` (self-clone), `raw.githubusercontent.com/deagy/cadre/main/install.sh`
- `install.ps1:30,49,92,94` → same, `github.com/deagy/cadre.git`
- `plugin_generation.go:37` → `registerURL = "https://github.com/deagy/cadre"`
- `plugin_generation.go:283` → `BASE="https://github.com/deagy/cadre-kernel/releases/download/v$AGENTIC_SDLC_VERSION"` (the kernel shim fetch)
- `plugin_generation.go:460-483` → `https://github.com/deagy/cadre/releases/download/cli-v$VERSION/...`
- `plugin_generation.go:1635, 2402` → prose/error text pointing at `github.com/deagy/cadre[-kernel]`

No other host appears anywhere in these three files — no npm/pip/go-proxy/docker/registry references, no third-party domain. **The build record's set of two (`cadre`, `cadre-kernel`) is independently confirmed complete**, not merely repeated. Both carry a licence (Apache-2.0, per AC-1 table above). AC-2 holds.

## AC-3 — gloop's self-description is true of gloop — PASS (README strictly), with an adjacent defect flagged below

- Badges requiring public indexing: confirmed absent. `README.md:7` only *narrates* their prior removal ("It previously described itself as an SDK, with badges for Go Report Card, pkg.go.dev and an MIT licence... They are gone"); no live badge markup remains anywhere in the file.
- No link to `pkg.go.dev/github.com/deagy/gloop`: confirmed. The only `pkg.go.dev` mentions are `README.md:7` (historical, in the removal narrative) and `README.md:65` ("pkg.go.dev cannot index a private module" — a true statement, not a link to the 404).
- No remaining licence claim: confirmed, `README.md:509` states no licence, consistent with AC-1.
- Grepped README.md itself for `select`/`roster plan`: only legitimate references remain — `gloop roster show`/`gloop roster validate` (both real, confirmed live in `--help` below), and `cadre select` (`README.md:396,442`, a different tool's command, correctly attributed to cadre not gloop).

**On README.md's own text, AC-3 passes.**

### Defect found outside README.md's literal scope (verification steps 4-6)

The task also asked me to check "LIVE documents" beyond the README and to run the CLI. Both surfaced a real gap the build record's claim of "five live documents rewritten" does not fully cover:

- **`docs/ROSTER.md` is internally self-contradictory.** Its top banner (lines 3-10) says *"Removed. `gloop roster plan` and `roster.Select` are gone, along with `gloop select` and `pkg/selector`."* But the body below still teaches the removed commands as current, working usage: `docs/ROSTER.md:58` ("When `[roster]` is absent, `gloop select` uses the native catalog behavior"), `:68-77` (a full `gloop roster plan /path/to/cadre-roster --task ... > plan.json` example, including a git-remote variant), `:89` ("`gloop select` uses the roster automatically when the config has `[roster].path`"), `:208` ("`gloop select --verbose` prints each fired recipe to stderr"). None of this reflects the CLI as it now behaves (verified below).
- **`docs/ARCHITECTURE.md:81`** still documents `gloop select <task>` in present tense as an existing command ("resolves which agents the catalog routes a task to, without calling a provider"), with no removal notice anywhere nearby.
- **`docs/ROSTER_PEER_EXCHANGE.md:88`** still states "`gloop select --verbose` reports the executed mode per fired recipe" in present tense.
- `CHANGELOG.md` is clean — its `gloop select`/`roster plan` mentions are correctly framed as historical `[Unreleased]`/past-version entries (e.g. `CHANGELOG.md:12`), which is appropriate for a changelog.
- **CLI help confirms the commands are actually gone**: `go run ./cmd/gloop --help` lists only `config, dispatch, gate, handoff, init, roster, run, session, status` — no `select`. `go run ./cmd/gloop roster --help` lists only `show, validate` — no `plan` — and states "Route selection and dispatch-plan generation are cadre's, not gloop's." So the CLI itself is correctly fixed; three of the five "live" docs were not fully swept to match it.
- Minor: `cmd/gloop/cmd/root.go:35` still has an orphaned example header `# Select agents for a task` with no example line under it (root `--help` output reproduces this dangling comment) — residue of an incompletely removed example block, not a false claim per se but evidence the sweep missed spots.

This does not falsify AC-3 as literally scoped (README.md only), but it does falsify the build record's broader claim that all five "live" documents were made consistent with the removal — `docs/ROSTER.md`, `docs/ARCHITECTURE.md`, and `docs/ROSTER_PEER_EXCHANGE.md` were not.

### Removal-safety checks (verification step 4) — all pass

```
cd /home/deagy/sdk/gloop
go build ./...   # exit 0, no output
go vet ./...     # exit 0, no output
go test ./...    # exit 0, all packages ok or [no test files]
```

- `pkg/selector` directory: does not exist (confirmed via `ls`).
- `catalog.MatchRoutes` still exists: `pkg/catalog/match.go:37`.
- `pkg/roster` still exists and `pkg/config` genuinely depends on it: `pkg/config/config.go:15` and `pkg/config/roster_test.go:11` both `import "github.com/deagy/gloop/pkg/roster"`.
- No live `roster.Select` function remains (`grep -rn "func Select" pkg/roster/` empty). The one surviving `selector.Select`/`roster.Select` text hit in code is `pkg/tenant/catalog.go:92`, a deliberate negative comment ("Not deprecated alongside selector.Select and roster.Select, deliberately.") — not a functional reference.

### `--provider`/`--model` false-claim fix (verification step 6) — confirmed fixed

`go run ./cmd/gloop dispatch --help` shows only `-v/--verbose`, `--config`, `--knowledge` — no `--provider`/`--model`. The build record's admission that it introduced then corrected this false claim checks out against the live binary.

## CI status (all four repos)

```
deagy/cadre                  fd2c2295  success run 33586252288
deagy/cadre-kernel           8da1b135  success run 33629166510
deagy/recall                 3ee2795f  success run 33537575047
deagy/gloop                  81b46e01  success run 33630353829
```

## Repo cleanliness (post-verification)

`git status --porcelain` empty in all four of `/home/deagy/sdk/{cadre,cadre-kernel,recall,gloop}` — no edits made during this verification pass.

## Verdicts

- **AC-1: PASS**
- **AC-2: PASS**
- **AC-3: PASS** (strictly, on README.md's own claims) — flag: `docs/ROSTER.md`, `docs/ARCHITECTURE.md`, `docs/ROSTER_PEER_EXCHANGE.md` still contain present-tense descriptions of `gloop select` / `gloop roster plan` that the CLI no longer supports, contradicting the build record's "five live documents rewritten" claim (CP-3-build.md). Fix direction: complete the doc sweep in those three files — either delete the stale usage sections or replace them with the same "Removed, routing lives in cadre" treatment `docs/ROSTER.md`'s own banner already states but its body doesn't follow through on.
