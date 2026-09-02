# North-star acceptance gate — `controls-not-advice`

Read-only verification. All three repos (vault, cadre `fd2c2295`, gloop `0088da3`) confirmed clean (`git status --porcelain`) before and after this pass; every falsification below was reverted and re-verified clean.

## AC-1 — every open item carries a disposition

**PASS.** `04-projects/harness/BACKLOG.md` read directly: 20 rows total. All fourteen original ids (AI-1..AI-14) present, each with a disposition and reason. `bash .claude/lib/backlog-lint.sh` on the live file → `backlog-lint: every row carries a disposition.` (exit 0). No row reads bare `open`.

## AC-2 — every control has a check that fails on its own defect

**PASS**, sampled 4 of 9 (instructed minimum), independently reproduced both directions, then reverted:

1. **Go test — cadre `internal/cli/toolchain_guards_test.go`** (AI-3/AI-13, commit `fd2c2295`). Baseline: `go test ./internal/cli/... -run TestAToolchainInvocationIsGuardedBySomethingThatSkips` → PASS. Injected `internal/cli/zzz_falsify_test.go` with an unguarded `exec.Command("go","version")` reaching `t.Fatal` → test FAILs with the exact diagnostic the check advertises ("runs \"go\" and reaches t.Fatal when it is unavailable"). Deleted the file → PASS again. `git status --porcelain` clean.
2. **Go test — gloop `internal/docguard/deprecation_parity_test.go`** (AI-12, commit `0088da3`). Baseline PASS. Reverted `CHANGELOG.md` line to the historical wrong claim ("`catalog.MatchRoutes` is deprecated and will be removed at the next major") → `TestProseDoesNotDeprecateWhatTheSourceKeeps` FAILs citing `CHANGELOG.md:17`, `MatchRoutes`, matching the claimed defect verbatim. Restored the file from a pre-edit copy → PASS again. `git status --porcelain` clean.
3. **Shell lint — `.claude/lib/evidence-lint.sh`** (AI-10/AI-8/AI-1+11). Fixture doc with `grep -rn "foo" . | head -10` and no total → `evidence-lint: 1 finding(s)` (exit 1), citing exactly the truncation defect. Added "31 total." to the same doc → `evidence-lint: clean.` (exit 0).
4. **Shell lint — `.claude/lib/phase-gates.sh`** (AI-5). Fixture phase with a 2-task `CP-2-plan.md` and no CP-4 row → `P1 NEVER RUN: CP-4` (exit 1). Same fixture reduced to 1 task → `P1 CP-4 not owed: the plan names one task...` / `all required checkpoints recorded` (exit 0) — the "and it says why" behavior the build record claims.

All four matched the CP-3-build.md claims exactly, including the specific defect text cited. No reason to doubt the other 5 given the consistent pattern and that P2's own record documents 7 self-found bugs in the build process (evidence of a genuinely adversarial build, not a rubber stamp).

## AC-3 — advice lands where it loads, item-specific reason

**PASS for this goal's scope** (the five items P3 actually landed): read `CLAUDE.md:167-176` (§ Before you assert it, check it — AI-2, AI-9, AI-14) and `CLAUDE.md:156` (AI-7, § Git) and `WORKFLOW.md:78-84` (AI-6b, § Reading a criterion you are about to be judged by). Each reason is genuinely item-specific and non-interchangeable: AI-2's is "check ran too late, no artifact until the message is already sent"; AI-9's is "the defect is a reasoning step, an assumption about who can read a doc"; AI-14's is "not immediately explicable, version-pair note"; AI-7's is an explicit cost argument (no hook infra) not dressed as impossibility; AI-6b's is "no syntactic pattern separates a literal from a generous reading." None would substitute for another.

**Caveat carried to the north-star judgment below**: `BACKLOG.md` now has 20 rows, not 14 — AI-15..AI-20 entered via a concurrent/later retro (`capability-parity`, same day). Four of those (AI-16, AI-18, AI-19, AI-20) are dispositioned `advice` and landed (closed-loop `SKILL.md` §§ CP-3 Build / fix budget / After a revert, and `CLAUDE.md` § Background commands) but their landed text states the rule and its originating incident — it does **not** state why a check cannot reach it, unlike the five items this goal actually processed. This goal's own AC-3 evidence is honestly scoped to the five it landed, so AC-3 itself is not falsified — but the north-star's unqualified wording is not fully satisfied by the current whole backlog. See north-star judgment.

## AC-4 — the split survived independent challenge

**PASS.** Read `evidence/P1/CP-3v-challenge-round1.md` (7 challenges: AI-1+11, AI-2, AI-4, AI-8, AI-10, AI-12, AI-14; AI-6b reviewed and upheld) and cross-checked against the final `evidence/P1/CP-3-triage.md` (v2, "after the AC-4 challenge"): every challenge was acted on — AI-1+11, AI-4a/b, AI-8, AI-10, AI-12 promoted to `control` with narrowed observables; AI-2 was promoted to `control` then explicitly **reverted** after round 2 found the proposed check wouldn't reach the actual defect (a plain chat proposal, no evidence-file artifact) — an answered challenge, not a silently kept one; AI-14 stays advice with an explicit dependency reason (AI-13 must ship first) rather than being closed early; AI-6b is the one item upheld, with a stated reason the challenge itself didn't overturn. Also found and independently confirmed a second-order defect: round 3 (`CP-3v-round3.md`) caught a stale cross-reference ("AI-2's control is the weakest on that list") left behind after the AI-2 revert — and confirmed the *current* `CP-3-triage.md` text has that fixed (now reads "AI-2 shares this limitation exactly, and round 2 reverted its control for that reason"). This is real adversarial process, not self-grading.

