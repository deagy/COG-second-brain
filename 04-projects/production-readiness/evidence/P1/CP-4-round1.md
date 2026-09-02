# CP-4 integration verification — production-readiness P1 (AC-1, AC-2, AC-3)

Read-only. All four repos (`cadre`, `cadre-kernel`, `recall`, `gloop`) confirmed `git status --porcelain` clean before and after this run.

## 1. cadre does not reference what gloop removed — PASS

`grep -rn "gloop select\|gloop roster plan\|selector\.Select\|roster\.Select\|pkg/selector"` across all of `cadre` (`.go` and `.md`, including `internal/generators/` generated-plugin sources and `roster/**`) returns zero hits. Nothing in cadre ever names these — not code, not generated plugin `README.md`s, not `roster/` docs. There is no cross-repository break here because cadre never told an operator to run a gloop command in the first place; cadre's `plugin/README.md` describes `pkg/govplan` reading cadre's own dispatch plan, with gloop absent from the text entirely (see #3).

## 2. Licence coherence, kernel — PASS on AC-2's literal scope, with a gap worth carrying to P5

- `gh repo view deagy/cadre-kernel --json licenseInfo` → `apache-2.0`. `gh api repos/deagy/cadre-kernel/license` confirms a `LICENSE` file (Apache-2.0, "Copyright 2026 Daniel Eagy") on the default branch at commit `8da1b13`.
- cadre's `SECURITY.md` and `plugin/README.md` — the two files that mention `cadre-kernel` by name — make **no licensing claim about the kernel at all** (they describe the release-download/verify flow and version pins). No false statement to find.
- **Gap**: cadre's `internal/generators/plugin_generation.go:283` and `SECURITY.md`'s own documented verify flow both fetch the kernel **by release tag**, not by browsing the repo. The only published kernel release is `v0.14.2`, tagged at commit `24ec47c` — two commits *before* `8da1b13` ("Add Apache-2.0 licence"). Downloaded and inspected the actual release tarball (`agentic-sdlc-v0.14.2-linux-amd64.tar.gz`): it contains only the `agentic-sdlc` binary — no `LICENSE`, no reference to one, and `SHA256SUMS` likewise carries none. Someone who installs "by version" today — via cadre's installer or by following `SECURITY.md`'s own `gh release download` example — gets an artifact with no licence text anywhere in it; the licence is real but lives only in the git repository, not in anything the documented install path actually fetches.
- This does not fail AC-2 as worded ("comes from a repository carrying a licence" — true) and it matches the goal's own sequencing: `spec.md` explicitly defers all releases to P5, and AC-6/AC-7 exist precisely to prove the release artifacts work. Flagging it here because P1's own baseline finding was about the *installer's download path*, and that path is not yet actually fixed — only the repository behind it is. Recommend P5 include re-cutting a kernel release from current HEAD and re-checking AC-2 against the release artifact itself, not just repo metadata.

## 3. Four repos agree about what gloop is — PASS (vacuously, and that is itself confirmation)

`grep -rniE "\bgloop\b"` across all `.md` and `.go` files in `cadre`, `recall`, and `cadre-kernel` returns **zero hits in all three**. No SDK framing, no MIT claim, no pkg.go.dev link, no description of gloop anywhere outside gloop's own repository — consistent with T-02's build-record claim ("nothing imports it... checked across cadre, recall and cadre-kernel") and CP-3v round 1's independent finding. Nothing to contradict gloop's new self-description because nothing describes gloop at all. This is the correct state, not an evasion — it matches the decision record that gloop's public/internal framing was never referenced elsewhere.

## 4. AC-3 / AC-3b split — genuine decomposition, not a relaxation at the gate

Checked against `WORKFLOW.md` § "Amending a gated criterion": amending *before* gating is fine; amending *after* a failing finding and *before* the verdict is recorded is not — "let the criterion fail, and open a new deferred criterion for the follow-on work."

- `evidence/P1/evidence/checkpoints.tsv` records round 3 as **FAIL** ("AC-3 is larger than the phase assumed") — the failure is in the ledger, not edited away. That satisfies "let it fail."
- `spec.md`'s current AC-3 text is scoped to "licensing, visibility and the removed commands." Confirmed by diff that commit `04c356a` ("Fix the round-3 defects, and stop guessing at the --config contract") fixes exactly that scope: `README.md`'s stale "Selector Engine" architecture box (removed-command residue) is replaced, and the badge/MIT-claim narrative from earlier commits stands unchanged and true.
- AC-3b's spec text names the two items explicitly carried out of scope: the cobra-CLI claim and the `--config` contract. Independently confirmed both are **unrelated to the removal** — `docs/ARCHITECTURE.md:45`'s cobra claim was about the CLI framework, nothing to do with deleted selectors, and was fixed as a drive-by in the same commit (`grep -rln spf13/cobra --include=*.go .` → empty, confirming the row is now accurate: hand-rolled dispatcher). The `--config` claim is a blanket "all commands support" statement, also unrelated to what was removed, and — per the commit message's own account — resisted three attempts to state correctly (the second attempt was itself a false "verifier produced a false positive" claim, corrected in the same commit).
- Read `README.md:162-176` at HEAD: it no longer asserts a specific `--config` contract. It states plainly that the old blanket claim was wrong, gives the parts that are known (search order), and points at `AC-3b` for the rest — a documented gap, not a confident falsehood. That is consistent with the CLAUDE.md discipline of not overclaiming resolution.
- Conclusion: the split matches the `AC-07b`-style pattern `WORKFLOW.md` explicitly blesses as the alternative to relaxing a failed criterion. AC-3's new scope is exactly what was fixed and re-observed here as true; AC-3b's scope is exactly the two falsehoods that were pre-existing and unrelated to P1's actual work (the deletion + licensing). This is decomposition on evidence, not a criterion edited to dodge its own failure.
- Minor ledger gap, noted but not blocking: no `CP-3v` round-4 **PASS** entry exists in `checkpoints.tsv` for the now-narrowed AC-3 — the last logged verdict is round 3's FAIL. I independently re-observed the narrowed AC-3's claims true at HEAD (`04c356a`), so this doesn't change my verdict, but the ledger itself does not show a formal close-out of AC-3 under its new, narrower text.

## 5. Traceability — mostly closed, one broken pointer

- Grepped all of `evidence/P1/*.md` for `AC-4|AC-5|AC-6|AC-7|AC-8|AC-3b` — zero hits. P1's own evidence trail claims nothing outside AC-1/AC-2/AC-3. Clean.
- **Defect**: `spec.md`'s traceability table lists AC-3 as `verified`, evidenced by `evidence/P1/CP-5-acceptance.md`. That file **does not exist** — `evidence/P1/` contains `CP-2-plan.md`, `CP-3-build.md`, `CP-3v-round{1,2,3}.md`, and `evidence/checkpoints.tsv` only. No CP-5 acceptance checkpoint has run for P1 at all (checkpoints.tsv's last row is CP-3v round 3, FAIL). The spec is asserting a verified status on evidence that was never written. This is exactly the kind of claim CP-4 exists to catch before it propagates into STATUS.md or a future phase's assumptions.

