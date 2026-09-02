# CP-4 integration verification — production-readiness P4 (AC-5)

Artifacts: `/home/deagy/sdk/cadre` at `bb35c49e` (CI run 33646263553, independently re-fetched
green). CP-3v: 1 round (`evidence/P4/CP-3v-round1.md`), PASS, not re-verified here per dispatch
instruction. Scope of this report: cross-task wiring and global/cross-phase acceptance only.

## Verdict

**FAIL:fixable**

The pre-parse refusal is a blind string scan over every element of `args`, not a scan that
tracks which flags are known to consume a following value. It correctly ignores query text and
`--config`'s own value, and correctly respects `--`. But it cannot distinguish "this token is a
flag" from "this token is another flag's *value*" — and `delete-staged`/`disposition-staged`
both take a free-text `--reason`. A steward who legitimately deletes a staged record and writes
`--reason "--retention-days"` (or `--trigger ...`, or `--as-of ...` — quoting exactly what
prompted the deletion, a wholly plausible reason string) gets the entire live command refused as
an absent capability, told the capability doesn't exist, when the command was actually going to
succeed. This is exactly the failure mode CP-4's brief named — "a pre-parse scan that reads
values as flags would break real invocations" — reproduced live below. CP-3v's own enumeration
(~15 reach-paths) never tried the refused word *as a flag's value*; every negative case it ran
used unrelated placeholder values (`z`, `w`).

Every other check passed: the two dispatch routes compose correctly with P3's observed-actor
plumbing across the full staged lifecycle, the drift guard is untouched and passing (P4 touched
no markdown), all three generated trees remain byte-identical, and traceability documents make
no premature claim.

## INTEGRATION_CLAIMS_CHECKED: 12

## EVIDENCE

