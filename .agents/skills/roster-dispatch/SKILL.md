---
name: roster-dispatch
description: Dispatch a domain specialist from COG's vendored kadre roster. Resolves a role from catalog.yaml, loads its AGENT.md, computes the sandbox from the capability tier, spawns it through a sandboxed runner, writes a run-record (Change 4 AC-2/3), and routes the output to a different agent for peer review (AC-4).
---

Read `.claude/skills/roster-dispatch/SKILL.md` and execute it exactly as written — that file is the authoritative
playbook. Then follow `.agents/rules/cog.md`.

Antigravity substitution: where the playbook delegates to a `.claude/agents/<name>`
worker, invoke `.agents/agents/<name>.md` via `invoke_subagent` instead.