## 6. CI status, verbatim

```
deagy/cadre                  fd2c2295  success run 33586252288
deagy/cadre-kernel           8da1b135  success run 33629166510
deagy/recall                 3ee2795f  success run 33537575047
deagy/gloop                  04c356ad  success run 33633218009
```

All four green at HEAD, including gloop's final round-3-fix commit.

---

## Contract

```
VERDICT: FAIL:fixable
INTEGRATION_CLAIMS_CHECKED: 13
EVIDENCE:
EVIDENCE AC-1/AC-2/AC-3 | CP-4 | PASS | cadre has zero references to gloop select/roster plan/selector.Select/roster.Select/pkg/selector in code, generated plugin output, or roster/** docs | grep across /home/deagy/sdk/cadre
EVIDENCE AC-2 | CP-4 | PASS | cadre-kernel repo carries Apache-2.0 on its default branch; GitHub-reported licenseInfo = apache-2.0 | gh repo view / gh api repos/deagy/cadre-kernel/license
EVIDENCE AC-2 | CP-4 | NOTE | the only published kernel release (v0.14.2, tag at 24ec47c) predates the licence commit (8da1b13) by two commits; the release tarball itself contains only the binary, no LICENSE text, and no reference to one — cadre's own documented install/verify path does not currently surface the licence, only the repo does. Consistent with releases being deferred to P5; carry into AC-6/AC-7 re-check | downloaded and inspected agentic-sdlc-v0.14.2-linux-amd64.tar.gz; gh api repos/deagy/cadre-kernel/git/refs/tags/v0.14.2
EVIDENCE AC-1 | CP-4 | PASS | cadre's SECURITY.md and plugin/README.md, the only two files naming cadre-kernel, make no licensing claim about it at all — nothing to falsify | /home/deagy/sdk/cadre/SECURITY.md, plugin/README.md
EVIDENCE AC-3 | CP-4 | PASS | cadre, recall, cadre-kernel contain zero mentions of gloop anywhere (docs or code) — no cross-repo description to contradict gloop's new self-description | grep -rniE "\bgloop\b" across three repos
EVIDENCE AC-3/AC-3b | CP-4 | PASS | round-3 FAIL is recorded in evidence/P1/evidence/checkpoints.tsv before AC-3's text was narrowed, satisfying WORKFLOW.md's "let it fail" rule; narrowed AC-3 scope matches exactly what commit 04c356a fixed (README Selector Engine box) | checkpoints.tsv, gloop commit 04c356a diff
EVIDENCE AC-3b | CP-4 | PASS | cobra-CLI claim and --config contract claim are independently confirmed unrelated to the command removal (pre-existing documentation drift); --config claim is now stated as an open gap pointing at AC-3b rather than asserted falsely | docs/ARCHITECTURE.md:45, README.md:162-176 at gloop HEAD 04c356a
EVIDENCE traceability | CP-4 | FAIL | spec.md's traceability table marks AC-3 "verified" citing evidence/P1/CP-5-acceptance.md, which does not exist; no CP-5 checkpoint has run for P1 | ls evidence/P1/, evidence/P1/evidence/checkpoints.tsv (last row: CP-3v round 3, FAIL)
EVIDENCE traceability | CP-4 | PASS | P1's own evidence files (CP-2/CP-3/CP-3v rounds) make no claims about AC-4 through AC-8 or AC-3b | grep across evidence/P1/*.md
EVIDENCE CI | CP-4 | PASS | all four repos green at HEAD via ci-status.sh, gloop's HEAD is the round-3-fix commit | ci-status.sh output above
EVIDENCE repo cleanliness | CP-4 | PASS | git status --porcelain empty in all four repos before and after this verification | direct observation
EVIDENCE AC-2 | CP-4 | PASS | installer's fetch set (cadre, cadre-kernel only, per T-05) independently re-confirmed unchanged since CP-3v round 1 — no new hosts introduced by the licence commit | plugin_generation.go
EVIDENCE gloop CI | CP-4 | PASS | gloop HEAD 04c356ad is green, matching the commit the task named as final state | ci-status.sh
FAILURES:
- traceability | spec.md claims AC-3 "verified" via evidence/P1/CP-5-acceptance.md, a file that was never written | Fix: either run CP-5 acceptance for P1 and write that file, or correct the traceability table to reflect the true state (CP-4 gated here, CP-5 pending) before any later phase treats AC-3 as closed.
- AC-2 (advisory, not blocking) | the licence fix lives only in cadre-kernel's git history, not in the one published release the installer/documented verify flow actually fetches | Fix: no action needed in P1 itself (releases are explicitly P5's job), but P5's AC-6/AC-7 work should re-cut a kernel release from current HEAD and re-verify the release artifact carries or references the licence, not just the repo.
```
