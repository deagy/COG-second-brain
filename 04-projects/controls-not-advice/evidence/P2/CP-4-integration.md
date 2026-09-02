# CP-4 integration verification — controls-not-advice P2

**Verdict: PASS**

Scope: nine controls built across cadre, gloop, and the vault (`.claude/lib/{evidence-lint,spec-lint,phase-gates}.sh`), claiming AC-2. CP-3v already passed after two rounds on individual falsifications (not re-verified here). This checkpoint re-observed cross-task wiring: script-vs-script coherence, retroactive effect of the AI-5 phase-gates rule on closed phases, SKILL.md accuracy, P1-triage-vs-P2-build drift, blast radius on two closed goals, and traceability containment.

## 1. Do the three vault scripts contradict each other?

No. Ran all three over `controls-not-advice`, `repo-consolidation`, `capability-parity`:

- `phase-gates.sh` reads `evidence/P*/evidence/checkpoints.tsv` + `CP-2-plan.md` task counts.
- `evidence-lint.sh` reads prose inside `evidence/**/*.md` (inventory/salvage/axes patterns).
- `spec-lint.sh` reads only `spec.md`.

Disjoint inputs, disjoint failure vocabularies — no case where one script's PASS condition is another's FAIL condition on the same artifact. `evidence-lint.sh`'s one real finding (`repo-consolidation/evidence/P3/CP-2-plan.md` missing the `destination-already-does` axis) sits on a phase `phase-gates.sh` reports as fully recorded — different lenses (checkpoint bookkeeping vs. content quality), not a conflict.

## 2. Did the AI-5 task-count rule retroactively flip any phase's verdict?

No, confirmed by running both script versions, not by inspection. Recovered the pre-AI-5 `phase-gates.sh` (`git show 0a80ed3:.claude/lib/phase-gates.sh`) and diffed its output against the current version over all three goals:

```
controls-not-advice: identical (P1 pass, P2 NEVER RUN: CP-4 CP-5)
repo-consolidation:  identical (P1 NEVER RUN: CP-4; P2 NEVER RUN: CP-5; P5 NEVER RUN: CP-3v)
capability-parity:   identical (all phases recorded, exit 0)
```

Reason the rule is a no-op here: the AI-5 branch only changes `phase_required` when a phase's `CP-2-plan.md` names **exactly one** task. Task counts across every phase in the three goals: controls-not-advice P1=5, P2=0(no plan tasks); repo-consolidation P1=6, P2=3, P3=6, P4=6, P5=0; capability-parity P2=0, P4=4 (P1/P3 have no `CP-2-plan.md` file). None equals 1, so `phase_required` never narrows — the new rule is dormant on every phase that exists today. No cross-phase regression.

The repo-consolidation P1/P5 and capability-parity original-five-phase CP-4 gaps are pre-existing and already independently discovered/documented by those goals' own north-star audits (`repo-consolidation/evidence/P5/north-star-evidence-audit.md`, capability-parity's `evidence/CP-4-integration.md` retrospective CP-4 run under "AI-15") — not new findings surfaced by controls-not-advice.

## 3. Is the SKILL.md gate section coherent?

Yes. `.claude/skills/ultragoal/SKILL.md` names `spec-lint.sh` once (line 52, CP-1 charter, "before recording CP-1") and `ci-status.sh`/`phase-gates.sh`/`evidence-lint.sh` together under "The two acceptance gates" (lines 116-215, run before per-phase CP-5 and the final north-star gate). Each script's stated reason matches its code:

