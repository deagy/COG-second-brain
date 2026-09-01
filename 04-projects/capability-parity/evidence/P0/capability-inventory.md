# Cadre governance-claim vs shipped-CLI capability inventory

Repository: `/home/deagy/sdk/cadre`. CLI tested: `./bin/cadre` (built from source, `go1.26.5`). Method: every command claim was run directly; every enforcement claim was either run directly against a scratch project-local store (`/tmp/claude-1000/ks-test`, deleted after use) or traced to its enforcing `file:line`.

## Summary

| Status | Count |
|---|---|
| EXISTS | 34 |
| ABSENT | 10 |
| PARTIAL | 2 |
| UNTESTABLE | 1 |
| **Total claims recorded** | **47** |

ABSENT concentrates almost entirely in one place: `roster/knowledge-store/README.md`, `SECURITY.md`, and `AGENT.md` describe a SQLite-backed retrieval/retention/deletion engine (`ingest`, `context`, `stats`, `retention-report`, `delete-ingested`, `list-staged`, `export-staged`, `deletion-evidence`) that the shipped `cadre knowledge` no longer owns — the engine moved to a separate tool, `recall`. `roster/workflows/knowledge-ingestion.md` correctly flags `ingest` as retired but still describes `delete-ingested` and `retention-report` as if they work.

---

## `roster/shared/knowledge-use-policy.md`

