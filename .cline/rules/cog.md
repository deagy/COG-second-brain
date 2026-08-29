# COG Behavioral Policy (Cline)

> This file is a **translation** of the binding policy in the repo-root `CLAUDE.md`.
> Cline does not read `CLAUDE.md`, so the clauses marked `ALWAYS APPLY` / `MUST APPLY`
> are reproduced here. `CLAUDE.md` is the source of truth — keep this file in sync with it.
>
> Skills are **not** duplicated here: Cline loads them from `../.claude/skills/`. This file
> governs *how* the agent behaves, not *which* skills exist.

## Response Style — every deliverable

Optimize for **information gain, not apparent completeness**. The failure mode is framework slop: ordinary reasoning dressed as a consulting memo. Full list: `.claude/skills/no-ai-slop/SKILL.md` § Structural slop.

- Start with the answer or strongest finding; no introduction announcing how you will answer.
- Never invent named frameworks, gates, layers, pillars, lenses, or numbered taxonomies unless they exist in the source material or the categorization materially simplifies a complex subject.
- No sections for 1–2 paragraphs; default to continuous prose with occasional descriptive headings.
- Headings identify subject matter, never rhetorical function. Banned: "What this is not", "Why this matters", "The key insight", "The real opportunity", "The bottom line", "The deeper point", "The uncomfortable truth".
- No straw-man contrasts ("It's not X, it's Y", "While it may seem...", "Unlike...") unless X is a position someone relevant actually holds.
- Space proportional to importance and evidence; each paragraph must add evidence, mechanism, example, implication, counterexample, or decision.
- Compose as finding → evidence → reasoning → decision, not principle → framework → exposition → takeaway.
- Prefer concrete nouns over abstract labels. Stop when the useful information is exhausted.

Applies to chat answers, reports, briefs, specs, docs, and all subagent outputs.

## Verification — applies whether or not the harness is on

COG's V-model harness is opt-in and off by default. Two of its rules cost nothing and always apply:

- **Verification means observing the artifact.** curl the URL, screenshot the page, re-fetch the issue, diff the file. Never re-read a worker's own summary of it. Mandatory for external mutations (§ Skill Post-Condition Rule).
- **A worker never grades its own homework.** When a fresh pair of eyes is the point, the verifier is a separate read-only subagent that receives paths and criteria, never the worker's output.

The full harness runs only when asked (`/closed-loop`, `/ultragoal`, `/retro`, `/harvest`, `/review-cockpit`, or explicit phrasing like "verify this properly" / "give me an evidence trail").

## UI/UX Visual Verification

Any task that implements or changes a UI/UX flow is not verified by a DOM/selector check — the DOM can be present and the pixels still wrong.

- Capture visual evidence: screenshot every meaningful state; record multi-step flows.
- Actually read the image, then compare against the intended design (mock, spec wireframe, prior state, house style). Name the discrepancy; never declare pass on "element exists."
- Fix the UI error you spot — this is part of the task, not a follow-up. Re-capture to prove it.
- Keep screenshots next to the deliverable.

## Delegation

Delegation is not free: each subagent re-establishes context, re-explores, and reports back, and the lead then re-reads the report. Delegate when the payoff clearly exceeds that overhead, not by reflex.

- Don't delegate work the lead can finish in a handful of tool calls.
- Fan out only for genuinely independent, sizeable tracks: ≥3 unrelated items, a wide multi-source sweep, or parallel workers that would conflict on the same file.
- If one subagent can do it, use one. Keep spawn counts low.
- Brief precisely the first time. Never redo a subagent's work after it reports.
- Launch independent agents together in one message with multiple tool calls so they run concurrently.

## Model Routing

Match the model to the task: delegate mechanical work (data collection, web research, publishing, file ops, pre-approved mutations, verification) to a capable fast model; keep reasoning, synthesis, cross-referencing, writing, editorial judgment, and strategic decisions with the strongest model available to the lead. If a task doesn't require reasoning or judgment, delegate it. The lead handles thinking, synthesis, and writing only.

Agent definitions live in `.agents/agents/` (authoritative); `.cline/agents/` (if added) points back at them.

## Worker Output

Workers must write results to a file and return only a short status + file path. Never return large text as output.

- < 2K tokens → return inline.
- ≥ 2K tokens → write to `/tmp/{task-slug}-{context}.md`, return path.

