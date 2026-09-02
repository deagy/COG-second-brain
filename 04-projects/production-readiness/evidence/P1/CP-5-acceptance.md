# P1 — CP-5 acceptance · AC-1, AC-2, AC-3

**EVIDENCE AC-1 | CP-5 | PASS** — no repository claims a licence it does not carry. Swept all four against what GitHub reports and against each repository's own markdown: cadre Apache-2.0, cadre-kernel Apache-2.0 (added at `8da1b13`, confirmed by re-fetching `gh repo view` rather than from the push), recall MIT, gloop none and now claiming none. recall's BSD-3-Clause mention is a changelog note about a transitive dependency, verified as such.

**EVIDENCE AC-2 | CP-5 | PASS** — the install path's complete fetch set, read out of `plugin_generation.go`, `install.sh` and `install.ps1` rather than assumed: `github.com/deagy/cadre` and `github.com/deagy/cadre-kernel`. No third-party downloads. Both Apache-2.0.

**EVIDENCE AC-3 | CP-5 | PASS** — gloop carries no badge requiring public indexing, no licence claim, and no live document describing the removed commands as current. Verified by reading all four live documents end to end and by running the built binary, at gloop `04c356a`.

**EVIDENCE — | CP-6 | PASS** — cadre `fd2c2295`, cadre-kernel `8da1b135` (run 33629166510), recall `3ee2795f`, gloop `04c356a`. All green on their own runners.

## What the gates cost, and what they were worth

| Gate | Verdict | Found |
|---|---|---|
| CP-3v 1 | FAIL | Three live documents still described removed commands; the build record claimed all five had been rewritten |
| CP-3v 2 | FAIL | Two more in the *same files*, one line from what round 1 fixed — plus `warnUnpinnedTiers`, dead code the removal left behind and the docs still described as behaviour |
| CP-3v 3 | FAIL | A second architecture diagram in README; a cobra claim with no cobra in the module; `loadCatalogForCLI`, dead the same way |
| CP-4 | FAIL | This file did not exist while the traceability matrix marked AC-3 `verified` against it |

**Three of the four failures are the same mistake: fixing what a report cited instead of reading the artifact.** Round 2 made it while explicitly trying not to. The two defects that were *not* about the removal — the cobra claim and the `--config` contract — were only found by reading whole documents, and they are what forced AC-3b.

## The `--config` contract, and why it is deferred rather than fixed

`README.md` said "All commands support `--config`". That is false, and the true statement resisted three attempts:

1. Five inspection commands reject it — right, by accident.
2. They accept it before the subcommand — **wrong**, and asserted to the user as a verifier false-positive. A test grepping for a leading `Usage:` scored `Error: unknown gate subcommand: "--config"` as acceptance. The verifier was right; the correction was not.
3. Definitive: `dispatch` and `run` consume `--config` as their positional plan-file argument, `init` rejects it as an unknown flag, five commands reject it as an unknown subcommand, and only `status` parses it.

Rather than write a fourth guess, the README now states the gap and points at AC-3b. **A document saying "this is not written down accurately yet" is true; one confidently describing the wrong contract is not.**

## AC-3b, and why it is a deferral rather than a relaxation

Round 3 found two falsehoods that predate this goal. `WORKFLOW.md` forbids rewording a criterion at its own gate, so AC-3 was not widened to absorb them or narrowed to dodge them: it closes on what it was chartered for, and AC-3b carries a claim-by-claim audit of gloop's documentation against the binary as its own phase. CP-4 judged the split a genuine decomposition, noting round 3's FAIL is recorded before the narrowing.

## Carried into later phases

- **The kernel's published release predates its licence.** `v0.14.2` was cut before `8da1b13`, so the tarball an installer downloads today carries no licence text even though the repository does. AC-2 as scoped is about the source repositories and passes; **P5 must re-cut before this is true of what people actually install.**
- **Nothing in any of the four gates on licences.** Only recall runs `go-licenses`, and that checks dependency licences — it would not have caught a repository with no `LICENSE` of its own.
- Two dangling citations sit in `controls-not-advice`'s P2 CP-4 report. Left as filed: correcting a verifier's report falsifies a record.
