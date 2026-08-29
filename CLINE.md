# COG + Cline

COG's 33 skills are read from `../.claude/skills/` automatically — Cline discovers skills
from `.claude/skills/` as a first-class project directory, so no copy is needed.

COG also ships per-agent surfaces (`.claude`, `.cursor`, `.gemini`, `.kiro`, `.agents`).

Cline does not read `CLAUDE.md`, so the behavioral policy from `CLAUDE.md` (verification
harness, engineering discipline, response style, and so on) is reproduced here in
`.cline/rules/cog.md`. That file is a translation — `CLAUDE.md` remains the source of
truth.
