# COG Second Brain — Framework Instructions

> Opt-in verification harness: `WORKFLOW.md` · Universal surface: `AGENTS.md`

## Response Style (ALWAYS APPLY, every agent, every deliverable)

Optimize for **information gain, not apparent completeness**. The failure mode is framework slop: ordinary reasoning dressed as a consulting memo. Full pattern list: `.claude/skills/no-ai-slop/SKILL.md` § Structural slop.

- Start with the answer or strongest finding; no introduction announcing how you will answer.
- Never invent named frameworks, gates, layers, pillars, lenses, or numbered taxonomies unless they exist in the source material or the categorization materially simplifies a complex subject.
- No sections for 1-2 paragraphs; default to continuous prose with occasional descriptive headings.
- Headings identify subject matter ("Authentication"), never rhetorical function. Banned: "What this is not", "Why this matters", "The key insight", "The real opportunity", "The bottom line", "The deeper point", "The uncomfortable truth".
- No straw-man contrasts ("It's not X, it's Y", "This isn't about X", "While it may seem...", "Unlike...") unless X is a position someone relevant actually holds.
- Space proportional to importance and evidence; each paragraph must add evidence, mechanism, example, implication, counterexample, or decision.
- Compose as **finding → evidence → reasoning → decision**, not principle → framework → exposition → takeaway.
- Prefer concrete nouns over abstract labels. Stop when the useful information is exhausted.

Applies to chat answers, reports, briefs, specs, docs, and all subagent outputs.

## Verification Harness (opt-in, off by default)

COG ships a V-model verification harness: decompose left (spec then plan), build at the apex, verify right with evidence traced to criterion IDs (`AC-n`). **It does not run unless you ask for it.** Ordinary work (notes, briefs, research, drafts, edits) takes no checkpoints, no lane classification, and no evidence ledger.

Three ways to turn it on:

- **By skill.** `/closed-loop`, `/ultragoal`, `/retro`, `/harvest`, `/review-cockpit`.
- **By phrasing.** "Run this through the closed loop", "verify this properly", "track this as an ultragoal", "give me an evidence trail".
- **By profile.** Set `verification_harness: on` in `00-inbox/MY-PROFILE.md` frontmatter to make the `normal`-lane pipeline the default for build tasks. Absent or `off` means opt-in per request.

Inside a harness run: checkpoints, gate classes, risk lanes, and file homes are in `WORKFLOW.md`; the build-verify-fix pipeline is in `.claude/skills/closed-loop/SKILL.md`; multi-session goals are in `.claude/skills/ultragoal/SKILL.md`. Those documents oblige nothing in a session that never invoked them.

Two of the harness's rules are worth applying whether or not it is on, because they cost nothing:

- **Verification means observing the artifact**: curl the URL, screenshot the page, re-fetch the issue, diff the file. Never re-read a worker's own summary of it. Mandatory for external mutations; see § Skill Post-Condition Rule.
- **A worker never grades its own homework.** When a fresh pair of eyes is the point (external mutations, auditable claims), the verifier is a separate read-only subagent that receives paths and criteria, never the worker's output.

## Visual Verification (ALWAYS APPLY, UI/UX tasks)

Any task that **implements or changes a UI/UX flow** is not verified by a DOM/selector check. The DOM can be present and the pixels still wrong: overflow, misalignment, clipped text, wrong contrast, broken responsive layout, z-index overlap.

- **Capture visual evidence.** Screenshot every meaningful state; record multi-step flows.
- **Actually read the image, then compare** against the intended design (mock, spec wireframe, prior state, house style). Name the discrepancy; never declare pass on "element exists."
- **Fix the UI error you spot**. This is part of the task, not a follow-up. Re-capture to prove it.
- Keep the screenshots next to the deliverable. Inside a harness run they are the CP-5 acceptance evidence.

## Delegation Cap (ALWAYS APPLY)

Delegation is not free: each subagent re-establishes context, re-explores, and reports back, and the lead then re-reads the report. Delegate when the payoff clearly exceeds that overhead, not by reflex.

- **Don't delegate work the lead can finish in a handful of tool calls.**
- **Fan out only for genuinely independent, sizeable tracks**: ≥3 unrelated items, a wide multi-source sweep, or parallel workers that would conflict on the same file.
- **If one subagent can do it, use one.** Keep spawn counts low.
- **Brief precisely the first time.** Avoid launch → wait → re-brief; never redo a subagent's work after it reports.
- Independent agents launched together go in **one message with multiple tool calls** so they run concurrently.

## Model Routing — ALWAYS APPLY

When spawning subagents, use the correct model for the task:

