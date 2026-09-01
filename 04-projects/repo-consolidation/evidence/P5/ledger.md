# P5 evidence ledger

## AC-11 — the split pipeline runs end to end

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-11 | CP-5 | PASS | Released kernel `v0.14.2` downloaded from its GitHub release and checksum-verified against `SHA256SUMS` before use — the artifact, not a local build. |
| AC-11 | CP-5 | PASS | It loads cadre's provider bundle: `provider list` → `{"id": "cadre", "version": "0.3.0", "manifest_sha256": …, "catalog_sha256": …}`. |
| AC-11 | CP-5 | PASS | `cadre select` enriched across the repository boundary: **2 gates standalone (G8, G9) → 9 with the kernel (G1…G9)**, each added gate carrying its reason and contributing route. `PATH` scrubbed in every run. |
| AC-11 | CP-5 | PASS | `--require-sdlc` with no kernel exits 1 rather than falling back silently. |
| AC-11 | CP-5 | PASS | `agentic-sdlc --provider <cadre> validate --root <project>` → `{"valid": true, "ready": true, "errors": [], "blockers": []}`, **exit 0**, on a project initialized from cadre's `generic` profile. |

Full transcript: `CP-5-acceptance-AC11.md`.

**The measurement was nearly wrong.** The first run reported `integrated` with no kernel wired, because a pipx-installed `agentic-sdlc 0.13.2` — a Python build predating the Go extraction — was on `PATH`. Scrubbing `PATH` is what made the result mean anything. Second time in two phases that a local environment supplied something a claim did not account for; the first was P4's "recall's full suite green". Left installed at the user's request, recorded here as a hazard.

**A defect it found.** `cadre select --require-sdlc` refuses correctly with no kernel, then names `github.com/deagy/cadre` as where to install one — a repository P1 removed it from. Four operator-facing messages carried the wrong home while the download shim beside them already had the right one. Fixed in `232314fc`.

## AC-09 — the catalog has one publishing home

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-09 | CP-5 | PASS | Every `catalog.yaml` across all four repositories enumerated. One home (`cadre/roster/catalog.yaml`, itself rendered from the per-role sources); two generated copies; two synthetic fixtures; gloop's own 10-route default catalog, a different artifact. `recall` and `agentic-lifecycle` hold none. |
| AC-09 | CP-5 | PASS | **Both drift checks mutation-tested.** Removing one agent from `provider/agent-catalog.json` → `generate-role-metadata --check` names the file, exit 1. Appending a line to `plugin/suite/roster/catalog.yaml` → `generate-plugin --check` names it, exit 1. Restored, both clean. |
| AC-09 | CP-5 | PASS | gloop vendors nothing: `pkg/roster` is a **loader** for an external roster supplied by path, with a 22-line synthetic fixture. |

## AC-10 — no concern has two owners

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-10 | CP-5 | PASS | Lifecycle contracts: `cadre/internal/kernel`, `cadre/cmd/agentic-sdlc`, `cadre/kernel/` all absent; `kernel-contracts/` is the vendored copy AC-04 guards. `agentic-lifecycle` archived (`archived: true`). |
| AC-10 | CP-5 | PASS | Knowledge retrieval: cadre's engine files absent (P4, −8,669 lines). Knowledge governance held apart, with its own database. |
| AC-10 | CP-5 | PASS | Governed selection: gloop's `Select()` and `catalog.MatchRoutes` deprecated with replacements named; removal tracked as AC-07b. |
| AC-10 | CP-5 | PASS | Agent definitions: row amended — its recommended owner (`agentic-lifecycle`) is archived; cadre is the home and gloop reads a roster by path. |
| AC-10 | CP-5 | PASS | Execution orchestration: row split three ways on evidence, with a revisit trigger. Finding: `CP-3-AC10-dispatch-finding.md`. |

### Why the dispatch row was amended rather than satisfied by deletion

