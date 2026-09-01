# P2 evidence ledger

## T-02 — no third contract definition survives

Inventory across all five repositories, searching for `run-record*`, `gate-result*`, `lifecycle-gates*`, `mutation-gates*`:

| Repository | Found | Verdict |
|---|---|---|
| `cadre-kernel` | `kernel/contracts/{run-record.schema.json,lifecycle-gates.json,mutation-gates.json}` and the embedded copy under `internal/kernel/contracts/` | **The authority.** Two locations, one source: `TestEmbeddedContractsMatchTheSourceOfTruth` holds the embed to `kernel/contracts/`. |
| `cadre` | `kernel-contracts/` — the same three files | Vendored copies, not definitions, held by `TestVendoredKernelContractsMatchTheKernel` and falsified in both directions. |
| `gloop` | none | |
| `recall` | none | |
| `agentic-lifecycle` | `schemas/run-record.yaml`, `schemas/gate-result.yaml` | **The third definition AC-05 requires gone.** Both are placeholder templates with literal example values, no types and no required set. |

After archiving: one authority, one guarded embed, one guarded vendored copy, and no other definition anywhere. AC-05's contract clause is met the moment T-03 lands.

`gate-result.yaml` exists nowhere else, and is not a loss: the kernel models gate results in `run-record.schema.json`'s `$defs.gate` and in `internal/kernel/gateissues_run.go`.

## T-01 — salvage decision recorded

Written into `04-projects/agentic-sdlc/planning/repository-ownership-decision.md` § "`agentic-lifecycle`, retired". Nine of ten agents have a cadre counterpart with stronger authority rules; `lifecycle-coordinator` is kept as a recorded concern rather than a ported role, because cadre already owns its five outputs across five deliberately separate places and porting it would both concentrate that and widen two closed enums in a schema vendored into the wheel and the plugin distribution.

## T-03 — archived, CP-6 approved

Lead-side observations. CP-3v rows pending; a fresh-context verifier is checking all five claims independently.

| Claim | Observation |
|---|---|
| Archived | `gh api repos/deagy/agentic-lifecycle` → `archived: true`, `visibility: private`. Observed on the repository, not taken from the archive command's output. |
| Nothing stranded | 209 uncommitted lines across six files were committed as `bc7ea86` and pushed before archiving — the intent-brief template plus `cli.py`, `mcp_server.py`, `renderer.py`, `store.py` and 157 new lines in `tests/test_runtime.py`. Committed as found and described as the author's; this session wrote none of it. |
| Forwarding address | `ab9e783` adds a README notice naming both successors and the substantive difference: cadre's aides are forbidden from making, implying or recording the decision they prepare a package for, which these stage agents were not. |
| Salvage landed | cadre `c11a19c`: `product-intent-agent` gains the intent record's shape. Suite green, all three generator checks current. |

### The forwarding note is narrower than intended

The repository is **private**, which was not checked before proposing the note. A forwarding address in a private archived repository is visible only to someone with access — in practice the author, later. Still worth having; not the "someone finds it a year from now" case it was argued for.

### The salvage grew in the doing

`agentic-lifecycle`'s template covered users, outcomes, non-goals, measures, constraints, assumptions, unknowns, open_questions. cadre's prose field list was already a superset, so the salvaged template was extended to cadre's own fields — owner, scope, exclusions, classification, environments, conflicts — rather than imported narrower than the contract it documents.

It also carries a rule borrowed from the denial contract: every field stated even when empty, because silence and "nothing" have to be distinguishable. An absent `exclusions` reads as nobody having considered scope; an empty one reads as somebody having considered it and found none.

## The one clause where readings diverge

AC-05 requires "no `run-record` definition exists outside the kernel". `schemas/run-record.yaml` still **exists** in the archived repository — archiving makes a repository read-only, not empty.

The criterion's intent is that no second source of truth can drift, and a read-only placeholder in an archived repository cannot. But that is the lead reading its own criterion generously on the one clause where the literal and intended readings differ, so the verifier was asked to classify every contract file it finds as authority, guarded copy, or independent definition, and to name the guarding test in each guarded case. Its answer stands, not this paragraph.

## CP-3v — fresh-context verification

