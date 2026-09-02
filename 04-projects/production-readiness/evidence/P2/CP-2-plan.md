# P2 — CP-2 plan · AC-8

The two known defects, closed with tests rather than fixes.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | Fix `#249`: the project-tier config walk reaches `$HOME` | AC-8 |
| T-02 | Add the test the issue itself notes is missing | AC-8 |
| T-03 | Correct the issue body, which cites Python deleted the day after it was filed | AC-8 |
| T-04 | Resolve the lifecycle kernel's two release homes to one | AC-8 |

## T-01 — what the defect actually is

`platform.FindFileAtProjectRoot` (`internal/platform/paths.go:113`) stats the candidate **before** testing the `.git` boundary. With no project root in the ancestry the walk climbs to `$HOME`, where `~/.agents/knowledge-store/config.json` is the *global* store's own config — so the global store answers to the project-local tier, and `KNOWLEDGE_STORE_HOME` is silently ignored.

Reproduced against the current binary: from a directory under `$HOME` with no `.git` between, `cadre knowledge config` reports `project-local` and resolves the global store's database while `KNOWLEDGE_STORE_HOME` points elsewhere.

Both stores share this function — the context store copies the resolution shape deliberately — so one fix covers both, and a divergence here would be worse than the bug.

## T-03 — the issue is wrong in a way the fix does not address

`#249` was filed 2026-08-12 against `roster/knowledge-store/src/config.py`. Commit `b418031e` deleted that file **the next day**. The issue has cited nonexistent code for three weeks.

Its *core defect* is live and reproduced. Its **"Why it matters" section is not**: it argues the scope gates are bypassed because in Python they keyed on `tier == TIER_GLOBAL_FALLBACK`. The Go gate is unconditional, and `internal/cli/knowledge.go:389` says so deliberately — *"weakening the CLI to match Python would require weakening the library, in the one direction this store must never fail."*

Leaving that in place means the next reader either fixes a bypass that does not exist or distrusts the issue. Correcting it is part of closing the defect, not tidying.

## T-04 — one concern, two release homes

cadre still tags `kernel-v*` and carries kernel release workflow; cadre-kernel publishes `v0.14.2` independently. That is residue from the split `repo-consolidation` existed to end, and it is a live hazard now the kernel is licensed: two publishing paths can drift in what they ship under the same version.

Decide which home wins, retire the other, and make cadre's installer resolve against the surviving one — which it already does (`github.com/deagy/cadre-kernel/releases/download/`), so the likely answer is that cadre's kernel release workflow is dead weight.

## What would falsify this phase

Fixing the walk and not testing it. The issue says plainly: *"No test pins the current behaviour."* A fix with no test is the same defect one commit later, and this is a defect that reproduces only from a directory shape nobody creates by accident.

The second falsification: fixing `FindFileAtProjectRoot` and checking only the knowledge store. Both stores share it, and the context store's copy is latent rather than absent — it becomes live the moment anyone creates `~/.agents/context-store/config.json`.