| Task type | Model | Agent definition |
|-----------|-------|-----------------|
| Data collection (GitHub, Slack, Jira, Linear, file reads) | **Sonnet** | `worker-data-collector` |
| Web research (search, fetch URLs, extract facts) | **Sonnet** | `worker-researcher` |
| Publishing (Slack, Confluence, Notion, webhooks) | **Sonnet** | `worker-publisher` |
| File operations (vault reads/writes, metadata, profiles) | **Sonnet** | `worker-file-ops` |
| Pre-approved mutations (Jira transitions, Linear updates, API calls) | **Sonnet** | `worker-executor` |
| People profile updates from brief/meeting data | **Sonnet** | `brief-people-updater` |
| Read-only verification, harness runs only (acceptance criteria, post-conditions) | **Sonnet** | `task-verifier` |
| Cross-task integration verify, harness runs only (CP-4) | **Sonnet** | `integration-verifier` |
| Targeted fixes after verifier FAIL:fixable | **Sonnet** | `fix-agent` |
| Harvest staging curation (propose-only) | **Sonnet** | `harvest-curator` |
| Reasoning, synthesis, cross-referencing, writing | **Opus** | Lead session (no delegation) |
| Editorial judgment, tone, strategic decisions | **Opus** | Lead session (no delegation) |

**Rule:** If a task doesn't require reasoning or judgment, delegate it to a Sonnet worker. The lead session (Opus) handles thinking, synthesis, and writing only.

Agent definitions live in `.claude/agents/`.

### Worker Output Rule — ALWAYS APPLY

Workers must **write results to a file** and return only a short status + file path. Never have a worker return large text as output.

| Output size | What to do |
|------------|------------|
| < 2K tokens | Return inline (short status, confirmation, error) |
| >= 2K tokens | Write to `/tmp/{task-slug}-{context}.md`, return path |

**Why:** Generating thousands of tokens as agent output is sequential and extremely slow. Writing to file is instant. The orchestrator or next agent reads the file via the Read tool.

**Pattern:**
```
# Worker prompt must include:
"Write your results to /tmp/{descriptive-name}.md and return ONLY a short status message with the file path."

# Worker returns:
"OK: /tmp/slack-data.md (gathered 47 messages, 12 threads)"

# Orchestrator reads:
Read("/tmp/slack-data.md")
```

**Applies to:** All `worker-*` agents, all `brief-*` agents, any subagent that collects, extracts, or processes data.

### Single-File Deliverable Rule — ALWAYS APPLY

The user reviews **one file per run**. Multi-file outputs (staging files, per-worker dumps, split reports) make review impossible.

- **Default: work in a single file.** If the task fits in one file, never split it.
- **Fan-out is allowed mid-run** (parallel workers must write separate staging files to avoid conflicts), **but the final step always consolidates**: one deliverable file with the main content (TL;DR, synthesis, plan) on top, then an `## Appendix — sources` section containing each sub-file's content (or a condensed version + link if a sub-file is bulky raw data).
- **After consolidating, delete the staging files.** The run folder ends with exactly one file (or zero, if the deliverable lives elsewhere).
- Never present the user with "see files A, B, C, D" — present one file.

### Fresh-Context Isolation — ALWAYS APPLY when fanning out workers

When the orchestrator dispatches multiple workers in parallel, pass each worker ONLY the digested context it needs — never paste a prior worker's raw output into the next worker's prompt. Pasted context induces *narrativisation*: the worker treats the preamble as "the orchestrator already framed the findings, I just classify them" instead of independently reading the source. Observed failure mode: a 5× speedup coupled with hallucinated findings and mis-cited references.

---

## Brain-First Knowledge Protocol (MUST APPLY)

Before answering any question about people, projects, strategy, decisions, or historical context:
1. Read relevant notes from `05-knowledge/` first (especially `05-knowledge/people/` for people questions).
2. If project-specific, also read related files in `04-projects/<project>/`.
3. Only then synthesize an answer.

If the user corrects a factual statement, write/update the correction in the relevant knowledge note immediately.

### Citation Rule
For factual statements written into durable notes (`05-knowledge/**`, people profiles, consolidated docs), include source attribution inline:

`[Source: [[path/to/note]] | YYYY-MM-DD | confidence: high|medium|low]`

Use one citation per distinct factual claim block where practical.

### Citation Verbatim & Verifier Pass — When Accuracy Matters

For skills that produce auditable claims about external sources (Slack threads, tickets, PRs, meeting transcripts — e.g. `team-brief`, `comprehensive-analysis`, `auto-research`), apply two additional disciplines:

