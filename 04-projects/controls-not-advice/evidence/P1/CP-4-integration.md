# CP-4 integration verification — controls-not-advice, P1

Read-only. Re-observed artifacts directly; did not re-verify individual CP-3v-passed dispositions.

## 1. Internal consistency across dispositions (CP-3-triage.md, full read)

One stale cross-reference is on record: round 3 (CP-3v-round3.md) found AI-9's row still saying "AI-2's control is the weakest on that list" after AI-2 was reverted to pure `advice` — a dangling reference to a control that no longer exists. Current `CP-3-triage.md:39` reads "AI-2 shares this limitation exactly, and round 2 reverted its control for that reason" — the fix landed; the phrase "AI-2's control" no longer appears anywhere in the document (grep confirmed, only the AI-9 row and AI-2's own row/tally reference AI-2).

Full re-scan for other cross-references (AI-13↔AI-14, AI-5↔phase-gates.sh, AI-4a↔AI-4b, AI-1+11↔AC-5) found no further contradictions:
- AI-14's row correctly states its fold into AI-13 is provisional ("AI-13 is a P2 proposal today... this row stays open as advice until AI-13 ships") — matches AI-13's own row, which is listed as `control`, not yet built. Consistent.
- AI-5's row claim ("the script has no task-count logic, so 'CP-4 owed when a phase has >1 task' is prose, not a gate") checked against the live `.claude/lib/phase-gates.sh`: confirmed — the script's only logic is presence/absence of `CP-3/CP-3v/CP-4/CP-5` rows in `checkpoints.tsv`, no task-counting anywhere in the file.
- No item classified `advice` for a reason another item's `control` disproves.

## 2. Are the nine controls distinct and jointly buildable

What P2 would build, one row per control:

| Control | Artifact | Repo |
|---|---|---|
| AI-3 | New test scanning `*_test.go` for `exec.Command("go", ...)` builds not preceded by `LookPath("go")` skip | cadre `internal/generators/` |
| AI-13 | New test asserting every `LookPath` guard site reports the resolved tool name on the success branch, not only on skip | cadre, same LookPath call sites as AI-3 |
| AI-5 | Extend existing `phase-gates.sh` with task-count logic | cog-second-brain `.claude/lib/` |
| AI-1+AI-11 | New CP-2 plan lint (sibling to `phase-gates.sh`) checking 5 required inventory headings | cog-second-brain `.claude/lib/` |
| AI-4a | New CP-1 spec lint: an AC's verification text names a fetch of an artifact its own phase's CP-6 hasn't yet published | cog-second-brain |
| AI-4b | New CP-4 integration check: count definitions of a named symbol across the known repo set, fail if != 1 | cog-second-brain (CP-4 tooling) |
| AI-8 | Evidence-doc lint: retire/archive verdict with no `git status --porcelain` quoted beside it | cog-second-brain `04-projects/**/evidence` |
| AI-10 | Evidence-doc lint: piped `grep`/`rg`/`find` → `head`/`tail` with no paired count, scoped to `evidence/P*/` | cog-second-brain `04-projects/**/evidence` |
| AI-12 | New `deprecated_symbols_test.go`, sibling to `documented_verbs_test.go` | cadre `internal/cli/` |

No genuine incompatibility (no proposed lint requires evidence docs to contain something another forbids). Two soft ambiguities, not contradictions:

