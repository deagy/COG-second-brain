# CP-3v Round 4 — Knowledge-store capability-claim audit

Commit under test: b534fb27 (branch main). Read-only verification, no edits made.

## Ground truth (internal/cli/knowledge.go)

- `liveKnowledgeVerbs` (knowledge.go:61): `init`, `search`, `config`
- Staged-record verbs (`knowledgeStagedSubcommands`, knowledge_staged.go:37-45): `propose`, `show-staged`, `import-staged`, `disposition-staged`, `ingest-accepted`, `delete-staged`
- `pythonEraVerbs` (knowledge.go:78-99), never rebuilt: `context`, `list-staged`, `export-staged`, `retention-report`, `delete-ingested`, `deletion-evidence`
- `retiredVerbs` (knowledge.go:26-53) includes `ingest`, `delete`, `stats`, `hybrid-search`, `backup`, `export`, `import`, etc. — retired with the engine, replaced by `recall`.
- `delete-staged` (knowledge_staged.go:221, 782-799) writes evidence to `staged_record_deletions` (staged_store.go:74, 725) — staged records only, no path to ingested content.
- `go test ./internal/cli/... -run 'TestDocumented|TestKnowledge|TestDeadPython'` → PASS, confirming the drift check that holds docs to `AnswerableKnowledgeVerbs()` is green at this commit.

## AC-2 — knowledge-store documents describe the surface that exists

Read in full: `roster/knowledge-store/README.md` (207 lines), `roster/knowledge-store/SECURITY.md` (56 lines), `roster/knowledge-store/AGENT.md` (69 lines), `roster/workflows/knowledge-ingestion.md` (30 lines).

EVIDENCE AC-2 | CP-3v | PASS | README.md's "Removed, and where each went" table (lines 144-151) and "What this section used to say" block (190-202) correctly list `ingest→recall upload`, `context→search` (noting `cadre context` is a different live command), `stats→recall store info`, `list-staged/export-staged→nothing (unwired/frozen)`, `retention-report/delete-ingested/deletion-evidence→nothing`. Commands table (117-132) lists only the 9 live verbs. | roster/knowledge-store/README.md:117-202
EVIDENCE AC-2 | CP-3v | PASS | SECURITY.md § Storage rules (line 38) and § Retrieval rules (line 30) state retention/deletion absence and name recall as the current home of ingested content, with no delete command. | roster/knowledge-store/SECURITY.md:30,38
EVIDENCE AC-2 | CP-3v | PASS | AGENT.md role line (15) and duty list (17, 31, 33, 51, 67) consistently state the two duties (retention, ingested-content deletion) "cannot currently be performed," name the removed verbs, and point to DESIGN-NOTES. | roster/knowledge-store/AGENT.md:15,17,31,33,51,67
EVIDENCE AC-2 | CP-3v | PASS | knowledge-ingestion.md steps 1 and 9 (lines 15, 26-28) state retention is "a paper record again" and deletion of ingested content "has no command," naming recall's Go API/CLI as having no delete path. | roster/workflows/knowledge-ingestion.md:15,26-28

**Verdict: PASS.** All four files were checked in full (not just first occurrence); no stale passage survives beside a correction in any of them, and each names recall as the destination for retrieval-engine work.

## AC-3 — retention has a stated owner (paper record, no enforcement)

Swept the whole tracked tree (excluding `provider/`, `plugin/`, `cline-plugins/` as mirrors, and the listed exempt paths) by concept — `retention|TTL|age-out|expir|purge|erasure|GDPR|audit trail` — not by verb name, then filtered to documents that actually describe the knowledge store's retention. Full occurrence list per file, not just first hit, at `/tmp/hits1.txt` and `/tmp/kb_docs.txt`.

EVIDENCE AC-3 | CP-3v | PASS | SECURITY.md § Storage rules states plainly (bold, lines 38-44): "no retention window is recorded for any content, nothing ages out... Every commitment these documents make about retention or erasure is currently a commitment about process, not about software." Names what would change it (a shipped command + DESIGN-NOTES). | roster/knowledge-store/SECURITY.md:38-44
EVIDENCE AC-3 | CP-3v | PASS | AGENT.md line 53: "a deletion or retention requirement is now *always* an escalation rather than sometimes a task: there is no tool here to satisfy one with." Consistent with lines 15,17,33. | roster/knowledge-store/AGENT.md:53
EVIDENCE AC-3 | CP-3v | PASS | knowledge-use-policy.md lines 24-30: "**Retention is not enforced, and ingested content cannot be deleted through cadre.**" States cost plainly and what would change it. | roster/shared/knowledge-use-policy.md:24-30
EVIDENCE AC-3 | CP-3v | PASS | knowledge-ingestion.md line 15: "**Retention is a paper record again**... a retention decision made here lives only in the steward's note, and nothing ages out on its own." Line 30 reinforces: no classification default, no later mechanism to catch an unresolved retention decision. | roster/workflows/knowledge-ingestion.md:15,30
EVIDENCE AC-3 | CP-3v | PASS | retention-and-deletion-executor/AGENT.md line 15 correctly scopes itself out of knowledge-store ingested content: "a retention or erasure obligation touching ingested knowledge has no tool behind it and must be raised as a gap rather than assigned." | roster/operations/retention-and-deletion-executor/AGENT.md:15
EVIDENCE AC-3 | CP-3v | PASS | PHASE4_ROADMAP.md and RELEASE_NOTES_PHASE4.md carry SUPERSEDED banners naming the absence before any feature list (see banner adequacy section below); their later "✅ Retention" claims are historical record of the withdrawn Python implementation, correctly framed by the banner. | PHASE4_ROADMAP.md:1-15; RELEASE_NOTES_PHASE4.md:1-25

