# P5 — settle cadre's remainder and the catalog's home

Three criteria. Two are measurable and mostly already true; the third is the ultragoal's last real consolidation question, and scoping found it is not what the phase plan's one line implied.

## AC-11 — the split pipeline runs end to end · **closed**

Done during scoping, because it is a measurement rather than a build. Evidence: `CP-5-acceptance-AC11.md`.

The one thing worth recording here is how nearly it was measured wrong. The first run reported `lifecycle_tracking: integrated` **without** any kernel wired — because a pipx-installed `agentic-sdlc 0.13.2`, a Python build predating the Go extraction, was on `PATH` and cadre found it. Scrubbing `PATH` and pointing `AGENTIC_SDLC_BIN` at the released binary is what made the measurement mean anything. Same failure shape as P4's "recall's suite green": the environment supplying something nobody accounted for.

## AC-09 — the catalog has one publishing home · **satisfied, verified**

Every catalog copy across all four repositories was enumerated, and each one's status established:

| Copy | Status |
|---|---|
| `cadre/roster/catalog.yaml` | the home — itself rendered from the per-role sources by `generate-role-metadata` |
| `cadre/provider/agent-catalog.json` | generated, 159 agents, drift-checked |
| `cadre/plugin/suite/roster/catalog.yaml` | generated, drift-checked |
| `cadre/roster/orchestration/test/fixtures/minimal-roster/catalog.yaml` | a 23-line synthetic fixture, not a copy |
| `gloop/pkg/catalog/catalog.yaml` | gloop's own 10-route default catalog — a different artifact, not cadre's |
| `gloop/pkg/roster/testdata/roster/catalog.yaml` | a 22-line fixture for gloop's roster **reader** |
| `recall`, `agentic-lifecycle` | none |

gloop consumes a roster by path rather than vendoring one: `pkg/roster` is a loader for an external `roster.json` + `catalog.yaml`. That is the shape AC-09 asks for.

**Both drift checks were mutation-tested rather than assumed.** Removing one agent from `provider/agent-catalog.json` → `generate-role-metadata --check` names the file and exits 1. Appending a line to the plugin's catalog copy → `generate-plugin --check` names it and exits 1. Restored, both clean.

## AC-10 — no concern has two owners · **one row is stale, and one is a real finding**

The ownership table in `04-projects/agentic-sdlc/planning/repository-ownership-decision.md` has six rows. Four are settled and verified absent from their losing claimants:

| Concern | Owner | Losing claimant | Verified |
|---|---|---|---|
| Lifecycle contracts | cadre-kernel | `cadre/internal/kernel`, `cadre/cmd/agentic-sdlc`, `cadre/kernel/` | all absent; `kernel-contracts/` is the vendored copy AC-04 guards |
| | | `agentic-lifecycle/schemas` | repository archived (`archived: true`) |
| Knowledge storage/retrieval | recall | cadre's retrieval engine | absent — P4 |
| Knowledge governance | separate, do not merge | — | held apart; P4 gave the staged store its own database |
| Governed selection | cadre | gloop's `Select()` / `catalog.MatchRoutes` | deprecated with replacements named; removal is AC-07b |

**The stale row.** "Agent definitions → `agentic-lifecycle`, as data" names a repository that is now archived. The definitions live in cadre's roster; gloop reads a roster rather than holding one. The row needs rewriting to say so — the decision it records was overtaken by P2.

**The finding.** The table assigns **execution orchestration to gloop**, and cadre has `internal/orchestration`: 73 Go files including `dispatch_core.go`, `api_runner_loop.go`, `api_runner_sandbox.go`. Its own package comment describes "native Go child process control, sandbox narrowing, confirmation gating, and audit logging". gloop has `pkg/dispatch`: 5,144 lines, "takes a DispatchPlan from the selector and executes roles sequentially", with retry, timeouts, sessions — and gates of its own.

Two implementations, one concern by the table's reading. **Whether it is actually one concern is exactly the question P3 got wrong in the other direction**, where a planned port turned out to be a composition once the code was read: the difference between cadre's selection and gloop's was governance, not capability. The same may be true here — cadre's dispatch is sandboxed, confirmation-gated and audited, gloop's is sequencing and retry — or it may not. That is a reading job, not a judgement to make from doc comments.

**This is the ultragoal's last consolidation question and it is put to the user rather than answered here.**