Read at the seams: cadre spawns **agent CLIs** (Claude Code, Codex) with its sandbox vocabulary mapped onto each CLI's permission flags, behind a confirmation gate and audit log. gloop drives **LLM provider APIs** through a session manager. `grep -rn "claude\|codex"` across gloop's dispatch and runtime returns nothing outside its Anthropic provider — gloop spawns no agent CLIs and claims none.

The one overlap is cadre's `runner="api"`, 2,199 lines, whose own comment says it "serves deployments where there is no coding CLI to spawn" — gloop's job description.

It stays in cadre because **the containment is the deliverable**: `https://` anywhere but `http://` only toward loopback/private/link-local hosts so a mistyped public endpoint cannot receive a key in the clear; the key as the *name* of an env var; writes off by default behind four independent conditions; a command allowlist empty by default and documented as *advisory, not a containment boundary*; and a fence separating the caller-supplied brief from the role's instructions, added to fix a bug where trusted instructions sat inside the untrusted slot.

gloop's `ToolExecutor` is a handler registry — a map from tool name to a closure, no path confinement, no allowlist, no URL policy. Its only mention of a sandbox is a comment that read-only means offering no tools at all. That is the right design for a general-purpose library, and it is why moving cadre's runner there would either push a security posture into a library that has never wanted one, or lose it.

**The condition that reopens this:** if gloop grows filesystem or command confinement, the duplication becomes real. Recorded as a trigger rather than as settled, because a correct decision with no standing reason to look again is how this consolidation's five stale rationales came to exist.

## North-star gate — ownership re-derived independently

A verifier derived its own concern map from the four repositories **before being allowed to read the ownership table or the spec**, then compared. Report: `north-star-ownership.md`.

| Concern | Result | Observation |
|---|---|---|
| Lifecycle contracts | PASS | cadre-kernel owns; cadre's three vendored JSON files byte-identical under a drift-guard test; no third copy |
| Knowledge storage and retrieval | PASS | recall owns; cadre's `internal/knowledge` has no index or search of its own |
| Governed selection | PASS | cadre owns; the concept is absent from gloop's selector and catalog |
| Agent-CLI spawning | PASS | cadre only — **gloop has no `os/exec` anywhere except one `git clone`** |
| Tool-loop containment | PASS | cadre only — gloop's `ToolExecutor` is a bare handler registry; its own comment at `session.go:466-471` confirms its "sandbox" means offering no tools |
| Role catalog | PASS | cadre's roster is the sole hand-authored source; every copy generated and CI-drift-checked |
| `agentic-lifecycle` | PASS | genuinely archived, and consumed by none of the four live repositories |
| gloop's deprecated selection | PARTIAL | still live and wired into `gloop select`, disclosed and tracked as AC-07b rather than hidden |
| **Lifecycle-gate CLI** | **FAIL** | see below |

**The two claims I wrote the conclusions for were attacked directly and held.** gloop has no rival to cadre's agent-CLI spawning, and no rival to its API-runner containment — established by reading gloop, not by trusting my finding.

### The failure: the losing implementation is the only one reachable

`which -a agentic-sdlc` returns exactly one path — `~/.local/bin/agentic-sdlc`, a pipx-installed **Python `agentic-sdlc==0.13.2`** built from `/tmp/up/agentic_sdlc-0.13.2-py3-none-any.whl`, carrying the full G1–G10 lifecycle-gate command surface. That is the concern cadre-kernel now owns. cadre-kernel's binary has the same name and **is not installed on this machine at all**.

So typing `agentic-sdlc` today runs the retired implementation, and the winning one is unreachable by its own name.

This is the north-star's own wording — *"the losing implementations are deleted or archived rather than left running"* — and it is left running. I had recorded the same binary in the AC-11 evidence as a **measurement hazard**, which understated it: the point is not that it can corrupt a measurement but that it is a live second owner. AC-02 does not catch it, because AC-02 only inspects cadre's tree; this artifact is in neither tree.

