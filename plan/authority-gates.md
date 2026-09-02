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

## The boundary

The gate applies only where the mutation leaves COG and touches an external system that
other people see or rely on. Everything that stays inside COG — writing to `05-knowledge/`,
a local braindump, a draft PRD, a consolidated framework that is not synced — takes no
gate. This is the same split the phase-level loop draws between work that stays inside the
project and work that reaches it. The whole external set, today, is five mutations.

## The registry

This document is the one claim on the authority mapping; it is owned here and referenced,
never re-declared in a skill (AC-5). Gate numbers are kept for traceability to cadre's
G1-G10; the authority is renamed from cadre's software-release role to the COG role that
actually decides — the **Publisher**, the human who owns the brain and approves the
external write. Each mutation names exactly one authority (AC-1).

| COG mutation | External system | Gate | Deciding authority |
|---|---|---|---|
| Publish a page to Confluence / Notion | Shared wiki | G7 release-readiness | Publisher |
| Post to Slack / socials / webhook | Public channel | G8 deployment-auth | Publisher |
| Sync a team brief back to Linear | Issue tracker | G9 release authority | Publisher |
| content-factory publish | Public post | G7 + G8 | Publisher |
| update-knowledge-base sync to external wiki | Shared KB | G7 | Publisher |

content-factory spans G7 and G8 but has one approval — one authority signs off the whole
publish, not one per gate. That is the one-shape rule (AC-1): the approval record carries a
single authority even when two gates apply.

## Approval-record shape

The approval is recorded in the run-record's `approval` binding **before** the mutation
runs (AC-3), mirroring the schema vendored in Change 1:

```
"human_approvals": [
  {
    "status": "approved",
    "approver": {"id": "<user>", "role": "Publisher", "kind": "human"},
    "decided_at": "<date-time>",
    "evidence_refs": [{"evidence_id": "<gate>-<slug>", "uri": "<artifact>",
                       "hash_algorithm": "sha256", "hash": "<digest>",
                       "classification": "internal"}],
    "note": "gate: G<n> | authority: Publisher"
  }
]
```

A mutation without a recorded approval is not executed: the skill stops at the gate and
asks (AC-2). After the mutation, the external artifact is re-fetched or re-read and
confirmed to match intent, not just the tool return (AC-4) — this is the same post-condition
each skill already runs; the gate simply makes the approval a first-class, audited record.

## Enforcement

Each of the three skills records the approval in the run-record before the mutation and
references this registry:

- `skills/publish-to-confluence/SKILL.md` — G7, Publisher; the run-record approval is
  written before the page is created; the post-condition re-fetches the page.
- `skills/team-brief/SKILL.md` — G9, Publisher; the Linear sync-back is gated with explicit
  approval recorded; the sync is the post-condition.
- `skills/content-factory/SKILL.md` — G7 + G8, Publisher; the publish is gated with the
  approval recorded; the screenshot/curl is the post-condition.