- spec-lint section (lines 55-72) describes the `released` and `negative` shapes and states the verified-skip explicitly: "skips any criterion the traceability matrix records as `verified`." Checked against the script: `grep -qE "^\| *$id *\|.*\| *verified *\|" "$spec"` — literal string match on the row, exactly as described, no hedging or overclaim. Matches the mechanism CP-3v round 2 stress-tested (and flagged, correctly, as trusting the string rather than auditing it — the SKILL.md text doesn't overclaim beyond that either).
- phase-gates section (163-176) states "whenever the phase's plan names more than one task" and "a plan naming no tasks is treated as owing CP-4" — both match the code (`tasks = "1"` branch only).
- evidence-lint section (190-207) matches the three checks (inventory/salvage/axes) verbatim in intent.

One soft note, not a defect: running `phase-gates.sh` "before" a phase's own CP-5 will trivially report that phase's own not-yet-run CP-4/CP-5 as `NEVER RUN` (observed live: controls-not-advice P2 shows exactly this). That's expected noise for an in-flight phase, not a false claim — the script's purpose is catching *prior* phases silently skipped, and it does that; SKILL.md doesn't claim otherwise.

## 4. Do P1's dispositions and P2's builds agree?

Mostly, with disclosed drift. Compared `evidence/P1/CP-3-triage.md`'s "what the check observes" column against `evidence/P2/CP-3-build.md`'s "check" column for all 9 controls:

| ID | Triage promised | Build delivered | Drift |
|---|---|---|---|
| AI-5 | absent CP-4 row/file | task-count rule in `phase-gates.sh` | none — exact match |
| AI-8, AI-10, AI-1+AI-11 | retire-verdict / inventory-truncation / axes checks | same properties, in `evidence-lint.sh` | home only (triage guessed separate scripts; consolidated) |
| AI-4b | CP-4 integration check | `spec-lint.sh` at CP-1 | home only, earlier and stricter (catches at charter instead of after the fact) |
| AI-12 | deprecation-parity, "sibling to `documented_verbs_test.go`" | gloop `internal/docguard/`, `TestProseDoesNotDeprecateWhatTheSourceKeeps` / `TestEveryDeprecatedSymbolIsAnnounced` | home guess wrong (`documented_verbs_test.go` actually lives in **cadre**, not gloop) but the built location is the *correct* one — gloop is where `catalog.MatchRoutes` actually lives |
| AI-3 | "guard on `LookPath("go")` before build" | "toolchain absence must skip" (`TestAToolchainInvocationIsGuardedBySomethingThatSkips`) | **property narrowed** — checks skip-on-absence, not presence of a specific `LookPath` guard. Disclosed by name in CP-3-build.md's "What building them changed" section |
| AI-13 | "resolved path reported on success" | "resolved tool not discarded to `_`" (`TestAResolvedToolIsNamedOnTheSuccessPath` — the name overclaims what the test checks) | **property narrowed**, disclosed in both CP-3-build.md and CP-3v-round1.md ("AI-13 honesty assessment": narrower guarantee than the retro's actual incident) |
| AI-4a | "CP-6-publish cross-check" | "verified-skip + phase-naming grep discharge" in `spec-lint.sh` | **property changed**, this is the exact defect CP-3v round 1 caught and round 2 fixed — extensively documented, not silent |

Every drift is one the evidence trail already names and reasons about openly (`CP-3-build.md` § "What building them changed about the classification", CP-3v round 1's whole report). None is a silent cross-task break — the trail's own self-awareness here is unusually good, which is exactly what AC-2's bar and this checkpoint's job are for. Flagging it as an observed pattern rather than a failure: three of nine controls guarantee a materially different (usually narrower) property than what P1 dispositioned, and none of the three drifted-to properties were re-checked against P1's *triage table itself* — only against the originating retro language. Worth a P2 retro action: reconcile the triage table's "what the check observes" column with what actually shipped, so a cold reader of P1 alone isn't misled about AI-3/AI-13/AI-4a's actual guarantee.

## 5. Blast radius on the two closed goals

No genuine new defect surfaced. `evidence-lint.sh` and `spec-lint.sh` run over `repo-consolidation` and `capability-parity`:

- `evidence-lint.sh` on repo-consolidation: 1 finding, `evidence/P3/CP-2-plan.md` missing the `destination-already-does` axis — this **is** the AI-1+AI-11 originating defect, preserved in the historical P3 record precisely because P3 was superseded by P4 (which is clean) rather than rewritten. Expected, not a regression.
- `evidence-lint.sh` on capability-parity: clean.
- `spec-lint.sh` on both: clean (both current specs' AC rows are `verified` and hit the skip, or were never unbounded/published-artifact-shaped to begin with).
- `phase-gates.sh` on repo-consolidation surfaces P1/P2/P5 gaps that repo-consolidation's own `evidence/P5/north-star-evidence-audit.md` and P5 retro already found, disclosed, and (per STATUS.md) partially left open by design (AC-07b/AC-10b deferred, tracked) — not something these new lints would have silently blocked a gate on; the gate already caught and recorded these itself, independently, before this goal existed.
- `phase-gates.sh` on capability-parity: clean — its original 5-phase CP-4 skip (AI-5's origin story) was already repaired retroactively under a separate item ("AI-15") before P2 built anything; every phase's `checkpoints.tsv` now carries a CP-4 PASS row dated 2026-09-02T01:00:10Z.

Neither closed goal would have failed its own north-star gate on account of anything P2 built. The one finding on repo-consolidation is a historical record correctly still showing the defect it was created to record.

## 6. Traceability containment

Confirmed. `04-projects/controls-not-advice/spec.md` traceability matrix: AC-1/AC-4/AC-5 = `verified` (P1), **AC-2 still reads `pending`** (P2's CP-3v passed but CP-5/CP-6/STATUS update haven't run yet — correct ordering, not premature), AC-3/AC-6/AC-7 = `pending`, untouched. Grepped every P2 evidence file for stray `AC-3`/`AC-6`/`AC-7` claims: none exist outside the false-positive-sweep table in `CP-3v-round2.md`, which cites them only to confirm the traceability matrix's own state (not to claim them). P2 claims AC-2 alone.

## Repository cleanliness

`/home/deagy/sdk/cadre` and `/home/deagy/sdk/gloop`: clean, `git status --porcelain` empty. Vault (`/home/deagy/cog-second-brain`) carries pre-existing uncommitted changes from the CP-3v round-2 pass (`evidence/P2/CP-3-build.md` +8 lines, `evidence/P2/evidence/checkpoints.tsv` +1 row, untracked `evidence/P2/CP-3v-round2.md`) — present before this verification began, not introduced by it. This CP-4 pass used only `Read`, `Bash` (cat/grep/diff/find/mktemp scratch files under `/tmp`), and one throwaway `old-phase-gates.sh` copy in the session scratchpad; no edits were made to any repository.

---

VERDICT: PASS
INTEGRATION_CLAIMS_CHECKED: 6
EVIDENCE:
EVIDENCE AC-2 | CP-4 | PASS | phase-gates.sh / evidence-lint.sh / spec-lint.sh read disjoint inputs (checkpoints.tsv+CP-2-plan.md vs. evidence/**/*.md prose vs. spec.md) and never contradict on a shared artifact across all three goals | direct runs, 04-projects/{controls-not-advice,repo-consolidation,capability-parity}
EVIDENCE AC-2 | CP-4 | PASS | AI-5 task-count rule is a no-op on every phase in all three goals today (no phase has exactly 1 task); old (0a80ed3) vs current phase-gates.sh produce byte-identical verdicts on all three goals — no retroactive regression | diffed script output, old script recovered via `git show 0a80ed3:.claude/lib/phase-gates.sh`
EVIDENCE AC-2 | CP-4 | PASS | SKILL.md's spec-lint/phase-gates/evidence-lint sections state mechanisms that match the code exactly, including the verified-skip's literal-string nature | .claude/skills/ultragoal/SKILL.md:48-215 vs .claude/lib/{spec-lint,phase-gates,evidence-lint}.sh
EVIDENCE AC-2 | CP-4 | PASS (with disclosed drift) | 6 of 9 controls match P1's dispositioned observable exactly or match on location-only; AI-3/AI-13/AI-4a guarantee a narrower/different property than triage promised, but every drift is named and reasoned about in CP-3-build.md and CP-3v-round1.md — no silent break | evidence/P1/CP-3-triage.md vs evidence/P2/CP-3-build.md
EVIDENCE AC-2 | CP-4 | PASS | new lints produce zero findings on capability-parity and exactly one historically-expected finding on repo-consolidation (the AI-1+AI-11 originating defect, preserved in a superseded P3 record); neither closed goal's north-star gate would have been newly blocked | evidence-lint.sh/spec-lint.sh runs over 04-projects/{repo-consolidation,capability-parity}; repo-consolidation/evidence/P5/north-star-evidence-audit.md
EVIDENCE AC-2 | CP-4 | PASS | spec.md traceability shows AC-2 still `pending` (correct pre-CP-5 state) and AC-3/AC-6/AC-7 untouched at `pending`; no P2 evidence file claims them | 04-projects/controls-not-advice/spec.md:65-71; grep -rE 'AC-[0-9]+' evidence/P2/*.md
FAILURES:
(none — one non-blocking observation recorded under check 4: reconcile P1's triage table wording for AI-3/AI-13/AI-4a with the narrower property each check actually ships, so a cold reader of P1 alone isn't misled)