**Proposed fix** (machine hygiene, no criterion reopened): uninstall the predecessor and install the kernel's own binary under that name, then add a check so the same shadowing cannot recur silently — which is the class of defect this consolidation exists to stop.

### A stale criterion, found in passing

AC-07's text requires `catalog.MatchRoutes` to carry a `Deprecated:` marker. gloop's CHANGELOG explicitly retracted that — *"that was wrong, and the code never said so… `catalog.MatchRoutes` is not deprecated and is not going away"* — and `grep -n Deprecated pkg/catalog/*.go` finds none. Nothing false is currently claimed, but AC-07's wording needs the same amendment AC-08 and the selection row already took.

## North-star gate — evidence audit

A second verifier re-ran all eleven criteria against the artifacts rather than the ledger. Report: `north-star-evidence-audit.md`. **Verdict: FAIL:escalate.**

### The finding: three repositories, one failure mode, one caught

CP-4 found it in recall — a cross-repo guard that hard-fails under CI, given no origin file by the workflow, so v0.3.0 was tagged red while the ledger said "full suite green". Fixed in `37d336e`.

**The same defect is live in the other two, and I verified both myself:**

| Repo | CI on HEAD | Since |
|---|---|---|
| recall `2c00c05` | success | fixed at v0.3.1 |
| cadre `232314fc` | **failure** | 10/10 pushes since `1ed3169a` |
| gloop `fd05a329` | **failure** | 4/4 pushes since `pkg/govplan` landed |

cadre's failing tests, read from the run log:

```
--- FAIL: TestVendoredKernelContractsMatchTheKernel
    no kernel contract source is reachable and this is CI, where this guard must not be
    skipped. Set KERNEL_CONTRACTS_DIR
--- FAIL: TestOurProviderBundleAcceptsTheKernelWeDependOn
    no kernel binary is reachable and this is CI. Set AGENTIC_SDLC_BIN
```

The workflow sets `AGENTIC_SDLC_BIN: ${{ github.workspace }}/bin/agentic-sdlc` — a path **P1 deleted** when it extracted the kernel. `KERNEL_CONTRACTS_DIR` is never set at all.

**`1ed3169a` is the exact commit the P1 ledger cites for AC-02's PASS**, quoting "full suite green and all three generator checks current on the merged tree before pushing". The local half was true; the push it describes went red and has stayed red through nine more.

I pushed to cadre six times today and did not once look at a run. I found this defect in recall, wrote a retro action about it, and then reproduced it in the repository I was working in — checking the CI *commands* locally and calling that CI.

### The other findings

| AC | Result | What |
|---|---|---|
| AC-05 | FAIL | The schemas were deleted and the repo archived, but an **executable, typed run-record implementation** (`lifecycle.py`, `store.py`) still lives at agentic-lifecycle's HEAD. The inventory searched filenames, not the concept — the exact failure mode the criterion was written against. |
| AC-07 | FAIL | The criterion requires a `Deprecated:` marker on `catalog.MatchRoutes` that correctly does not exist, and the amendment's rationale asserts gloop is "MIT-licensed, on pkg.go.dev" — `gh api repos/deagy/gloop` returns `private: true, license: null`. A false premise in a spec amendment. |
| AC-10 | WEAK | Substance independently confirmed; **process challenged**. `spec.md` was amended at 08:49, after the 07:19 finding that would have failed the row, and the verified rows written at 08:59. And the spec's own AC-08 section rejects this move for an identical shape: *"one concern with a requirement attached, not two concerns."* |

### Weakly verified — passes that would not catch a regression

- **AC-04, AC-06**: both guards are genuinely falsifiable and both are dead on the runner. They pass locally only because sibling checkouts happen to exist on this machine — the identical accident already diagnosed and fixed in recall.
- **AC-08**: the "no query" refusal does not refuse a *whitespace* query. Reproduced live: it returns a score-0 result and writes an audit row. The test passes because it tests the empty string.
- **AC-11**: the recorded "2 gates → 9" does not reproduce, because the evidence file never records the `--task`/`--files` that produced it. The enrichment mechanism is real; the figure is not reproducible from what was written down.
- **AC-11**: cadre's `SECURITY.md` still tells operators to run a deleted command and to download from the wrong repository under a tag scheme that does not exist.