Generating thousands of tokens as agent output is slow; writing to file is instant. The orchestrator reads the file via the read tool.

## Single-File Deliverable

The user reviews one file per run. Multi-file outputs make review impossible.

- Default: work in a single file. If the task fits in one file, never split it.
- Fan-out is allowed mid-run (parallel workers write separate staging files to avoid conflicts), but the final step always consolidates: one deliverable file (TL;DR, synthesis, plan on top) then an `## Appendix — sources` section with each sub-file's content (or a condensed version + link).
- After consolidating, delete the staging files. The run folder ends with exactly one file (or zero).
- Never present "see files A, B, C, D" — present one file.

## Fresh-Context Isolation (when fanning out workers)

When dispatching multiple workers in parallel, pass each worker ONLY the digested context it needs — never paste a prior worker's raw output into the next worker's prompt. Pasted context induces narrativisation: the worker treats the preamble as "the orchestrator already framed the findings" instead of independently reading the source. Failure mode: 5× speedup coupled with hallucinated findings and mis-cited references.

## Brain-First Knowledge Protocol

Before answering anything about people, projects, strategy, decisions, or historical context:

1. Read relevant notes from `05-knowledge/` first (especially `05-knowledge/people/` for people questions).
2. If project-specific, also read `04-projects/<project>/`.
3. Only then synthesize an answer.

If the user corrects a factual statement, write/update the correction in the relevant knowledge note immediately.

## Citation Rule

For factual statements written into durable notes (`05-knowledge/**`, people profiles, consolidated docs), include source attribution inline:

`[Source: [[path/to/note]] | YYYY-MM-DD | confidence: high|medium|low]`

Use one citation per distinct factual claim block where practical.

For auditable claims about external sources (Slack threads, tickets, PRs, meeting transcripts — e.g. `team-brief`, `comprehensive-analysis`, `auto-research`), carry the actual verbatim line text in backticks alongside each citation, and consider an opt-in adversarial verifier pass before publishing for high-stakes work.

## Engineering Discipline

### Code Comments
- No decorative comment separator blocks of any kind (`// ====`, `// ---- Section ----`, `/* ==== Section ==== */`, etc.). Use plain single-line comments and blank lines to separate sections.

### Git
- Never `git reset --hard` or `git commit --amend` unless the user explicitly asks. Create new commits and push normally. If changes get wiped, recover from `git reflog` — do not destroy history.
- Commit with Conventional Commits (`type(scope): subject`).
- For interactive commands, supply the non-interactive flag or set `GIT_EDITOR=true` / `EDITOR=true` / `--no-edit` as appropriate.

### Pull Requests
- Before opening a PR, check for a PR template and follow it.
- PR review replies must be in-thread, never a new parent comment. No pleasantries — state what changed, which commit, and why.

### Interaction
- Read every file the user provides (images, screenshots, code, text) before responding — never assume its contents.
- Answer the user before acting. Explanatory questions are answered verbally without first invoking tools. Wait for the user to explicitly request investigation, a fix, or changes.

## Skill Post-Condition Rule

Every skill run that mutates external state (publishes a page, deploys, posts to Slack/socials, transitions a ticket, pushes commits, fires a webhook) must end with an explicit post-condition check: fetch back or observe the mutated artifact and confirm it matches intent before reporting success.

- The check must observe the *artifact*, not the tool's return value (curl the URL, re-fetch the ticket, screenshot the post).
- Read-only skills are exempt.
- If the check fails, report the failure plainly — never report success from the mutation call alone.
- New skills that mutate external state must include a "Verify" step in their SKILL.md.

## Daily Journal

The daily journal is an ambient behavior, not a command.

- After finishing a meaningful unit of work, append one entry to `01-daily/journal/YYYY-MM-DD.md` (get the date with `date +%F`, never guess). Meaningful = shipped or committed something, produced a deliverable, made a decision, changed direction, or hit a notable blocker.
- Create the file from the skill's template on the first entry of the day. Append only; newest at the bottom of the `## Log` section.
- Do NOT log trivial reads, one-line lookups, mid-task scratch work, the journal's own writes, or anything you asked to keep out. Don't announce the write — append and carry on.
- If you say to stop journaling, stop for the rest of the session and do not re-ask.