**Out of scope, not a defect:** `docs/WEEK1-5_INFRASTRUCTURE.md:87` and its plugin mirror describe "TTL-based expiration" for a `cache_entries` table and "GDPR Data Retention" for an unrelated `audit_logs` table (Kubernetes/production-infra roadmap, no reference to `cadre knowledge`, ingestion, or the knowledge store). This is a different — itself apparently aspirational/undelivered — subsystem, not a knowledge-store retention claim, so it does not fall under AC-3's "document that describes retention" for this store.

**Verdict: PASS.** Every document found that describes knowledge-store retention states the paper-record/no-enforcement fact and what would change it. No document asserts retention enforcement as a present-tense knowledge-store capability outside the two SUPERSEDED-banner historical documents, which are adequately bannered.

## AC-4 — deletion of ingested content has a stated owner

EVIDENCE AC-4 | CP-3v | PASS | SECURITY.md line 46: "**Deletion of *staged* records does exist**... " immediately following the ingested-content absence (line 38), so the two claims sit side by side without contradiction — staged vs. ingested is kept distinct throughout. | roster/knowledge-store/SECURITY.md:38,46
EVIDENCE AC-4 | CP-3v | PASS | AGENT.md § Escalate when (line 51) and § Deletion (line 67): ingested-content deletion "is done in recall" is not claimed as done — it explicitly says cadre holds **no** evidence trail and no capability, only `delete-staged` for staged records. Matches the AC's framing that cadre holds no evidence of it. | roster/knowledge-store/AGENT.md:51,67
EVIDENCE AC-4 | CP-3v | PASS | knowledge-use-policy.md lines 26,32: states cost of absence plainly ("no tool here to do it with, and no evidence trail if they do it another way") and separately confirms staged-record deletion works. proposed-knowledge.schema.json's `recommended_action` description (line 91) reinforces the same act-vs-capability distinction. | roster/shared/knowledge-use-policy.md:26,32; roster/knowledge-store/proposed-knowledge.schema.json:91
EVIDENCE AC-4 | CP-3v | PASS | knowledge-ingestion.md line 28: "Deleting *ingested* content has no command... So there is no steward-facing way to remove ingested content." | roster/workflows/knowledge-ingestion.md:28
EVIDENCE AC-4 | CP-3v | PASS | dispatch-contract.md line 25 (and identical mirrors in plugin/skills and cline-plugins) correctly separates staged-record deletion capability from ingested-content's total absence, both consistent with ground truth. | .agents/skills/run-agent-orchestration/references/dispatch-contract.md:25
EVIDENCE AC-4 | CP-3v | PASS | internal/knowledge/README_CLI.md § Deletion (172-186) states cadre's own `delete` verb is retired, recall deletes only by id, and "deletion by retention window, classification, source or age has no equivalent" — recorded as "a capability gap in the migration." | internal/knowledge/README_CLI.md:172-186

**Verdict: PASS.** Every document sampled that describes deletion of ingested content states it is not a capability cadre has (not merely "done in recall" as an unqualified claim — several explicitly note recall's own CLI has no delete verb either, going further than the AC requires), states cadre holds no evidence trail, and states the cost of that absence.

## SUPERSEDED banner adequacy

**RELEASE_NOTES_PHASE4.md** (lines 1-25): Adequate. Before any feature list, the banner names the specific absent capabilities verbatim — "retention enforcement, TTL-based expiry, age-based retention policies, source-based deletion of ingested content, the `cadre knowledge delete` command and its deletion audit trail do not exist" — lists the seven removed verbs, states recall's CLI has no delete command, states no retention window/nothing ages out, and points to the three live documents (SECURITY.md, README.md, DESIGN-NOTES). A reader cannot reach the "✅ Retention Management" section (line 111) without passing this.

**PHASE4_ROADMAP.md** (lines 1-15): Adequate. Names Phase 4.6 specifically, names `Store.DeleteExpired`, TTL enforcement, cascade delete, and the deletion audit log as having "no counterpart today," states retention windows aren't recorded and nothing ages out, and cites SECURITY.md § Storage rules as the open-decision record. This precedes the "✅ COMPLETE" markers and the "Phase 4.6: Retention & Deletion" section (line 210).

Both banners go beyond "gestures at a rewrite" — they name the withdrawn commands and the specific false claims a skimming reader would otherwise find, which is the standard the task set.

## Generated-tree consistency (not audited independently, per instruction)

- `diff roster/knowledge-store/{README,SECURITY,AGENT}.md plugin/suite/roster/knowledge-store/{...}` → only a `<!-- GENERATED FILE -->` banner and a relative-path adjustment (`../../bin/cadre` → `../../../bin/cadre`) in README.md. No content drift.
- `diff roster/knowledge-store/AGENT.md provider/roles/knowledge-store/AGENT.md` → identical, no diff.
- `diff roster/workflows/knowledge-ingestion.md plugin/suite/roster/workflows/knowledge-ingestion.md` → only the generated-file banner.
- `cline-plugins/cline-agents/agents/knowledge-store-steward.md` vs `plugin/agents/knowledge-store-steward.md` → frontmatter/tool-naming conversion only (Cline's converter format); body content matches.

Regeneration is consistent; no independent capability claims originate in the generated trees.

## Overall

- AC-2: **PASS**
- AC-3: **PASS**
- AC-4: **PASS**

No fixable or escalable defects found in this round's scope. Concept-based sweep (not verb-name-based), full-file occurrence checks (not first-hit-only), and repository-root undated files were all covered per the three prior rounds' stated root causes.
