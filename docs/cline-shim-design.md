# Cline Integration — Shim Design

> Status: **design sketch** (staged for review, not yet built)
> Related: [`docs/AGENT-SUPPORT.md`](./AGENT-SUPPORT.md) is the packaging contract this doc extends.

## TL;DR

COG already ships a full native surface for Cline. Cline discovers skills from
`.claude/skills/` as a first-class project directory, and it reads `AGENTS.md` and
`.cursorrules` natively. The only thing that does **not** survive the trip is the
binding verification-harness / risk-lane policy that lives in `CLAUDE.md` (Cline does
not read `CLAUDE.md`).

So the Cline integration is not a new surface — it is a **~4-file rules shim** that
reproduces the `CLAUDE.md` `ALWAYS APPLY` / `MUST APPLY` clauses in a Cline-readable
location. No skill duplication, no parallel maintenance burden.

## Reality check: why the shim is thin

| Asset | Cline status | Shim action |
|---|---|---|
| 33 skills (`.claude/skills/*/SKILL.md`) | ✅ read natively from `.claude/skills/` | **none** — do not copy |
| `AGENTS.md` (universal skill catalog) | ✅ read natively | **none** |
| `.cursorrules` | ✅ read natively | **none** |
| `CLAUDE.md` binding policy (harness, risk lanes, verification-first, no-ai-slop) | ❌ not read by Cline | **→ translate to `.cline/rules/cog.md`** |
| 10 agents (`.agents/agents/*.md`) | partial | optional `.cline/agents/` for specialist/read-only roles |
| 7 Gemini `.toml` commands, 7 Kiro `powers` | alternate packaging of the same triggers | **none** — triggers already live in each SKILL.md `When to Invoke` |

Evidence: every `.claude/skills/*/SKILL.md` already carries the exact frontmatter Cline
requires — `name:` matching the directory, single-line `description:` under the 1024-char
cap. Cline discovers skills from `.claude/skills/`, `.clinerules/skills/`, or
`.cline/skills/`. `.claude/skills/` is already conformant, so this shim needs no skills at all.

## Proposed layout

```
.cline/
├── CLINE.md                 # Optional entry note (topology + where policy lives)
├── rules/
│   └── cog.md               # THE shim: CLAUDE.md binding policy, translated
├── agents/                  # OPTIONAL — specialist / read-only roles only
│   ├── task-verifier.md
│   ├── integration-verifier.md
│   └── harvest-curator.md
└── skills/
    └── .gitkeep             # INTENTIONALLY EMPTY — skills arrive via ../.claude/skills/
```

### `rules/cog.md` — what actually gets translated

Only the `ALWAYS APPLY` / `MUST APPLY` clauses from `CLAUDE.md` that Cline would
otherwise never see. Not the whole file. Concretely:

- **Verification-first** — all information sourced and verified; confidence levels stated.
- **The harness invariant** — the verifier never grades its own homework; observe the
  artifact (re-read the file, run the command), never the worker's summary.
- **Risk lanes** — when the closed-loop / evidence ledger applies.
- **The 10 core principles** — the behavioral rules that govern *how* Cline works, not
  the catalog of *what* skills exist.
- **Memory & handoff discipline** — read the memory bank first, externalize context.

Skill-specific content (invocation triggers, playbooks, step sequences) stays in the
SKILL.md that Cline already loads. Do not re-encode it here.

### `CLINE.md` — the optional onboarding note

A ~5-line pointer that explains the topology to a Cline user. Draft:

```markdown
# COG + Cline

COG's 33 skills are read from `../.claude/skills/` automatically — no copy needed.
COG also ships per-agent surfaces (`.claude`, `.cursor`, `.gemini`, `.kiro`, `.agents`).

Cline does not read `CLAUDE.md`, so the verification-harness / risk-lane policy from
`CLAUDE.md` is reproduced here in `.cline/rules/cog.md`.
```

### `.cline/agents/` — optional, low priority

Only the read-only / specialist roles benefit from Cline subagent isolation:
`task-verifier`, `integration-verifier`, `harvest-curator`. Each is a thin alias that
points back at the authoritative `.agents/agents/<name>.md` (same pointer-stub pattern
already used by the Antigravity `.agents/skills/` stubs). The workers that mutate state
(`worker-executor`, `worker-publisher`) can stay un-declared — Cline can still invoke
them via the skill triggers.

### Slash commands — no separate `commands/` dir

In Cline, **the slash command *is* the skill**, auto-generated from the SKILL.md
frontmatter `name`. So `/braindump`, `/daily-brief`, `/url-dump`, etc. already appear
once the repo is opened in Cline. The Gemini `.toml` and Kiro `powers` are just
alternate packaging of triggers already baked into each skill's `When to Invoke`. There
is no `.cline/commands/` to maintain.

## The one decision that matters: empty dir vs symlink

For `.cline/skills/`, three options:

- **(a) Empty + `.gitkeep`** — relies on native `.claude/skills/` discovery. **Recommended.**
- **(b) Symlink `skills` → `../.claude/skills`** — explicit, but git-tracked symlinks are
  fragile across forks and Windows. Avoid.
- **(c) Copy** — the anti-pattern: two sources of truth, drift guaranteed. Do not do this.

## How this fits the packaging contract

This doc extends [`docs/AGENT-SUPPORT.md`](./AGENT-SUPPORT.md). When the shim lands:

1. **Add a Cline row** to the support matrix there:

   | Cline | `.cline/rules/cog.md` (+ native `.claude/skills/` read) | Full skills, harness policy shimmed | Full surface (shimmed) |

2. **Update the "full surfaces" list** — Claude Code, Antigravity, `AGENTS.md`, and now
   Cline expose the complete public skill set.
3. **Update `plugin.json` / `marketplace-entry.json`** description to add "Cline" to the
   "Works with …" claim — this is truthful today, since Cline already reads the surface.
4. **`cog-update.sh`** — add the staged `.cline/` files to `FRAMEWORK_FILES` so
   `/update-cog` treats them as framework files (never touches personal content).
5. **`validate-agent-surface.sh`** — the current validator checks manifest JSON, declared
   skill paths, skill count vs shipped Claude skills, and `AGENTS.md` coverage. Cline is
   out of scope today; flag whether a "Cline shim present" check is worth adding.

## Open questions

- **Scope of the shim:** translate the full `CLAUDE.md` policy verbatim, or trim to the
  harness + risk-lane + verification-first subset? (Recommend the trimmed set — Cline
  users don't need the memory-bank handoff rules that are already in `AGENTS.md`.)
- **Ownership:** framework repo (this design) vs marketplace publisher. Recommend framework
  repo — it's a framework-completeness gap, per the 2026-08-28 braindump.
- **Cline Hub / plugin packaging:** separate, later — exposing COG as a marketable Cline
  *plugin* (manifest + hub listing) is a distribution play, distinct from the directory
  shim here.
- **MCP:** the long-game is exposing COG skills as MCP tools (Cline supports MCP
  natively). Would make "works with Cline" a non-issue for any MCP client. Not in this shim.

## Proposed next steps

1. Approve the trimmed `rules/cog.md` scope.
2. Stage `CLINE.md` + `.cline/rules/cog.md` (+ `.gitkeep`).
3. Add the Cline row to `docs/AGENT-SUPPORT.md` and the "Works with" claim to the manifests.
4. Add `.cline/` to `FRAMEWORK_FILES` in `cog-update.sh`.
5. (Optional) Extend `validate-agent-surface.sh` with a shim-present check.