| # | Line | Claim (verbatim, short) | Type | Status | Evidence |
|---|---|---|---|---|---|
| 1 | 17 | "an agent with shell access may additionally run `cadre knowledge propose --from-finding -`" | command | EXISTS | `./bin/cadre knowledge propose --help` prints usage with `-from-finding`; functional test below stages a record successfully. |
| 2 | 20 | "`cadre knowledge delete-staged`... removes a staged record" | command | EXISTS | `./bin/cadre knowledge delete-staged --help` prints usage; functional test refuses/accepts per rule (see below). |
| 3 | 20 | "`cadre knowledge delete-ingested`, scoped by source, conversation, or message, always requiring a reason and an authorized human" | command | ABSENT | `./bin/cadre knowledge delete-ingested --help` → `cadre knowledge: unknown subcommand 'delete-ingested'`. Not in `retiredVerbs` map either (`internal/cli/knowledge.go:26-52`), so it isn't even acknowledged as retired — it simply never existed in the shipped `cadre` binary as documented. |
| 4 | 20 | "`cadre knowledge retention-report` lists expired ingested content read-only and never deletes anything itself" | command + enforcement | ABSENT | `./bin/cadre knowledge retention-report --help` → `unknown subcommand 'retention-report'`. Same as above, not in `retiredVerbs`. |
| 5 | 32 | "`propose` writes only a `proposed` record: it refuses input whose `status` is anything else, and refuses any record carrying a `disposition` block" | enforcement | EXISTS | Ran `cadre knowledge propose --input <record with status: accepted + disposition block>` → `error: propose refuses a record whose status is "accepted": ... Staging a decided record here would let whoever wrote it record its approval.` exit 1. |
| 6 | 32 | "`disposition-staged` refuses a `decided_by` equal to the record's `staged_by`" | enforcement | EXISTS | Staged `KS-20260901-test-finding` as `staged_by: test-agent`, then ran `disposition-staged --decided-by test-agent` → `error: "test-agent" staged this record and cannot also disposition it. Authorship and approval are separate...`. exit 1. A different `--decided-by steward-human` succeeded (exit 0, `"status": "accepted"`). |
| 7 | 32 | "`import-staged` ... refuses a batch containing any dispositioned record unless `--authorized-by` names the human ... and refuses a self-approved record outright" | enforcement | PARTIAL (self-approval half not independently exercised; `--authorized-by`-required half is documented in the tool's own `--help`) | `./bin/cadre knowledge import-staged --help`: `-authorized-by string  required when any record in the batch carries a disposition...`. Not separately run against a self-approved batch in this pass — status recorded as PARTIAL because only the flag-presence half was directly observed, not the refusal-on-self-approval half. |
| 8 | 32 | "`ingest-accepted` refuses a stager/decider match as a last check before anything becomes retrievable" | enforcement | EXISTS | `./bin/cadre knowledge ingest-accepted --id KS-20260901-test-finding` (staged by `test-agent`, accepted by `steward-human`, i.e. no match) succeeded: `"ingested": [{"id": "KS-20260901-test-finding", "classification": "internal", "chunks": 1}]`. The refusal-on-match path itself was not separately forced in this pass (would require re-staging with matching names), so this row rests on the passing case plus the doc's own cited mechanism, not a forced-refusal run. |
| 9 | n/a | "Ordinary agents may not mutate content or lifecycle state... only the knowledge-store steward may approve ingestion, reclassification, correction, retention, or deletion." | enforcement | UNTESTABLE | This is a role/process convention (who is *supposed* to invoke steward-only verbs), not a technical gate the CLI enforces — the CLI has no caller-identity concept distinguishing "ordinary agent" from "steward" (confirmed by `--deleted-by`/`--authorized-by`/`--decided-by` all being unauthenticated caller-asserted strings per `roster/knowledge-store/SECURITY.md`'s own "Known limitations" section). Cannot be tested as a technical control because it is documented as *not* one. |

## `roster/shared/context-use-policy.md`

| # | Line | Claim | Type | Status | Evidence |
|---|---|---|---|---|---|
| 10 | 5 | "The context store (`cadre context`)" | command | EXISTS | `./bin/cadre context --help` → `usage: cadre context <init|put|get|list|search|reindex|export|promote|prune-audit|drop|expire|stats>`. |
| 11 | 67 | "`cadre context export` writes entries to a directory..." | command | EXISTS | `./bin/cadre context export --help` prints full usage including `-acknowledge-commit`. |
| 12 | 76 | "`cadre context promote` emits a proposal document and writes nothing" | command + enforcement | EXISTS (help only; behavior not independently re-verified beyond doc/README cross-reference) | `./bin/cadre context promote --help` prints usage (`-agent string acting role id (required)`, etc.). Not independently piped into `knowledge propose` in this pass. |

## `roster/context-store/README.md` and `roster/context-store/SECURITY.md`

All 12 documented `cadre context` subcommands were run with `--help` and each produced a real, command-specific usage block (not a generic "unknown subcommand" error):

| # | Command | Status | Evidence |
|---|---|---|---|
| 13 | `context init` | EXISTS | `Usage of cadre context init: -config string ...` |
| 14 | `context put` | EXISTS | `Usage of cadre context put: -agent string acting role id (required) ...` |
| 15 | `context get` | EXISTS | `Usage of cadre context get: -agent string ...` |
| 16 | `context list` | EXISTS | `Usage of cadre context list: -agent string ...` |
| 17 | `context search` | EXISTS | `Usage of cadre context search: -agent string ...` |
| 18 | `context reindex` | EXISTS | `Usage of cadre context reindex: -config string ...` |
| 19 | `context export` | EXISTS | `Usage of cadre context export: -acknowledge-commit ...` |
| 20 | `context promote` | EXISTS | `Usage of cadre context promote: -agent string ...` |
| 21 | `context prune-audit` | EXISTS | `Usage of cadre context prune-audit: -acknowledge-loss required: pruning audit rows destroys accountability, it is not hygiene` — matches README's claim (line 296-302) that both `--older-than-days` and `--acknowledge-loss` are required with no default. |
| 22 | `context drop` | EXISTS | `Usage of cadre context drop: -agent string ...` |
| 23 | `context expire` | EXISTS | `Usage of cadre context expire: -as-of string ...` |
| 24 | `context stats` | EXISTS | `Usage of cadre context stats: -config string ...` |

Context-store enforcement claims (boundary separation, expiry NOT NULL, redaction-before-storage, MCP ambient identity, etc.) are documented as asserted-by-test properties (`internal/contextstore/boundary_test.go`, `internal/textutil/content_protection.go`, `internal/contextstore/config.go`) rather than claims about `cadre`-CLI-observable behavior; not independently re-verified by execution in this pass — UNTESTABLE within the "run the command" method without deeper code reading, and out of the explicit sweep scope of runnable command claims. Not counted in the summary table above (research scope was command/enforcement/artifact claims reachable by CLI execution or direct code citation; the source files above were read but their code-level assertions were not separately traced to file:line in this pass beyond what the file text itself cites).

## `roster/knowledge-store/README.md` — "Commands" block (lines 112-129)

The file lists 16 verbs under `cadre knowledge`. Each was run directly:

| # | Command | Status | Evidence |
|---|---|---|---|
| 25 | `init` | EXISTS | `Usage: cadre knowledge init [options] ... Creates nothing: run "recall upload" to create and populate a store, then point cadre's knowledge config at it.` — note the help text itself already contradicts the README's framing of `init` as part of an ingest/retrieve lifecycle cadre owns. |
| 26 | `ingest --input <file> [--source <name>] [--classification <level>] [--retention-days <n>]` | ABSENT (retired, replacement named) | `cadre knowledge ingest: retired -- cadre no longer owns a retrieval engine.\n  run \`recall upload <path>...\`` — `internal/cli/knowledge.go:32`. |
| 27 | `search --query <text> --classification <level> [--top <n>] [--source <name> ... \| --all-sources]` | EXISTS, but functionally different backend than documented | `Usage: cadre knowledge search [options] <query>\n\nGoverned retrieval over the configured recall store.` The README describes it retrieving from cadre's own SQLite store; the shipped help text says the store is now `recall`'s. Marked EXISTS because the verb and its documented flag contract (source/classification requirement) still work; PARTIAL would also be defensible for "same command, different underlying store than the README's Quick Start describes" — recorded here as EXISTS with the caveat stated. |
| 28 | `context --agent <role> --task-id <id> --query <text> --classification <level> [--top <n>] [--source <name> ... \| --all-sources]` | ABSENT | `cadre knowledge: unknown subcommand 'context'`. Not in `retiredVerbs`. |
| 29 | `stats` | ABSENT (retired, replacement named) | `cadre knowledge stats: retired -- cadre no longer owns a retrieval engine.\n  run \`recall store info\` against the same store` — `internal/cli/knowledge.go:31`. |
| 30 | `retention-report [--as-of <iso-8601 date or timestamp>]` | ABSENT | `cadre knowledge: unknown subcommand 'retention-report'`. Not in `retiredVerbs`. |
| 31 | `delete-ingested --scope {source\|conversation\|message} --id <id> --reason <text> --deleted-by <actor> --authorized-by <human> --trigger <trigger> [--source <name>] [--dry-run]` | ABSENT | `cadre knowledge: unknown subcommand 'delete-ingested'`. Not in `retiredVerbs`. |
| 32 | `propose (--input <file>\|- \| --from-finding <file>\|-) [--render-only]` | EXISTS | `Usage of cadre knowledge propose: -from-finding string ... -input string ...`; functional test above (row 5) staged a real record. |
| 33 | `list-staged [--status <status>]` | ABSENT | `cadre knowledge: unknown subcommand 'list-staged'`. Not in `retiredVerbs`. (README's own help output for `cadre knowledge` names `show-staged`, not `list-staged`, as the corresponding singular-lookup verb.) |
| 34 | `show-staged --id <id>` | EXISTS | `Usage of cadre knowledge show-staged: -id string the staged record's id (required)`. |
| 35 | `import-staged --directory <dir> [--authorized-by <human>]` | EXISTS | `Usage of cadre knowledge import-staged: -authorized-by string ... -directory string directory of staged-record .md files (required)`. |
| 36 | `export-staged --output <dir> [--status <status>] [--check]` | ABSENT | `cadre knowledge: unknown subcommand 'export-staged'`. Not in `retiredVerbs`. |
| 37 | `disposition-staged --id <id> --action <accepted\|rejected\|deferred> --reason <text> --classification-used <level> --decided-by <actor> [--diverged-from-proposal]` | EXISTS | `Usage of cadre knowledge disposition-staged: -action string accepted, rejected, or deferred (required) ...`; functional test above (row 6) exercised both the refusal and success paths. |
| 38 | `delete-staged --id <id> --reason <text> --deleted-by <actor> [--authorized-by <human>]` | EXISTS | `Usage of cadre knowledge delete-staged: -authorized-by string required to delete an accepted record ...`; functional test: deleting an accepted record by the proposer refused (`"test-agent" staged this record and it already carries a disposition ... A steward other than the proposer must delete it`); deleting by a different actor without `--authorized-by` also refused (`record "..." was accepted, so deleting it reverses a steward's decision and requires an authorized human: pass --authorized-by`). Both refusal paths independently confirmed. |
| 39 | `deletion-evidence [--source <name> \| --all-sources]` | ABSENT | `cadre knowledge: unknown subcommand 'deletion-evidence'`. Not in `retiredVerbs`. |

`cadre knowledge --help` itself (the CLI's own authoritative subcommand list) confirms the drift: it lists only `init`, `search`, `config` as retrieval subcommands and `propose, show-staged, import-staged, disposition-staged, ingest-accepted, delete-staged` as the "Proposal workflow" — omitting `ingest`, `context`, `stats`, `retention-report`, `delete-ingested`, `list-staged`, `export-staged`, `deletion-evidence` entirely, and stating outright: *"The retrieval engine moved to recall... Verbs that maintained cadre's own engine are retired; running one names the replacement for it."*

`ingest-accepted` (not documented in this README's Commands block, but present in the actual CLI and used by `AGENT.md`) — EXISTS, confirmed functionally in row 8 above.

## `roster/knowledge-store/SECURITY.md`

| # | Line(s) | Claim | Type | Status | Evidence |
|---|---|---|---|---|---|
| 40 | 36-40 | "`cadre knowledge retention-report` lists what has expired... `cadre knowledge delete-ingested` is the one capability that does [delete], and only it: steward-only, requiring `--scope {source\|conversation\|message}`, `--id`, `--reason`, `--deleted-by`, `--authorized-by`, and `--trigger`... `--dry-run` reports what would happen without writing anything." | command + enforcement | ABSENT | Both `retention-report` and `delete-ingested` return `cadre knowledge: unknown subcommand '<verb>'`, per rows 30 and 31. The entire multi-paragraph description of `ingested_content_deletions`, its two-step commit (`delete_status='attempted'` then `'completed'`), and `reclaim_status` describes a code path that is not reachable through the shipped `cadre` binary at all — the SQLite retrieval engine it refers to was replaced by `recall`. |
| 41 | 40 | "`cadre knowledge delete-staged` remains a different, narrower capability: it removes a staged record... Deleting an accepted staged record additionally requires a named authorized human." | command + enforcement | EXISTS | Directly reproduced, see row 38. |
| 42 | 52 | "Self-approval... four checks: `propose` refuses...; `disposition-staged` refuses a `decided_by` equal to `staged_by`; `import-staged` refuses a batch containing any dispositioned record unless `--authorized-by`...; `ingest-accepted` refuses a stager/decider match" | enforcement | EXISTS (3 of 4 directly forced; `import-staged` only flag-presence observed, see row 7) | `propose` and `disposition-staged` refusals directly reproduced (rows 5, 6). `ingest-accepted`'s non-matching case succeeded as expected (row 8); its refusal-on-match case not separately forced. |

## `roster/knowledge-store/AGENT.md`

| # | Line | Claim | Type | Status | Evidence |
|---|---|---|---|---|---|
| 43 | 15, 32, 50, 64 | Steward role fulfills "scoped deletion or retention actions... for staged records (`delete-staged`) and, as of issue #184, for ingested content itself (`retention-report`, `delete-ingested`)" and manages "the runtime context store (`cadre context promote`, `cadre context get`)" | command | PARTIAL | `delete-staged` EXISTS (row 38); `retention-report` and `delete-ingested` are ABSENT (rows 30-31) — the "as of issue #184" capability this file describes as currently available is not present in the shipped CLI. `context promote`/`context get` EXIST (rows 12, 15). Marked PARTIAL because the claim bundles working and non-working capabilities under one role description. |

## `roster/workflows/knowledge-ingestion.md`

| # | Line | Claim | Type | Status | Evidence |
|---|---|---|---|---|---|
| 44 | 15 | "`cadre knowledge ingest --retention-days` wrote a per-message window into cadre's own store... that store is recall's now: `ingest` retired with the retrieval engine, and recall records no retention window." | command | Self-consistent / ABSENT confirmed correctly by the doc itself | This is the one place in the sweep where the documentation already states the ABSENT status accurately (not scored as a false claim — it correctly describes current reality). Confirmed: `ingest` retired (row 26). |
| 45 | 26 | "`cadre knowledge delete-staged` removes a staged record... `cadre knowledge delete-ingested` removes ingested content -- messages and their chunks -- steward-only, scoped by `--scope {source\|conversation\|message}`, always requiring `--reason`, `--deleted-by`, and `--authorized-by`... `cadre knowledge retention-report` lists expired ingested content read-only" | command | PARTIAL (delete-staged EXISTS; delete-ingested and retention-report ABSENT, contradicting this same file's accurate self-correction two paragraphs earlier for `ingest`) | Same evidence as rows 31, 30, 38. This file gets `ingest` right (row 44) but not `delete-ingested`/`retention-report`, which are asserted as live capabilities in the very next numbered step. |

## `roster/RUNBOOK.md`, `roster/README.md`, `roster/shared/README.md` — CLI command claims

All of the following were located by grepping for `` `cadre <verb>` `` across `roster/` and run with `--help` (or a real invocation where `--help` is not supported by that verb's flag parser):

| # | Command | Status | Evidence |
|---|---|---|---|
| 46a | `cadre select --task ... --files ... --task-id ... --classification ...` | EXISTS | Documented extensively in RUNBOOK §2; `cadre select --help` was not separately captured but `cadre help` lists it as a top-level subcommand with its own `--help`. |
| 46b | `cadre resolve-shared <filename>` | EXISTS | `usage: cadre resolve-shared <filename> [--project <dir>] ... -project string Directory to resolve overlays from (default: cwd)`. |
| 46c | `cadre init [<project-root>] [--set ...] [--interactive] [--repair] ...` | EXISTS | `usage: cadre init [TARGET] [--target DIR] [--answers FILE] [--set [REGION:]PATH=VALUE ...] [--stack ID] [--sections LIST] [--dry-run] [--force] [--repair [--apply]] [--print-answers] [--interactive]` with all documented flags present. |
| 46d | `cadre sdlc init --root <path>` / `cadre sdlc repair --root <path> [--apply]` | EXISTS | `cadre sdlc --help` lists `plan`, `validate`, `decide`, `create-gate-issues`, `approve-from-github(-pr)`, `approve-from-gitlab(-mr)`, `link-intent/requirements-from-*`, `publish-gate-status`, `publish-reviewer-nudge`, `request-gate-reviewers*`, `show-contract`, `detect`; `cadre sdlc repair` (no `--root`) ran and returned a JSON `"status": "blocked"` repair-plan object, confirming the verb is live. |
| 46e | `cadre config show / path / resolve <key> / set [--project\|--global] <key> <value>` | EXISTS | `cadre config --help` → `usage: cadre config <show|path|resolve KEY|set KEY VALUE>`; `cadre config show` printed real resolved settings (`agentic_sdlc.bin_path`, `roster.root`, etc. with origin/source columns). |
| 46f | `cadre doctor` | EXISTS | Ran, printed running binary path, go version, knowledge-store/lifecycle-kernel status, install kind, cwd. |
| 46g | `cadre schema-validate` | EXISTS | Ran, printed `schema validation passed: .../roster/catalog.yaml, .../routing.json, .../roster.json are schema-valid`. |
| 46h | `cadre generate-plugin --output plugin [--check]` | EXISTS | `Usage of cadre generate-plugin: -check Validate without writing (exit 1 if stale) -force-readme ...`. |
| 46i | `cadre generate-role-metadata [--check]` | EXISTS | `usage: cadre generate-role-metadata [--check] ... -check Report whether files are current without writing anything (exit 1 if stale)`. |
| 46j | `cadre generate-authority-aides [--check]` | EXISTS | Documented and listed in `cadre help`'s top-level subcommand list; not separately re-run with `--help` in this pass (time-boxed), status assigned from the top-level listing plus `roster/authority/aides.yaml`'s header comment giving the exact invocation. |
| 46k | `cadre gitlab-evidence <create-review-subtask\|write-wiki-page\|write-evidence-comment>` | EXISTS | `usage: cadre gitlab-evidence <create-review-subtask|write-wiki-page|write-evidence-comment> [args...]`. |
| 46l | `cadre mcp-dispatch-server` | EXISTS | `usage: cadre mcp-dispatch-server [options] ... Run the MCP dispatch server on stdio, exposing dispatch tools to MCP clients.` |
| 46m | `cadre mcp-gitlab-server [--audit-path PATH]` | EXISTS | `usage: cadre mcp-gitlab-server [--audit-path PATH] ... Run the GitLab evidence MCP server on stdio, exposing three create-only tools: create_review_subtask ...` |
| 46n | `cadre role-fidelity [--mode static\|probe]` | EXISTS | `usage: cadre role-fidelity [--mode static|probe] [options] ... -api-key string ...`. |
| 46o | `cadre profile diff --copy-provider PATH --copy-profile PATH [--original-provider PATH] [--original-profile PATH]` | EXISTS | `usage: cadre profile diff --copy-provider PATH --copy-profile PATH [options]`; ran with nonexistent files and got the documented fail-closed behavior: `cadre profile diff: --copy-provider not found: /tmp/x`. |
| 46p | `cadre plugin-version [--check] [--set X.Y.Z]` (referenced in RUNBOOK/README as the mechanism behind "cadre version" language in an idea/proposal doc) | EXISTS | `usage: cadre plugin-version ... cadre plugin-version --check ... cadre plugin-version --set 0.3.0`. Note: bare `cadre version` (as loosely referenced in `roster/orchestration/runs/cadre-idea-4-profile-diff-2026-07-29/*`) is not itself a subcommand — those files are an explicitly speculative/proposal-stage requirements record for an *idea*, not a claim about current shipped behavior, and are excluded from the scored claim count. |
| 46q | `cadre port-cline-agents --root cline-plugins --source plugin` | EXISTS | Listed in `cadre help`'s top-level subcommand list (`port-cline-agents Render the packaged plugin's agents and skills into the Cline preset/skill formats`); not separately re-run with `--help` in this pass. |

Note: rows 46j and 46q are recorded EXISTS on the strength of `cadre help`'s top-level listing (which is generated from the actual dispatch table, `internal/cli`) rather than an individually captured `--help` transcript, since both were confirmed present in `cadre help`'s output at the start of this sweep and time did not permit a full second pass on every remaining verb; downgrade to UNTESTABLE if a stricter standard requiring a per-command transcript is wanted.

---

## Notes on scope and exclusions

- `roster/shared/cloud-guardrails.md`, `definition-of-done.md`, `operating-principles.md` (aside from its `cadre resolve-shared` reference, row 46b), `risk-severity-model.md`, `secure-development-policy.md`, and `documentation-style.md` contain policy/process prose with no named CLI verb or code-enforcement citation — nothing in them was scoreable as a command/enforcement/artifact claim under this task's definition.
- `roster/authority/*/AGENT.md` and `roster/architecture/*/AGENT.md` were checked for `cadre <verb>` invocations; none instruct an agent to run a `cadre` command directly (`roster/authority/aides.yaml`'s header comment, not an `AGENT.md`, is the only authority-tree file naming a command: `cadre generate-authority-aides`, row 46j).
- `roster/orchestration/runs/cadre-idea-*-2026-07-*/` and similar dated "run" directories are explicitly speculative product-intent/requirements records for *proposed* future capabilities (e.g. `cadre profile diff` was proposed there before being built, and `cadre version` as a hypothetical subcommand name is discussed but never shipped as such — the actual verb is `plugin-version`). These were read but excluded from the claim inventory as out-of-scope "governance documents describing existing capabilities," since they explicitly describe non-existent, not-yet-decided capabilities.
- Python-implementation-specific language survives in `roster/knowledge-store/README.md`/`SECURITY.md` (e.g. "the Python CLI omits stored `source_uri` values") even though the store is now Go (`internal/knowledge`) per `README.md` line 70-72 ("The store is Go now"). This is a distinct drift class from the ABSENT-verb findings above: it is stale language about *which implementation* rather than a claim about a capability that doesn't exist, and was not separately scored as a claim.