First pass returned **FAIL:fixable** on AC-05d. Four criteria passed; the fifth did not, and the failure was the exact clause the lead had read generously.

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-05a | CP-3v | PASS | `archived: true`, `visibility: private`, read from the GitHub API. |
| AC-05b | CP-3v | PASS | Working tree clean; local HEAD and `origin/main` identical. Origin confirmed as `deagy/agentic-lifecycle`. |
| AC-05c | CP-3v | PASS | The salvaged template is in cadre's `product-intent-agent` and in neither gloop nor recall. Other copies are cadre's own generated mirrors and worktrees, not a second repository. |
| AC-05d | CP-3v | **FAIL → PASS after fix** | See below. |
| AC-05e | CP-3v | PASS | cadre's full suite green; both generator checks current. |
| AC-05f | CP-3v | PASS | The fix touched exactly four files across three commits and altered nothing else. |

### The clause the lead got wrong

The lead argued a read-only file cannot drift, so "no `run-record` definition exists outside the kernel" was met in substance. The verifier read it literally: `schemas/run-record.yaml` and `schemas/gate-result.yaml` still existed at HEAD, an independent definition with no test tying it to the authority.

The literal reading was correct. Read-only prevents drift *in place*; it does not stop someone browsing `schemas/` and taking two plausible contract files as a definition, having never seen the README one directory up. **A file at HEAD reads as current.**

### The fix went out wrong once

Unarchive, `git rm` both schemas, write a pointer README in their place. Removing the last two files deleted `schemas/` entirely, so the write failed — and the commit went out anyway, its message claiming "a pointer left in their place naming the authority and the two guarded copies". No pointer existed.

Corrected by a further commit rather than an amend. `630bb4f` is titled "actually leave the pointer dd2ec27 claimed to" and states in its body that the earlier commit "went out describing a file that was not in it."

Re-verification confirmed all of it independently, and was asked to check the *history's* honesty as well as the files: it quoted the correcting commit and judged that it "names the discrepancy rather than hiding it." It also cross-checked the pointer's claims against the live repositories rather than trusting them — 24 required fields, thirteen `$defs`, `gate` present, and both guarding test names found verbatim in their files.

End state: archived, `630bb4f` on both sides, `schemas/` holding one README, no contract definition tracked anywhere at HEAD, and no untracked leftovers.

## CP-4 — integration

Run rather than skipped, because P1's retro (AI-5) recorded CP-4 being skipped by omission as its own finding.

Searched all four surviving repositories for any reference to the retired one. `cadre-kernel`, `gloop` and `recall`: zero. `cadre`: seven, all the salvage-attribution line propagated through its own generated mirrors — `provider/roles/`, `plugin/suite/`, `cline-plugins/`. Prose provenance, not a dependency; no code path resolves anything from the archived repository.

Judged acceptable without change: the line already reads "before that repository was archived", so a reader is told not to chase it. Recorded rather than silently accepted.

P1's artifacts re-checked and still hold: `cadre-kernel`'s suite green.

## Correction, 2026-09-01 — AC-05 was closed on a filename search

T-02 recorded "no third contract definition survives" after deleting `schemas/run-record.yaml` and `schemas/gate-result.yaml`. The criterion says **no `run-record` definition exists outside the kernel**, and one did: `src/agentic_lifecycle/contracts.py` and `lifecycle.py` between them defined a run record in code — its `gates` map, per-gate `status`, `human_decision` and `history` — with `store.py` persisting it.

This ledger even names `store.py` among the files committed before archiving. It was seen, and read as salvage rather than as a surviving definition.

**Archiving is not the same as removal when a repository is installable.** `pyproject.toml` declared `agentic-lifecycle = agentic_lifecycle.cli:main`, so the losing implementation was one `pip install` from any machine — and P5's north-star pass found a pipx-installed predecessor of the same lineage already shadowing the kernel on this machine's PATH.

Closed properly in `853ec2c`: implementation and packaging removed, documentation kept, repository re-archived, history intact at `630bb4f`.

The lesson is the search, not the file. **Look for the concept, not the filename** — the same failure that let a broken `delete` verb and a broken staged workflow ship in P4, both found by running a command rather than by grepping for a name.