## CI repaired in all three repositories

| Repo | Before | After | Run |
|---|---|---|---|
| recall | red on v0.3.0's commit | **green** | fixed in P4, `37d336e`, released v0.3.1 |
| gloop | red on 4/4 pushes since `pkg/govplan` landed | **green** | `33532899185` |
| cadre | red on 10/10 pushes since `1ed3169a` | **green** | `33534720412` |

cadre's last green run before this was `180a00ca` — the P0 baseline, measured before any consolidation work began. Every commit of this ultragoal until now landed on a red runner.

**The guards demonstrably ran, not skipped.** Both hard-fail under CI when their inputs are missing, and GitHub sets `CI=true`, so `ok github.com/deagy/cadre/cli/internal/orchestration 42.543s` on the runner is proof of execution rather than of absence. The five kernel steps — checkout and build, in the three jobs that need one — all report success.

### AC-02, restated on a green commit

The P1 ledger recorded AC-02 as PASS at `1ed3169a`, quoting "full suite green and all three generator checks current on the merged tree before pushing". That was true locally and false on the runner, and stayed false for nine more pushes.

**Corrected, not rewritten:** the criterion itself (`internal/kernel/`, `cmd/agentic-sdlc/` and `kernel/` absent, full suite passing under `CGO_ENABLED=1 go test -tags sqlite_fts5`) is satisfied at `c4447718`, verified by run `33534720412` — a run ID rather than a local exit code, which is the difference the original row was missing.

### What it cost, and what that says

Turning CI on took four pushes and surfaced four defects, three of which I introduced while fixing the first: a workflow left with an `env:` key and no value (rejected outright — zero jobs, zero seconds), a `go build` inserted before a job's own `setup-go` so its cache restore untarred into a populated module cache, and a `run:` line whose value started with a quote and continued unquoted.

That is the ratio a workflow gives you after ten unexercised commits: every stale path surfaces at once and each fix uncovers the next. The alternative was leaving it red and continuing to record "suite green" from a laptop.

**A real defect fell out of it.** With `AGENTIC_SDLC_BIN` finally exported, `TestEveryGlobalOnlyFieldIsRefusedFromAProjectFile` failed — it writes a project-local `agentic_sdlc.bin_path` and expects a refusal, but the environment is tier 1 and `resolveCore` returns before any file is read. Not a bypass: the project's value is ignored entirely, which is what a global-only field wants. But the test's isolation covered only `XDG_CONFIG_HOME`, so its verdict depended on whether the machine had a variable set — passing on a clean laptop, failing on a wired runner, for reasons unrelated to the property under test. `isolateConfigEnv` now clears every field's variable and restores it after.

Fourth instance today of one shape: **a check whose answer depends on the room rather than the code.** Three were missing CI inputs; this was a test reading the environment it was meant to be isolated from.


## AC-11's gate figure, re-verified

The audit could not reproduce "2 gates → 9" and was right to say so: `CP-5-acceptance-AC11.md` recorded the numbers without the `--task`/`--files` that produced them, and gate sets depend on the task's matched routes — the auditor's two chosen tasks gave different counts, correctly.

Re-run with the inputs recorded: **standalone 2 (`G8, G9`) → integrated 9 (`G1…G9`)**, identical to the original. The figure was accurate; the evidence was incomplete. The invocation is now written into the acceptance file, including the detail that `bin/cadre` rebuilds itself and so needs `go` on the scrubbed `PATH` — omitting it is why the first re-run attempt produced no JSON at all.

A criticism worth keeping separate from its conclusion: "I cannot reproduce this" is a defect in the evidence whether or not the claim is true, and this one was true.