1. **Verbatim quote alongside the citation.** Every cited reference should carry the actual line text in backticks, not just a link. Pattern: `[<short>] (<link>) — \`<verbatim quote>\``. If you can't quote the source verbatim, drop the claim — that's the failure mode this discipline prevents.

2. **Opt-in adversarial verifier pass before publishing.** For high-stakes briefs/reviews, after the draft is assembled, spawn one `worker-data-collector` (Sonnet) whose only job is to re-fetch each cited URL and tag every claim `Verified | Weakened | Falsified` against the verbatim quote. Falsified claims are dropped; Weakened are demoted (e.g. "blocker" → "heads up"). Output contract: `CLAIM <id> | <tag> | <one-sentence justification with link>`.

This is opt-in per skill — not a hard rule for every output. Apply it where wrongness costs the most.

---

## Engineering Discipline — ALWAYS APPLY

### Code Comments
- Never use decorative comment separator blocks of any kind — `// ====`, `// ----`, `// ---- Section Name ----`, `// -----------` full-line dividers, `/* ==== Section Name ==== */`, etc. Use plain single-line comments and blank lines to separate sections instead.

### Git
- Never `git reset --hard` or `git commit --amend` unless the user explicitly asks. Always create new commits and push normally. If changes get wiped, recover from `git reflog` — do not destroy history.
- Always commit with commitlint standards (Conventional Commits: `type(scope): subject`).
- When a command requires interactive input (e.g. `git rebase --continue`, editor prompts), supply the non-interactive flag or set `GIT_EDITOR=true` / `EDITOR=true` / `--no-edit` as appropriate.
- **Never put a file write and the commit describing it in one compound command.** Write, confirm the write landed, then commit. A heredoc that silently no-ops leaves a commit message describing work that does not exist, and the message is what everyone reads afterwards. A `PreToolUse` hook could enforce this — COG ships no hook infrastructure, so this is a cost decision rather than an impossible one, and worth revisiting if hooks ever arrive for another reason.

### Pull Requests
- Before opening a PR, check the repository for a PR template (e.g. `.github/PULL_REQUEST_TEMPLATE.md` or similar) and always follow it when composing the PR description.
- PR review replies must be in-thread via `gh api repos/{owner}/{repo}/pulls/comments/{id}/replies`, never a new parent comment, then resolve the thread via the GraphQL `resolveReviewThread` mutation. No pleasantries ("great catch", etc.) — state what changed, which commit, and why.

### Background commands
- A background command that queries one repository must not resolve its arguments from the session's working directory. Pass `-R <owner/repo>` and an explicit sha; `git rev-parse HEAD` in a background shell resolves against the session's cwd, not the repository you are asking about.
- Do not end a background command with an `echo` after the command whose exit code matters. The notification reports the *last* command's status, so a failed watch followed by `echo` is reported as success. Two CI watches in one session reported exit 0 while having 404'd on an empty run id.
- Verify the outcome against the artifact, not the wrapper's exit code — for CI, `.claude/lib/ci-status.sh`, which resolves the run for HEAD's exact sha and treats a missing or in-flight run as not-green.
- No check reaches these: a `PreToolUse` hook could inspect the command string before it runs, and COG ships no hook infrastructure. A cost argument, not an impossibility, and it closes alongside the write-and-commit rule above if hooks ever arrive.

### Before you assert it, check it

Three rules that no lint reaches, for one shared reason: **each defect happens in a message rather than in a file.** There is no artifact to inspect and no moment after the fact when a check could run — by the time anything exists to lint, the wrong claim has already been made. That is the reason they live here rather than in a test, and it is not a statement that they matter less.

- **Verify a name or destination exists before putting the decision to the user.** A citation about a name is not evidence the name is free. `cadre-lifecycle` was proposed as a repository name off a misread citation; `gh repo create` refusing it was the only thing standing between that session and pushing into an archived repository. The check is mechanical and already exists — it just ran too late to be a check.
- **Check a repository's visibility before reasoning about who its documentation reaches.** `gh repo view --json visibility` is one line. Nothing invokes it, because the defect is a reasoning step: an argument about what a document exposes, built on an assumption about who can read it.
- **Treat an environment note as a finding until shown otherwise.** "Installed kernel 0.13.2, repository 0.14.2" was recorded as a curiosity. It was a guard checking the wrong artifact. Most environment notes are not version-pair-shaped, which is why this stays judgment — but a note you cannot immediately explain is a finding you have not investigated yet.

### Interaction
- Read every file the user provides (images, screenshots, code, text) with the read tool before responding — never assume its contents.
- Answer the user before acting. Explanatory questions should be answered verbally without first invoking tools or editing code. Wait for the user to explicitly request investigation, a fix, or changes.

---

## Skill Post-Condition Rule — ALWAYS APPLY