- **AI-3 and AI-13** both operate over the same `exec.LookPath` call sites in cadre's `*_test.go` files, checking two different properties (build-without-skip vs. silent-on-success). The triage's "where it lives" column ("Test in `internal/generators/`" vs "Test over the guard files") does not say whether P2 should build one test file with two assertions or two files. Either is a valid P2 implementation; the document just doesn't disambiguate it, so 9 named controls may land as 8 physical test files.
- **AI-8 and AI-10** are both labeled "Evidence-doc lint" with no artifact-boundary stated. Round 1/round 2 evidence (CP-3v-challenge-round1.md, CP-3v-round2.md) shows they were independently proposed and independently reclassified, and they check distinct patterns (working-tree precondition beside a verdict vs. paired-count beside a truncated grep) — **they are not the same check answering the same question twice**, but nothing in the triage states whether P2 should build them as one file (two `Test` functions, à la `documented_verbs_test.go`'s multi-test pattern) or two. Not a conflict; a one-line clarification would remove the ambiguity before P2 starts.

Net: 9 controls, 9 distinct observables/fail-conditions, likely 7-9 physical artifacts depending on how P2 groups the LookPath and evidence-doc checks. Not a defect — grouping related checks into one test file is normal practice — but worth flagging so P2's task breakdown doesn't accidentally read "9 controls" as "9 separate build tasks."

## 3. Cross-phase wiring

**P3 (AC-3/AC-6), 5 advice items — landability check:**

| Item | Concrete enough to land? |
|---|---|
| AI-2 | Yes — "verify a naming/destination target exists before proposing it to the user," landable as a step in a naming-decision skill |
| AI-6b | Yes — "the literal reading of a criterion governs at gate time," landable in the ultragoal/closed-loop acceptance-gate section |
| AI-7 | Yes — "never combine a file write and its describing commit in one compound command," landable as a git-discipline line (parallel to CLAUDE.md's existing Git section) |
| AI-9 | Yes, thinly — "check repo visibility before reasoning about doc reach," a one-line reminder, though the triage itself admits "nothing would invoke it" mechanically; as *advice* text this is still a placeable sentence |
| AI-14 | Weakest of the five — "treat an environment note as a finding until shown otherwise" is a general epistemic stance. Still one placeable sentence, but its own row flags it as provisional (folded into AI-13 once built), so P3 should treat it as the item most likely to need rewording when it lands |

All five reduce to a single sentence with a stated reason; none is so vague it can't be placed in CLAUDE.md or a skill body. AI-14 is the one to watch in P3.

**P4 (AC-7) — does P1's method generalize:** P1's operating method was "ask what the retro actually saw, not what the item's sentence generalizes to; split into the structural part a check can observe and the residual that needs judgment" (CP-3-triage.md, "The method round 1 applied unevenly"). This generalizes cleanly into a retro-time question: when an action item is drafted, ask whether the defect just observed has a structural signature distinct from its generalized prose form. That's the same question, asked one step earlier (at authoring instead of triage), which is exactly the shape AC-7 wants `/retro` to enforce. No gap found.

## 4. Conflicts with existing cadre/cog tooling

- `documented_verbs_test.go` and `duplicate_paragraphs_test.go` (both read in full) scan cadre's own `roster/`, `.agents/skills/`, and repo-root `.md` files — a different repo and a different document set from every proposed control here. AI-1+AI-11, AI-8, and AI-10's evidence-doc lints are scoped to `04-projects/**` in cog-second-brain. No overlap in scan roots, no duplicate check.
- **AI-10 vs AI-8, direct question asked:** not the same tool. AI-8 fires on a missing `git status --porcelain` beside a retire/archive verdict; AI-10 fires on a piped `grep`/`rg`/`find` with no paired count. Different trigger pattern, different fail condition, independently proposed and independently survived the AC-4 challenge (round 1: AI-8 "CHALLENGED (strong)", AI-10 "CHALLENGED (moderate)" — CP-3v-challenge-round1.md). Both may end up as functions in one file; that would still be two checks, not one check counted twice.
- AI-12's proposed `deprecated_symbols_test.go` is explicitly framed as a new sibling file, not a modification or duplicate of `documented_verbs_test.go`. Checked its cited example (`catalog.MatchRoutes` in `internal/selector/selection.go`): no `// Deprecated:` tag and no CHANGELOG mention exist today, so the cited instance is historical (already resolved or superseded elsewhere), consistent with how `documented_verbs_test.go`'s own header cites historical instances it was written against. Not a live contradiction; the proposed test doesn't yet exist so there's nothing for it to duplicate.
- `.claude/lib/ci-status.sh` and `checkpoint.sh` (both read in full) cover CI-status freshness and checkpoint recording respectively — neither overlaps any of the 9 proposed controls' subject matter.

## 5. Traceability closure

Ran `phase-gates.sh` directly against the goal folder (observing the artifact, not the workers' summaries):

```
$ bash .claude/lib/phase-gates.sh 04-projects/controls-not-advice
P1     NEVER RUN: CP-4 CP-5
```

This is the expected, correct state at this point in the pipeline: CP-4 is this task (running now), CP-5 (acceptance) is next. `spec.md`'s traceability table and `STATUS.md`'s "Open AC-n" section still read all-pending / "not started" — also expected, since both are conventionally updated at CP-6 closeout, which hasn't run. Neither is a P1 defect.

One divergence worth recording: `spec.md`'s own phase table (`Phases` section) describes P1 as needing to "prove the two superseded ones are superseded" (referring to AI-1/AI-11, based on the baseline table's "Migration-plan guidance (target shipped)" row). The actual triage classified **zero** items `superseded` — AI-1+AI-11 became a merged `control` instead, on the reasoning that the rule is forward-looking (applies to future migration plans) rather than a dead reference to the one already-shipped plan. This is visible, reasoned, and covered by CP-2's own T-03 ("Disposition AI-1 and AI-11, with evidence for or against superseded") — the triage answered "against." AC-5 is satisfied vacuously (nothing is claimed superseded without evidence, because nothing is claimed superseded). But `spec.md`'s phase-table prose is now stale relative to the actual outcome and will read as unfulfilled to a reader who doesn't open `evidence/P1/`. Cosmetic, not blocking — worth a one-line correction at CP-6.

No AC belonging to a later phase (AC-2, AC-3, AC-6, AC-7) is claimed as done anywhere in P1's evidence.

## Verdict

No cross-task contradiction, no artifact collision with existing tooling, no scope creep into later phases' criteria. Two documentation-clarity gaps found (AI-3/AI-13 and AI-8/AI-10 artifact-boundary ambiguity; spec.md's stale "two superseded" phrasing) — both fixable in a sentence, neither blocks P2/P3 from proceeding, neither contradicts AC-1/AC-4/AC-5's already-PASSed CP-3v evidence.

```
VERDICT: PASS
INTEGRATION_CLAIMS_CHECKED: 13
EVIDENCE:
EVIDENCE AC-1 | CP-4 | PASS | No stale cross-references remain after the round-3 AI-9/AI-2 fix; full re-scan of CP-3-triage.md found no other item contradicting another's disposition reason | CP-3-triage.md:39, CP-3v-round3.md
EVIDENCE AC-1 | CP-4 | PASS | AI-5's claim that phase-gates.sh has no task-count logic re-confirmed by reading the live script | .claude/lib/phase-gates.sh
EVIDENCE AC-1 | CP-4 | PASS | AI-3's cited live defect (LookPath("git") only, then go build with no LookPath("go") guard) re-confirmed in guard_binaries_test.go; AI-13's cited pattern (t.Skipf reports tool name only on failure) re-confirmed in packaged_selector_test.go | ~/sdk/cadre/internal/generators/guard_binaries_test.go:66-71, packaged_selector_test.go:104-106
EVIDENCE AC-4 | CP-4 | PASS | Round 1 challenge (CP-3v-challenge-round1.md) is independently reasoned against original retro text, not the triage's own summaries — genuine adversarial pass, not self-grading | CP-3v-challenge-round1.md
EVIDENCE AC-5 | CP-4 | PASS | Zero items dispositioned superseded; AC-5's evidence requirement is therefore vacuously satisfied. AI-6a is the sole landed claim, independently traceable to WORKFLOW.md:72 and commit 6d09b29 | CP-3-triage.md, CP-3v-round3.md
EVIDENCE cross-task | CP-4 | PASS | 9 controls checked for buildability collision: no lint requires what another forbids; AI-3/AI-13 and AI-8/AI-10 share subject-matter scope but check distinct properties, not duplicates | CP-3-triage.md control table
EVIDENCE cross-task | CP-4 | PASS | No proposed control duplicates documented_verbs_test.go or duplicate_paragraphs_test.go — different scan roots (cadre roster/ vs cog-second-brain 04-projects/**) | ~/sdk/cadre/internal/cli/documented_verbs_test.go, duplicate_paragraphs_test.go
EVIDENCE cross-task | CP-4 | PASS | AI-8 and AI-10 confirmed as two distinct checks (different trigger pattern, independently challenged and reclassified), not the same tool | CP-3v-challenge-round1.md, CP-3v-round2.md
EVIDENCE AC-3/AC-6 (P3 forward) | CP-4 | PASS | All 5 advice items reduce to one placeable sentence with a stated reason; AI-14 is the thinnest and flagged as provisional by its own row | CP-3-triage.md advice table
EVIDENCE AC-7 (P4 forward) | CP-4 | PASS | P1's structural/residual split method generalizes into a retro-time question ("does this defect have a checkable signature distinct from its prose form") without needing this triage's specific context | CP-3-triage.md "The method round 1 applied unevenly"
EVIDENCE traceability | CP-4 | PASS | phase-gates.sh run directly against the goal: correctly reports CP-4/CP-5 never run for P1, nothing else missing — matches actual pipeline position | bash .claude/lib/phase-gates.sh 04-projects/controls-not-advice
EVIDENCE traceability | CP-4 | PASS | spec.md/STATUS.md pending-state is expected pre-CP-6, not a P1 defect | spec.md Traceability section, STATUS.md
EVIDENCE traceability | CP-4 | PASS (advisory) | spec.md's phase-table text ("prove the two superseded ones") is stale against the actual zero-superseded outcome; cosmetic, fixable at CP-6 | spec.md Phases section vs CP-3-triage.md tally
FAILURES:
(none blocking)
```
