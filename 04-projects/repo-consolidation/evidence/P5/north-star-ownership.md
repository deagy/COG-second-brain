# North-star ownership claim — adversarial verification

Claim under test: "Every concern has exactly one owning repository, and the
losing implementations are deleted or archived rather than left running."

Method: independent concern map derived first and saved to
`/tmp/claude-1000/northstar-independent-list.md`, BEFORE reading
`04-projects/agentic-sdlc/planning/repository-ownership-decision.md` or
`04-projects/repo-consolidation/spec.md`. This file is the comparison plus
full evidence.

## Comparison: independent derivation vs. their table

Concerns both sides name, and agree on:

- Lifecycle contracts/kernel — cadre-kernel owns; cadre vendors 3 JSON files
  byte-identical (diffed), with an explicit drift-guard test
  (`kernel_contracts_drift_test.go`). Matches AC-01–04, P1 "verified."
- Knowledge storage/retrieval — recall owns the engine; cadre's
  `internal/knowledge` self-documents as reduced to governance/proposal
  workflow only, no corpus/index/search. Matches the ownership doc's
  "settled 2026-08-29" section and AC-08's intent, though AC-08 itself is
  still marked "pending" in the traceability table (P4 "not started") even
  though the code already looks like the post-migration shape — a
  documentation-lag, not a duplication finding.
- Governed selection vs. execution — cadre owns the governed selection
  record (risk rules, quality gates, fingerprint, schema versioning); gloop
  owns execution-pattern primitives underneath it. The split is real: gloop
  has no concept of risk rules/quality gates/fingerprints, cadre has no
  concept of an execution pattern. Matches the amended "two concerns" section
  and AC-06/AC-07's framing.
- Agent-CLI spawning — cadre only (`SpawnClaudeCodeChild`,
  `spawnChildWithPrompt`); gloop's dispatcher drives LLM provider APIs
  in-process and has zero `os/exec` usage outside `git clone` in
  `pkg/roster/roster.go:371`. **Independently confirmed claim (a) from the
  brief is true**: no rival exists in gloop.
- Tool-loop filesystem/command containment — cadre only
  (`api_runner_sandbox.go`: refused-command list, path-escape checks,
  read/write/iteration caps). gloop's own code comment
  (`pkg/runtime/session.go:466-471`) says the read-only "sandbox" is just
  "no tools at all" — no path confinement, no command allowlist exists
  anywhere in gloop. **Independently confirmed claim (b) from the brief is
  true**: no rival containment engine in gloop.
- Agent definitions/catalog — `cadre/roster` is the sole hand-authored
  source; `plugin/agents/*.md` and `cline-plugins/cline-agents/agents/*.md`
  both carry `generated: true` / `canonical_source:` (or
  `canonicalSource:`/`convertedFrom:`) frontmatter, and CI
  (`.github/workflows/validate.yml:569`, `generate-plugin --check`) fails the
  build on drift. `gloop/pkg/roster` is a loader for an externally-supplied
  file, not a second catalog (its own testdata is a 22-line synthetic
  fixture, confirmed by directory listing). Matches AC-09/AC-10's
  2026-09-01 amendment exactly.

Concerns/artifacts I found that their table does not name:

- **A pipx-installed Python predecessor CLI, live on PATH, implementing the
  exact concern cadre-kernel now owns — not mentioned anywhere in either
  document.** See "Load-bearing finding" below. This is the one gap that
  changes the verdict.
- gloop's generic in-process approval-gate primitive (`gloop/gates`) — not
  named as a concern row at all. Verified it is NOT a duplicate of
  cadre-kernel's G1-G10 lifecycle gates (no forge/GitHub/GitLab client, no
  run-record schema, no versioned gate contract — a bare
  Create/Approve/Reject/Skip state machine). Silent in their table because
  it isn't a conflict, not because it was missed.
- gloop's composition/middleware layer (`orchestrate`, `loops`, `handoff`,
  `tenant`, `ratelimit`, `redact`) — gloop-only, no cadre equivalent, folded
  into their one-line "gloop owns unopinionated orchestration" row without
  itemizing. Coarser grain, not a disagreement.

Their table names one thing I'd folded into a bigger bucket rather than
listed separately: "Knowledge governance" (cadre's `staged_*.go` vs. recall's
`hitl`) as two different concerns (authority vs. accuracy) that should not
merge. Re-reading confirms this distinction is real and correct — not a
disagreement, just something I under-split initially.

## Load-bearing finding: pipx-installed `agentic-sdlc` predecessor

