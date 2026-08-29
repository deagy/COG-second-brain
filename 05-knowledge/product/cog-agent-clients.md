---
type: knowledge
domain: product
project: COG (second brain)
topic: Multi-agent-client support
created: 2026-08-28 20:50
last_updated: 2026-08-28
source: cline-shim-project
version: "1.0"
tags: ["#knowledge", "#cog", "#agent-clients", "#integration", "#cline"]
related:
  - 05-knowledge/technical/agentic-sdlc-governance.md
  - docs/AGENT-SUPPORT.md
  - CLINE.md
  - docs/cline-shim-design.md
---

# COG Multi-Agent-Client Support

## Overview
COG (Cognition + Obsidian + Git) is built to work with multiple AI agent clients, not just Claude. It markets support for seven — Claude Code, Antigravity, Cursor, Kiro, Gemini CLI, Codex, and Cline — via the Agent Plugins spec. As of 2026-08-28 the concrete implementation splits into three tiers:

- **Claude — native.** Skills in `.claude/skills/`, roles in `.claude/agents/`, behavioral policy in `CLAUDE.md`. This is the reference implementation; every other surface points back at it.
- **Cline — thin shim.** Skills load natively from `../.claude/skills/` (Cline treats `.claude` as a first-class project directory, so no copy is needed). Behavioral policy is a faithful translation of `CLAUDE.md` into `.cline/rules/cog.md`; specialist roles are read-only stubs that redirect to `.claude/agents/`. `CLAUDE.md` is the source of truth and the shim is regenerated from upstream via `/update-cog`.
- **Kiro / Cursor / Gemini / Codex — documented surfaces.** Per-agent directories (`.kiro`, `.cursor`, `.gemini`, `.agents`) exist; the universal `AGENTS.md` doubles as documentation for agents that don't read `CLAUDE.md` natively.

The governing principle is **no duplication of behavior**: skills and roles live in exactly one place, and agent-specific directories are thin pointers, not copies. A partial shim would give a client worse behavior than the reference, so translations are complete rather than trimmed.

## How Each Client Connects
| Client | Skills | Roles | Policy | Nature |
|--------|--------|-------|--------|--------|
| Claude | `.claude/skills/` | `.claude/agents/` | `CLAUDE.md` | native (reference) |
| Cline | natively from `.claude/skills/` | redirect stubs → `.claude/agents/` | `.cline/rules/cog.md` (translation) | shim |
| Kiro / Cursor / Gemini / Codex | `.kiro/powers/` etc. | via `.agents/` | `AGENTS.md` (universal docs) | surface + docs |

## Cline Shim (added 2026-08-28)
Closed the gap "COG has no Cline integration" with a minimal, non-duplicative shim:

- **Skill discovery** — no copy. Cline discovers the 33 skills from `.claude/skills/` directly. `.cline/skills/` holds only an intentional `.gitkeep` marker.
- **Policy** — `.cline/rules/cog.md` is a full 13-section translation of `CLAUDE.md`'s binding clauses. `CLAUDE.md` remains source of truth; the design doc explicitly cites it to prevent drift.
- **Specialist roles** — `.cline/agents/` holds read-only stubs for `task-verifier`, `integration-verifier`, and `harvest-curator`. Each is a redirect to the authoritative `.claude/agents/<name>.md`; zero content copied. Read-only verifiers cannot edit files or mutate external state (the "worker never grades its own homework" contract carried across).
- **Update hygiene** — the shim files were added to `FRAMEWORK_FILES` in `cog-update.sh`, so `/update-cog` treats them as framework files (regenerated from upstream, never mixed with personal content).
- **Public framing** — `plugin.json` and `marketplace-entry.json` both now list Cline in the "Works with …" claim; `docs/AGENT-SUPPORT.md` adds a Cline row to the support matrix.

## Specialist Roles (shared across clients)
Ten specialist agents split into two classes, identical for every client:

- **Workers** (write results to a temp file, return a short status + path): data-collector, researcher, file-ops, executor, publisher, brief-people-updater.
- **Verifiers** (read-only, fresh context, cannot edit/mutate): task-verifier (CP-3 gate), integration-verifier (CP-4 cross-task wiring), harvest-curator (propose-only adoption notes; never writes `05-knowledge/`).

## Public Framing
`plugin.json` and `marketplace-entry.json` both state "Works with Claude Code, Antigravity, Cursor, Kiro, Gemini CLI, Codex, Cline." The marketplace entry also names inspirations (Garry Tan's gstack/gbrain, dwarves-kit).

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-08-28 | 1.0 | Initial entry from the Cline integration shim (CLINE.md, design doc, manifests, support matrix) | Cline integration project |

## Related
- [Per-task denial contract & governance](../technical/agentic-sdlc-governance.md) — the read-only-verifier / "worker never grades its own homework" contract originates here.
- [COG + Cline](../../CLINE.md)
- [Cline shim design doc](../../docs/cline-shim-design.md)
- [Agent support matrix](../../docs/AGENT-SUPPORT.md)

## Notes
- **Shim-present assertion (resolved 2026-08-28).** `scripts/validate-agent-surface.sh` now checks the Cline shim: `CLINE.md` and `.cline/rules/cog.md` exist, the three `.cline/agents/` stubs still redirect to `.claude/agents/<name>.md`, `.cline/skills/.gitkeep` is present, and the shim is registered in `cog-update.sh` FRAMEWORK_FILES. Verified passing on the restored tree and on a negative run (removed `CLINE.md` → assertion fires). No Cline-specific agent convention differs: `.cline/agents/` mirrors `.agents/agents/` exactly — both redirect directly to `.claude/agents/<name>.md` with identical frontmatter (name, description, `subagent: true`, `model: flash`), and the targets exist.
- **Verify rule:** every new guard or assertion in a validation script must be proven by an independent negative run that forces it to fire, not by a happy-path pass alone. (Established adding the Cline shim-present assertion — a happy-path pass gave false confidence until a negative run with `CLINE.md` removed confirmed the assertion actually catches a missing shim.)
- The shim is regenerative: `/update-cog` pulls framework-file updates from upstream and applies them surgically, leaving personal content untouched.

---

*Last updated: 2026-08-28 | Source: Cline integration shim (CLINE.md, design doc, plugin/marketplace manifests, AGENT-SUPPORT.md)*