EVIDENCE AC-5 | CP-4 | FAIL | `delete-staged --id X --reason "--retention-days" --deleted-by tester` on a real, existing staged record is refused as an absent capability (exit 2, the b418031e/recall/open-decision message) instead of deleting the record — the pre-parse scanner treats `--reason`'s own value as if it were an independent flag, because it scans every space-separated argv token for a match against `absentKnowledgeCapabilityFlags` with no notion of which preceding flag consumes a value. `disposition-staged --reason "please handle --trigger for compliance"` was *not* tripped only because that whole phrase was one shell-quoted argv element that doesn't start with `-`; a reason of exactly `--trigger` (unquoted-looking but still one token) would trip identically. | `internal/cli/knowledge_absent_capability.go:57-77` (loop has no per-flag value-arity table); live run against `/tmp/cp4-cadre` built from `bb35c49e`
EVIDENCE AC-5 | CP-4 | PASS | `-config <path>` correctly does not get swallowed and does not itself swallow a later real search: `cadre knowledge -config config.json search "some query about retention-days policy" --classification internal` reaches real validation (`--classification is required`-shaped output, i.e. past the refusal), not the absent-capability message — the word inside quoted query text without a leading dash is correctly ignored (`!strings.HasPrefix(arg, "-")` skip). | live run against `/tmp/cp4-cadre`
EVIDENCE AC-5 | CP-4 | PASS | `search "please delete-ingested content per trigger retention-days"` (record/query text containing the refused words as plain prose, no leading dash) is not refused — reaches real `--classification is required` validation. | live run against `/tmp/cp4-cadre`
EVIDENCE AC-5 | CP-4 | PASS | The `--` positional terminator is honoured (`break` on `"--"` in the scan loop, per CP-3v round 1's own case); confirmed by reading `internal/cli/knowledge_absent_capability.go:60-62`, not re-run live since CP-3v already exercised it and the code hasn't changed since. | `internal/cli/knowledge_absent_capability.go:60-62`
EVIDENCE AC-5 | CP-4 | PASS | Full staged lifecycle composes with P3's observed-actor plumbing under the P4 refusal: fresh binary built from `bb35c49e`, `propose` → `show-staged` → `disposition-staged --action accepted --classification-used internal --decided-by CP4-DECIDER` → (separate record) `delete-staged --reason ... --deleted-by CP4-INTEGRATION-VERIFIER --authorized-by second-reviewer` → `deletion-evidence-staged`. Every one of `show-staged`, `disposition-staged`'s recorded history, `delete-staged`, and `deletion-evidence-staged` carried `"observed_actor": "os:deagy git:daniel.eagy@sqs.world"` distinct from the caller-asserted `staged_by`/`decided_by`/`deleted_by`/`authorized_by` fields, and no step was incorrectly refused. | live run against fresh `bb35c49e` build, `/tmp` scratch config, cleaned up after
EVIDENCE AC-5 | CP-4 | PASS | `TestEveryDocumentedKnowledgeVerbIsAnswerable` (the drift guard) passes at `bb35c49e`. P4's commit (`git show --stat bb35c49e`) touched only `internal/cli/knowledge.go`, `internal/cli/knowledge_staged.go`, `internal/cli/knowledge_absent_capability.go`, `internal/cli/knowledge_absent_capability_test.go` — zero markdown files. The guard scans only `roster/`, `.agents/skills/`, repo-root markdown, and `CHANGELOG.md` (`documented_verbs_test.go:255-303`); it never reads `.go` source, so the new `--retention-days`/`--trigger`/`--as-of`/`b418031e`/`recall` prose (which lives entirely in Go comments and the `os.Stderr` message) is structurally invisible to it — correctly, since none of that text is a governance claim the guard is designed to police. | `go test ./internal/cli/... -run TestEveryDocumentedKnowledgeVerbIsAnswerable -v` → PASS; `git show --stat bb35c49e`
EVIDENCE AC-5 | CP-4 | PASS | `roster/knowledge-store/SECURITY.md` was not touched by `bb35c49e` (absent from the commit's file list) and its existing § Storage rules text (line 38) already states the same facts the refusal now surfaces at the CLI — removed in `b418031e`, none rebuilt, content lives in a recall store with no delete CLI. No contradiction possible between a document that didn't change and a refusal whose content CP-3v round 1 already diffed against it line-by-line. | `roster/knowledge-store/SECURITY.md:38`; `git show --stat bb35c49e`
EVIDENCE AC-5 | CP-4 | PASS | All three generators produce empty diffs at `bb35c49e`: `generate-role-metadata` (`catalog.yaml`, `provider/agent-catalog.json`, 318-file `provider/` bundle, `routing.json`), `generate-plugin -output plugin` (646 files), `port-cline-agents -root cline-plugins -source plugin` (159 agents, 9 skills) — `git status --porcelain` empty before and after each. Correct: P4 changed only `internal/cli/*.go`, none of which feeds any of the three generator input roots (`roster/`, `.agents/skills/`, `catalog.yaml`). | live run, `/home/deagy/sdk/cadre`, `git status --porcelain` empty throughout
EVIDENCE AC-5 | CP-4 | PASS | `spec.md`'s traceability table (AC-5 row: "pending") and `STATUS.md`'s phase table (P4: "not started") correctly do not yet claim P4 closed — consistent with CP-4 not having run before this report and CP-5 not having run at all. No premature or contradictory claim to flag here (unlike P3's CP-4, which caught stale "not started" text *after* CP-3v had already passed four rounds — that staleness pattern is not present here since this report is itself the first CP-4 pass). | `spec.md` (AC-5 row); `STATUS.md` (P4 row, "Next action" section)
EVIDENCE AC-5 | CP-4 | PASS | P4's evidence files (`CP-2-plan.md`, `CP-3-build.md`, `CP-3v-round1.md`, `evidence/checkpoints.tsv`) mention no AC other than AC-5 (`grep -n "AC-6\|AC-7\|AC-3b" evidence/P4/*.md evidence/P4/evidence/*.tsv` returns nothing) — no silent scope creep into AC-6, AC-7, or AC-3b. | `evidence/P4/*.md`, `evidence/P4/evidence/checkpoints.tsv`
EVIDENCE AC-5 | CP-4 | PASS/note | `CP-2-plan.md` named T-03 as "the same for the context store" but `CP-3-build.md`'s actual T-03 became "both dispatch routes covered (KnowledgeCmd/KnowledgeStagedCmd)" — the context store was deliberately *not* touched, and CP-3v round 1 independently confirmed that's correct (`--scope`/`--as-of` stay live on `context`). Scope drifted from the plan's literal wording but the outcome is right and was verified; not a defect, noted for the record. | `evidence/P4/CP-2-plan.md` (T-03) vs `evidence/P4/CP-3-build.md` (T-03) vs `evidence/P4/CP-3v-round1.md` § 3
EVIDENCE AC-5 | CP-4 | PASS | Harness controls and `ci-status.sh`, run verbatim (below) — all consistent with actual state except the expected P4 CP-4/CP-5 gap (this report is that CP-4; CP-5 has not run). | see Harness controls section

## Harness controls (verbatim)

**`phase-gates.sh 04-projects/production-readiness`** (exit 1, expected — this report is P4's
first CP-4, CP-5 has not run yet):
```
P1     all required checkpoints recorded
P2     all required checkpoints recorded
P3     all required checkpoints recorded
P4     NEVER RUN: CP-4 CP-5

phase-gates: 1 phase(s) never ran a required checkpoint.
  An absent checkpoint is not a pass. It means the gate was never asked,
  which leaves the same evidence bundle behind as a clean run.
```

**`spec-lint.sh 04-projects/production-readiness`**:
```
spec-lint: clean.
```

**`evidence-lint.sh 04-projects/production-readiness`**:
```
evidence-lint: clean.
```

**`citation-lint.sh 04-projects/production-readiness`**:
```
citation-lint: 20 commit citation(s), 26 vault path(s) checked.
citation-lint: every citation resolves.
```

**`ci-status.sh`** over all four repositories:
```
deagy/cadre                  bb35c49e  success run 33646263553
deagy/cadre-kernel           8da1b135  success run 33629166510
deagy/recall                 3ee2795f  success run 33537575047
deagy/gloop                  04c356ad  success run 33633218009
```
cadre's row matches the claimed commit and CI run exactly.

## FAILURES

- Value-collision false refusal | `refuseAbsentKnowledgeCapability` (`internal/cli/knowledge_absent_capability.go:57-77`) scans every argv token independently for a match against `absentKnowledgeCapabilityFlags`, with no concept of which flag a token is the *value* of | Reproduced live: `cadre knowledge delete-staged --id <existing-id> --reason "--retention-days" --deleted-by tester` on a real staged record returns exit 2 with the absent-capability message and does **not** delete the record, even though `delete-staged` is fully live and this exact invocation (same flags, different reason text) succeeds. Any of `--reason`, or any other free-text flag value on `propose`/`disposition-staged`/`delete-staged`, that happens to equal `--retention-days`, `--trigger`, or `--as-of` (with or without an `=value` suffix, or single-dash) triggers the same false refusal.

## FIX_HINTS

- Give the scanner an arity table for the flags each of the two commands actually defines (`--reason`, `--id`, `--action`, `--deleted-by`, `--authorized-by`, `--classification-used`, `--decided-by`, `--config`, `--input`, etc. — mirroring the existing `-config` special-case at `KnowledgeStagedRoute:72-75`) and skip the token immediately following any value-consuming flag before testing it against `absentKnowledgeCapabilityFlags`. Alternative: run the real `flag.FlagSet` first and only fire the absent-capability message when parsing fails with "flag provided but not defined" on one of the three named flags — inverts the current "scan before parsing" structure but removes the value/flag ambiguity entirely, since by the time real parsing fails every other flag's value has already been consumed correctly.
- Add a regression test alongside `knowledge_absent_capability_test.go` asserting `delete-staged --reason "--retention-days" --deleted-by x --id <valid>` (or an equivalent live-value-collision case) does **not** trigger the absent-capability path — this is the shape CP-3v's enumeration did not cover.

## Housekeeping

- `/home/deagy/sdk/cadre` left as found: `git status --porcelain` empty before and after (checked before/after the value-collision test, before/after the three generator runs, and at report time). Binary built to `/tmp/cp4-cadre`, deleted after use. No worktrees or clones created.
- `/home/deagy/cog-second-brain` left as found: only reads, no edits. `git status --porcelain -- 04-projects/production-readiness/` empty.
- Scratch staged-record test directory (`/tmp/cp4-knowledge-test`, a project-local knowledge-store config plus two staged records) created under `/tmp`, fully exercised through the staged lifecycle, and removed (`rm -rf`) before finishing.
