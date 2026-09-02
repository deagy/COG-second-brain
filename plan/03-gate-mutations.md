---
type: plan
project: cog-cadre-integration
change: 03-gate-mutations
created: 2026-09-02
depends_on: ["01-run-record", "02-per-task-amend"]
status: draft
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
| Publish a page to Confluence / Notion | Shared wiki | G7 release-readiness | Release Owner |
| Post to Slack / socials / webhook | Public channel | G8 deployment-auth | Release Owner |
| Sync a team brief back to Linear | Issue tracker | G9 release authority | Release Authority |
| content-factory publish | Public post | G7 + G8 | Release Owner + Release Authority |
| update-knowledge-base sync to external wiki | Shared KB | G7 | Release Owner |

Everything that stays internal — writing to `05-knowledge/`, a local braindump, a
draft PRD, a consolidated framework that is not synced — takes no gate. The
distinction is the same one the phase-level loop already draws between work that
stays inside the project and work that reaches it.

## Where it lands

- A new `plan/authority-gates.md` registry (kept in the plan for now; the
  production form is a small schema in `05-knowledge/`) listing each mutation, its
  gate, its authority, and its approval-record shape. This is the one claim on the
  authority mapping, owned in one place.
- `skills/publish-to-confluence/SKILL.md` — the approval step records the authority
  and gate in the run-record before the page is created, and the post-condition
  re-fetches the page to confirm it matches.
- `skills/team-brief/SKILL.md` — the sync-back to Linear is gated as G9 with the
  Release Authority's explicit approval recorded; the sync is the post-condition.
- `skills/content-factory/SKILL.md` — the publish step is gated G7+G8 with a
  screenshot as the post-condition, matching the existing voice-checklist.

## Acceptance criteria

- `AC-1` Each external mutation names exactly one gate and one authority; no
  mutation maps to two authorities for the same approval (the one-shape rule).
- `AC-2` A mutation without a recorded approval is not executed; the skill stops at
  the gate and asks.
- `AC-3` The approval — authority, gate, timestamp, who approved — is in the
  run-record's `approval` binding before the mutation runs.
- `AC-4` After the mutation, the external artifact is re-fetched or re-read and
  confirmed to match intent (the post-condition), not just the tool return.
- `AC-5` Internal writes (knowledge-base edits, drafts, braindumps) take no gate;
  verified by running a knowledge-consolidation that never hits a gate.

## Files touched

New: `plan/authority-gates.md` (temporary home). Edited:
`skills/publish-to-confluence/SKILL.md`, `skills/team-brief/SKILL.md`,
`skills/content-factory/SKILL.md`.

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
`approval` binding, and the amend semantics (change 2) must exist so a denied
mutation has a defined re-entry rather than a dead end.