```
$ which -a agentic-sdlc
/home/deagy/.local/bin/agentic-sdlc

$ agentic-sdlc --version
0.13.2

$ cat ~/.local/share/pipx/venvs/agentic-sdlc/pipx_metadata.json | python3 -m json.tool
...
"package": "agentic-sdlc",
"package_or_url": "/tmp/up/agentic_sdlc-0.13.2-py3-none-any.whl",
"package_version": "0.13.2",
```

`agentic-sdlc --help` shows the full G1-G10 lifecycle-gate command surface:
`detect, init, plan, validate, status, approve-from-github(-pr),
approve-from-gitlab(-mr), link-intent/-requirements-from-{github,gitlab}-issue,
create-gate-issues, list-gate-issues, publish-gate-status,
request-gate-reviewers(-gitlab), decide, invalidate, reenter, upgrade, ...` —
the identical concern surface as `cadre-kernel/internal/kernel` (gates.go,
gateissues*.go, gatereviewers*.go, gatestatus*.go, decide.go, reentry.go,
repair.go, githubclient.go, gitlabclient.go).

cadre-kernel's own binary carries the **same command name**, deliberately:

```go
// cadre-kernel/cmd/agentic-sdlc/main.go
// Command agentic-sdlc is the Go lifecycle kernel CLI.
// A separate binary from `cadre`, deliberately. The kernel owns lifecycle
// gate schemas, run-record validation and gate-authority semantics; roster/
// asks and the kernel answers.
```

But that Go binary is **not installed anywhere on this machine's PATH**:

```
$ for d in $(echo $PATH | tr ':' ' '); do find "$d" -maxdepth 1 -iname "agentic-sdlc*"; done
/home/deagy/.local/bin/agentic-sdlc          # <- only the Python 0.13.2 predecessor
```

`cadre-kernel/bin/agentic-sdlc` exists only inside the repo checkout and is a
dev wrapper shell script ("Builds (if needed) and execs the Go implementation
under cmd/agentic-sdlc"), not something on `$PATH`.

This is neither the archived `agentic-lifecycle` repository (different
package name: `portable-agentic-lifecycle`, different console-script name:
`agentic-lifecycle`, confirmed `gh api repos/deagy/agentic-lifecycle` →
`archived: true`) nor anything AC-02 checks (AC-02 only inspects cadre's own
tree for `internal/kernel/`, `cmd/agentic-sdlc/`, `kernel/`, all of which are
in fact absent from cadre — confirmed). It is a third artifact: a leftover
pipx install of cadre's own pre-Go-rewrite Python package (built from
`/tmp/up/agentic_sdlc-0.13.2-py3-none-any.whl`), never covered by any AC in
`spec.md`, never mentioned in the ownership decision doc. Right now, typing
`agentic-sdlc` on this machine invokes the losing implementation; the winning
one is unreachable by that name.

## Seam checks

- recall <-> cadre/internal/knowledge: real seam. cadre imports
  `github.com/deagy/recall v0.3.1`; its own README states plainly what
  remains ("no corpus... no search, no index, no chunk table"). Holds.
- gloop/knowledge/recall <-> recall: real seam, a documented adapter
  (`Store` interface wraps `recallcore`/`recallstore`/`recallembedder`),
  gloop imports `github.com/deagy/recall v0.1.0` as a real dependency, not a
  reimplementation. Holds.
- cadre <-> cadre-kernel: real seam for the *contracts* (vendored + drift
  test) but the seam is not enforced for the *installed binary* — nothing
  prevents (and nothing currently checks for) a stray old build shadowing
  the new one on `$PATH`, which is exactly what has happened.
- cadre <-> gloop selection: real seam per the code (governed record vs.
  execution plan, neither a subset), but the loser's CLI surface
  (`gloop select`, `gloop roster plan`) is still wired to `pkg/selector.Select`
  / `pkg/roster.Select` today — a documented, tracked exception (AC-07/07b),
  not a hidden one.
- cadre <-> gloop gates: real seam (generic in-process primitive vs.
  forge-integrated G1-G10 kernel with schema/run-record). Holds.

## Minor spec-drift note (not scored as a failure)

AC-07's criterion text says "gloop's `Select()` and `catalog.MatchRoutes`
carry Go `Deprecated:` markers." Current code and gloop's own CHANGELOG
explicitly walk this back for `catalog.MatchRoutes`: "An earlier draft of
this entry said it would be removed; that was wrong, and the code never said
so... `catalog.MatchRoutes` is not deprecated and is not going away."
Confirmed by `grep -n "Deprecated" pkg/catalog/*.go` — no hits. AC-07's own
wording is stale relative to a correction gloop's maintainers already made in
the open. Not itself evidence of duplication (AC-07 is still "pending" in the
traceability table, so nothing false is currently being claimed as
"verified"), but whoever closes P3 will need to amend AC-07's text the same
way AC-08 and the selection row were already amended twice.

