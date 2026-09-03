---
type: plan
project: cog-cadre-integration
change: 03-gate-mutations
created: 2026-09-02
depends_on: ["01-run-record", "02-per-task-amend"]
status: implemented
tags: ["#plan", "#gates", "#authority", "#publishing"]
---

# Change 3 — Gate the high-consequence mutations

## The change

COG already requires explicit human approval before it publishes externally, but it
does so ad hoc: each skill says "ask the user first" in its own words with no shared
authority model and no audit trail. This change frames the external mutations as
release gates with a named authority and a single approval record that lands in the
run-record. It is deliberately narrow. COG's capture loop, braindumps, briefs, and
knowledge-base edits stay as they are — fast, no gate. The gate applies only where
the mutation leaves COG and touches an external system that other people see or
rely on. That is the whole set.

The authority model is cadre's G1-G10, read down to only the gates that match a
COG mutation's consequence. Not all ten apply; the mapping is the work of this
change, and it should keep the existing human names so the mapping is legible to
the person who approved the mutation.

## The mapping

| COG mutation | External system | Gate | Deciding authority |
|---|---|---|---|
| Publish a page to Confluence / Notion | Shared wiki | G8 release-readiness | Publisher |
| Post to Slack / socials / webhook | Public channel | G9 deployment-authorization | Publisher |
| Sync a team brief back to Linear | Issue tracker | G7 evidence | Publisher |
| content-factory publish | Public post | G8 + G9 | Publisher |
| update-knowledge-base sync to external wiki | Shared KB | G8 release-readiness | Publisher |

Everything that stays internal — writing to `05-knowledge/`, a local braindump, a
draft PRD, a consolidated framework that is not synced — takes no gate. The
distinction is the same one the phase-level loop already draws between work that
stays inside the project and work that reaches it.

## Where it lands

- A new `plan/authority-gates.md` registry (kept in the plan for now; the
  production form is a small schema in `05-knowledge/`) listing each mutation, its
  gate, its authority, and its approval-record shape. This is the one claim on the
  authority mapping, owned in one place.
- `.claude/skills/publish-to-confluence/SKILL.md` — the approval step records the authority
  and gate in the run-record before the page is created, and the post-condition
  re-fetches the page to confirm it matches.
- `.claude/skills/team-brief/SKILL.md` — the sync-back to Linear is gated as G8 with the
  Publisher's explicit approval recorded; the sync is the post-condition.
- `.claude/skills/content-factory/SKILL.md` — the publish step is gated G8+G9 with a
  screenshot as the post-condition, matching the existing voice-checklist.

## Acceptance criteria

- `AC-1` Each external mutation names exactly one gate and one authority; no
  mutation maps to two authorities for the same approval (the one-shape rule).
- `AC-2` A mutation without a recorded approval is not executed; the skill stops at
  the gate and asks.
- `AC-3` The approval — authority, gate, timestamp, who approved — is recorded before
  the mutation runs, via `checkpoint.sh record_approval` into
  `.claude/logs/approval-ledger.tsv`. A run-record cannot hold it: it is written at
  Phase 7, after the Phase 6 mutation, and the gated skills are not harness entry
  points, so in an ordinary session no run-record exists at all. Inside a harness run
  Phase 7 folds the ledger rows into the matching gate's `human_approvals`.
- `AC-4` After the mutation, the external artifact is re-fetched or re-read and
  confirmed to match intent (the post-condition), not just the tool return.
- `AC-5` Internal writes (knowledge-base edits, drafts, braindumps) take no gate;
  verified by running a knowledge-consolidation that never hits a gate.

## Files touched

New: `plan/authority-gates.md` (temporary home). Edited:
`.claude/skills/publish-to-confluence/SKILL.md`, `.claude/skills/team-brief/SKILL.md`,
`.claude/skills/content-factory/SKILL.md`.

## Risk

Medium. The blast radius is three skills, and the failure mode is over-gating: if
the boundary between "external, gated" and "internal, ungated" is drawn too wide,
COG's capture loop slows to a crawl and the feature stops being useful. The
boundary is the one judgment to get right, and it should be drawn from what each
skill actually writes and where it writes it, not from a general principle. The
second risk is that the authority names (Release Owner, Release Authority) come
from cadre's software-release context and feel wrong for a personal knowledge tool;
the mapping should keep the gate numbers for traceability but can rename the
authority to something a COG user recognizes if that reads better. That is a
cosmetic decision, not a structural one.

## Unblock

Decide the external/internal boundary by listing each skill's writes and tagging
them, and confirm the authority names. The run-record (change 1) must carry the
`approval` binding, and the amend semantics (change 2) must exist so a denied mutation has a defined re-entry rather than a dead end.

## Implementation (committed: 883b7fd)

Created `plan/authority-gates.md`, the one registry mapping each external mutation to
exactly one gate and one authority. Gate numbers are cadre's own ladder; the
authority is renamed from cadre's software-release role to **Publisher** (the human who
approves the external write) so the mapping stays legible to a COG user. AC-1 met:
content-factory spans G8+G9 but has one approval — one authority signs the whole publish.
The four publishing skills reference the registry and record the approval through
`checkpoint.sh record_approval` before the mutation (AC-3): publish-to-confluence G8,
team-brief G7, content-factory G8+G9, update-knowledge-base G8 — cadre's ladder, where
G7 is Evidence, G8 Release Readiness and G9 Deployment Authorization. Each skill already ran a post-condition
re-fetch (AC-4); internal writes remain ungated (AC-5, unchanged).

One note for a later pass: the registry is currently a plan doc; its production form is
the small schema in `05-knowledge/` the plan calls for. That is a move, not a change, and
is left for the merge.
