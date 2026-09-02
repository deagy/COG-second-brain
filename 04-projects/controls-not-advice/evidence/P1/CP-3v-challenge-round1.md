# Adversarial challenge — P1 triage (`04-projects/controls-not-advice/evidence/P1/CP-3-triage.md`)

Read-only. All eleven `advice` calls reviewed against their originating retro defects (not just the triage's summary of them). Two pre-flagged items (AI-7, AI-9) confirmed but not dwelt on, per instructions — they matter here mainly as a **consistency baseline**: several unflagged items use the identical "check the precondition, not the judgment" shape that got AI-9 conceded, and weren't held to the same standard.

## `advice` items, individually

### AI-1 + AI-11 (merged) — CHALLENGED
Reason given: "A check could assert five headings exist and nothing about whether the inventory was done." True as far as it goes, but the actual originating defect (P3 retro) was not a *badly filled* axis — it was a **missing axis entirely**: "The destination was never inventoried. AI-1 requires four axes of the source. All four were run on cadre and none on gloop." That is a structural absence, exactly what a structural check catches.

**Observable:** a port/extraction plan doc (`evidence/P*/CP-2-plan.md` under any future migration goal) contains five required section headings (imports, prose mentions, data readers, releasable-component models, destination-does-already) each followed by ≥1 bullet before the next heading.
**Where it lives:** a CP-2 gate script (sibling to `phase-gates.sh`) run against any plan doc tagged as a port/extraction plan, or a `.claude/skills/ultragoal/SKILL.md` § Phase 0 requirement enforced the same way `phase-gates.sh` enforces checkpoint presence.
**Fails when:** a required heading is absent, or present with zero bullets under it — which is precisely the AI-11 shape ("none of them look at what it moves into" = the fifth heading never existed).
It won't catch a *dishonest* inventory (real content, wrong conclusions) — that residual is legitimately advice — but the triage classified the whole item as advice without carving out the structural half it just used to build AI-3.

### AI-2 — CHALLENGED (strong)
Reason given: "The defect happens in a question posed to the user. There is no artifact to inspect, and any check would have to run before the message is sent." That "before the message is sent" framing is not a reason it can't be a control — it's a description of exactly where a precondition gate belongs.

Grounding from the P1 retro: the defect was proposing `cadre-lifecycle` as a repo name/destination to the user off a misread citation, with nothing checking GitHub for it. The retro itself notes the save came from luck: *"`gh repo create` refusing a name was the only thing standing between the session and pushing into an archived repository."* That refusal already proves the check is mechanical — `gh repo create`/`gh repo view` already implements it, just too late (at creation, not at the question).

**Observable:** before any assistant message proposing a repository/branch name or destination to the user for a decision, a `gh repo view <candidate>` (or `gh api repos/<owner>/<candidate>`) call has run in that turn and its exit code/status is quoted in the message.
**Where it lives:** same class of artifact as AI-9's conceded fix — a pre-question check step in the skill governing user-facing naming decisions (e.g. `.claude/skills/ultragoal/SKILL.md` or the closed-loop CP-6 user-gate step), or a transcript lint equivalent to what AI-9 proposes for visibility.
**Fails when:** a naming/destination question is put to the user without a preceding existence-check tool call in the transcript for that turn.
This is structurally identical to AI-9 (already conceded feasible) — "check X before reasoning about Y put to the user" — yet AI-9 was flagged and AI-2 wasn't. That inconsistency is the strongest single finding in this pass.

### AI-4 — CHALLENGED (strong)
Reason given: "Requires understanding what the phase does. A schema check reaches the matrix's shape, never whether a criterion is reachable from inside its phase." The general prose form does resist full automation, but the retro names two concrete defect instances, and both are independently checkable — the same narrowing the triage itself applied to turn AI-3's unmechanizable prose into a control:

- **AC-03** ("acceptance by the *released* kernel"): a criterion whose own verification step fetches from a location (GitHub release, package registry) that this phase's own CP-6 is what populates. **Observable:** an AC's verification text names a network fetch (`gh release download`, `pip install`, `docker pull`, `curl <registry>`) of an artifact this same phase publishes, and the AC's phase has not yet recorded a CP-6 PASS. **Where it lives:** a CP-1 spec lint run at chartering, cross-referencing the AC verification column against the phase's own CP-6 record. **Fails when:** such a fetch is named for a not-yet-shipped phase's own output — a circular-verification-ordering defect, mechanically detectable.
- **AC-04** ("no third definition exists"): a universal-negative claim over the whole fleet of repos. This is the exact shape `documented_verbs_test.go` and the AC-7 drift guard already check (per the spec: *"the AC-7 drift guard failed on a phantom verb in eight falsifications"*). **Observable:** grep across the known repo set for definitions of the named symbol/type; count == 1. **Where it lives:** as a CP-4 integration-verifier check, identical in kind to checks this project has already shipped. **Fails when:** count != 1.

Both instances are catchable; the triage never attempted the narrowing it used elsewhere.

### AI-6b — UPHELD
Origin (P2 retro): a criterion read generously in the lead's own favor ("an archived file cannot drift" as a defense against "no definition exists outside the kernel"). Checked whether the landed AI-6a text (WORKFLOW.md:72-76, confirmed added 2026-09-01 in commit `6d09b29`) already absorbs this — it doesn't; that section is entirely about *editing* a criterion after a failing finding, not about *interpreting* an unedited, ambiguous one. No syntactic pattern reliably distinguishes a literal from a generous reading; the only mechanism that reaches it is an independent verifier reading the unedited text (which the harness already has, via CP-3v). Genuinely advice — but note the residual is thin: most of what AI-6 named is now covered by AI-6a, and what's left is a normal judgment call inherent to any verifier role, not a special gap.

### AI-8 — CHALLENGED (strong)
Reason given: "A judgment about worth. Nothing can decide what is worth salvaging." That attacks a claim the item doesn't make. AI-8 doesn't ask a check to judge salvage *value* — it asks that the working tree be *inspected* before the value-judgment is made. Origin (P2 retro): *"The salvage assessment was made from committed state only. 209 lines sat uncommitted in the working tree, including the very artifact that turned out to be worth salvaging."*

**Observable:** before a CP-2/CP-3 evidence entry records a "nothing survives" / archive / retire verdict for a repository, a `git status --porcelain` (or `git status` output) for that repository's working tree is quoted in the same evidence file.
**Where it lives:** a check paired with the retire/archive step, structurally identical to `phase-gates.sh` — fail if a retire-verdict evidence file exists with no working-tree-state line, or if the working-tree state shows uncommitted changes with no corresponding acknowledgment in the assessment prose.
**Fails when:** either condition above holds.
This is the same "precondition, not judgment" shape the triage used to concede AI-9. It should have been conceded on the same grounds.

### AI-10 — CHALLENGED (moderate)
Reason given a global `| head` scan would fire on legitimate uses "far more often than right, and would be disabled" — correct as a global rule, but the triage only evaluated the global version. Origin (P3 T-05 defect): a `grep ... | head -10` inside a documented inventory step was treated as complete (11 real hits, 31 in the full count).

**Observable, narrower scope:** inside CP-2/CP-3 evidence markdown specifically (not arbitrary shell usage anywhere), a fenced code block whose command pipes a search/inventory command (`grep`, `rg`, `find`) into `head`/`tail`, with no adjacent `wc -l` (or explicit "N total" count) for the same query.
**Where it lives:** an evidence-doc lint, scoped to files under `evidence/P*/` that are tagged as inventories — same category of artifact `duplicate_paragraphs_test.go` already scans.
**Fails when:** such a pipeline appears with no paired total count in the same evidence file.
Scoped to the artifact type where the actual defect occurred, the false-positive risk the triage cites drops substantially — it doesn't touch ad hoc bash use outside evidence docs.

### AI-12 — CHALLENGED (partial/moderate)
Triage already concedes drift and duplicate-paragraph checks cover part of this. The originating P3 instance not yet covered: *"a changelog said a function would be removed after the source had un-deprecated it"* — `catalog.MatchRoutes` un-deprecated in source, CHANGELOG still described it as scheduled for removal. This is a narrow, syntactically-detectable pattern in Go: `// Deprecated:` is a fixed doc-comment convention.

**Observable:** for every symbol carrying (or not carrying) a `// Deprecated:` comment in source, cross-reference CHANGELOG.md / README mentions of that symbol's deprecation status; flag a mismatch.
**Where it lives:** a sibling test to `documented_verbs_test.go`, e.g. `deprecated_symbols_test.go`.
**Fails when:** CHANGELOG/README asserts deprecated for a symbol whose source no longer carries the tag, or vice versa.
The general "find its prose twin" habit stays advice; this specific, recurring defect shape does not.

### AI-14 — CHALLENGED (weak/moderate, partial)
Origin: *"An environment note was filed as trivia and was not. P1 recorded 'installed kernel 0.13.2, repository 0.14.2' as a curiosity... a guard checking the wrong artifact."* This is the retro-writing-side twin of AI-13 (already `control`). Once AI-13 ships (guard logs which version it resolved), the version-mismatch text pattern in evidence notes ("installed X, repository/pinned Y", two differing version strings) becomes mechanically detectable independent of any judgment about "trivia vs. finding":

**Observable:** an evidence note matching a version-pair pattern (two version numbers for the same tool/artifact, differing) with no adjacent resolution/decision line.
**Where it lives:** an evidence-doc lint alongside AI-13's guard-logging change; effectively subsumed by building AI-13 properly.
**Fails when:** such a pattern appears unresolved.
The general epistemic stance ("treat notes as findings until shown otherwise") genuinely can't be checked in full — most environment notes aren't version-pair-shaped — but the one concrete instance that generated this item already reduces to AI-13's mechanism, so it shouldn't have needed its own separate advice entry at all.

## Independent checks

**1. AI-3's claimed live defect — CONFIRMED.**
Read both files directly. `guard_binaries_test.go:71-73` guards only on `git` (`exec.LookPath("git")`, `t.Skip` if absent), then at line 86 runs `exec.Command("go", "build", ...)` with no prior `go` toolchain check; failure there hits `t.Fatalf` (line 89-91), not a skip. `packaged_selector_test.go:105-109` correctly loops over `[]string{"git", "go"}` and skips on either being absent. The codebase does disagree with itself exactly as claimed — not hypothetical.

**2. AI-6a genuinely landed — CONFIRMED, split is honest.**
`WORKFLOW.md:72-76` was added in commit `6d09b29` (2026-09-01, verified via `git log -S`/`git show`), and its text — "amending a criterion after a finding that would fail it... is not an amendment" — matches the "rewrite before the phase closes" half of AI-6's original wording (`BACKLOG.md` AI-6). It does not, and was never claimed to, cover the "literal reading governs, never read generously" half — that's a genuinely distinct failure mode (editing the test vs. misreading an unedited one), correctly carried forward as AI-6b rather than silently dropped.

**3. AI-5's proposed rule vs. `phase-gates.sh` — CONFIRMED, with one nuance.**
Read the script directly (not the description). `required="CP-3 CP-3v CP-4 CP-5"` is applied uniformly to every phase — the script itself contains **no task-count logic**; the "CP-4 owed only when phase has >1 task" rule is not encoded in the script, only assertable in prose (per the plan for P2/P4 of this goal). What the script does correctly do, verified by reading the awk logic (lines 73-91): a checkpoint row present in `checkpoints.tsv` column 2 — regardless of PASS/FAIL/SKIP in column 3 — counts as "recorded," so a `SKIP` row satisfies it; a checkpoint with neither a `.tsv` row nor an evidence file is reported `NEVER RUN` and drives a non-zero exit. So: bare absence → failure (confirmed), recorded SKIP → satisfied (confirmed), but the *task-count threshold itself* is not something the script enforces or could enforce without reading the plan — that part of AI-5's answer is a stated rule for humans/skills to apply, not a mechanized gate, and the triage's phrasing ("the control exists") slightly overstates how much of the rule the script actually encodes.

**4. Merged AI-1+AI-11 "P3 plan shipped 2026-08-30" — CONFIRMED.**
`04-projects/repo-consolidation/evidence/P3/evidence/checkpoints.tsv` shows CP-5 (acceptance) at `2026-08-30T00:16:24Z` and CP-7 (retro) at `2026-08-30T00:21:47Z` — P3 closed 2026-08-30 as claimed (git commit dates read 2026-08-29 due to local-timezone day-boundary rounding, not a discrepancy). `evidence/P3/CP-2-plan.md` exists and is the real plan artifact AI-1 targeted. AI-11's own text (P3 retro, filed after P3 shipped) confirms the plan already existed and was missing the fifth axis — so the "apply before the P3 plan is written" instruction is indeed temporally spent for that specific artifact.

## Overall judgment

11-of-14 as advice is not defensible as triaged. Of the eight non-pre-flagged `advice` items scrutinized, seven yield a concrete, boundable observable once tested against the *actual originating defect* rather than the item's generalized prose — the same narrowing move the triage itself used to convert AI-3 and AI-5 into controls, but declined to apply to the rest. Two items (AI-2, AI-8) are especially damaging: both have the identical "check the precondition before the human/judgment step" shape that the triage already conceded feasible for AI-9, and both were nonetheless filed as advice with no acknowledgment of the parallel. Only AI-6b survives scrutiny as clean advice with no exploitable narrower slice.

This matches the spec's own prediction (AC-4: "classifying an item as advice is the cheap disposition and the lead is the one doing the classifying") almost exactly — the pattern here isn't that the individual reasons given are dishonest, it's that the same narrowing technique was applied inconsistently: used to rescue AI-3/AI-5 into `control`, withheld from items that would have required actually building something. A defensible P1 closeout would carve controls out of AI-1+AI-11 (structural headings), AI-2 (name-existence precondition), AI-4 (two concrete lint shapes), and AI-8 (working-tree precondition) at minimum, and downgrade AI-10, AI-12, AI-14 to narrower control + genuinely-residual-advice pairs the way AI-3 and AI-6 were split.