## Evidence rows

EVIDENCE NORTH-STAR | ownership | PASS | Lifecycle contracts/schemas — cadre-kernel owns; cadre's 3 vendored JSON files are byte-identical with a drift-guard test, no third copy (agentic-lifecycle's schemas were templates, now archived) | cadre/internal/orchestration/kernel_contracts_drift_test.go; diff confirmed identical
EVIDENCE NORTH-STAR | ownership | PASS | Knowledge storage/retrieval engine — recall owns it; cadre/internal/knowledge is reduced to a governance/proposal wrapper with no index or search of its own | cadre/internal/knowledge/README.md:1-9; cadre/internal/retrieval/store.go imports github.com/deagy/recall/{core,embedder,govern,store}
EVIDENCE NORTH-STAR | ownership | PASS | Governed agent selection (risk rules/quality gates/fingerprint) — cadre owns it; gloop has no equivalent concept | cadre/internal/selector/*.go (concept absent from gloop/pkg/selector, gloop/pkg/catalog)
EVIDENCE NORTH-STAR | ownership | PASS | Agent-CLI spawning — cadre only (SpawnClaudeCodeChild, spawnChildWithPrompt); gloop has no os/exec except `git clone` | cadre/internal/orchestration/dispatch_core_phase3_spawn.go:34; cadre/internal/orchestration/spawn_child.go; grep os/exec across gloop → only pkg/roster/roster.go:371
EVIDENCE NORTH-STAR | ownership | PASS | Tool-loop filesystem/command containment — cadre only (refusedCommands, path escapes, byte caps); gloop's ToolExecutor is a bare handler registry with no confinement | cadre/internal/orchestration/api_runner_sandbox.go:36-42; gloop/pkg/runtime/session.go:466-471
EVIDENCE NORTH-STAR | ownership | PASS | Agent role catalog — cadre/roster is sole hand-authored source; plugin/agents, cline-plugins copies are generated+CI-drift-checked; gloop/pkg/roster is a loader, not a claimant | cadre/plugin/agents/halt-authority.md:1-8 (generated: true, canonical_source); cadre/.github/workflows/validate.yml:569 (generate-plugin --check)
EVIDENCE NORTH-STAR | ownership | PASS | Predecessor repo agentic-lifecycle — genuinely archived, not consumed by any of the 4 live repos | gh api repos/deagy/agentic-lifecycle → archived:true, pushed_at 2026-08-29; no import/path reference found in cadre, cadre-kernel, recall, gloop
EVIDENCE NORTH-STAR | ownership | PARTIAL | Governed selection's losing gloop implementation (pkg/selector.Select, pkg/roster.Select) — still live, compiled, wired into `gloop select` / `gloop roster plan`, not deleted or archived; disclosed and tracked (AC-07/AC-07b), not hidden | gloop/pkg/selector/doc.go:3-4 "Deprecated: ... Select is removed at gloop's next major release"; gloop/cmd/gloop/cmd/select.go calls selector.Select
EVIDENCE NORTH-STAR | ownership | FAIL | Lifecycle-gate CLI (G1-G10, forge integration) — cadre-kernel is the intended sole owner, but a pipx-installed Python predecessor `agentic-sdlc==0.13.2` implementing the same command surface is live on $PATH; the Go binary of the same name is not installed anywhere on this machine, so the losing implementation is neither deleted nor archived and is the only one reachable by its own name | `which -a agentic-sdlc` → only /home/deagy/.local/bin/agentic-sdlc (pipx, built from /tmp/up/agentic_sdlc-0.13.2-py3-none-any.whl); cadre-kernel/cmd/agentic-sdlc/main.go (not installed on PATH)

## Verdict

FAIL:fixable — uninstall the orphaned predecessor and reinstall/alias the
kernel's own binary under the same name: `pipx uninstall agentic-sdlc`, then
build and install `cadre-kernel`'s `cmd/agentic-sdlc` (e.g. `go install
github.com/deagy/cadre-kernel/cmd/agentic-sdlc@latest` or a pipx/brew
equivalent once the kernel publishes a release) so that `agentic-sdlc` on
`$PATH` resolves to the winning implementation. This is a machine-hygiene
fix, not a design decision, and does not require reopening any AC — it
requires adding a check for it (e.g. an AC or CI/onboarding step that fails
if a non-kernel `agentic-sdlc` shadows the released one) so the same drift
can't recur silently, which is exactly the class of defect this whole
consolidation effort was started to stop.

Everything else independently checked — the two claims singled out in the
brief (gloop has no agent-CLI-spawning rival; cadre's api_runner sandbox has
no gloop rival because gloop has no filesystem/command containment) — held
up under direct code reading, not just under trust of the ownership
document's own prose.
