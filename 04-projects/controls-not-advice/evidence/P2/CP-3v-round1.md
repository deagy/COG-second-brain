# AC-2 verification — controls-not-advice P2

**Verdict: FAIL:fixable**

9 of 9 controls independently reproduced in both directions (fail-on-defect, pass-on-fix/restore). All Go tests and shell-script falsifications were run directly by this verifier, not read from the build record. All repos (`cadre`, `gloop`, vault) confirmed `git status --porcelain` clean after every injection/restore cycle.

The FAIL is not about any of the nine checks failing to falsify — every one does. It is that **AI-4a/AI-4b's "passes on clean tree" claim is false when tested against the real artifact that matters most**: `spec-lint.sh` run against the *current, already-shipped* `04-projects/repo-consolidation/spec.md` still fires both findings (AC-05, AC-11), identically to the pre-fix commit `3a08861`. The build record never actually ran the check against real, present-day repo-consolidation — its "passes on" evidence was a synthetic/described case, not an observed one, which is exactly the gap AC-2 exists to close ("a check seen only passing is not evidence" — here it's the inverse: a check claimed-passing that was never actually run clean).

## Per-control verdicts

| # | ID | Verdict | Fail-direction reproduced | Pass/restore-direction reproduced |
|---|---|---|---|---|
| 1 | AI-3 | PASS | Yes, all 3 cited defects independently (guard_binaries_test.go:86, standalone_test.go:45, resolve_shared_integration_test.go:32) — each reproduced by removing only the guard, error message named the exact line | Yes, `git checkout --` restore, clean pass each time |
| 2 | AI-13 | PASS (narrower than the retro's full concern — see note) | Yes, discarding `agentic-sdlc`'s LookPath result to `_` fails with correct message | Yes, clean tree passes (provider_compatibility_test.go:133 logs the binary) |
| 3 | AI-12 | PASS | Yes, both directions: restoring the historical CHANGELOG claim ("MatchRoutes is deprecated") fails at CHANGELOG.md:17; injecting an unannounced `// Deprecated:` marker on `pkg/catalog.MatchFile` fails the other test | Yes, both restores clean |
| 4 | AI-10 | PASS | Yes, fixture reproducing "grep...\|head -10, 11 hits" fires | Yes, adding `wc -l` beside it discharges |
| 5 | AI-8 | PASS | Yes, fixture "Nothing survives as code" with no git-status quote fires | Yes, adding `git status --porcelain` beside it discharges |
| 6 | AI-1+AI-11 | PASS | Yes, against real history: `evidence-lint.sh` on `04-projects/repo-consolidation/evidence/P3/CP-2-plan.md` fires "missing axis: destination-already-does" | Yes, `04-projects/repo-consolidation/evidence/P4/CP-2-plan.md` (all 5 axes present, confirmed by grep) is clean |
| 7 | AI-4a | **FAIL:fixable** — falsifies correctly on fixtures and on historical commit, but its "passes on clean tree" claim is false on the real current artifact (see below) | Yes, on `3a08861`'s `spec.md`: AC-11 fires | **No** — current `repo-consolidation/spec.md` still fires identically; never actually shown clean on real data |
| 8 | AI-4b | **FAIL:fixable**, same defect as AI-4a (same script, same root cause) | Yes, on `3a08861`'s `spec.md`: AC-05 fires | **No** — current `repo-consolidation/spec.md` still fires identically |
| 9 | AI-5 | PASS | Yes, fixture: 2 tasks (T-01, T-02), no CP-4 row → `NEVER RUN: CP-4`, exit 1 | Yes, fixture: 1 task, no CP-4 row → `CP-4 not owed: the plan names one task`, exit 0 |

## AI-4a/AI-4b in detail — the actual defect

`spec-lint.sh` (`.claude/lib/spec-lint.sh:44-101`) scans every markdown table row beginning `| AC-n |` in `spec.md`, filtering out only rows where a column literally reads `verified`/`pending`/`open`/`deferred` (line 101). The **acceptance-criteria table** rows (`| AC-05 | ... | ... |`, 3 columns) never carry that literal, so they are always scanned — including after the criterion has shipped. The **traceability table** row that actually names the phase (`| AC-05 | P2 · re-closed P5 | ... | verified |`) gets *excluded* by that same filter, because it contains the word "verified" — so the row that would discharge the finding is the one the discharge-grep never reaches; the discharge-grep instead searches the whole file for the literal phrase `AC-05.*(published (by|in)|shipped (by|in)|released (by|in) P[0-9]|after P[0-9])`, which nothing in `repo-consolidation/spec.md` matches, even in the amendment prose at line 78 ("became AC-11 in P5 where an installed, released, provider-wired kernel actually exists" — "released" is followed by a comma, not "by"/"in P[0-9]").

Confirmed directly:
```
$ bash .claude/lib/spec-lint.sh 04-projects/repo-consolidation
04-projects/repo-consolidation/spec.md:29  AC-05 asserts a universal negative with no bounded set...
04-projects/repo-consolidation/spec.md:36  AC-11 verified against a published artifact, and no line says which phase publishes it
spec-lint: 2 finding(s).
```
Identical findings, identical lines, against `git show 3a08861:...spec.md` (the pre-fix version) and the current, shipped, "verified" version. The check does not distinguish them because **the AC table's own wording was never amended** — only the separate traceability row and closure evidence discharged it in practice. Whether that counts as a "real defect" is arguable (the check's stated purpose is lexical: "does the wording say where it can be checked," and the wording genuinely still doesn't) — but the build record's claim that it "passes on: criteria naming the publishing phase" is not demonstrated against any real artifact, and the one real artifact it should most obviously pass on (repo-consolidation's own shipped, closed spec) fails instead. That is a crying-wolf risk on a goal AC-2 is not supposed to keep re-litigating.

Confirmed the check mechanism itself is sound in isolation — a hand-built fixture with the phase named in the required pattern (`released in P3`, `no line says` discharge, bounded negative with `counted across the four known repositories`) passes clean (`spec-lint: clean.`) — so this is a real gap in the check's discharge logic against realistic prose, not a broken script.

## AI-13 honesty assessment

Acceptable, with a caveat worth recording rather than silently accepting. The retro's actual originating defect was broader than "path discarded to `_`": a stale pipx-installed `agentic-sdlc 0.13.2` sat on PATH and silently satisfied a compatibility window it should have failed, because the version it reported was never logged. The fix that actually closes that story is `TestTheCompatibilityFloorIsAKernelThatWasActuallyReleased` (tightening the floor) plus the `t.Logf` at `provider_compatibility_test.go:133` — neither of which is what `TestAResolvedToolIsNamedOnTheSuccessPath` checks. AI-13's control only guarantees the resolved *path* isn't thrown away for a non-generic binary; it says nothing about whether the *version* gets logged or reasoned about. The build record is honest about this narrowing ("Which agentic-sdlc you found is the whole question") and the triage doc explicitly ties the residual to AI-14 staying open as advice until AI-13 ships — so the disposition is self-aware, not dishonest. But note it is a materially narrower guarantee than "a stale-version site can't silently pass," and the check is verified as passing on a site (`provider_compatibility_test.go`) that is not currently at risk of the discard defect (it already logs) — the falsification is real (injection fails, clean tree passes) but it's testing a property that the one site the item was named after had already fixed by other means before this control existed. Acceptable evidence for AC-2's literal bar; not evidence that AI-13's control would have caught the retro's actual incident.

## AI-5 scope assessment

Genuinely encoded, not just described. `phase-gates.sh:85-97`: reads `CP-2-plan.md`, counts distinct `T-nn` via `grep -oE '\bT-[0-9]+\b' | sort -u | wc -l`, and only when `tasks = "1"` does it drop CP-4 from `phase_required`. Verified both branches directly with fixtures (table above, row 9). The `|| true` guard against `set -e`/`pipefail` killing the script on a task-less plan (mentioned as bug #8 in the build record) is present at line 88-92 and is real — a plan naming zero tasks is treated as "owing CP-4" per the comment at line 83-84, correctly matching the stated intent.

## Dead-check audit

None of the nine are dead.
- cadre CI (`internal/cli` tests, incl. `toolchain_guards_test.go`): `go test -tags sqlite_fts5 -race ./...` present in cadre's workflow (line 200 of the workflow scanned), which covers `./internal/cli/...` and `./internal/orchestration/...` and `./internal/generators/...`.
- gloop CI: `go test -race -count=1 ./...` (gloop workflow), covers `./internal/docguard/...`.
- `evidence-lint.sh` and `spec-lint.sh`: both genuinely referenced in `.claude/skills/ultragoal/SKILL.md` (lines 52 and 184 respectively), in the CP-1/pre-flight and evidence sections, not stray mentions.
- `phase-gates.sh`: referenced at `.claude/skills/ultragoal/SKILL.md:139`, inside the "every phase must have been asked its gates" north-star-gate section — genuinely wired, not decorative.

## False-positive sweep — evidence-lint.sh / spec-lint.sh across all `04-projects/` goals

Ran both scripts against every goal directory under `04-projects/` (`agentic-sdlc`, `capability-parity`, `cog-second-brain`, `controls-not-advice`, `harness`, `repo-consolidation`, `secure-quantum-environment`; `agentic-sdlc` has no `spec.md` so `spec-lint.sh` correctly errors "no spec.md under..." rather than silently skipping).

`evidence-lint.sh` findings, all judged genuine (no false positives found):
- `repo-consolidation/evidence/P3/CP-2-plan.md:1` — missing `destination-already-does` axis. This is the AI-1+AI-11 originating defect itself, still present in the historical P3 evidence record (expected — P3 was superseded by P4, not rewritten).
- `agentic-sdlc/planning/repository-ownership-decision.md:91` — "Archived. Nothing survives as code" with no `git status --porcelain` anywhere in the document (confirmed via grep). This is a genuine, previously-unflagged instance of the AI-8 pattern in a different, unrelated goal — real evidence the check generalizes and catches things nobody was looking for, not a false positive.

`spec-lint.sh` findings: the two `repo-consolidation/spec.md` findings above (AC-05, AC-11) are the only ones across all goals, and are the false-positive/crying-wolf risk documented above. No findings in `controls-not-advice`, `capability-parity`, `cog-second-brain`, `harness`, or `secure-quantum-environment`.

## Fix hints

- AI-4a/AI-4b (`spec-lint.sh`): either (a) rewrite the discharge grep to also search the traceability table row for the same `$id` (currently excluded by the `verified/pending/open/deferred` filter, which should filter *findings*, not the *discharge search corpus*), or (b) require the AC-criteria-table row itself to name the phase inline when closed, and treat that as the discharge condition instead of free-text anywhere in the file. Either way, re-run against `04-projects/repo-consolidation/spec.md` and confirm `spec-lint: clean.` before re-closing AC-2.
- Everything else: no fix needed; all 7 remaining controls reproduce cleanly in both directions with correct, defect-naming failure messages, and no dead or false-positive-crying checks were found among them.

## Reproduction summary

9/9 reproduced independently (fail direction + restore/pass direction), by running the checks myself — not by reading the build record's claims. 2/9 (AI-4a, AI-4b) reproduce the fail direction correctly but do not actually pass on the real clean-tree artifact the build record implies, which is the basis for FAIL:fixable. All repos (`cadre`, `gloop`, this vault) confirmed clean via `git status --porcelain` after every injection.