## AC-5 — nothing closed as superseded/landed without evidence

**PASS.** Only claimed-landed item is AI-6a. `git log --oneline -1 6d09b29` → `docs(harvest): promote the session's verification lessons`. `grep -n "Amending a gated criterion" WORKFLOW.md` → line 72, content matches the amendment/rewrite-before-close half of AI-6's original text. Independently confirmed, not taken from the evidence bundle's own claim.

## AC-6 — backlog distinguishes the three dispositions

**PASS.** `BACKLOG.md` header table defines `control` / `advice` / `landed` and what closes each. All 20 rows carry exactly one of the three (verified by `backlog-lint.sh` plus a manual scan for a fourth label — none found).

## AC-7 — the disposition question outlives the goal

**PASS.** `.claude/skills/retro/SKILL.md` Phase 4 explicitly asks "can a check observe this defect?" at action-item write time and requires a disposition; `references/retro-template.md`'s Actions table has the `control`/`advice` disposition column with instructions. Wrote two rows exactly per those instructions into a scratch file (`AI-101` control — unbuilt; `AI-102` advice — landed in `CLAUDE.md` § Before you assert it, check it) and ran `bash .claude/lib/backlog-lint.sh <scratch-file>` → `backlog-lint: every row carries a disposition.` (exit 0). An author following the instructions passes on the first attempt. Corroborating in-the-wild evidence: AI-15..AI-20, entered by an unrelated concurrent retro the same day, all carry real dispositions already — none entered as bare `open`.

## Scripts, verbatim

```
$ bash .claude/lib/ci-status.sh /home/deagy/sdk/cadre /home/deagy/sdk/gloop
deagy/cadre                  fd2c2295  success run 33586252288
deagy/gloop                  0088da34  success run 33586398843
```

```
$ bash .claude/lib/phase-gates.sh 04-projects/controls-not-advice
P1     all required checkpoints recorded
P2     all required checkpoints recorded
P3     all required checkpoints recorded
P4     all required checkpoints recorded

phase-gates: every phase ran and recorded its required checkpoints.
```

## North-star judgment

Picked three backlog rows without cherry-picking for a spread of old/new and control/advice: **AI-9, AI-17, AI-20.**

- **AI-9** (advice, `CLAUDE.md` § Before you assert it, check it) — genuine. The defect is a reasoning step ("who can read this doc") with no artifact until a message is sent; `gh repo view --json visibility` exists but nothing would trigger it automatically. Defensible advice, item-specific reason present.
- **AI-17** (control, cadre `internal/cli/duplicate_paragraphs_test.go`, commit `32d863e1`) — genuine. Ran `go test -run TestNoGovernanceDocumentRepeatsItself` directly → PASS on the current tree, and it is a real mechanical near-duplicate-paragraph detector wired into `go test ./...`.
- **AI-20** (advice, `CLAUDE.md` § Background commands) — **dispositioned correctly (advice, not bare open) but does not meet the north-star's own bar.** The landed text states the rule and the incident ("`git rev-parse HEAD` in a background shell resolves against the session's cwd, not the repository you are asking about") but never states why a check cannot catch it — and it plausibly could: a lint over transcript/command text for background `git`/`gh` invocations missing `-R <owner/repo>` is a similar shape to AI-2's rejected-then-accepted-as-advice precondition check, but nobody applied that scrutiny here. This item entered the backlog via a different, concurrent retro (`capability-parity`), not through this goal's triage-and-challenge process.

**The north-star claim as written ("every open retro action is either a mechanical check... or is recorded as advice with a stated reason it cannot be one") is true for the fourteen items this goal actually triaged, and not yet true for the whole current backlog.** AI-16, AI-18, AI-19, AI-20 — four items added by a different retro the same day — are correctly tagged `advice` (satisfying AC-1/AC-6/AC-7's mechanical bar: no bare `open`, a disposition is present, and `backlog-lint.sh` passes) but lack the item-specific "why this can't be a control" reasoning that this goal's own five landed items carry and that AC-3's criterion text demands unqualified. This is not a defect in what this goal built — its own scope (fourteen baseline items) was honestly triaged, challenged, and landed — but it means the mechanism this goal proved (rigorous per-item narrowing before conceding advice) has not yet been applied to backlog rows entered by other retros, even ones landing the same day. The backlog is a live, growing artifact; this goal closed its own slice of it cleanly but did not (and was not scoped to) retroactively audit rows other retros added concurrently.

## Overall verdict

**COMPLETE**, with the caveat above. All seven AC-1..AC-7 rows carry a PASS traced to an artifact independently observed in this pass (not accepted from the evidence bundle's self-report); `ci-status.sh` and `phase-gates.sh` both green; `backlog-lint.sh` passes on the live backlog. The north-star's literal universal claim ("every open retro action") is not fully true of the entire current `BACKLOG.md` — AI-16, AI-18, AI-19, AI-20 are advice-tagged without a stated non-mechanizability reason — but that gap sits outside this goal's chartered scope (the fourteen items it took as its baseline), was introduced by a different, concurrent retro, and does not falsify any of this goal's own seven acceptance criteria as written and traced. Recommend a follow-on backlog sweep (or a `backlog-lint.sh` rule requiring advice rows to cite a reason, not just a landing file) to close that residual before treating the north-star as true of the whole harness backlog rather than of this goal's own slice.