Every skill run that **mutates external state** (publishes a page, deploys, posts to Slack/socials, transitions a ticket, pushes commits, fires a webhook) must end with an explicit **post-condition check**: fetch back or observe the mutated artifact and confirm it matches intent before reporting success.

The failure mode this prevents is **confident-but-unchecked**: a step returns plausible output that no downstream layer validates. Rules:

- The check must observe the *artifact*, not the tool's return value (curl the URL, re-fetch the ticket, screenshot the post).
- Read-only skills are exempt.
- If the check fails, report the failure plainly — never report success from the mutation call alone.
- New skills that mutate external state must include a "Verify" step in their SKILL.md.

---

## Daily Journal (ALWAYS APPLY)

The daily journal is an **ambient** behavior, not a command. The trigger lives here because it has to be loaded in every session; the procedure lives in the skill (`.claude/skills/daily-journal/SKILL.md`).

- **After finishing a meaningful unit of work, append one entry** to `01-daily/journal/YYYY-MM-DD.md` (get the date with `date +%F`, never guess). Meaningful = shipped or committed something, produced a deliverable, made a decision, changed direction, or hit a notable blocker.
- **Create the file from the skill's template on the first entry of the day.** Append only; newest entries at the bottom of the `## Log` section.
- **Do NOT log** trivial reads, one-line lookups, mid-task scratch work, the journal's own writes, or anything you asked to keep out. Do not announce the write — append and carry on.
- Read the skill body for the entry format, `reflect` mode, and the full guardrails before the session's first write.
- If you say to stop journaling, stop for the rest of the session and do not re-ask.

---

## Integration Preferences

Before using — or designing anything that names — an external integration in a skill, check `00-inbox/MY-INTEGRATIONS.md`. This includes plans, gate/authority registries, and specs that map work to an external system, not only a runtime call:

- **Active integrations**: Use normally.
- **Disabled integrations**: Skip silently. Do not attempt to call their tools, do not suggest setting them up, do not mention them in output.
- **Unknown integrations** (not listed in either section): Ask the user if they want to set it up. If they say no, add it to the Disabled section.

## Role Packs

COG uses role packs (`.claude/roles/*.md`) to personalize skill recommendations and integration suggestions per user role.

### How role matching works
1. During onboarding, the user's role text is matched against `role_id` and `aliases` in each role pack's YAML frontmatter.
2. The matched role pack is stored as `role_pack` in `00-inbox/MY-PROFILE.md` frontmatter.
3. When suggesting skills or workflows, check the user's `role_pack` and order recommendations by role relevance.

### Role-aware behavior
- **Skill suggestions**: When a user asks "what can COG do?" or similar, prioritize skills listed in their role pack. Show role-specific explanations from the pack.
- **Integration prompts**: When a skill needs an integration the user hasn't set up, check their role pack to provide role-specific context for why it matters.
- **No role pack match**: If the user's role doesn't match any pack, recommend core skills (`roles: [all]`) and let them discover team skills organically.

### Available role packs
Role packs live in `.claude/roles/`. New roles can be added by dropping a file following the `_template.md` format.

## Vault Structure

### User configuration files (`00-inbox/`)
- `MY-PROFILE.md` — User info, role pack, agent mode, active projects
- `MY-INTERESTS.md` — Topics for daily briefs
- `MY-INTEGRATIONS.md` — Active/disabled external service integrations

### Professional tracking (`03-professional/`)
- `COMPETITIVE-WATCHLIST.md` — Companies/people being tracked

### Framework files (updated via `cog-update.sh` or `/update-cog`)
- `.claude/skills/`: Claude Code skills (33 skills)
- `.claude/agents/` - Worker and verifier agent definitions (10 agents)
- `.claude/roles/` — Role packs for personalized recommendations
- `.claude/lib/` - Harness helper scripts (`checkpoint.sh`, `lane-classify.sh`)
- `.kiro/powers/` — Kiro powers
- `.gemini/commands/` — Gemini CLI commands
- `AGENTS.md` — Universal agent documentation

### Knowledge system (`05-knowledge/`)
- `people/` — People CRM profiles (progressive, evidence-based)
- `consolidated/` — Frameworks and synthesis documents
- `patterns/` — Identified patterns
- `timeline/` — Thinking evolution
- `booklets/` — URL bookmarks by category

### Content directories (never touched by updates)
- `00-inbox/` — Profiles, interests, integrations
- `01-daily/` — Briefs and check-ins
- `02-personal/` — Personal braindumps (private)
- `03-professional/` — Professional braindumps and strategy
- `04-projects/` — Per-project tracking
- `05-knowledge/` — Consolidated insights and patterns
